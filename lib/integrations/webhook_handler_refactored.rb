# frozen_string_literal: true

require 'openssl'
require 'net/http'
require 'uri'
require_relative '../errors'

class WebhookHandler
  def initialize(task_manager, intelligence, linear_integration = nil)
    @task_manager = task_manager
    @intelligence = intelligence
    @linear = linear_integration
    @logger = task_manager.instance_variable_get(:@logger)
    @redis = task_manager.instance_variable_get(:@redis)
  end

  def verify_todoist_signature(payload, signature)
    return false unless signature

    secret = ENV['TODOIST_WEBHOOK_SECRET'] || ENV.fetch('WEBHOOK_SECRET', nil)
    raise TaskBrain::ConfigurationError, 'TODOIST_WEBHOOK_SECRET not configured' unless secret

    expected_signature = OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
    valid = Rack::Utils.secure_compare(signature, "sha256=#{expected_signature}")

    raise TaskBrain::WebhookVerificationError, 'Todoist' unless valid

    true
  end

  def verify_linear_signature(payload, signature)
    return false unless signature

    secret = ENV.fetch('LINEAR_WEBHOOK_SECRET', nil)
    raise TaskBrain::ConfigurationError, 'LINEAR_WEBHOOK_SECRET not configured' unless secret

    expected_signature = OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
    valid = Rack::Utils.secure_compare(signature, expected_signature)

    raise TaskBrain::WebhookVerificationError, 'Linear' unless valid

    true
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
  rescue StandardError => e
    @logger.error "Error handling Todoist event: #{e.message}"
    raise
  end

  def handle_linear_event(data)
    raise TaskBrain::ConfigurationError, 'Linear integration not configured' unless @linear

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
  rescue StandardError => e
    @logger.error "Error handling Linear event: #{e.message}"
    raise
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

    task_data = @linear.create_task_from_issue(issue_data['id'])

    return unless task_data

    task = @task_manager.create_task(task_data)
    @logger.info "Created task #{task[:id]} from Linear issue #{issue_data['identifier']}"
  end

  def handle_linear_issue_updated(issue_data)
    db = @task_manager.instance_variable_get(:@db)
    task = db[:tasks].where(external_id: issue_data['id'], source: 'linear').first

    return unless task

    # Update task from Linear data
    update_data = @linear.format_issue_for_update(issue_data)
    @task_manager.update_task(task[:id], update_data)

    @logger.info "Updated task #{task[:id]} from Linear issue #{issue_data['identifier']}"
  end

  def handle_linear_issue_deleted(issue_data)
    db = @task_manager.instance_variable_get(:@db)
    task = db[:tasks].where(external_id: issue_data['id'], source: 'linear').first

    return unless task

    # Soft delete the task
    db[:tasks].where(id: task[:id]).update(
      completed: true,
      sync_status: 'deleted',
      updated_at: Time.now
    )

    @logger.info "Soft-deleted task #{task[:id]} for Linear issue #{issue_data['identifier']}"
  end

  def should_create_task_for_issue?(issue_data)
    # Check if issue is assigned to the user
    return false unless issue_data['assignee']

    user_id = ENV.fetch('LINEAR_USER_ID', nil)
    return false unless user_id

    issue_data['assignee']['id'] == user_id
  end

  def notify_claude_of_change(event_type, event_data)
    webhook_url = ENV.fetch('CLAUDE_WEBHOOK_URL', nil)
    return unless webhook_url

    Thread.new do
      payload = {
        event_type: event_type,
        event_data: event_data,
        timestamp: Time.now.iso8601,
        context: gather_context_for_event(event_type, event_data)
      }

      uri = URI(webhook_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.read_timeout = 10
      http.open_timeout = 5

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request['X-API-Key'] = ENV.fetch('CLAUDE_API_KEY', nil)
      request.body = payload.to_json

      response = http.request(request)

      if response.code.to_i >= 300
        @logger.error "Failed to notify Claude: #{response.code} - #{response.body}"
      else
        @logger.info "Successfully notified Claude of #{event_type}"
      end
    rescue StandardError => e
      @logger.error "Error notifying Claude: #{e.message}"
    end
  end

  def gather_context_for_event(_event_type, _event_data)
    {
      total_active_tasks: @task_manager.count_tasks,
      overdue_count: @task_manager.count_overdue_tasks,
      today_count: @task_manager.count_today_tasks,
      recent_completions: @task_manager.get_recent_activity(5).select { |a| a[:action] == 'completed' },
      productivity_score: @intelligence.calculate_productivity_score
    }
  rescue StandardError => e
    @logger.error "Error gathering context: #{e.message}"
    {}
  end
end
