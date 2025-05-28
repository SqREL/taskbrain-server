# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'sinatra/cors'
require 'redis'
require 'pg'
require 'sequel'
require 'httparty'
require 'json'
require 'logger'
require 'dotenv/load' unless ENV['RACK_ENV'] == 'test'
require 'jwt'
require 'sidekiq'
require 'chronic'

require_relative 'lib/task_manager'
require_relative 'lib/integrations/todoist'
require_relative 'lib/integrations/google_calendar'
require_relative 'lib/integrations/linear'
# require_relative 'lib/integrations/evernote' # Not implemented yet
require_relative 'lib/task_intelligence'
require_relative 'lib/integrations/webhook_handler'
require_relative 'lib/security_utils'
require_relative 'lib/validation_utils'

set :port, 3000
set :bind, '0.0.0.0'
set :logging, true

# CORS configuration
set :allow_origin, ENV['ALLOWED_ORIGINS']&.split(',')&.first || 'https://claude.ai'
set :allow_methods, 'GET,HEAD,POST,PUT,DELETE,OPTIONS'
set :allow_headers, 'Authorization,Content-Type,Accept,X-Claude-API-Key'

before do
  headers['Access-Control-Allow-Origin'] = settings.allow_origin
  headers['Access-Control-Allow-Methods'] = settings.allow_methods
  headers['Access-Control-Allow-Headers'] = settings.allow_headers if request.options?
end

options '*' do
  200
end

# Initialize services (skip in test environment)
if ENV['RACK_ENV'] != 'test'
  $redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')
  $db = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://postgres:password@localhost/taskmanager')
  $logger = Logger.new('logs/server.log')

  # Initialize managers
  $task_manager = TaskManager.new($db, $redis, $logger)
  $todoist = TodoistIntegration.new(ENV.fetch('TODOIST_CLIENT_ID', nil), ENV.fetch('TODOIST_CLIENT_SECRET', nil))
  $calendar = GoogleCalendarIntegration.new(ENV.fetch('GOOGLE_CLIENT_ID', nil), ENV.fetch('GOOGLE_CLIENT_SECRET', nil))
  $linear = LinearIntegration.new(ENV.fetch('LINEAR_API_KEY', nil))
  # $evernote = EvernoteIntegration.new(ENV['EVERNOTE_DEV_TOKEN']) # Not implemented yet
  $intelligence = TaskIntelligence.new($task_manager, $calendar, $linear)
  $webhook_handler = WebhookHandler.new($task_manager, $intelligence)
end

# Authentication middleware
def authenticate_request
  api_key = request.env['HTTP_AUTHORIZATION']&.sub(/^Bearer /, '')
  env_key = ENV.fetch('API_KEY', nil)
  
  api_key && env_key && Rack::Utils.secure_compare(api_key, env_key)
end

def authenticate_claude_request
  claude_key = request.env['HTTP_X_CLAUDE_API_KEY']
  claude_key && Rack::Utils.secure_compare(claude_key, ENV.fetch('CLAUDE_API_KEY', nil))
end

before do
  content_type :json
end

# Protect API endpoints
before '/api/*' do
  # Skip auth for health check
  pass if request.path_info == '/api/health'

  unless authenticate_request
    $logger&.warn "401 Unauthorized access attempt: #{request.path_info} from #{request.env['REMOTE_ADDR']}"
    halt 401, { error: 'Unauthorized - Invalid API key' }.to_json
  end
end

# Enhanced protection for Claude endpoints
before '/api/claude/*' do
  unless authenticate_claude_request
    $logger&.warn "401 Unauthorized Claude API access attempt: #{request.path_info} from #{request.env['REMOTE_ADDR']}"
    halt 401, { error: 'Unauthorized - Invalid Claude API key' }.to_json
  end
end

# Health check
get '/health' do
  { status: 'ok', timestamp: Time.now.to_i }.to_json
end

# Dashboard
get '/' do
  content_type :html
  File.read('public/dashboard.html')
end

# Authentication endpoints
post '/auth/todoist' do
  code = params[:code]
  result = $todoist.exchange_code(code)

  if result[:success]
    # Store encrypted tokens and setup webhook
    SecurityUtils.secure_store_token($redis, 'todoist_token', result[:access_token])
    $todoist.setup_webhook(result[:access_token])
    { success: true }.to_json
  else
    status 400
    { error: result[:error] }.to_json
  end
end

