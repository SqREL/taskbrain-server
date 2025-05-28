# frozen_string_literal: true

require 'forwardable'

class AppConfig
  extend Forwardable

  attr_reader :db, :redis, :logger, :task_manager, :integrations, :intelligence, :webhook_handler

  def_delegators :@integrations, :todoist, :calendar, :linear

  def initialize(options = {})
    @env = options[:env] || ENV['RACK_ENV'] || 'development'
    @options = options
  end

  def setup!
    setup_logging
    setup_databases
    setup_integrations
    setup_core_services
    self
  end

  def test?
    @env == 'test'
  end

  def development?
    @env == 'development'
  end

  def production?
    @env == 'production'
  end

  private

  def setup_logging
    @logger = @options[:logger] || begin
      require 'logger'
      Logger.new(test? ? StringIO.new : 'logs/server.log')
    end
  end

  def setup_databases
    if test?
      @redis = @options[:redis]
      @db = @options[:db]
    else
      require 'redis'
      require 'sequel'

      @redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')
      @db = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://postgres:password@localhost/taskmanager')
    end
  end

  def setup_integrations
    @integrations = IntegrationContainer.new(
      todoist_client_id: ENV.fetch('TODOIST_CLIENT_ID', nil),
      todoist_client_secret: ENV.fetch('TODOIST_CLIENT_SECRET', nil),
      google_client_id: ENV.fetch('GOOGLE_CLIENT_ID', nil),
      google_client_secret: ENV.fetch('GOOGLE_CLIENT_SECRET', nil),
      linear_api_key: ENV.fetch('LINEAR_API_KEY', nil)
    )
  end

  def setup_core_services
    @task_manager = TaskManager.new(@db, @redis, @logger)
    @intelligence = TaskIntelligence.new(@task_manager, @integrations.calendar, @integrations.linear)
    @webhook_handler = WebhookHandler.new(@task_manager, @intelligence, @integrations.linear)
  end
end

class IntegrationContainer
  attr_reader :todoist, :calendar, :linear

  def initialize(options = {})
    @todoist = TodoistIntegration.new(
      options[:todoist_client_id],
      options[:todoist_client_secret]
    )

    @calendar = GoogleCalendarIntegration.new(
      options[:google_client_id],
      options[:google_client_secret]
    )

    @linear = LinearIntegration.new(options[:linear_api_key])
  end
end
