# frozen_string_literal: true

module TaskBrain
  class Error < StandardError; end

  class ValidationError < Error
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super(errors.is_a?(Array) ? errors.join(', ') : errors.to_s)
    end
  end

  class NotFoundError < Error
    attr_reader :resource_type, :id

    def initialize(resource_type, id)
      @resource_type = resource_type
      @id = id
      super("#{resource_type} with id '#{id}' not found")
    end
  end

  class AuthenticationError < Error
    def initialize(message = 'Authentication failed')
      super
    end
  end

  class AuthorizationError < Error
    def initialize(message = 'You are not authorized to perform this action')
      super
    end
  end

  class IntegrationError < Error
    attr_reader :integration_name, :original_error

    def initialize(integration_name, original_error = nil)
      @integration_name = integration_name
      @original_error = original_error
      message = "Error communicating with #{integration_name}"
      if original_error
        error_message = original_error.respond_to?(:message) ? original_error.message : original_error.to_s
        message += ": #{error_message}"
      end
      super(message)
    end
  end

  class WebhookVerificationError < Error
    attr_reader :service

    def initialize(service)
      @service = service
      super("Invalid webhook signature from #{service}")
    end
  end

  class RateLimitError < Error
    attr_reader :retry_after

    def initialize(retry_after = nil)
      @retry_after = retry_after
      message = 'Rate limit exceeded'
      message += ". Retry after #{retry_after} seconds" if retry_after
      super(message)
    end
  end

  class ConfigurationError < Error
    def initialize(message)
      super("Configuration error: #{message}")
    end
  end
end
