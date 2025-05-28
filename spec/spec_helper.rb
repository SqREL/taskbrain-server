# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_group 'Controllers', 'server.rb'
  add_group 'Models', 'lib/'
  add_group 'Integrations', 'lib/integrations'
end

ENV['RACK_ENV'] = 'test'
ENV['DATABASE_URL'] = 'postgres://postgres:password@localhost/taskmanager_test'

require 'rack/test'
require 'rspec'
require 'webmock/rspec'
require 'factory_bot'
require 'database_cleaner/sequel'

# Initialize test doubles for database and Redis
require 'sequel'
require 'redis'

# Create simple mock objects for testing
class MockDB
  def method_missing(_name, *_args)
    self
  end

  def respond_to_missing?(_name, _include_private = false)
    true
  end
end

class MockRedis
  def method_missing(_name, *_args)
    true
  end

  def respond_to_missing?(_name, _include_private = false)
    true
  end
end

class MockLogger
  def info(*args)
    puts "INFO: #{args.join(' ')}" if ENV['DEBUG_TESTS']
  end

  def warn(*args)
    puts "WARN: #{args.join(' ')}" if ENV['DEBUG_TESTS']
  end

  def error(*args)
    puts "ERROR: #{args.join(' ')}"
  end

  def debug(*args)
    puts "DEBUG: #{args.join(' ')}" if ENV['DEBUG_TESTS']
  end
end

class MockTaskManager
  def initialize
    @task_counter = 0
  end

  def get_tasks(_filters = {})
    []
  end

  def get_task(_id)
    nil
  end

  def create_task(data)
    @task_counter += 1
    {
      id: @task_counter,
      content: data[:content] || data['content'],
      description: data[:description] || data['description'],
      priority: data[:priority] || data['priority'] || 3,
      due_date: data[:due_date] || data['due_date'],
      created_at: Time.now,
      updated_at: Time.now,
      completed: false,
      source: 'manual',
      energy_level: data[:energy_level] || data['energy_level'] || 3,
      estimated_duration: data[:estimated_duration] || data['estimated_duration'] || 60
    }
  end

  def update_task(_id, _data)
    true
  end

  def delete_task(_id)
    true
  end

  def count_tasks
    0
  end

  def count_overdue_tasks
    0
  end

  def count_today_tasks
    0
  end

  def count_high_priority_tasks
    0
  end

  def get_recent_activity(*_args)
    []
  end

  def get_upcoming_deadlines(*_args)
    []
  end
end

class MockIntelligence
  def analyze_new_task(_task)
    {
      priority_adjustment: { suggested: 4, confidence: 0.8 },
      time_estimate: { estimate_minutes: 90, confidence: 0.7 },
      auto_apply: false
    }
  end

  def calculate_productivity_score
    75.0
  end

  def suggest_priorities(*_args)
    { high_priority: [], medium_priority: [], context_based: [], energy_matched: [] }
  end

  def suggest_daily_schedule(*_args)
    { morning_block: [], afternoon_block: [], evening_block: [] }
  end

  def smart_reschedule(*_args)
    { feasible: true, conflicts: [], alternatives: [], impact_score: 0.8, rescheduled: true }
  end

  def analyze_completion_patterns
    {}
  end

  def general_recommendations
    []
  end

  def morning_recommendations
    []
  end

  def afternoon_recommendations
    []
  end

  def planning_recommendations
    []
  end

  def overdue_analysis
    {}
  end

  def analyze_task_impact(_task)
    {}
  end

  def analyze_priority(_task)
    { confidence: 0.5, suggested_priority: 3 }
  end

  def update_patterns
    true
  end
end

class MockCalendar
  def get_events_for_date(_date)
    []
  end

  def find_available_slots(_date, _duration, _token = nil)
    []
  end
end

class MockIntegration
  def method_missing(_name, *_args)
    nil
  end

  def respond_to_missing?(_name, _include_private = false)
    true
  end
end

$db = MockDB.new
$redis = MockRedis.new

# Initialize simple mock globals before loading the app
$logger = MockLogger.new
$task_manager = MockTaskManager.new
$intelligence = MockIntelligence.new
$webhook_handler = MockIntegration.new
$todoist = MockIntegration.new
$calendar = MockCalendar.new
$linear = MockIntegration.new

# Load the application
require_relative '../server'

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

# Configure FactoryBot
FactoryBot.find_definitions

# Define the Sinatra app for testing
def app
  Sinatra::Application
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include FactoryBot::Syntax::Methods

  # Use color output
  config.color = true

  # Use documentation format
  config.formatter = :documentation

  # Run specs in random order to surface order dependencies
  config.order = :random
  Kernel.srand config.seed

  # Database cleaner configuration (disabled for mocked database)
  # config.before(:suite) do
  #   DatabaseCleaner[:sequel, db: $db].strategy = :transaction
  #   DatabaseCleaner[:sequel, db: $db].clean_with(:truncation)
  # end

  # config.around do |example|
  #   DatabaseCleaner[:sequel, db: $db].cleaning do
  #     example.run
  #   end
  # end

  # Initialize test doubles in before(:suite) - but using simple mock classes
  config.before(:suite) do
    # For testing, we'll create simple mock classes
  end

  # Reset mocks before each test
  config.before do
    # Additional setup if needed
  end

  # Set test environment variables
  config.before do
    ENV['API_KEY'] = 'test_api_key'
    ENV['CLAUDE_API_KEY'] = 'test_claude_key'
    ENV['ENCRYPTION_KEY'] = 'kLFG+u/1SOVaoIpld0MzUJoO81uhBLsz8zXCNiIhDW4='
    ENV['TODOIST_WEBHOOK_SECRET'] = 'test_todoist_secret'
    ENV['LINEAR_WEBHOOK_SECRET'] = 'test_linear_secret'
    ENV['ALLOWED_ORIGINS'] = 'https://claude.ai,http://localhost:3000'
  end

  # Expectations configuration
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Mocks configuration
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Shared context for API tests
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
