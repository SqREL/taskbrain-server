class TaskManager
  def initialize(db, redis, logger)
    @db = db
    @redis = redis
    @logger = logger
    setup_database
  end

  def setup_database
    @db.run <<-SQL
      CREATE TABLE IF NOT EXISTS tasks (
        id SERIAL PRIMARY KEY,
        external_id VARCHAR(255) UNIQUE,
        content TEXT NOT NULL,
        description TEXT,
        project_id VARCHAR(255),
        priority INTEGER DEFAULT 1,
        due_date TIMESTAMP,
        completed BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        source VARCHAR(50) DEFAULT 'manual',
        labels TEXT[],
        parent_id INTEGER REFERENCES tasks(id),
        estimated_duration INTEGER, -- in minutes
        actual_duration INTEGER,
        complexity_score FLOAT,
        energy_level INTEGER, -- 1-5 scale
        context_tags TEXT[],
        dependencies INTEGER[],
        sync_status VARCHAR(20) DEFAULT 'synced'
      );

      CREATE TABLE IF NOT EXISTS task_events (
        id SERIAL PRIMARY KEY,
        task_id INTEGER REFERENCES tasks(id),
        event_type VARCHAR(50) NOT NULL,
        event_data JSONB,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS user_patterns (
        id SERIAL PRIMARY KEY,
        pattern_type VARCHAR(50) NOT NULL,
        pattern_data JSONB,
        confidence_score FLOAT,
        last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
      CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
      CREATE INDEX IF NOT EXISTS idx_tasks_completed ON tasks(completed);
      CREATE INDEX IF NOT EXISTS idx_task_events_type ON task_events(event_type);
    SQL
  end

  def create_task(data)
    task_data = {
      content: data['content'],
      description: data['description'],
      project_id: data['project_id'],
      priority: data['priority'] || 1,
      due_date: parse_due_date(data['due_date']),
      labels: data['labels'] || [],
      estimated_duration: data['estimated_duration'],
      energy_level: data['energy_level'] || 3,
      context_tags: data['context_tags'] || [],
      dependencies: data['dependencies'] || [],
      source: data['source'] || 'manual',
      external_id: data['external_id']
    }

    task_id = @db[:tasks].insert(task_data)
    task = get_task(task_id)
    
    # Log creation event
    log_task_event(task_id, 'created', task_data)
    
    # Cache in Redis for quick access
    @redis.setex("task:#{task_id}", 3600, task.to_json)
    
    @logger.info "Created task: #{task[:content]} (ID: #{task_id})"
    task
  end

  def get_task(id)
    # Try cache first
    cached = @redis.get("task:#{id}")
    return JSON.parse(cached, symbolize_names: true) if cached

    task = @db[:tasks].where(id: id).first
    return nil unless task

    # Enhance with real-time data
    task = enhance_task_data(task)
    
    # Cache result
    @redis.setex("task:#{id}", 3600, task.to_json)
    task
  end

  def get_tasks(filters = {})
    query = @db[:tasks]
    
    query = query.where(completed: false) if filters[:status] == 'active'
    query = query.where(completed: true) if filters[:status] == 'completed'
    query = query.where(project_id: filters[:project]) if filters[:project]
    query = query.where(priority: filters[:priority]) if filters[:priority]
    
    if filters[:due_date]
      case filters[:due_date]
      when 'today'
        query = query.where(due_date: Date.today..Date.today + 1)
      when 'week'
        query = query.where(due_date: Date.today..Date.today + 7)
      when 'overdue'
        query = query.where(Sequel.lit('due_date < ?', DateTime.now))
      end
    end

    tasks = query.order(:priority, :due_date).all
    tasks.map { |task| enhance_task_data(task) }
  end

  def update_task(id, data)
    # Invalidate cache
    @redis.del("task:#{id}")
    
    update_data = data.select { |k, v| 
      ['content', 'description', 'priority', 'due_date', 'completed', 
       'estimated_duration', 'energy_level', 'context_tags', 'labels'].include?(k) 
    }
    
    update_data[:due_date] = parse_due_date(update_data[:due_date]) if update_data[:due_date]
    update_data[:updated_at] = DateTime.now

    rows_updated = @db[:tasks].where(id: id).update(update_data)
    return nil if rows_updated == 0

    task = get_task(id)
    
    # Log update event
    log_task_event(id, 'updated', update_data)
    
    @logger.info "Updated task: #{task[:content]} (ID: #{id})"
    task
  end

  def complete_task(id, actual_duration = nil)
    update_data = {
      completed: true,
      updated_at: DateTime.now,
      actual_duration: actual_duration
    }
    
    task = update_task(id, update_data)
    
    if task
      log_task_event(id, 'completed', { actual_duration: actual_duration })
      
      # Update productivity patterns
      update_completion_patterns(task)
      
      @logger.info "Completed task: #{task[:content]} (ID: #{id})"
    end
    
    task
  end

  def delete_task(id)
    @redis.del("task:#{id}")
    rows_deleted = @db[:tasks].where(id: id).delete
    
    if rows_deleted > 0
      log_task_event(id, 'deleted', {})
      @logger.info "Deleted task ID: #{id}"
      true
    else
      false
    end
  end

  def count_tasks(filters = {})
    query = @db[:tasks]
    query = query.where(completed: false) unless filters[:include_completed]
    query.count
  end

  def count_overdue_tasks
    @db[:tasks].where(
      completed: false,
      Sequel.lit('due_date < ?', DateTime.now)
    ).count
  end

  def count_today_tasks
    @db[:tasks].where(
      completed: false,
      due_date: Date.today..Date.today + 1
    ).count
  end

  def count_high_priority_tasks
    @db[:tasks].where(
      completed: false,
      priority: 4..5
    ).count
  end

  def get_recent_activity(limit = 10)
    @db[:task_events]
      .join(:tasks, id: :task_id)
      .select_all(:task_events)
      .select_append(:tasks__content)
      .order(Sequel.desc(:timestamp))
      .limit(limit)
      .all
  end

  def get_upcoming_deadlines(limit = 5)
    @db[:tasks]
      .where(completed: false)
      .where(Sequel.lit('due_date > ?', DateTime.now))
      .order(:due_date)
      .limit(limit)
      .select(:id, :content, :due_date, :priority)
      .all
  end

  def sync_with_todoist
    token = @redis.get('todoist_token')
    return unless token

    # Fetch latest tasks from Todoist
    response = HTTParty.get(
      'https://api.todoist.com/rest/v2/tasks',
      headers: { 'Authorization' => "Bearer #{token}" }
    )

    return unless response.success?

    todoist_tasks = JSON.parse(response.body)
    
    todoist_tasks.each do |todoist_task|
      existing_task = @db[:tasks].where(external_id: todoist_task['id']).first
      
      task_data = {
        content: todoist_task['content'],
        description: todoist_task['description'],
        project_id: todoist_task['project_id'],
        priority: todoist_task['priority'],
        due_date: todoist_task['due'] ? DateTime.parse(todoist_task['due']['datetime']) : nil,
        completed: todoist_task['is_completed'],
        labels: todoist_task['labels'],
        external_id: todoist_task['id'],
        source: 'todoist',
        updated_at: DateTime.now
      }

      if existing_task
        @db[:tasks].where(id: existing_task[:id]).update(task_data)
        @redis.del("task:#{existing_task[:id]}")
      else
        @db[:tasks].insert(task_data.merge(created_at: DateTime.now))
      end
    end

    @logger.info "Synced #{todoist_tasks.length} tasks from Todoist"
  end

  def get_productivity_analytics(period = 'week')
    end_date = DateTime.now
    start_date = case period
    when 'day'
      end_date - 1
    when 'week'
      end_date - 7
    when 'month'
      end_date - 30
    else
      end_date - 7
    end

    completed_tasks = @db[:tasks].where(
      completed: true,
      updated_at: start_date..end_date
    ).count

    total_tasks = @db[:tasks].where(
      created_at: start_date..end_date
    ).count

    avg_completion_time = @db[:tasks].where(
      completed: true,
      updated_at: start_date..end_date
    ).avg(:actual_duration) || 0

    {
      period: period,
      completed_tasks: completed_tasks,
      total_tasks: total_tasks,
      completion_rate: total_tasks > 0 ? (completed_tasks.to_f / total_tasks * 100).round(2) : 0,
      avg_completion_time: avg_completion_time.round(2)
    }
  end

  private

  def enhance_task_data(task)
    # Add computed fields
    task = task.dup
    task[:is_overdue] = task[:due_date] && !task[:completed] && task[:due_date] < DateTime.now
    task[:days_until_due] = task[:due_date] ? ((task[:due_date] - DateTime.now) / 86400).round : nil
    task[:urgency_score] = calculate_urgency_score(task)
    
    # Add subtasks if any
    task[:subtasks] = @db[:tasks].where(parent_id: task[:id]).all
    
    task
  end

  def calculate_urgency_score(task)
    score = task[:priority] || 1
    
    if task[:due_date]
      days_until_due = (task[:due_date] - DateTime.now) / 86400
      
      if days_until_due < 0
        score += 10 # Overdue
      elsif days_until_due < 1
        score += 5 # Due today
      elsif days_until_due < 3
        score += 3 # Due soon
      end
    end
    
    score
  end

  def parse_due_date(date_string)
    return nil unless date_string
    
    if date_string.is_a?(String)
      # Try parsing with Chronic for natural language
      Chronic.parse(date_string) || DateTime.parse(date_string)
    else
      date_string
    end
  rescue
    nil
  end

  def log_task_event(task_id, event_type, event_data)
    @db[:task_events].insert(
      task_id: task_id,
      event_type: event_type,
      event_data: Sequel.pg_jsonb(event_data),
      timestamp: DateTime.now
    )
  end

  def update_completion_patterns(task)
    # Analyze patterns for future intelligence
    hour_of_day = task[:updated_at].hour
    day_of_week = task[:updated_at].wday
    
    pattern_data = {
      hour: hour_of_day,
      day: day_of_week,
      priority: task[:priority],
      estimated_duration: task[:estimated_duration],
      actual_duration: task[:actual_duration]
    }

    @db[:user_patterns].insert(
      pattern_type: 'completion_time',
      pattern_data: Sequel.pg_jsonb(pattern_data),
      confidence_score: 1.0,
      last_updated: DateTime.now
    )
  end
end