post '/auth/google' do
  code = params[:code]
  result = $calendar.exchange_code(code)

  if result[:success]
    SecurityUtils.secure_store_token($redis, 'google_token', result[:access_token])
    SecurityUtils.secure_store_token($redis, 'google_refresh_token', result[:refresh_token], 86_400) # 24 hours
    { success: true }.to_json
  else
    status 400
    { error: result[:error] }.to_json
  end
end

# Task management endpoints
get '/api/tasks' do
  filter_errors = ValidationUtils.validate_filters(params)

  if filter_errors.any?
    halt 400, { errors: filter_errors }.to_json
  end

  filters = {
    project: params[:project],
    priority: params[:priority],
    due_date: params[:due_date],
    status: params[:status] || 'active'
  }.compact

  tasks = $task_manager.get_tasks(filters)
  { tasks: tasks }.to_json
end

get '/api/tasks/:id' do
  task = $task_manager.get_task(params[:id])
  if task
    task.to_json
  else
    status 404
    { error: 'Task not found' }.to_json
  end
end

post '/api/tasks' do
  validation_result = ValidationUtils.validate_and_parse_json(request.body.read)

  if validation_result[:errors]
    halt 400, { errors: validation_result[:errors] }.to_json
  end

  # Create task with intelligence
  task = $task_manager.create_task(validation_result[:data])
  suggestions = $intelligence.analyze_new_task(task)

  {
    task: task,
    suggestions: suggestions
  }.to_json
end

put '/api/tasks/:id' do
  validation_result = ValidationUtils.validate_and_parse_json(request.body.read)

  if validation_result[:errors]
    halt 400, { errors: validation_result[:errors] }.to_json
  end

  task = $task_manager.update_task(params[:id], validation_result[:data])

  if task
    task.to_json
  else
    status 404
    { error: 'Task not found' }.to_json
  end
end

delete '/api/tasks/:id' do
  success = $task_manager.delete_task(params[:id])

  if success
    { success: true }.to_json
  else
    status 404
    { error: 'Task not found' }.to_json
  end
end

# Intelligence endpoints
get '/api/intelligence/priorities' do
  priorities = $intelligence.suggest_priorities
  { priorities: priorities }.to_json
end

get '/api/intelligence/schedule' do
  date = params[:date] || Date.today.to_s
  schedule = $intelligence.suggest_daily_schedule(date)
  { schedule: schedule }.to_json
end

get '/api/intelligence/overdue' do
  overdue = $intelligence.get_overdue_analysis
  { overdue: overdue }.to_json
end

post '/api/intelligence/reschedule' do
  data = JSON.parse(request.body.read)
  task_id = data['task_id']
  new_date = data['new_date']

  result = $intelligence.smart_reschedule(task_id, new_date)
  result.to_json
end

# Context endpoints
get '/api/context/calendar' do
  date = params[:date] || Date.today.to_s
  events = $calendar.get_events_for_date(date)
  { events: events }.to_json
end

get '/api/context/linear' do
  project = params[:project]
  issues = $linear.get_issues(project)
  { issues: issues }.to_json
end

# get '/api/context/notes' do
#   query = params[:q]
#   notes = $evernote.search_notes(query)
#   { notes: notes }.to_json
# end

# Webhook endpoints
post '/webhooks/todoist' do
  signature = request.env['HTTP_X_TODOIST_HMAC_SHA256']
  payload = request.body.read

  unless $webhook_handler.verify_todoist_signature(payload, signature)
    status 401
    return { error: 'Invalid signature' }.to_json
  end

  data = JSON.parse(payload)
  $webhook_handler.handle_todoist_event(data)

  { success: true }.to_json
end

post '/webhooks/linear' do
  signature = request.env['HTTP_X_LINEAR_SIGNATURE']
  payload = request.body.read

  unless $webhook_handler.verify_linear_signature(payload, signature)
    status 401
    return { error: 'Invalid signature' }.to_json
  end

  data = JSON.parse(payload)
  $webhook_handler.handle_linear_event(data)

  { success: true }.to_json
end

# Analytics endpoints
get '/api/analytics/productivity' do
  period = params[:period] || 'week'
  analytics = $task_manager.get_productivity_analytics(period)
  analytics.to_json
end

get '/api/analytics/patterns' do
  patterns = $intelligence.analyze_completion_patterns
  { patterns: patterns }.to_json
end

# Enhanced Claude API endpoints

