# frozen_string_literal: true

require_relative '../errors'
require_relative '../security_utils'

module Services
  class AuthService
    def initialize(redis, integrations)
      @redis = redis
      @integrations = integrations
    end

    def authenticate_todoist(code)
      result = @integrations.todoist.exchange_code(code)

      raise TaskBrain::IntegrationError.new('Todoist', result[:error]) unless result[:success]

      SecurityUtils.secure_store_token(@redis, 'todoist_token', result[:access_token])
      @integrations.todoist.setup_webhook(result[:access_token])
      { success: true }
    end

    def authenticate_google(code)
      result = @integrations.calendar.exchange_code(code)

      raise TaskBrain::IntegrationError.new('Google Calendar', result[:error]) unless result[:success]

      SecurityUtils.secure_store_token(@redis, 'google_token', result[:access_token])
      SecurityUtils.secure_store_token(@redis, 'google_refresh_token', result[:refresh_token], 86_400)
      { success: true }
    end

    def verify_api_key(provided_key)
      expected_key = ENV.fetch('API_KEY', nil)
      return false unless provided_key && expected_key

      Rack::Utils.secure_compare(provided_key, expected_key)
    end

    def verify_claude_api_key(provided_key)
      expected_key = ENV.fetch('CLAUDE_API_KEY', nil)
      return false unless provided_key && expected_key

      Rack::Utils.secure_compare(provided_key, expected_key)
    end
  end
end
