# frozen_string_literal: true

require 'spec_helper'
require_relative '../spec/support/app_helper'

RSpec.describe 'Claude API Endpoints', type: :request do
  before do
    mock_task_manager_methods
    mock_intelligence_methods
    mock_calendar_methods
  end

  describe 'GET /api/claude/full_context' do
    it 'requires Claude API key authentication' do
      get '/api/claude/full_context', {}, auth_headers
      expect(last_response.status).to eq(401)
    end

    it 'returns comprehensive context data' do
      get '/api/claude/full_context', {}, claude_headers
      expect(last_response.status).to eq(200)

      response_data = parse_json_response
      expect(response_data).to have_key('tasks')
      expect(response_data).to have_key('productivity')
      expect(response_data).to have_key('calendar')
      expect(response_data).to have_key('capacity')
      expect(response_data).to have_key('recent_activity')
      expect(response_data).to have_key('upcoming_deadlines')
    end

    it 'includes task categorization' do
      get '/api/claude/full_context', {}, claude_headers
      response_data = parse_json_response

      expect(response_data['tasks']).to have_key('active')
      expect(response_data['tasks']).to have_key('overdue')
      expect(response_data['tasks']).to have_key('today')
      expect(response_data['tasks']).to have_key('high_priority')
    end

    it 'includes productivity metrics' do
      get '/api/claude/full_context', {}, claude_headers
      response_data = parse_json_response

      expect(response_data['productivity']).to have_key('score')
      expect(response_data['productivity']).to have_key('patterns')
      expect(response_data['productivity']).to have_key('recommendations')
    end
  end

  describe 'POST /api/claude/smart_create' do
    let(:task_data) { build(:task_data) }

    it 'requires Claude API key authentication' do
      post '/api/claude/smart_create', task_data.to_json, auth_headers.merge(json_headers)
      expect(last_response.status).to eq(401)
    end

    it 'creates task with enhanced AI analysis' do
      post '/api/claude/smart_create', task_data.to_json, claude_headers
      expect(last_response.status).to eq(200)

      response_data = parse_json_response
      expect(response_data).to have_key('task')
      expect(response_data).to have_key('intelligence')
      expect(response_data).to have_key('optimal_scheduling')
      expect(response_data).to have_key('impact_analysis')
      expect(response_data).to have_key('recommended_actions')
    end

    it 'validates input data' do
      invalid_data = build(:invalid_task_data)
      post '/api/claude/smart_create', invalid_data.to_json, claude_headers
      expect(last_response.status).to eq(400)

      response_data = parse_json_response
      expect(response_data).to have_key('errors')
    end

    it 'includes optimal scheduling suggestions' do
      post '/api/claude/smart_create', task_data.to_json, claude_headers
      response_data = parse_json_response

      expect(response_data['optimal_scheduling']).to be_an(Array)
    end

    it 'includes immediate action recommendations' do
      task_with_dependencies = task_data.merge('dependencies' => [1, 2])
      post '/api/claude/smart_create', task_with_dependencies.to_json, claude_headers
      response_data = parse_json_response

      expect(response_data['recommended_actions']).to be_an(Array)
    end
  end

  describe 'POST /api/claude/bulk_create' do
    let(:bulk_data) { build(:bulk_tasks_data) }

    it 'requires Claude API key authentication' do
      post '/api/claude/bulk_create', bulk_data.to_json, auth_headers.merge(json_headers)
      expect(last_response.status).to eq(401)
    end

    it 'creates multiple tasks' do
      post '/api/claude/bulk_create', bulk_data.to_json, claude_headers
      expect(last_response.status).to eq(200)

      response_data = parse_json_response
      expect(response_data).to have_key('results')
      expect(response_data['results']).to be_an(Array)
      expect(response_data['results'].length).to eq(3)
    end

    it 'handles mixed valid and invalid tasks' do
      mixed_data = {
        'tasks' => [
          build(:task_data),
          build(:invalid_task_data),
          build(:task_data, content: 'Another valid task')
        ]
      }

      post '/api/claude/bulk_create', mixed_data.to_json, claude_headers
      expect(last_response.status).to eq(200)

      response_data = parse_json_response
      results = response_data['results']

      expect(results[0]).to have_key('success')
      expect(results[1]).to have_key('errors')
      expect(results[2]).to have_key('success')
    end

    it 'validates that tasks is an array' do
      invalid_bulk_data = { 'tasks' => 'not an array' }
      post '/api/claude/bulk_create', invalid_bulk_data.to_json, claude_headers
      expect(last_response.status).to eq(400)

      response_data = parse_json_response
      expect(response_data['errors']).to include('Tasks must be an array')
    end

    it 'includes intelligence analysis for each valid task' do
      post '/api/claude/bulk_create', bulk_data.to_json, claude_headers
      response_data = parse_json_response

      successful_results = response_data['results'].select { |r| r['success'] }
      successful_results.each do |result|
        expect(result).to have_key('suggestions')
        expect(result).to have_key('task')
      end
    end
  end

  describe 'GET /api/claude/context/:date' do
    let(:test_date) { '2024-01-15' }

    it 'requires Claude API key authentication' do
      get "/api/claude/context/#{test_date}", {}, auth_headers
      expect(last_response.status).to eq(401)
    end

    it 'returns date-specific context' do
      get "/api/claude/context/#{test_date}", {}, claude_headers
      expect(last_response.status).to eq(200)

      response_data = parse_json_response
      expect(response_data).to have_key('date')
      expect(response_data).to have_key('tasks')
      expect(response_data).to have_key('calendar_events')
      expect(response_data).to have_key('schedule_suggestions')
      expect(response_data).to have_key('availability_windows')
      expect(response_data).to have_key('energy_optimization')
    end

    it 'includes task categorization for the date' do
      get "/api/claude/context/#{test_date}", {}, claude_headers
      response_data = parse_json_response

      expect(response_data['tasks']).to have_key('due_today')
      expect(response_data['tasks']).to have_key('available_for_scheduling')
    end

    it 'returns 400 for invalid date format' do
      get '/api/claude/context/invalid-date', {}, claude_headers
      expect(last_response.status).to eq(400)

      response_data = parse_json_response
      expect(response_data['error']).to include('Invalid date format')
    end

    it 'calls intelligence service for schedule suggestions' do
      expect($intelligence).to receive(:suggest_daily_schedule).with(test_date)
      get "/api/claude/context/#{test_date}", {}, claude_headers
    end

    it 'calls calendar service for events and availability' do
      expect($calendar).to receive(:get_events_for_date).with(test_date)
      expect($calendar).to receive(:find_available_slots).with(test_date, 60)
      get "/api/claude/context/#{test_date}", {}, claude_headers
    end
  end

  describe 'POST /api/claude/reschedule_batch' do
    let(:reschedule_data) { build(:reschedule_data) }

    it 'requires Claude API key authentication' do
      post '/api/claude/reschedule_batch', reschedule_data.to_json, auth_headers.merge(json_headers)
      expect(last_response.status).to eq(401)
    end

    it 'reschedules multiple tasks' do
      post '/api/claude/reschedule_batch', reschedule_data.to_json, claude_headers
      expect(last_response.status).to eq(200)

      response_data = parse_json_response
      expect(response_data).to have_key('results')
      expect(response_data['results']).to be_an(Array)
      expect(response_data['results'].length).to eq(2)
    end

    it 'validates that reschedule_requests is an array' do
      invalid_data = { 'reschedule_requests' => 'not an array' }
      post '/api/claude/reschedule_batch', invalid_data.to_json, claude_headers
      expect(last_response.status).to eq(400)

      response_data = parse_json_response
      expect(response_data['errors']).to include('Reschedule requests must be an array')
    end

    it 'calls intelligence service for each reschedule request' do
      requests = reschedule_data[:reschedule_requests]

      requests.each do |request|
        expect($intelligence).to receive(:smart_reschedule)
          .with(request[:task_id], request[:new_date])
          .and_return(sample_reschedule_result)
      end

      post '/api/claude/reschedule_batch', reschedule_data.to_json, claude_headers
    end

    it 'includes task_id in each result' do
      post '/api/claude/reschedule_batch', reschedule_data.to_json, claude_headers
      response_data = parse_json_response

      response_data['results'].each_with_index do |result, index|
        expected_task_id = reschedule_data[:reschedule_requests][index][:task_id]
        expect(result['task_id']).to eq(expected_task_id)
      end
    end
  end

  describe 'existing Claude endpoints' do
    describe 'GET /api/claude/status' do
      it 'still works with enhanced authentication' do
        get '/api/claude/status', {}, claude_headers
        expect(last_response.status).to eq(200)

        response_data = parse_json_response
        expect(response_data).to have_key('total_tasks')
        expect(response_data).to have_key('productivity_score')
      end
    end

    describe 'POST /api/claude/create_task' do
      it 'still works with existing functionality' do
        task_data = build(:task_data)
        post '/api/claude/create_task', task_data.to_json, claude_headers
        expect(last_response.status).to eq(200)

        response_data = parse_json_response
        expect(response_data).to have_key('task')
        expect(response_data).to have_key('suggestions')
      end
    end

    describe 'GET /api/claude/recommendations' do
      it 'accepts context parameter' do
        get '/api/claude/recommendations?context=morning', {}, claude_headers
        expect(last_response.status).to eq(200)
      end
    end
  end

  describe 'helper method integration' do
    it 'uses analyze_current_capacity helper' do
      get '/api/claude/full_context', {}, claude_headers
      response_data = parse_json_response

      expect(response_data['capacity']).to have_key('total_active_tasks')
      expect(response_data['capacity']).to have_key('estimated_total_hours')
      expect(response_data['capacity']).to have_key('capacity_status')
      expect(response_data['capacity']).to have_key('recommendation')
    end

    it 'uses suggest_optimal_time_slots helper' do
      task_data = build(:task_data, energy_level: 5, estimated_duration: 90)
      post '/api/claude/smart_create', task_data.to_json, claude_headers
      response_data = parse_json_response

      expect(response_data['optimal_scheduling']).to be_an(Array)
    end

    it 'uses generate_immediate_actions helper' do
      task_with_meeting = build(:task_data, context_tags: ['meeting'])
      post '/api/claude/smart_create', task_with_meeting.to_json, claude_headers
      response_data = parse_json_response

      expect(response_data['recommended_actions']).to be_an(Array)
    end
  end
end