# Full context endpoint for Claude
get '/api/claude/full_context' do
  {
    tasks: {
      active: $task_manager.get_tasks(status: 'active'),
      overdue: $task_manager.get_tasks(due_date: 'overdue'),
      today: $task_manager.get_tasks(due_date: 'today'),
      high_priority: $task_manager.get_tasks.select { |t| t[:priority] >= 4 }
    },
    productivity: {
      score: $intelligence.calculate_productivity_score,
      patterns: $intelligence.analyze_completion_patterns,
      recommendations: $intelligence.get_general_recommendations
    },
    calendar: $calendar.get_events_for_date(Date.today.to_s),
    capacity: analyze_current_capacity,
    recent_activity: $task_manager.get_recent_activity(10),
    upcoming_deadlines: $task_manager.get_upcoming_deadlines(10)
  }.to_json
end

# Enhanced task creation with AI analysis
post '/api/claude/smart_create' do
  validation_result = ValidationUtils.validate_and_parse_json(request.body.read)

  if validation_result[:errors]
    status 400
    content_type :json
    return { errors: validation_result[:errors] }.to_json
  end

  # Enhanced AI analysis
  task = $task_manager.create_task(validation_result[:data])
  intelligence = $intelligence.analyze_new_task(task)
  calendar_context = get_calendar_availability_context

  {
    task: task,
    intelligence: intelligence,
    optimal_scheduling: suggest_optimal_time_slots(task, calendar_context),
    impact_analysis: $intelligence.analyze_task_impact(task),
    recommended_actions: generate_immediate_actions(task)
  }.to_json
end

# Bulk task operations for Claude
post '/api/claude/bulk_create' do
  body = request.body.read
  
  if body.nil? || body.strip.empty?
    halt 400, { errors: ['Request body is required'] }.to_json
  end

  begin
    data = JSON.parse(body)
  rescue JSON::ParserError => e
    halt 400, { errors: ["Invalid JSON: #{e.message}"] }.to_json
  end

  tasks_data = data['tasks']
  unless tasks_data.is_a?(Array)
    halt 400, { errors: ['Tasks must be an array'] }.to_json
  end

  results = []
  tasks_data.each_with_index do |task_data, index|
    task_validation = ValidationUtils.validate_task_data(task_data)

    if task_validation.any?
      results << { index: index, errors: task_validation }
    else
      task = $task_manager.create_task(ValidationUtils.sanitize_task_data(task_data))
      suggestions = $intelligence.analyze_new_task(task)
      results << {
        index: index,
        task: task,
        suggestions: suggestions,
        success: true
      }
    end
  end

  { results: results }.to_json
end

# Context-aware daily schedule for specific date
get '/api/claude/context/:date' do
  date = params[:date]

  begin
    parsed_date = Date.parse(date)
  rescue ArgumentError
    halt 400, { error: 'Invalid date format' }.to_json
  end

  {
    date: date,
    tasks: {
      due_today: $task_manager.get_tasks.select do |t|
        t[:due_date] && Date.parse(t[:due_date].to_s) == parsed_date
      end,
      available_for_scheduling: $task_manager.get_tasks(status: 'active').select do |t|
        t[:due_date].nil? || Date.parse(t[:due_date].to_s) >= parsed_date
      end
    },
    calendar_events: $calendar.get_events_for_date(date),
    schedule_suggestions: $intelligence.suggest_daily_schedule(date),
    availability_windows: $calendar.find_available_slots(date, 60),
    energy_optimization: get_energy_recommendations_for_date(parsed_date)
  }.to_json
end

# Intelligent batch rescheduling
post '/api/claude/reschedule_batch' do
  body = request.body.read
  
  if body.nil? || body.strip.empty?
    halt 400, { errors: ['Request body is required'] }.to_json
  end

  begin
    data = JSON.parse(body)
  rescue JSON::ParserError => e
    halt 400, { errors: ["Invalid JSON: #{e.message}"] }.to_json
  end

  reschedule_requests = data['reschedule_requests']
  unless reschedule_requests.is_a?(Array)
    halt 400, { errors: ['Reschedule requests must be an array'] }.to_json
  end

  results = []
  reschedule_requests.each do |request|
    task_id = request['task_id']
    new_date = request['new_date']

    result = $intelligence.smart_reschedule(task_id, new_date)
    results << result.merge(task_id: task_id)
  end

  { results: results }.to_json
end

# Real-time status for Claude
get '/api/claude/status' do
  status = {
    total_tasks: $task_manager.count_tasks,
    overdue_tasks: $task_manager.count_overdue_tasks,
    today_tasks: $task_manager.count_today_tasks,
    high_priority: $task_manager.count_high_priority_tasks,
    recent_activity: $task_manager.get_recent_activity(10),
    next_deadlines: $task_manager.get_upcoming_deadlines(5),
    productivity_score: $intelligence.calculate_productivity_score
  }

  status.to_json
end

