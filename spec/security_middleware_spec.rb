# frozen_string_literal: true

require 'spec_helper'
require_relative '../spec/support/app_helper'

RSpec.describe 'Security Middleware', type: :request do
  before do
    mock_task_manager_methods
  end

  describe 'API authentication' do
    context 'when accessing protected endpoints without authentication' do
      it 'returns 401 for /api/tasks' do
        get '/api/tasks'
        expect(last_response.status).to eq(401)
        expect(parse_json_response['error']).to include('Unauthorized')
      end

      it 'returns 401 for /api/intelligence/priorities' do
        get '/api/intelligence/priorities'
        expect(last_response.status).to eq(401)
        expect(parse_json_response['error']).to include('Unauthorized')
      end

      it 'allows access to health endpoint without auth' do
        get '/health'
        expect(last_response.status).to eq(200)
      end

      it 'allows access to root endpoint without auth' do
        allow(File).to receive(:read).with('public/dashboard.html').and_return('<html>Dashboard</html>')
        get '/'
        expect(last_response.status).to eq(200)
      end
    end

    context 'when accessing protected endpoints with valid API key' do
      it 'allows access to /api/tasks with valid auth header' do
        get '/api/tasks', {}, auth_headers
        expect(last_response.status).to eq(200)
      end

      it 'allows access to /api/intelligence/priorities with valid auth header' do
        allow($intelligence).to receive(:suggest_priorities).and_return({ high_priority: [] })
        get '/api/intelligence/priorities', {}, auth_headers
        expect(last_response.status).to eq(200)
      end
    end

    context 'when accessing protected endpoints with invalid API key' do
      it 'returns 401 with invalid auth header' do
        get '/api/tasks', {}, { 'Authorization' => 'Bearer invalid_key' }
        expect(last_response.status).to eq(401)
        expect(parse_json_response['error']).to include('Unauthorized')
      end

      it 'returns 401 with malformed auth header' do
        get '/api/tasks', {}, { 'Authorization' => 'invalid_format' }
        expect(last_response.status).to eq(401)
        expect(parse_json_response['error']).to include('Unauthorized')
      end
    end
  end

  describe 'Claude API authentication' do
    context 'when accessing Claude endpoints without Claude API key' do
      it 'returns 401 for /api/claude/status even with valid API key' do
        get '/api/claude/status', {}, auth_headers
        expect(last_response.status).to eq(401)
        expect(parse_json_response['error']).to include('Claude API key')
      end

      it 'returns 401 for /api/claude/full_context' do
        get '/api/claude/full_context', {}, auth_headers
        expect(last_response.status).to eq(401)
        expect(parse_json_response['error']).to include('Claude API key')
      end
    end

    context 'when accessing Claude endpoints with valid Claude API key' do
      before do
        mock_intelligence_methods
        mock_calendar_methods
      end

      it 'allows access to /api/claude/status' do
        get '/api/claude/status', {}, claude_headers
        expect(last_response.status).to eq(200)
      end

      it 'allows access to /api/claude/full_context' do
        get '/api/claude/full_context', {}, claude_headers
        expect(last_response.status).to eq(200)
      end
    end

    context 'when accessing Claude endpoints with invalid Claude API key' do
      it 'returns 401 with invalid Claude API key' do
        headers = auth_headers.merge('X-Claude-API-Key' => 'invalid_claude_key')
        get '/api/claude/status', {}, headers
        expect(last_response.status).to eq(401)
        expect(parse_json_response['error']).to include('Claude API key')
      end
    end
  end

  describe 'CORS headers' do
    it 'sets correct CORS headers for API requests' do
      get '/api/tasks', {}, auth_headers
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('https://claude.ai')
    end

    it 'sets JSON content type for API responses' do
      get '/api/tasks', {}, auth_headers
      expect(last_response.headers['Content-Type']).to include('application/json')
    end
  end

  describe 'authentication helper methods' do
    describe '#authenticate_request' do
      it 'returns true for valid API key' do
        # We need to test this through actual requests since the methods are part of the Sinatra app
        get '/api/tasks', {}, auth_headers
        expect(last_response.status).not_to eq(401)
      end
    end

    describe '#authenticate_claude_request' do
      it 'returns true for valid Claude API key' do
        mock_intelligence_methods
        get '/api/claude/status', {}, claude_headers
        expect(last_response.status).not_to eq(401)
      end
    end
  end

  describe 'request and response logging' do
    before do
      allow($logger).to receive(:info)
      allow($logger).to receive(:warn)
    end

    it 'logs request start' do
      expect($logger).to receive(:info).with(%r{GET /api/tasks - Started})
      get '/api/tasks', {}, auth_headers
    end

    it 'logs request completion with timing' do
      expect($logger).to receive(:info).with(%r{GET /api/tasks - Completed \d+ in \d+\.\d+ms})
      get '/api/tasks', {}, auth_headers
    end

    it 'logs unauthorized access attempts' do
      expect($logger).to receive(:warn).with(/401 Unauthorized access attempt/)
      get '/api/tasks'
    end
  end
end
