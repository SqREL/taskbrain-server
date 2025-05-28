# frozen_string_literal: true

require 'openssl'
require 'net/http'
require 'uri'

class WebhookHandler
  def initialize(task_manager, intelligence)
    @task_manager = task_manager
    @intelligence = intelligence
    @logger = task_manager.instance_variable_get(:@logger)
    @redis = task_manager.instance_variable_get(:@redis)
  end

  def verify_todoist_signature(payload, signature)
    return false unless signature

    secret = ENV['WEBHOOK_SECRET']
    expected_signature = OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
    Rack::Utils.secure_compare(signature, "sha256=#{expected_signature}")
  end

  def handle_todoist_event(data)
    event_name = data['event_name']
    event_data = data['event_data']

    @logger.info "Received Todoist webhook: #{event_name}"

    case event_name
    when 'item:added'
      handle_task_created(event_data)
    when 'item:updated'
      handle_task_updated(event_data)
    when 'item:completed'
      handle_task_completed(event_data)
    when 'item:deleted'
      handle_task_deleted(event_data)
    else
      @logger.warn "Unknown Todoist event: #{event_name}"
    end

    # Notify Claude about the change
    notify_claude_of_change(event_name, event_data)
  end

  def handle_linear_event(data)
    action = data['action']
    issue_data = data['data']

    @logger.info "Received Linear webhook: #{action}"

    case action
    when 'create'
      handle_linear_issue_created(issue_data)
    when 'update'
      handle_linear_issue_updated(issue_data)
    when 'remove'
      handle_linear_issue_deleted(issue_data)
    else
      @logger.warn "Unknown Linear event: #{action}"
    end

    # Notify Claude about the change
    notify_claude_of_change("linear:#{action}", issue_data)
  end

  private

  def handle_task_created(event_data)
    # Check if task already exists
    existing_task = @task_manager.instance_variable_get(:@db)[:tasks]
                                 .where(external_id: event_data['id']).first

    return if existing_task

    # Create new task
    task_data = {
      'content' => event_data['content'],
      'description' => event_data['description'],
      'project_id' => event_data['project_id'],
      'priority' => event_data['priority'],
      'due_date' => event_data['due']&.dig('datetime'),
      'labels' => event_data['labels'],
      'external_id' => event_data['id'],
      'source' => 'todoist'
    }

    task = @task_manager.create_task(task_data)

    # Run intelligence analysis
    return unless task

    suggestions = @intelligence.analyze_new_task(task)

    # Auto-apply high-confidence suggestions
    return unless suggestions[:auto_apply]

    @task_manager.update_task(task[:id], suggestions[:updates])
    @logger.info "Auto-applied intelligence suggestions for task #{task[:id]}"
  end

  def handle_task_updated(event_data)
    db = @task_manager.instance_variable_get(:@db)
    task = db[:tasks].where(external_id: event_data['id']).first

    return unless task

    # Update local task
    update_data = {
      'content' => event_data['content'],
      'description' => event_data['description'],
      'priority' => event_data['priority'],
      'due_date' => event_data['due']&.dig('datetime'),
      'labels' => event_data['labels']
    }

    @task_manager.update_task(task[:id], update_data)

    # Re-analyze priorities after update
    updated_task = @task_manager.get_task(task[:id])
    return unless updated_task

    priority_analysis = @intelligence.analyze_priority(updated_task)

    # Suggest priority changes if confidence is high
    if priority_analysis[:confidence] > 0.8 &&
       priority_analysis[:suggested] != updated_task[:priority]

      cache_key = "priority_suggestion:#{task[:id]}"
      suggestion_data = {
        task_id: task[:id],
        current_priority: updated_task[:priority],
        suggested_priority: priority_analysis[:suggested],
        reasoning: priority_analysis[:reasoning],
        timestamp: Time.now.to_i
      }

      @redis.setex(cache_key, 3600, suggestion_data.to_json)
      @logger.info "Cached priority suggestion for task #{task[:id]}"
    end
  end

  def handle_task_completed(event_data)
    db = @task_manager.instance_variable_get(:@db)
    task = db[:tasks].where(external_id: event_data['id']).first

    return unless task

    # Mark as completed in local database
    @task_manager.complete_task(task[:id])

    # Update productivity patterns
    @intelligence.update_patterns

    @logger.info "Marked task #{task[:id]} as completed via webhook"
  end

  def handle_task_deleted(event_data)
    db = @task_manager.instance_variable_get(:@db)
    task = db[:tasks].where(external_id: event_data['id']).first

    return unless task

    # Soft delete - mark as deleted but keep for analytics
    db[:tasks].where(id: task[:id]).update(
      completed: true,
      sync_status: 'deleted',
      updated_at: Time.now
    )

    @logger.info "Soft-deleted task #{task[:id]} via webhook"
  end

  def handle_linear_issue_created(issue_data)
    # Create corresponding task if it's assigned to the user
    return unless should_create_task_for_issue?(issue_data)

    task_data = $linear.create_task_from_issue(issue_data['id'])

    return unless task_data

    task = @task_manager.create_task(task_data)
    @logger.info "Created task #{task[:id]} from Linear issue #{issue_data['identifier']}"
  end

  def handle_linear_issue_updated(issue_data)
    db = @task_manager.instance_variable_get(:@db)
    task = db[:tasks].where(external_id: issue_data['id'], source: 'linear').first

    return unless task

    # Update task based on Linear issue changes
    update_data = {
      'content' => issue_data['title'],
      'description' => issue_data['description'],
      'priority' => linear_priority_to_task_priority(issue_data['priority'])
    }

    # Handle state changes
    if issue_data['state']['type'] == 'completed'
      @task_manager.complete_task(task[:id])
    else
      @task_manager.update_task(task[:id], update_data)
    end
  end

  def handle_linear_issue_deleted(issue_data)
    db = @task_manager.instance_variable_get(:@db)
    task = db[:tasks].where(external_id: issue_data['id'], source: 'linear').first

    return unless task

    # Mark as deleted
    db[:tasks].where(id: task[:id]).update(
      sync_status: 'deleted',
      updated_at: Time.now
    )
  end

  def notify_claude_of_change(event_type, event_data)
    claude_webhook_url = ENV['CLAUDE_WEBHOOK_URL']
    return unless claude_webhook_url

    # Prepare notification payload
    notification = {
      timestamp: Time.now.to_i,
      event_type: event_type,
      event_data: event_data,
      context: {
        total_tasks: @task_manager.count_tasks,
        overdue_tasks: @task_manager.count_overdue_tasks,
        productivity_score: @intelligence.calculate_productivity_score
      }
    }

    # Send async notification
    Thread.new do
      uri = URI(claude_webhook_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = notification.to_json

      response = http.request(request)

      if response.code.to_i >= 200 && response.code.to_i < 300
        @logger.info "Successfully notified Claude of #{event_type}"
      else
        @logger.warn "Failed to notify Claude: #{response.code} #{response.message}"
      end
    rescue StandardError => e
      @logger.error "Error notifying Claude: #{e.message}"
    end
  end

  def should_create_task_for_issue?(issue_data)
    # Create task if issue is assigned to the authenticated user
    # or if it's in a specific team/project we're tracking

    assignee_email = issue_data.dig('assignee', 'email')
    user_email = ENV['USER_EMAIL'] # Set this in environment

    return true if assignee_email == user_email

    # Check if it's in a tracked team
    tracked_teams = ENV['TRACKED_LINEAR_TEAMS']&.split(',') || []
    team_key = issue_data.dig('team', 'key')

    tracked_teams.include?(team_key)
  end

  def linear_priority_to_task_priority(linear_priority)
    case linear_priority
    when 0 then 1 # No priority -> Low
    when 1 then 2 # Low -> Medium-Low
    when 2 then 3 # Medium -> Medium
    when 3 then 4 # High -> High
    when 4 then 5 # Urgent -> Critical
    else 1
    end
  end
end