post '/api/claude/create_task' do
  data = JSON.parse(request.body.read)

  # Enhanced task creation with AI context
  task = $task_manager.create_task(data)
  suggestions = $intelligence.analyze_new_task(task)

  # Auto-apply intelligent suggestions if confidence is high
  task = $task_manager.update_task(task[:id], suggestions[:updates]) if suggestions[:auto_apply]

  {
    task: task,
    suggestions: suggestions,
    impact_analysis: $intelligence.analyze_task_impact(task)
  }.to_json
end

get '/api/claude/recommendations' do
  context = params[:context] || 'general'

  recommendations = case context
                    when 'morning'
                      $intelligence.get_morning_recommendations
                    when 'afternoon'
                      $intelligence.get_afternoon_recommendations
                    when 'planning'
                      $intelligence.get_planning_recommendations
                    else
                      $intelligence.get_general_recommendations
                    end

  recommendations.to_json
end

# Helper methods for enhanced Claude endpoints
def analyze_current_capacity
  active_tasks = $task_manager.get_tasks(status: 'active')
  total_estimated_time = active_tasks.sum { |t| t[:estimated_duration] || 60 }

  {
    total_active_tasks: active_tasks.length,
    estimated_total_hours: (total_estimated_time / 60.0).round(1),
    capacity_status: case total_estimated_time
                     when 0..480 then 'light'
                     when 481..960 then 'moderate'
                     when 961..1440 then 'heavy'
                     else 'overloaded'
                     end,
    recommendation: get_capacity_recommendation(total_estimated_time)
  }
end

def get_capacity_recommendation(minutes)
  case minutes
  when 0..240
    'You have light workload. Good time to take on additional tasks or focus on long-term projects.'
  when 241..480
    'Moderate workload. Maintain current pace and prioritize effectively.'
  when 481..720
    'Heavy workload. Consider deferring non-essential tasks.'
  else
    'Overloaded schedule. Urgent need to reschedule or delegate tasks.'
  end
end

def get_calendar_availability_context
  today = Date.today.to_s
  events = $calendar.get_events_for_date(today)

  {
    total_events: events.length,
    busy_hours: events.sum { |e| calculate_event_duration(e) },
    available_slots: $calendar.find_available_slots(today, 30),
    next_free_slot: events.empty? ? 'Now' : find_next_available_time(events)
  }
end

def suggest_optimal_time_slots(task, calendar_context)
  duration = task[:estimated_duration] || 60
  energy_level = task[:energy_level] || 3

  available_slots = calendar_context[:available_slots] || []

  # Filter slots by energy level and time of day
  optimal_slots = available_slots.select do |slot|
    slot_hour = Time.parse(slot[:start].to_s).hour

    case energy_level
    when 4..5 # High energy
      (9..12).include?(slot_hour)
    when 3 # Medium energy
      (9..15).include?(slot_hour)
    else # Low energy
      (14..18).include?(slot_hour)
    end
  end.first(3)

  optimal_slots.map do |slot|
    {
      start_time: slot[:start],
      end_time: Time.parse(slot[:start].to_s) + (duration * 60),
      confidence: calculate_slot_confidence(slot, task),
      reasoning: generate_slot_reasoning(slot, task)
    }
  end
end

def generate_immediate_actions(task)
  actions = []

  # Check for dependencies
  if task[:dependencies]&.any?
    actions << {
      type: 'check_dependencies',
      message: 'Review task dependencies before starting',
      priority: 'high'
    }
  end

  # Check for context requirements
  if task[:context_tags]&.include?('meeting')
    actions << {
      type: 'schedule_meeting',
      message: 'Schedule required meeting or call',
      priority: 'medium'
    }
  end

  # Check for resource requirements
  if task[:content]&.downcase&.include?('research')
    actions << {
      type: 'gather_resources',
      message: 'Gather research materials and references',
      priority: 'medium'
    }
  end

  actions
end

def get_energy_recommendations_for_date(_date)
  hour = Time.now.hour

  {
    current_energy_level: estimate_current_energy_level(hour),
    optimal_task_types: get_optimal_task_types_for_hour(hour),
    energy_forecast: generate_daily_energy_forecast,
    recommendations: get_time_specific_recommendations(hour)
  }
end

def estimate_current_energy_level(hour)
  case hour
  when 6..9 then 4
  when 9..12 then 5
  when 12..14 then 3
  when 14..17 then 4
  when 17..20 then 2
  else 1
  end
end

def get_optimal_task_types_for_hour(hour)
  case hour
  when 6..12
    ['complex analysis', 'creative work', 'problem solving']
  when 12..17
    %w[meetings collaboration communication]
  when 17..21
    ['planning', 'review', 'administrative tasks']
  else
    ['light tasks', 'personal development']
  end
