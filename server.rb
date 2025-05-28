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
require 'dotenv/load'
require 'jwt'
require 'sidekiq'
require 'chronic'

require_relative 'lib/task_manager'
require_relative 'lib/integrations/todoist'
require_relative 'lib/integrations/google_calendar'
require_relative 'lib/integrations/linear'
require_relative 'lib/integrations/evernote'
require_relative 'lib/task_intelligence'
require_relative 'lib/webhook_handler'

set :port, 3000
set :bind, '0.0.0.0'
set :logging, true

register Sinatra::Cors

allow do
  origins '*'
  resource '*', headers: :any, methods: %i[get post put delete options]
end

# Initialize services
$redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')
$db = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://postgres:password@localhost/taskmanager')
$logger = Logger.new('logs/server.log')

# Initialize managers
$task_manager = TaskManager.new($db, $redis, $logger)
$todoist = TodoistIntegration.new(ENV['TODOIST_CLIENT_ID'], ENV['TODOIST_CLIENT_SECRET'])
$calendar = GoogleCalendarIntegration.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'])
$linear = LinearIntegration.new(ENV['LINEAR_API_KEY'])
$evernote = EvernoteIntegration.new(ENV['EVERNOTE_DEV_TOKEN'])
$intelligence = TaskIntelligence.new($task_manager, $calendar, $linear)
$webhook_handler = WebhookHandler.new($task_manager, $intelligence)

before do
  content_type :json
  headers 'Access-Control-Allow-Origin' => '*'
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
    # Store tokens and setup webhook
    $redis.set('todoist_token', result[:access_token])
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
    $redis.set('google_token', result[:access_token])
    $redis.set('google_refresh_token', result[:refresh_token])
    { success: true }.to_json
  else
    status 400
    { error: result[:error] }.to_json
  end
end

# Task management endpoints
get '/api/tasks' do
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
  data = JSON.parse(request.body.read)

  # Validate required fields
  unless data['content']
    status 400
    return { error: 'Content is required' }.to_json
  end

  # Create task with intelligence
  task = $task_manager.create_task(data)
  suggestions = $intelligence.analyze_new_task(task)

  {
    task: task,
    suggestions: suggestions
  }.to_json
end

put '/api/tasks/:id' do
  data = JSON.parse(request.body.read)
  task = $task_manager.update_task(params[:id], data)

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

get '/api/context/notes' do
  query = params[:q]
  notes = $evernote.search_notes(query)
  { notes: notes }.to_json
end

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
  payload = request.body.read
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

# Error handling
error 500 do
  $logger.error "Server error: #{env['sinatra.error']}"
  { error: 'Internal server error' }.to_json
end

error 404 do
  { error: 'Not found' }.to_json
end

# Start background jobs
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
