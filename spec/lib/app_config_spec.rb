# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/app_config'

RSpec.describe AppConfig do
  let(:mock_logger) { instance_double(Logger) }
  let(:mock_redis) { instance_double(Redis) }
  let(:mock_db) { instance_double(Sequel::Database) }

  describe '#initialize' do
    it 'sets environment from options' do
      config = AppConfig.new(env: 'test')
      expect(config.test?).to be true
    end

    it 'defaults to RACK_ENV' do
      allow(ENV).to receive(:[]).with('RACK_ENV').and_return('production')
      config = AppConfig.new
      expect(config.production?).to be true
    end
  end

  describe '#setup!' do
    let(:config) do
      AppConfig.new(
        env: 'test',
        logger: mock_logger,
        redis: mock_redis,
        db: mock_db
      )
    end

    before do
      # Mock integration classes with proper initialization
      todoist_class = Class.new do
        def initialize(client_id, client_secret); end
      end

      google_calendar_class = Class.new do
        def initialize(client_id, client_secret); end
      end

      linear_class = Class.new do
        def initialize(api_key); end
      end

      task_manager_class = Class.new do
        def initialize(db, redis, logger); end
      end

      task_intelligence_class = Class.new do
        def initialize(task_manager, calendar, linear); end
      end

      webhook_handler_class = Class.new do
        def initialize(task_manager, intelligence, linear = nil); end
      end

      stub_const('TodoistIntegration', todoist_class)
      stub_const('GoogleCalendarIntegration', google_calendar_class)
      stub_const('LinearIntegration', linear_class)
      stub_const('TaskManager', task_manager_class)
      stub_const('TaskIntelligence', task_intelligence_class)
      stub_const('WebhookHandler', webhook_handler_class)

      allow(TodoistIntegration).to receive(:new).and_return(double('todoist'))
      allow(GoogleCalendarIntegration).to receive(:new).and_return(double('calendar'))
      allow(LinearIntegration).to receive(:new).and_return(double('linear'))
      allow(TaskManager).to receive(:new).and_return(double('task_manager'))
      allow(TaskIntelligence).to receive(:new).and_return(double('intelligence'))
      allow(WebhookHandler).to receive(:new).and_return(double('webhook_handler'))
    end

    it 'sets up all components' do
      expect(config.setup!).to eq(config)
      expect(config.logger).to eq(mock_logger)
      expect(config.redis).to eq(mock_redis)
      expect(config.db).to eq(mock_db)
      expect(config.task_manager).not_to be_nil
      expect(config.intelligence).not_to be_nil
      expect(config.webhook_handler).not_to be_nil
    end

    it 'creates integration container' do
      config.setup!
      expect(config.integrations).not_to be_nil
      expect(config.todoist).not_to be_nil
      expect(config.calendar).not_to be_nil
      expect(config.linear).not_to be_nil
    end
  end

  describe 'environment helpers' do
    it '#test? returns true for test environment' do
      config = AppConfig.new(env: 'test')
      expect(config.test?).to be true
      expect(config.development?).to be false
      expect(config.production?).to be false
    end

    it '#development? returns true for development environment' do
      config = AppConfig.new(env: 'development')
      expect(config.development?).to be true
      expect(config.test?).to be false
      expect(config.production?).to be false
    end

    it '#production? returns true for production environment' do
      config = AppConfig.new(env: 'production')
      expect(config.production?).to be true
      expect(config.test?).to be false
      expect(config.development?).to be false
    end
  end
end