end

def generate_daily_energy_forecast
  (6..22).map do |hour|
    {
      hour: hour,
      energy_level: estimate_current_energy_level(hour),
      recommended_activities: get_optimal_task_types_for_hour(hour)
    }
  end
end

def get_time_specific_recommendations(hour)
  case hour
  when 6..9
    'Morning peak: Tackle your most challenging and important tasks now.'
  when 9..12
    'Optimal focus time: Perfect for deep work and complex problem-solving.'
  when 12..14
    'Post-lunch dip: Good time for lighter tasks and social activities.'
  when 14..17
    'Afternoon recovery: Ideal for meetings, calls, and collaborative work.'
  when 17..20
    'Evening wind-down: Review progress, plan tomorrow, handle admin tasks.'
  else
    'Low energy period: Focus on rest and light personal tasks.'
  end
end

# Private helper methods
private

def calculate_event_duration(event)
  return 1 unless event[:start_time] && event[:end_time]

  start_time = Time.parse(event[:start_time])
  end_time = Time.parse(event[:end_time])
  ((end_time - start_time) / 3600).round(1) # Return hours
rescue StandardError
  1 # Default to 1 hour if parsing fails
end

def find_next_available_time(events)
  return 'Now' if events.empty?

  sorted_events = events.sort_by { |e| Time.parse(e[:start_time]) }
  last_event = sorted_events.last

  return 'Now' unless last_event[:end_time]

  end_time = Time.parse(last_event[:end_time])
  end_time.strftime('%H:%M')
rescue StandardError
  'Now'
end

def calculate_slot_confidence(slot, task)
  # Simple confidence calculation based on slot duration and task requirements
  base_confidence = 0.7

  # Increase confidence if slot is longer than needed
  base_confidence += 0.2 if slot[:duration] > (task[:estimated_duration] || 60)

  # Decrease confidence if slot is barely adequate
  base_confidence -= 0.1 if slot[:duration] < ((task[:estimated_duration] || 60) * 1.2)

  [base_confidence, 1.0].min
end

def generate_slot_reasoning(slot, task)
  reasons = []

  slot_hour = Time.parse(slot[:start].to_s).hour
  energy_level = task[:energy_level] || 3

  if energy_level >= 4 && (9..12).include?(slot_hour)
    reasons << 'High-energy task scheduled during peak focus hours'
  elsif energy_level <= 2 && (15..18).include?(slot_hour)
    reasons << 'Low-energy task scheduled during afternoon low-focus period'
  end

  reasons << 'Adequate buffer time available' if slot[:duration] > (task[:estimated_duration] || 60)

  reasons.join(', ')
end

# Enhanced error handling with request tracking
def log_error(error, request_context = {})
  error_id = SecureRandom.uuid
  error_details = {
    error_id: error_id,
    message: error.message,
    backtrace: error.backtrace&.first(5),
    request_path: request.path_info,
    request_method: request.request_method,
    user_agent: request.env['HTTP_USER_AGENT'],
    remote_ip: request.env['REMOTE_ADDR'],
    timestamp: Time.now.iso8601
  }.merge(request_context)

  $logger&.error error_details.to_json
  error_id
end

# Error handling
error 500 do
  error_id = log_error(env['sinatra.error'])
  status 500
  {
    error: 'Internal server error',
    error_id: error_id,
    message: 'Please contact support with this error ID'
  }.to_json
end

error 404 do
  $logger&.warn "404 Not Found: #{request.path_info} from #{request.env['REMOTE_ADDR']}"
  { error: 'Not found', path: request.path_info }.to_json
end

# 401 errors are handled by halt statements with specific messages

# error 400 do
#   { error: 'Bad request' }.to_json
# end

# Add request logging middleware
before do
  @request_start_time = Time.now
  $logger&.info "#{request.request_method} #{request.path_info} - Started"
end

after do
  if @request_start_time
    duration = ((Time.now - @request_start_time) * 1000).round(2)
    $logger&.info "#{request.request_method} #{request.path_info} - Completed #{response.status} in #{duration}ms"
  end
end

# Start background jobs (skip in test environment)
unless ENV['RACK_ENV'] == 'test'
  Thread.new do
    # Sync with external services every 5 minutes
    loop do
      begin
        $task_manager.sync_with_todoist
        $intelligence.update_patterns
      rescue StandardError => e
        $logger.error "Background sync error: #{e.message}"
      end

      sleep 300 # 5 minutes
    end
  end

  $logger.info 'Task Management Server started on port 3000'
end
