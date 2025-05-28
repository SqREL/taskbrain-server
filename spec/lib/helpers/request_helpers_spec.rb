# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/helpers/request_helpers'
require_relative '../../../lib/errors'

RSpec.describe RequestHelpers do
  let(:test_class) do
    Class.new do
      include RequestHelpers

      attr_reader :request, :auth_service

      def initialize(request, auth_service)
        @request = request
        @auth_service = auth_service
      end

      def halt(status, headers, body)
        throw :halt, { status: status, headers: headers, body: body }
      end
    end
  end

  let(:mock_request) { double('Request') }
  let(:mock_auth_service) { double('AuthService') }
  let(:helper) { test_class.new(mock_request, mock_auth_service) }

  describe '#authenticate_request' do
    let(:mock_env) { {} }

    before do
      allow(mock_request).to receive(:env).and_return(mock_env)
    end

    it 'extracts bearer token and verifies with auth service' do
      mock_env['HTTP_AUTHORIZATION'] = 'Bearer test_token'
      expect(mock_auth_service).to receive(:verify_api_key).with('test_token').and_return(true)

      expect(helper.authenticate_request).to be true
    end

    it 'returns false when no authorization header' do
      expect(mock_auth_service).to receive(:verify_api_key).with(nil).and_return(false)

      expect(helper.authenticate_request).to be false
    end
  end

  describe '#authenticate_claude_request' do
    let(:mock_env) { {} }

    before do
      allow(mock_request).to receive(:env).and_return(mock_env)
    end

    it 'extracts Claude API key and verifies with auth service' do
      mock_env['HTTP_X_CLAUDE_API_KEY'] = 'claude_key'
      expect(mock_auth_service).to receive(:verify_claude_api_key).with('claude_key').and_return(true)

      expect(helper.authenticate_claude_request).to be true
    end
  end

  describe '#json_body' do
    let(:mock_body) { double('Body') }

    before do
      allow(mock_request).to receive(:body).and_return(mock_body)
      allow(mock_body).to receive(:rewind)
    end

    it 'parses valid JSON' do
      allow(mock_body).to receive(:read).and_return('{"key": "value"}')

      result = helper.json_body
      expect(result).to eq({ 'key' => 'value' })
    end

    it 'returns empty hash for empty body' do
      allow(mock_body).to receive(:read).and_return('')

      result = helper.json_body
      expect(result).to eq({})
    end

    it 'raises ValidationError for invalid JSON' do
      allow(mock_body).to receive(:read).and_return('invalid json')

      expect { helper.json_body }
        .to raise_error(TaskBrain::ValidationError, /Invalid JSON/)
    end
  end

  describe '#json_error' do
    it 'halts with error response' do
      result = catch(:halt) do
        helper.json_error('Something went wrong', 400)
      end

      expect(result[:status]).to eq(400)
      expect(result[:headers]).to eq({ 'Content-Type' => 'application/json' })
      expect(JSON.parse(result[:body])).to eq({ 'error' => 'Something went wrong' })
    end

    it 'defaults to 400 status' do
      result = catch(:halt) do
        helper.json_error('Bad request')
      end

      expect(result[:status]).to eq(400)
    end
  end

  describe '#json_response' do
    it 'halts with JSON response' do
      data = { result: 'success' }

      result = catch(:halt) do
        helper.json_response(data, 201)
      end

      expect(result[:status]).to eq(201)
      expect(result[:headers]).to eq({ 'Content-Type' => 'application/json' })
      expect(JSON.parse(result[:body])).to eq({ 'result' => 'success' })
    end

    it 'defaults to 200 status' do
      result = catch(:halt) do
        helper.json_response({ ok: true })
      end

      expect(result[:status]).to eq(200)
    end
  end

  describe '#validate_json_body' do
    before do
      validation_utils_class = Class.new do
        def self.validate_and_parse_json(json)
          { data: JSON.parse(json), errors: nil }
        end
      end
      stub_const('ValidationUtils', validation_utils_class)
      allow(mock_request).to receive(:body).and_return(double(read: '{}'))
    end

    it 'delegates to ValidationUtils' do
      expect(ValidationUtils).to receive(:validate_and_parse_json).with('{}')
      helper.validate_json_body
    end
  end
end
