class TaskIntelligence
  def initialize(task_manager, calendar, linear)
    @task_manager = task_manager
    @calendar = calendar
    @linear = linear
    @db = task_manager.instance_variable_get(:@db)
    @redis = task_manager.instance_variable_get(:@redis)
    @logger = task_manager.instance_variable_get(:@logger)
  end

  def analyze_new_task(task)
    suggestions = {
      priority_adjustment: analyze_priority(task),
      time_estimate: estimate_duration(task),
      optimal_schedule: suggest_optimal_time(task),
      dependencies: detect_dependencies(task),
      breakdown_suggestions: suggest_breakdown(task),
      context_recommendations: suggest_context(task),
      auto_apply: false
    }

    # Determine if we should auto-apply suggestions
    confidence_scores = suggestions.values.map { |s| s.is_a?(Hash) ? s[:confidence] || 0 : 0 }
    avg_confidence = confidence_scores.sum / confidence_scores.length.to_f

    if avg_confidence > 0.8
      suggestions[:auto_apply] = true
      suggestions[:updates] = build_auto_updates(suggestions)
    end

    suggestions
  end

  def suggest_priorities
    tasks = @task_manager.get_tasks(status: 'active')
    
    # Score tasks based on multiple factors
    scored_tasks = tasks.map do |task|
      score = calculate_comprehensive_score(task)
      task.merge(intelligence_score: score)
    end

    # Sort by score and return top priorities
    priorities = scored_tasks.sort_by { |t| -t[:intelligence_score] }.first(10)
    
    {
      high_priority: priorities.first(3),
      medium_priority: priorities[3..6],
      context_based: get_context_based_priorities,
      energy_matched: get_energy_matched_tasks
    }
  end

  def suggest_daily_schedule(date)
    target_date = Date.parse(date)
    tasks = @task_manager.get_tasks(status: 'active')
    calendar_events = @calendar.get_events_for_date(date)
    
    # Filter tasks suitable for the day
    suitable_tasks = tasks.select do |task|
      task[:due_date].nil? || Date.parse(task[:due_date].to_s) <= target_date + 3
    end

    # Build time-based schedule
    schedule = build_optimal_schedule(suitable_tasks, calendar_events, target_date)
    
    {
      morning_block: schedule[:morning],
      afternoon_block: schedule[:afternoon],
      evening_block: schedule[:evening],
      buffer_tasks: schedule[:buffer],
      estimated_workload: calculate_daily_workload(schedule),
      energy_optimization: optimize_for_energy_levels(schedule)
    }
  end

  def get_overdue_analysis
    overdue_tasks = @db[:tasks].where(
      completed: false,
      Sequel.lit('due_date < ?', DateTime.now)
    ).all

    analysis = {
      total_overdue: overdue_tasks.length,
      critical_overdue: overdue_tasks.select { |t| t[:priority] >= 4 }.length,
      avg_overdue_days: calculate_avg_overdue_days(overdue_tasks),
      reschedule_suggestions: [],
      impact_analysis: analyze_overdue_impact(overdue_tasks)
    }

    # Generate reschedule suggestions
    overdue_tasks.each do |task|
      suggestion = generate_reschedule_suggestion(task)
      analysis[:reschedule_suggestions] << suggestion if suggestion
    end

    analysis
  end

  def smart_reschedule(task_id, new_date)
    task = @task_manager.get_task(task_id)
    return { error: 'Task not found' } unless task

    parsed_date = Date.parse(new_date)
    
    # Analyze impact of rescheduling
    impact = analyze_reschedule_impact(task, parsed_date)
    
    # Check for conflicts
    conflicts = check_schedule_conflicts(parsed_date, task[:estimated_duration])
    
    # Generate alternative suggestions if conflicts exist
    alternatives = conflicts.any? ? suggest_alternative_dates(task, parsed_date) : []

    result = {
      feasible: conflicts.empty?,
      conflicts: conflicts,
      alternatives: alternatives,
      impact_score: impact[:score],
      recommendations: impact[:recommendations]
    }

    # Auto-reschedule if highly feasible
    if result[:feasible] && impact[:score] > 0.7
      @task_manager.update_task(task_id, { due_date: parsed_date })
      result[:rescheduled] = true
    end

    result
  end

  def calculate_productivity_score
    # Analyze recent productivity patterns
    recent_completion = @db[:tasks].where(
      completed: true,
      updated_at: (DateTime.now - 7)..DateTime.now
    ).count

    total_created = @db[:tasks].where(
      created_at: (DateTime.now - 7)..DateTime.now
    ).count

    overdue_count = @task_manager.count_overdue_tasks
    
    # Base score from completion rate
    base_score = total_created > 0 ? (recent_completion.to_f / total_created * 100) : 50
    
    # Penalties for overdue tasks
    overdue_penalty = overdue_count * 5
    
    # Bonus for consistent patterns
    consistency_bonus = calculate_consistency_bonus
    
    score = [base_score - overdue_penalty + consistency_bonus, 0].max
    [score, 100].min.round(1)
  end

  def get_morning_recommendations
    current_hour = Time.now.hour
    return get_general_recommendations unless (6..11).include?(current_hour)

    high_energy_tasks = @db[:tasks].where(
      completed: false,
      energy_level: 4..5
    ).order(:priority).limit(5).all

    {
      focus_tasks: high_energy_tasks.first(3),
      quick_wins: get_quick_win_tasks,
      planning_items: get_planning_tasks,
      energy_note: "Morning is optimal for high-energy, complex tasks"
    }
  end

  def get_afternoon_recommendations
    current_hour = Time.now.hour
    return get_general_recommendations unless (12..17).include?(current_hour)

    {
      collaborative_tasks: get_collaborative_tasks,
      medium_energy_tasks: get_medium_energy_tasks,
      communication_items: get_communication_tasks,
      energy_note: "Afternoon is great for collaboration and communication"
    }
  end

  def get_planning_recommendations
    incomplete_projects = analyze_incomplete_projects
    upcoming_deadlines = @task_manager.get_upcoming_deadlines(10)
    
    {
      project_health: incomplete_projects,
      deadline_alerts: upcoming_deadlines,
      capacity_analysis: analyze_current_capacity,
      suggested_focus_areas: suggest_focus_areas,
      weekly_goals: generate_weekly_goals
    }
  end

  def get_general_recommendations
    {
      top_priorities: suggest_priorities[:high_priority],
      quick_actions: get_quick_win_tasks,
      overdue_attention: get_overdue_analysis[:critical_overdue],
      productivity_tip: get_contextual_productivity_tip
    }
  end

  def analyze_completion_patterns
    patterns = @db[:user_patterns].where(pattern_type: 'completion_time').all
    
    return {} if patterns.empty?

    # Analyze by hour of day
    hourly_completions = patterns.group_by { |p| p[:pattern_data]['hour'] }
    best_hours = hourly_completions.sort_by { |hour, completions| -completions.length }.first(3)

    # Analyze by day of week
    daily_completions = patterns.group_by { |p| p[:pattern_data]['day'] }
    best_days = daily_completions.sort_by { |day, completions| -completions.length }.first(3)

    {
      optimal_hours: best_hours.map(&:first),
      optimal_days: best_days.map(&:first),
      completion_velocity: calculate_completion_velocity(patterns),
      accuracy_rate: calculate_estimation_accuracy(patterns)
    }
  end

  def update_patterns
    # Update machine learning patterns based on recent data
    recent_completions = @db[:task_events].where(
      event_type: 'completed',
      timestamp: (DateTime.now - 30)..DateTime.now
    ).all

    # Update time-based patterns
    update_time_patterns(recent_completions)
    
    # Update complexity patterns
    update_complexity_patterns(recent_completions)
    
    @logger.info "Updated intelligence patterns from #{recent_completions.length} recent completions"
  end

  def analyze_task_impact(task)
    {
      dependency_impact: analyze_dependency_impact(task),
      project_impact: analyze_project_impact(task),
      deadline_cascade: analyze_deadline_cascade(task),
      team_impact: analyze_team_impact(task)
    }
  end

  private

  def analyze_priority(task)
    content_keywords = extract_keywords(task[:content])
    urgency_words = ['urgent', 'asap', 'critical', 'important', 'deadline']
    
    urgency_score = urgency_words.any? { |word| content_keywords.include?(word) } ? 1 : 0
    
    # Check for deadline proximity
    deadline_score = 0
    if task[:due_date]
      days_until = (Date.parse(task[:due_date].to_s) - Date.today).to_i
      deadline_score = 1 if days_until <= 1
      deadline_score = 0.5 if days_until <= 3
    end

    suggested_priority = [task[:priority] + urgency_score + deadline_score, 5].min
    
    {
      current: task[:priority],
      suggested: suggested_priority.round,
      reasoning: build_priority_reasoning(urgency_score, deadline_score),
      confidence: 0.7
    }
  end

  def estimate_duration(task)
    content = task[:content].downcase
    
    # Simple keyword-based estimation
    if content.include?('quick') || content.include?('simple')
      estimate = 15
    elsif content.include?('review') || content.include?('check')
      estimate = 30
    elsif content.include?('meeting') || content.include?('call')
      estimate = 60
    elsif content.include?('research') || content.include?('analyze')
      estimate = 120
    elsif content.include?('create') || content.include?('build')
      estimate = 180
    else
      estimate = 60 # default
    end

    {
      estimate_minutes: estimate,
      confidence: 0.6,
      reasoning: "Based on task content analysis"
    }
  end

  def suggest_optimal_time(task)
    patterns = analyze_completion_patterns
    
    if patterns[:optimal_hours]&.any?
      optimal_hour = patterns[:optimal_hours].first
      {
        suggested_time: "#{optimal_hour}:00",
        reasoning: "Based on your completion patterns",
        confidence: 0.8
      }
    else
      {
        suggested_time: "09:00",
        reasoning: "General productivity recommendation",
        confidence: 0.4
      }
    end
  end

  def detect_dependencies(task)
    # Simple keyword matching for dependencies
    all_tasks = @task_manager.get_tasks(status: 'active')
    potential_deps = []

    task_keywords = extract_keywords(task[:content])
    
    all_tasks.each do |other_task|
      next if other_task[:id] == task[:id]
      
      other_keywords = extract_keywords(other_task[:content])
      overlap = (task_keywords & other_keywords).length
      
      if overlap > 1
        potential_deps << {
          task_id: other_task[:id],
          task_content: other_task[:content],
          relationship_strength: overlap
        }
      end
    end

    {
      dependencies: potential_deps.first(3),
      confidence: potential_deps.any? ? 0.5 : 0.1
    }
  end

  def suggest_breakdown(task)
    content = task[:content]
    
    # Suggest breakdown for complex tasks
    if content.length > 100 || content.include?('and') || content.include?('&')
      {
        should_break_down: true,
        suggested_subtasks: generate_subtask_suggestions(content),
        confidence: 0.6
      }
    else
      {
        should_break_down: false,
        confidence: 0.8
      }
    end
  end

  def suggest_context(task)
    content = task[:content].downcase
    
    contexts = []
    contexts << 'computer' if content.match?(/email|code|write|research|online/)
    contexts << 'phone' if content.match?(/call|contact|reach out/)
    contexts << 'meeting' if content.match?(/discuss|meet|present/)
    contexts << 'focused' if content.match?(/analyze|create|plan|design/)
    
    {
      suggested_contexts: contexts,
      confidence: contexts.any? ? 0.7 : 0.3
    }
  end

  def build_auto_updates(suggestions)
    updates = {}
    
    if suggestions[:priority_adjustment][:confidence] > 0.8
      updates[:priority] = suggestions[:priority_adjustment][:suggested]
    end
    
    if suggestions[:time_estimate][:confidence] > 0.7
      updates[:estimated_duration] = suggestions[:time_estimate][:estimate_minutes]
    end
    
    if suggestions[:context_recommendations][:confidence] > 0.7
      updates[:context_tags] = suggestions[:context_recommendations][:suggested_contexts]
    end
    
    updates
  end

  def calculate_comprehensive_score(task)
    score = 0
    
    # Priority weight (0-25 points)
    score += (task[:priority] || 1) * 5
    
    # Urgency based on due date (0-25 points)
    if task[:due_date]
      days_until = (Date.parse(task[:due_date].to_s) - Date.today).to_i
      if days_until < 0
        score += 25 # Overdue
      elsif days_until == 0
        score += 20 # Due today
      elsif days_until <= 2
        score += 15 # Due soon
      elsif days_until <= 7
        score += 10 # Due this week
      end
    end
    
    # Context relevance (0-15 points)
    current_hour = Time.now.hour
    if task[:energy_level]
      if (6..11).include?(current_hour) && task[:energy_level] >= 4
        score += 15 # High energy task in morning
      elsif (12..17).include?(current_hour) && task[:energy_level] == 3
        score += 10 # Medium energy task in afternoon
      elsif (18..22).include?(current_hour) && task[:energy_level] <= 2
        score += 8 # Low energy task in evening
      end
    end
    
    # Project importance (0-10 points)
    if task[:project_id]
      project_task_count = @db[:tasks].where(project_id: task[:project_id], completed: false).count
      score += [project_task_count, 10].min
    end
    
    # Dependency factor (0-10 points)
    dependent_tasks = @db[:tasks].where(Sequel.pg_array(:dependencies).contains([task[:id]])).count
    score += [dependent_tasks * 3, 10].min
    
    score
  end

  def get_context_based_priorities
    current_hour = Time.now.hour
    
    if (6..11).include?(current_hour)
      @db[:tasks].where(completed: false, energy_level: 4..5).order(:priority).limit(3).all
    elsif (12..17).include?(current_hour)
      @db[:tasks].where(completed: false, energy_level: 2..3).order(:priority).limit(3).all
    else
      @db[:tasks].where(completed: false, energy_level: 1..2).order(:priority).limit(3).all
    end
  end

  def get_energy_matched_tasks
    current_hour = Time.now.hour
    
    # Match tasks to typical energy levels throughout the day
    if (6..10).include?(current_hour)
      energy_filter = 4..5 # High energy morning
    elsif (10..14).include?(current_hour)
      energy_filter = 3..4 # Good mid-morning to early afternoon
    elsif (14..17).include?(current_hour)
      energy_filter = 2..3 # Moderate afternoon
    else
      energy_filter = 1..2 # Low energy evening/night
    end

    @db[:tasks].where(completed: false, energy_level: energy_filter).order(:priority).limit(5).all
  end

  def build_optimal_schedule(tasks, events, date)
    schedule = {
      morning: [],
      afternoon: [],
      evening: [],
      buffer: []
    }

    # Sort tasks by intelligence score
    sorted_tasks = tasks.sort_by { |t| -calculate_comprehensive_score(t) }

    # Allocate to time blocks based on energy levels
    sorted_tasks.each do |task|
      energy = task[:energy_level] || 3
      
      if energy >= 4 && schedule[:morning].length < 3
        schedule[:morning] << task
      elsif energy >= 3 && schedule[:afternoon].length < 4
        schedule[:afternoon] << task
      elsif schedule[:evening].length < 2
        schedule[:evening] << task
      else
        schedule[:buffer] << task
      end
    end

    schedule
  end

  def calculate_daily_workload(schedule)
    total_minutes = 0
    
    schedule.each do |period, tasks|
      next if period == :buffer
      
      period_minutes = tasks.sum { |t| t[:estimated_duration] || 60 }
      total_minutes += period_minutes
    end
    
    {
      total_minutes: total_minutes,
      total_hours: (total_minutes / 60.0).round(1),
      workload_level: categorize_workload(total_minutes)
    }
  end

  def categorize_workload(minutes)
    case minutes
    when 0..240 then 'light'
    when 241..480 then 'moderate'
    when 481..600 then 'heavy'
    else 'overloaded'
    end
  end

  def optimize_for_energy_levels(schedule)
    recommendations = []
    
    # Check if high-energy tasks are in morning
    morning_energy = schedule[:morning].map { |t| t[:energy_level] || 3 }.sum
    if morning_energy < 10
      recommendations << "Consider moving high-energy tasks to morning block"
    end
    
    # Check evening workload
    evening_workload = schedule[:evening].sum { |t| t[:estimated_duration] || 60 }
    if evening_workload > 120
      recommendations << "Evening block may be too heavy - consider lighter tasks"
    end
    
    recommendations
  end

  def extract_keywords(text)
    # Simple keyword extraction
    words = text.downcase.split(/\W+/)
    stopwords = %w[the and or but in on at to for of with by from a an is are was were be been being have has had do does did will would could should]
    words.reject { |word| stopwords.include?(word) || word.length < 3 }
  end

  def build_priority_reasoning(urgency_score, deadline_score)
    reasons = []
    reasons << "Contains urgency keywords" if urgency_score > 0
    reasons << "Has approaching deadline" if deadline_score > 0
    reasons.join(", ")
  end

  def generate_subtask_suggestions(content)
    # Simple heuristic for breaking down tasks
    if content.include?(' and ')
      content.split(' and ').map(&:strip)
    elsif content.length > 100
      ["Plan and research for: #{content[0..50]}...", "Execute: #{content[0..50]}...", "Review and finalize: #{content[0..50]}..."]
    else
      []
    end
  end

  # Additional helper methods would continue here...
  def calculate_avg_overdue_days(overdue_tasks)
    return 0 if overdue_tasks.empty?
    
    total_overdue_days = overdue_tasks.sum do |task|
      (DateTime.now - task[:due_date]).to_i
    end
    
    (total_overdue_days / overdue_tasks.length.to_f).round(1)
  end

  def analyze_overdue_impact(overdue_tasks)
    {
      high_priority_overdue: overdue_tasks.count { |t| t[:priority] >= 4 },
      project_impact: overdue_tasks.group_by { |t| t[:project_id] }.transform_values(&:count),
      dependency_blocks: count_dependency_blocks(overdue_tasks)
    }
  end

  def count_dependency_blocks(overdue_tasks)
    overdue_ids = overdue_tasks.map { |t| t[:id] }
    
    @db[:tasks].where(completed: false).select do |task|
      dependencies = task[:dependencies] || []
      (dependencies & overdue_ids).any?
    end.count
  end

  def get_quick_win_tasks
    @db[:tasks].where(
      completed: false,
      Sequel.lit('estimated_duration <= ?', 30)
    ).order(:priority).limit(5).all
  end

  def get_contextual_productivity_tip
    hour = Time.now.hour
    
    case hour
    when 6..9
      "Morning focus: Tackle your most challenging task first"
    when 9..12
      "Peak performance time: Ideal for complex problem-solving"
    when 12..14
      "Post-lunch: Good time for routine tasks and communication"
    when 14..17
      "Afternoon energy: Collaborate and handle meetings"
    when 17..20
      "Wind down: Review progress and plan tomorrow"
    else
      "Evening: Light tasks and preparation for tomorrow"
    end
  end
end
