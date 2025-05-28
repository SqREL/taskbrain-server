# frozen_string_literal: true

require 'httparty'
require_relative '../errors'

module Integrations
  class Base
    include HTTParty

    class << self
      attr_accessor :integration_name
    end

    def initialize(config = {})
      @config = config
      validate_configuration!
    end

    def healthy?
      health_check
      true
    rescue StandardError
      false
    end

    protected

    def handle_response(response, action = nil)
      case response.code
      when 200..299
        response
      when 401
        raise TaskBrain::AuthenticationError, "Authentication failed for #{self.class.integration_name}"
      when 403
        raise TaskBrain::AuthorizationError, "Access denied for #{self.class.integration_name}"
      when 404
        raise TaskBrain::NotFoundError.new(self.class.integration_name, action) if action

        raise TaskBrain::IntegrationError.new(self.class.integration_name, 'Resource not found')
      when 429
        retry_after = response.headers['Retry-After']&.to_i
        raise TaskBrain::RateLimitError, retry_after
      when 400..499
        raise TaskBrain::IntegrationError.new(self.class.integration_name,
                                              "Client error: #{response.code} - #{response.body}")
      when 500..599
        raise TaskBrain::IntegrationError.new(self.class.integration_name, "Server error: #{response.code}")
      else
        raise TaskBrain::IntegrationError.new(self.class.integration_name, "Unexpected response: #{response.code}")
      end
    end

    def with_error_handling
      yield
    rescue HTTParty::Error => e
      raise TaskBrain::IntegrationError.new(self.class.integration_name, e)
    rescue StandardError => e
      raise unless e.is_a?(TaskBrain::Error)

      raise
    end

    def validate_configuration!
      required_config_keys.each do |key|
        if @config[key].nil? || @config[key].to_s.strip.empty?
          raise TaskBrain::ConfigurationError,
                "Missing required configuration: #{key} for #{self.class.integration_name}"
        end
      end
    end

    def required_config_keys
      []
    end

    def health_check
      raise NotImplementedError, 'Subclasses must implement health_check'
    end

    def integration_name
      self.class.integration_name || self.class.name.split('::').last.gsub('Integration', '')
    end
  end
end
