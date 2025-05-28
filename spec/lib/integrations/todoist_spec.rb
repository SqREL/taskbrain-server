# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/integrations/todoist'

RSpec.describe TodoistIntegration do
  let(:client_id) { 'test_client_id' }
  let(:client_secret) { 'test_client_secret' }
  let(:integration) { described_class.new(client_id, client_secret) }

  describe '#initialize' do
    it 'sets client credentials' do
      expect(integration.instance_variable_get(:@client_id)).to eq(client_id)
      expect(integration.instance_variable_get(:@client_secret)).to eq(client_secret)
    end
  end

  describe '#exchange_code' do
    let(:auth_code) { 'test_auth_code' }

    it 'returns success response for valid code exchange' do
      allow(described_class).to receive(:post).and_return(
        double('Response', success?: true, :[] => 'test_access_token')
      )

      result = integration.exchange_code(auth_code)
      expect(result[:success]).to be true
      expect(result[:access_token]).to eq('test_access_token')
    end

    it 'returns error response for failed code exchange' do
      allow(described_class).to receive(:post).and_return(
        double('Response', success?: false, :[] => nil)
      )

      result = integration.exchange_code(auth_code)
      expect(result[:success]).to be false
      expect(result[:error]).to eq('Authentication failed')
    end

    it 'sends correct parameters to Todoist API' do
      expect(described_class).to receive(:post).with(
        '/oauth/access_token',
        {
          body: {
            client_id: client_id,
            client_secret: client_secret,
            code: auth_code
          }
        }
      ).and_return(double('Response', success?: true, :[] => 'token'))

      integration.exchange_code(auth_code)
    end
  end

  describe '#setup_webhook' do
    let(:access_token) { 'test_access_token' }
    let(:webhook_url) { 'https://example.com/webhooks/todoist' }

    before do
      ENV['BASE_URL'] = 'https://example.com'
    end

    it 'creates webhook with correct parameters' do
      expect(described_class).to receive(:post).with(
        '/rest/v2/webhooks',
        {
          headers: {
            'Authorization' => "Bearer #{access_token}",
            'Content-Type' => 'application/json'
          },
          body: {
            target_url: webhook_url,
            event_types: ['item:added', 'item:updated', 'item:completed', 'item:deleted']
          }.to_json
        }
      ).and_return(double('Response', success?: true))

      result = integration.setup_webhook(access_token)
      expect(result).to be true
    end

    it 'returns false when webhook setup fails' do
      allow(described_class).to receive(:post).and_return(
        double('Response', success?: false)
      )

      result = integration.setup_webhook(access_token)
      expect(result).to be false
    end
  end

  describe '#get_tasks' do
    let(:access_token) { 'test_access_token' }

    it 'fetches tasks with authorization header' do
      expect(described_class).to receive(:get).with(
        '/rest/v2/tasks',
        {
          headers: { 'Authorization' => "Bearer #{access_token}" },
          query: {}
        }
      ).and_return(double('Response', success?: true, parsed_response: []))

      result = integration.get_tasks(access_token)
      expect(result).to eq([])
    end

    it 'includes query parameters when provided' do
      expect(described_class).to receive(:get).with(
        '/rest/v2/tasks',
        {
          headers: { 'Authorization' => "Bearer #{access_token}" },
          query: { project_id: '123', filter: 'today' }
        }
      ).and_return(double('Response', success?: true, parsed_response: []))

      integration.get_tasks(access_token, project_id: '123', filter: 'today')
    end

    it 'returns empty array when request fails' do
      allow(described_class).to receive(:get).and_return(
        double('Response', success?: false)
      )

      result = integration.get_tasks(access_token)
      expect(result).to eq([])
    end
  end

  describe '#create_task' do
    let(:access_token) { 'test_access_token' }
    let(:task_data) { { 'content' => 'Test task', 'priority' => 4 } }

    it 'creates task with correct headers and data' do
      expect(described_class).to receive(:post).with(
        '/rest/v2/tasks',
        {
          headers: {
            'Authorization' => "Bearer #{access_token}",
            'Content-Type' => 'application/json'
          },
          body: task_data.to_json
        }
      ).and_return(double('Response', success?: true, parsed_response: task_data))

      result = integration.create_task(access_token, task_data)
      expect(result).to eq(task_data)
    end

    it 'returns nil when creation fails' do
      allow(described_class).to receive(:post).and_return(
        double('Response', success?: false)
      )

      result = integration.create_task(access_token, task_data)
      expect(result).to be_nil
    end
  end

  describe '#verify_webhook_signature' do
    let(:payload) { '{"event_name": "item:added"}' }
    let(:secret) { 'webhook_secret' }

    it 'returns true for valid signature' do
      expected_signature = OpenSSL::HMAC.hexdigest('SHA256', secret, payload)

      result = integration.verify_webhook_signature(payload, expected_signature, secret)
      expect(result).to be true
    end

    it 'returns false for invalid signature' do
      result = integration.verify_webhook_signature(payload, 'invalid_signature', secret)
      expect(result).to be false
    end

    it 'uses secure comparison to prevent timing attacks' do
      expect(Rack::Utils).to receive(:secure_compare)
      integration.verify_webhook_signature(payload, 'signature', secret)
    end
  end
end
