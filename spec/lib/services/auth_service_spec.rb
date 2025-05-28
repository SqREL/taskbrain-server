# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/services/auth_service'
require_relative '../../../lib/errors'

RSpec.describe Services::AuthService do
  let(:mock_redis) { instance_double(Redis) }
  let(:mock_todoist) { instance_double('TodoistIntegration') }
  let(:mock_calendar) { instance_double('GoogleCalendarIntegration') }
  let(:mock_integrations) do
    double('IntegrationContainer', todoist: mock_todoist, calendar: mock_calendar)
  end
  let(:service) { described_class.new(mock_redis, mock_integrations) }

  before do
    # Mock SecurityUtils properly
    security_utils_class = Class.new do
      def self.secure_store_token(*args); end
    end
    stub_const('SecurityUtils', security_utils_class)
    allow(SecurityUtils).to receive(:secure_store_token)
  end

  describe '#authenticate_todoist' do
    let(:code) { 'auth_code_123' }

    context 'with successful exchange' do
      before do
        allow(mock_todoist).to receive(:exchange_code).with(code).and_return({
                                                                               success: true,
                                                                               access_token: 'token_123'
                                                                             })
        allow(mock_todoist).to receive(:setup_webhook)
      end

      it 'stores token and sets up webhook' do
        expect(SecurityUtils).to receive(:secure_store_token)
          .with(mock_redis, 'todoist_token', 'token_123')
        expect(mock_todoist).to receive(:setup_webhook).with('token_123')

        result = service.authenticate_todoist(code)
        expect(result).to eq({ success: true })
      end
    end

    context 'with failed exchange' do
      before do
        allow(mock_todoist).to receive(:exchange_code).with(code).and_return({
                                                                               success: false,
                                                                               error: 'Invalid code'
                                                                             })
      end

      it 'raises IntegrationError' do
        expect { service.authenticate_todoist(code) }
          .to raise_error(TaskBrain::IntegrationError) do |error|
            expect(error.message).to match(/Invalid code/)
            expect(error.integration_name).to eq('Todoist')
          end
      end
    end
  end

  describe '#authenticate_google' do
    let(:code) { 'google_auth_code' }

    context 'with successful exchange' do
      before do
        allow(mock_calendar).to receive(:exchange_code).with(code).and_return({
                                                                                success: true,
                                                                                access_token: 'access_token',
                                                                                refresh_token: 'refresh_token'
                                                                              })
      end

      it 'stores both access and refresh tokens' do
        expect(SecurityUtils).to receive(:secure_store_token)
          .with(mock_redis, 'google_token', 'access_token')
        expect(SecurityUtils).to receive(:secure_store_token)
          .with(mock_redis, 'google_refresh_token', 'refresh_token', 86_400)

        result = service.authenticate_google(code)
        expect(result).to eq({ success: true })
      end
    end

    context 'with failed exchange' do
      before do
        allow(mock_calendar).to receive(:exchange_code).with(code).and_return({
                                                                                success: false,
                                                                                error: 'Invalid grant'
                                                                              })
      end

      it 'raises IntegrationError' do
        expect { service.authenticate_google(code) }
          .to raise_error(TaskBrain::IntegrationError) do |error|
            expect(error.message).to match(/Invalid grant/)
            expect(error.integration_name).to eq('Google Calendar')
          end
      end
    end
  end

  describe '#verify_api_key' do
    before do
      rack_utils = Module.new do
        def self.secure_compare(first, second)
          first == second
        end
      end
      stub_const('Rack::Utils', rack_utils)
    end

    context 'with valid API key' do
      before do
        allow(ENV).to receive(:fetch).with('API_KEY', nil).and_return('valid_key')
      end

      it 'returns true' do
        expect(service.verify_api_key('valid_key')).to be true
      end
    end

    context 'with invalid API key' do
      before do
        allow(ENV).to receive(:fetch).with('API_KEY', nil).and_return('valid_key')
      end

      it 'returns false' do
        expect(service.verify_api_key('invalid_key')).to be false
      end
    end

    context 'with missing API key configuration' do
      before do
        allow(ENV).to receive(:fetch).with('API_KEY', nil).and_return(nil)
      end

      it 'returns false' do
        expect(service.verify_api_key('any_key')).to be false
      end
    end
  end

  describe '#verify_claude_api_key' do
    before do
      rack_utils = Module.new do
        def self.secure_compare(first, second)
          first == second
        end
      end
      stub_const('Rack::Utils', rack_utils)
    end

    context 'with valid Claude API key' do
      before do
        allow(ENV).to receive(:fetch).with('CLAUDE_API_KEY', nil).and_return('claude_key')
      end

      it 'returns true' do
        expect(service.verify_claude_api_key('claude_key')).to be true
      end
    end

    context 'with invalid Claude API key' do
      before do
        allow(ENV).to receive(:fetch).with('CLAUDE_API_KEY', nil).and_return('claude_key')
      end

      it 'returns false' do
        expect(service.verify_claude_api_key('wrong_key')).to be false
      end
    end
  end
end
