# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'sinatra/cors'
require 'json'
require 'dotenv/load' unless ENV['RACK_ENV'] == 'test'

# Load application files
require_relative 'lib/app_config'
require_relative 'lib/errors'
require_relative 'lib/task_manager'
require_relative 'lib/integrations/todoist'
require_relative 'lib/integrations/google_calendar'
require_relative 'lib/integrations/linear'
require_relative 'lib/task_intelligence'
require_relative 'lib/integrations/webhook_handler_refactored'
require_relative 'lib/security_utils'
require_relative 'lib/validation_utils'
require_relative 'lib/services/task_service'
require_relative 'lib/services/intelligence_service'
require_relative 'lib/services/auth_service'
require_relative 'lib/helpers/request_helpers'

class TaskBrainApp < Sinatra::Base
  configure do
    set :port, 3000
    set :bind, '0.0.0.0'
    set :logging, true

    # CORS configuration
    set :allow_origin, ENV['ALLOWED_ORIGINS']&.split(',')&.first || 'https://claude.ai'
    set :allow_methods, 'GET,HEAD,POST,PUT,DELETE,OPTIONS'
    set :allow_headers, 'Authorization,Content-Type,Accept,X-Claude-API-Key'

    # Initialize configuration
    set :app_config, AppConfig.new(env: settings.environment).setup!

    # Initialize services
    set :task_service, Services::TaskService.new(
      settings.app_config.task_manager,
      settings.app_config.intelligence
    )

    set :intelligence_service, Services::IntelligenceService.new(
      settings.app_config.task_manager,
      settings.app_config.intelligence,
      settings.app_config.calendar
    )

    set :auth_service, Services::AuthService.new(
      settings.app_config.redis,
      settings.app_config.integrations
    )
  end

  # Helpers
  helpers RequestHelpers

  helpers do
    def app_config
      settings.app_config
    end

    def task_service
      settings.task_service
    end

    def intelligence_service
      settings.intelligence_service
    end

    def auth_service
      settings.auth_service
    end
  end

  # Middleware
  before do
    headers['Access-Control-Allow-Origin'] = settings.allow_origin
    headers['Access-Control-Allow-Methods'] = settings.allow_methods
    headers['Access-Control-Allow-Headers'] = settings.allow_headers if request.options?

    content_type :json
    @request_start_time = Time.now
  end

  after do
    if @request_start_time && app_config.logger
      duration = ((Time.now - @request_start_time) * 1000).round(2)
      method = request.request_method
      path = request.path_info
      app_config.logger.info "#{method} #{path} - Completed #{response.status} in #{duration}ms"
    end
  end

  # Authentication filters
  before '/api/*' do
    pass if request.path_info == '/api/health'

    unless authenticate_request
      app_config.logger&.warn "Unauthorized access attempt: #{request.path_info}"
      json_error('Unauthorized - Invalid API key', 401)
    end
  end

  before '/api/claude/*' do
    unless authenticate_claude_request
      app_config.logger&.warn "Unauthorized Claude API access attempt: #{request.path_info}"
      json_error('Unauthorized - Invalid Claude API key', 401)
    end
  end

  # CORS
  options '*' do
    200
  end

  # Public endpoints
  get '/health' do
    { status: 'ok', timestamp: Time.now.to_i }.to_json
  end

  get '/' do
    content_type :html
    File.read('public/dashboard.html')
  end

  # Authentication endpoints
  post '/auth/todoist' do
    result = auth_service.authenticate_todoist(params[:code])
    json_response(result)
  rescue TaskBrain::IntegrationError => e
    json_error(e.message, 400)
  end

  post '/auth/google' do
    result = auth_service.authenticate_google(params[:code])
    json_response(result)
  rescue TaskBrain::IntegrationError => e
    json_error(e.message, 400)
  end

  # Task management endpoints
  get '/api/tasks' do
    filter_errors = ValidationUtils.validate_filters(params)
    json_error(filter_errors, 400) if filter_errors.any?

    filters = {
      project: params[:project],
      priority: params[:priority],
      due_date: params[:due_date],
      status: params[:status] || 'active'
    }.compact

    tasks = task_service.list_tasks(filters)
    json_response({ tasks: tasks })
  end

  get '/api/tasks/:id' do
    task = task_service.find_task(params[:id])
    json_response(task)
  rescue TaskBrain::NotFoundError => e
    json_error(e.message, 404)
  end

  post '/api/tasks' do
    validation_result = validate_json_body
    json_error(validation_result[:errors], 400) if validation_result[:errors]

    result = task_service.create_task_with_intelligence(validation_result[:data])
    json_response(result)
  rescue TaskBrain::ValidationError => e
    json_error(e.errors, 400)
  end

  put '/api/tasks/:id' do
    validation_result = validate_json_body
    json_error(validation_result[:errors], 400) if validation_result[:errors]

    task = task_service.update_task(params[:id], validation_result[:data])
    json_response(task)
  rescue TaskBrain::NotFoundError => e
    json_error(e.message, 404)
  rescue TaskBrain::ValidationError => e
    json_error(e.errors, 400)
  end

  delete '/api/tasks/:id' do
    task_service.delete_task(params[:id])
    json_response({ success: true })
  rescue TaskBrain::NotFoundError => e
    json_error(e.message, 404)
  end

  # Intelligence endpoints
  get '/api/intelligence/priorities' do
    priorities = intelligence_service.priorities
    json_response({ priorities: priorities })
  end

  get '/api/intelligence/schedule' do
    schedule = intelligence_service.daily_schedule(params[:date])
    json_response({ schedule: schedule })
  end

  get '/api/intelligence/overdue' do
    overdue = intelligence_service.analyze_overdue_tasks
    json_response({ overdue: overdue })
  end

  post '/api/intelligence/reschedule' do
    data = json_body
    result = intelligence_service.smart_reschedule_task(data['task_id'], data['new_date'])
    json_response(result)
  rescue TaskBrain::ValidationError => e
    json_error(e.message, 400)
  end

  # Context endpoints
  get '/api/context/calendar' do
    date = params[:date] || Date.today.to_s
    events = app_config.calendar.get_events_for_date(date)
    json_response({ events: events })
  end

  get '/api/context/linear' do
    issues = app_config.linear.get_issues(params[:project])
    json_response({ issues: issues })
  end

  # Webhook endpoints
  post '/webhooks/todoist' do
    signature = request.env['HTTP_X_TODOIST_HMAC_SHA256']
    payload = request.body.read

    json_error('Invalid signature', 401) unless app_config.webhook_handler.verify_todoist_signature(payload, signature)

    data = JSON.parse(payload)
    app_config.webhook_handler.handle_todoist_event(data)
    json_response({ success: true })
  rescue TaskBrain::WebhookVerificationError => e
    json_error(e.message, 401)
  end

  post '/webhooks/linear' do
    signature = request.env['HTTP_X_LINEAR_SIGNATURE']
    payload = request.body.read

    json_error('Invalid signature', 401) unless app_config.webhook_handler.verify_linear_signature(payload, signature)

    data = JSON.parse(payload)
    app_config.webhook_handler.handle_linear_event(data)
    json_response({ success: true })
  rescue TaskBrain::WebhookVerificationError => e
    json_error(e.message, 401)
  end

  # Analytics endpoints
  get '/api/analytics/productivity' do
    period = params[:period] || 'week'
    analytics = app_config.task_manager.get_productivity_analytics(period)
    json_response(analytics)
  end

  get '/api/analytics/patterns' do
    patterns = app_config.intelligence.analyze_completion_patterns
    json_response({ patterns: patterns })
  end

  # Claude API endpoints
  get '/api/claude/full_context' do
    context = intelligence_service.full_context
    json_response(context)
  end

  post '/api/claude/smart_create' do
    validation_result = validate_json_body
    json_error(validation_result[:errors], 400) if validation_result[:errors]

    result = task_service.create_task_with_intelligence(validation_result[:data])

    # Add additional context for Claude
    result[:optimal_scheduling] = suggest_optimal_time_slots(
      result[:task],
      calendar_availability_context
    )
    result[:recommended_actions] = generate_immediate_actions(result[:task])

    json_response(result)
  rescue TaskBrain::ValidationError => e
    json_error(e.errors, 400)
  end

  post '/api/claude/bulk_create' do
    data = json_body
    tasks_data = data['tasks']

    json_error(['Tasks must be an array'], 400) unless tasks_data.is_a?(Array)

    # Validate each task
    tasks_data.each_with_index do |task_data, index|
      errors = ValidationUtils.validate_task_data(task_data)
      json_error("Task at index #{index}: #{errors.join(', ')}", 400) if errors.any?
    end

    results = task_service.bulk_create_tasks(tasks_data)
    json_response({ results: results })
  rescue TaskBrain::ValidationError => e
    json_error(e.errors, 400)
  end

  get '/api/claude/context/:date' do
    context = intelligence_service.context_for_date(params[:date])
    json_response(context)
  rescue TaskBrain::ValidationError => e
    json_error(e.message, 400)
  end

  post '/api/claude/reschedule_batch' do
    data = json_body
    reschedule_requests = data['reschedule_requests']

    json_error(['Reschedule requests must be an array'], 400) unless reschedule_requests.is_a?(Array)

    results = intelligence_service.batch_reschedule_tasks(reschedule_requests)
    json_response({ results: results })
  rescue TaskBrain::ValidationError => e
    json_error(e.errors, 400)
  end

  get '/api/claude/status' do
    status = task_service.status_summary
    json_response(status)
  end

  get '/api/claude/recommendations' do
    recommendations = intelligence_service.recommendations(params[:context])
    json_response(recommendations)
  end

  # Error handlers
  error TaskBrain::NotFoundError do
    json_error(env['sinatra.error'].message, 404)
  end

  error TaskBrain::ValidationError do
    error = env['sinatra.error']
    json_error(error.errors, 400)
  end

  error TaskBrain::AuthenticationError do
    json_error(env['sinatra.error'].message, 401)
  end

  error TaskBrain::AuthorizationError do
    json_error(env['sinatra.error'].message, 403)
  end

  error TaskBrain::IntegrationError do
    app_config.logger&.error "Integration error: #{env['sinatra.error'].message}"
    json_error('Service temporarily unavailable', 503)
  end

  error 500 do
    error_id = SecureRandom.uuid
    app_config.logger&.error "Internal error #{error_id}: #{env['sinatra.error']&.message}"
    json_error("Internal server error. Error ID: #{error_id}", 500)
  end

  error 404 do
    json_error('Not found', 404)
  end

  # Helper methods for Claude endpoints
  private

  def suggest_optimal_time_slots(_task, _calendar_context)
    # Implementation moved to IntelligenceService
    []
  end

  def calendar_availability_context
    # Implementation moved to IntelligenceService
    {}
  end

  def generate_immediate_actions(_task)
    # Implementation moved to IntelligenceService
    []
  end
end

# Start the application
if __FILE__ == $PROGRAM_NAME
  # Start background sync thread
  unless ENV['RACK_ENV'] == 'test'
    Thread.new do
      app_config = AppConfig.new.setup!
      loop do
        begin
          app_config.task_manager.sync_with_todoist
          app_config.intelligence.update_patterns
        rescue StandardError => e
          app_config.logger.error "Background sync error: #{e.message}"
        end

        sleep 300 # 5 minutes
      end
    end
  end

  TaskBrainApp.run!
end
