# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/integrations/base'
require_relative '../../../lib/errors'

RSpec.describe Integrations::Base do
  let(:test_integration_class) do
    Class.new(described_class) do
      self.integration_name = 'TestService'

      def required_config_keys
        %i[api_key api_secret]
      end

      def health_check
        # Dummy implementation
        true
      end
    end
  end

  let(:valid_config) { { api_key: 'key123', api_secret: 'secret456' } }
  let(:integration) { test_integration_class.new(valid_config) }

  describe '#initialize' do
    it 'accepts configuration' do
      expect { test_integration_class.new(valid_config) }.not_to raise_error
    end

    it 'validates configuration on initialization' do
      expect { test_integration_class.new({}) }
        .to raise_error(TaskBrain::ConfigurationError, /Missing required configuration: api_key/)
    end
  end

  describe '#healthy?' do
    it 'returns true when health check passes' do
      expect(integration.healthy?).to be true
    end

    it 'returns false when health check fails' do
      allow(integration).to receive(:health_check).and_raise(StandardError)
      expect(integration.healthy?).to be false
    end
  end

  describe '#handle_response' do
    let(:mock_response) { double('HTTParty::Response') }

    context 'with successful response' do
      it 'returns response for 2xx status codes' do
        allow(mock_response).to receive(:code).and_return(200)
        expect(integration.send(:handle_response, mock_response)).to eq(mock_response)
      end
    end

    context 'with error responses' do
      it 'raises AuthenticationError for 401' do
        allow(mock_response).to receive(:code).and_return(401)

        expect { integration.send(:handle_response, mock_response) }
          .to raise_error(TaskBrain::AuthenticationError, /Authentication failed for TestService/)
      end

      it 'raises AuthorizationError for 403' do
        allow(mock_response).to receive(:code).and_return(403)

        expect { integration.send(:handle_response, mock_response) }
          .to raise_error(TaskBrain::AuthorizationError, /Access denied for TestService/)
      end

      it 'raises NotFoundError for 404 with action' do
        allow(mock_response).to receive(:code).and_return(404)

        expect { integration.send(:handle_response, mock_response, 'task_123') }
          .to raise_error(TaskBrain::NotFoundError) do |error|
            expect(error.resource_type).to eq('TestService')
            expect(error.id).to eq('task_123')
          end
      end

      it 'raises RateLimitError for 429' do
        allow(mock_response).to receive(:code).and_return(429)
        allow(mock_response).to receive(:headers).and_return({ 'Retry-After' => '60' })

        expect { integration.send(:handle_response, mock_response) }
          .to raise_error(TaskBrain::RateLimitError) do |error|
            expect(error.retry_after).to eq(60)
          end
      end

      it 'raises IntegrationError for other 4xx errors' do
        allow(mock_response).to receive(:code).and_return(400)
        allow(mock_response).to receive(:body).and_return('Bad request')

        expect { integration.send(:handle_response, mock_response) }
          .to raise_error(TaskBrain::IntegrationError) do |error|
            expect(error.message).to match(/Client error: 400 - Bad request/)
            expect(error.integration_name).to eq('TestService')
          end
      end

      it 'raises IntegrationError for 5xx errors' do
        allow(mock_response).to receive(:code).and_return(503)

        expect { integration.send(:handle_response, mock_response) }
          .to raise_error(TaskBrain::IntegrationError) do |error|
            expect(error.message).to match(/Server error: 503/)
            expect(error.integration_name).to eq('TestService')
          end
      end
    end
  end

  describe '#with_error_handling' do
    it 'executes block successfully' do
      result = integration.send(:with_error_handling) { 'success' }
      expect(result).to eq('success')
    end

    it 'converts HTTParty errors to IntegrationError' do
      httparty_error = HTTParty::Error.new('Connection failed')

      expect do
        integration.send(:with_error_handling) { raise httparty_error }
      end.to raise_error(TaskBrain::IntegrationError, /Connection failed/)
    end

    it 'passes through TaskBrain errors' do
      task_brain_error = TaskBrain::AuthenticationError.new('Invalid token')

      expect do
        integration.send(:with_error_handling) { raise task_brain_error }
      end.to raise_error(TaskBrain::AuthenticationError, 'Invalid token')
    end

    it 'raises other errors unchanged' do
      expect do
        integration.send(:with_error_handling) { raise ArgumentError, 'Bad argument' }
      end.to raise_error(ArgumentError, 'Bad argument')
    end
  end

  describe '#validate_configuration!' do
    it 'passes with all required keys present' do
      expect { integration.send(:validate_configuration!) }.not_to raise_error
    end

    it 'raises error for missing keys' do
      integration = test_integration_class.allocate
      integration.instance_variable_set(:@config, { api_key: 'key' })

      expect { integration.send(:validate_configuration!) }
        .to raise_error(TaskBrain::ConfigurationError, /Missing required configuration: api_secret/)
    end

    it 'raises error for empty values' do
      integration = test_integration_class.allocate
      integration.instance_variable_set(:@config, { api_key: 'key', api_secret: '  ' })

      expect { integration.send(:validate_configuration!) }
        .to raise_error(TaskBrain::ConfigurationError, /Missing required configuration: api_secret/)
    end
  end
end
