# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/integrations/webhook_handler'
require_relative '../../support/app_helper'

RSpec.describe WebhookHandler do
  include AppHelper

  let(:mock_task_manager) { double('TaskManager') }
  let(:mock_intelligence) { double('TaskIntelligence') }
  let(:mock_logger) { double('Logger') }
  let(:mock_redis) { double('Redis') }
  let(:webhook_handler) { described_class.new(mock_task_manager, mock_intelligence) }

  before do
    mock_db = double('Database')
    mock_tasks_dataset = double('TasksDataset')

    allow(mock_db).to receive(:[]).with(:tasks).and_return(mock_tasks_dataset)
    allow(mock_tasks_dataset).to receive_messages(where: mock_tasks_dataset, first: nil)

    allow(mock_task_manager).to receive(:instance_variable_get).with(:@logger).and_return(mock_logger)
    allow(mock_task_manager).to receive(:instance_variable_get).with(:@redis).and_return(mock_redis)
    allow(mock_task_manager).to receive(:instance_variable_get).with(:@db).and_return(mock_db)
    allow(mock_logger).to receive(:info)
    allow(mock_logger).to receive(:warn)
    allow(mock_logger).to receive(:error)
  end

  describe '#verify_todoist_signature' do
    let(:payload) { '{"test": "data"}' }
    let(:secret) { 'test_secret' }

    before do
      ENV['TODOIST_WEBHOOK_SECRET'] = secret
    end

    it 'returns true for valid signature' do
      expected_signature = OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
      signature = "sha256=#{expected_signature}"

      result = webhook_handler.verify_todoist_signature(payload, signature)
      expect(result).to be true
    end

    it 'returns false for invalid signature' do
      invalid_signature = 'sha256=invalid_signature'

      result = webhook_handler.verify_todoist_signature(payload, invalid_signature)
      expect(result).to be false
    end

    it 'returns false for missing signature' do
      result = webhook_handler.verify_todoist_signature(payload, nil)
      expect(result).to be false
    end

    it 'uses WEBHOOK_SECRET as fallback' do
      ENV['TODOIST_WEBHOOK_SECRET'] = nil
      ENV['WEBHOOK_SECRET'] = secret

      expected_signature = OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
      signature = "sha256=#{expected_signature}"

      result = webhook_handler.verify_todoist_signature(payload, signature)
      expect(result).to be true
    end
  end

  describe '#verify_linear_signature' do
    let(:payload) { '{"test": "data"}' }
    let(:secret) { 'linear_secret' }

    before do
      ENV['LINEAR_WEBHOOK_SECRET'] = secret
    end

    it 'returns true for valid signature' do
      expected_signature = OpenSSL::HMAC.hexdigest('SHA256', secret, payload)

      result = webhook_handler.verify_linear_signature(payload, expected_signature)
      expect(result).to be true
    end

    it 'returns false for invalid signature' do
      invalid_signature = 'invalid_signature'

      result = webhook_handler.verify_linear_signature(payload, invalid_signature)
      expect(result).to be false
    end

    it 'returns false for missing signature' do
      result = webhook_handler.verify_linear_signature(payload, nil)
      expect(result).to be false
    end

    it 'returns false when secret is not configured' do
      ENV['LINEAR_WEBHOOK_SECRET'] = nil

      result = webhook_handler.verify_linear_signature(payload, 'any_signature')
      expect(result).to be false
    end
  end

  describe '#handle_todoist_event' do
    let(:webhook_data) { build(:todoist_webhook_payload) }

    before do
      allow(webhook_handler).to receive(:notify_claude_of_change)
      allow(mock_task_manager).to receive(:create_task).and_return(sample_task)
      allow(mock_intelligence).to receive(:analyze_new_task).and_return(sample_intelligence_analysis)
    end

    it 'logs the received event' do
      expect(mock_logger).to receive(:info).with(/Received Todoist webhook: item:added/)
      webhook_handler.handle_todoist_event(webhook_data)
    end

    it 'calls appropriate handler based on event name' do
      expect(webhook_handler).to receive(:handle_task_created).with(webhook_data['event_data'])
      webhook_handler.handle_todoist_event(webhook_data)
    end

    it 'notifies Claude of the change' do
      allow(webhook_handler).to receive(:handle_task_created)
      expect(webhook_handler).to receive(:notify_claude_of_change)
        .with('item:added', webhook_data['event_data'])
      webhook_handler.handle_todoist_event(webhook_data)
    end

    it 'warns about unknown events' do
      unknown_event = webhook_data.merge('event_name' => 'unknown:event')
      expect(mock_logger).to receive(:warn).with(/Unknown Todoist event: unknown:event/)
      webhook_handler.handle_todoist_event(unknown_event)
    end

    context 'for different event types' do
      it 'handles item:updated events' do
        updated_data = webhook_data.merge('event_name' => 'item:updated')
        expect(webhook_handler).to receive(:handle_task_updated)
        webhook_handler.handle_todoist_event(updated_data)
      end

      it 'handles item:completed events' do
        completed_data = webhook_data.merge('event_name' => 'item:completed')
        expect(webhook_handler).to receive(:handle_task_completed)
        webhook_handler.handle_todoist_event(completed_data)
      end

      it 'handles item:deleted events' do
        deleted_data = webhook_data.merge('event_name' => 'item:deleted')
        expect(webhook_handler).to receive(:handle_task_deleted)
        webhook_handler.handle_todoist_event(deleted_data)
      end
    end
  end

  describe '#handle_linear_event' do
    let(:webhook_data) { build(:linear_webhook_payload) }

    before do
      allow(webhook_handler).to receive(:notify_claude_of_change)
    end

    it 'logs the received event' do
      expect(mock_logger).to receive(:info).with(/Received Linear webhook: create/)
      webhook_handler.handle_linear_event(webhook_data)
    end

    it 'calls appropriate handler based on action' do
      expect(webhook_handler).to receive(:handle_linear_issue_created).with(webhook_data['data'])
      webhook_handler.handle_linear_event(webhook_data)
    end

    it 'notifies Claude of the change' do
      allow(webhook_handler).to receive(:handle_linear_issue_created)
      expect(webhook_handler).to receive(:notify_claude_of_change)
        .with('linear:create', webhook_data['data'])
      webhook_handler.handle_linear_event(webhook_data)
    end

    it 'warns about unknown actions' do
      unknown_action = webhook_data.merge('action' => 'unknown_action')
      expect(mock_logger).to receive(:warn).with(/Unknown Linear event: unknown_action/)
      webhook_handler.handle_linear_event(unknown_action)
    end
  end

  describe '#handle_task_created' do
    let(:event_data) { build(:todoist_webhook_payload)['event_data'] }
    let(:mock_db) { double('Database') }

    before do
      allow(mock_task_manager).to receive(:instance_variable_get).with(:@db).and_return(mock_db)
      allow(mock_db).to receive(:[]).with(:tasks).and_return(double('TasksDataset', where: double('Query', first: nil)))
      allow(mock_task_manager).to receive(:create_task).and_return(sample_task)
      allow(mock_intelligence).to receive(:analyze_new_task).and_return(sample_intelligence_analysis)
      allow(mock_task_manager).to receive(:update_task)
    end

    it 'creates a new task when task does not exist' do
      expected_task_data = {
        'content' => event_data['content'],
        'description' => event_data['description'],
        'project_id' => event_data['project_id'],
        'priority' => event_data['priority'],
        'due_date' => event_data['due']&.dig('datetime'),
        'labels' => event_data['labels'],
        'external_id' => event_data['id'],
        'source' => 'todoist'
      }

      expect(mock_task_manager).to receive(:create_task).with(expected_task_data)
      webhook_handler.send(:handle_task_created, event_data)
    end

    it 'runs intelligence analysis on new task' do
      expect(mock_intelligence).to receive(:analyze_new_task).with(sample_task)
      webhook_handler.send(:handle_task_created, event_data)
    end

    it 'auto-applies suggestions when confidence is high' do
      high_confidence_analysis = sample_intelligence_analysis.merge(auto_apply: true, updates: { priority: 4 })
      allow(mock_intelligence).to receive(:analyze_new_task).and_return(high_confidence_analysis)

      expect(mock_task_manager).to receive(:update_task).with(sample_task[:id], { priority: 4 })
      expect(mock_logger).to receive(:info).with(/Auto-applied intelligence suggestions/)

      webhook_handler.send(:handle_task_created, event_data)
    end

    it 'does not create task if it already exists' do
      existing_task = double('ExistingTask')
      query = double('Query', first: existing_task)
      dataset = double('TasksDataset', where: query)
      allow(mock_db).to receive(:[]).with(:tasks).and_return(dataset)

      expect(mock_task_manager).not_to receive(:create_task)
      webhook_handler.send(:handle_task_created, event_data)
    end
  end

  describe '#notify_claude_of_change' do
    let(:event_type) { 'item:added' }
    let(:event_data) { { 'task_id' => 123 } }
    let(:claude_webhook_url) { 'https://claude.ai/webhook' }

    before do
      ENV['CLAUDE_WEBHOOK_URL'] = claude_webhook_url
      allow(mock_task_manager).to receive_messages(count_tasks: 10, count_overdue_tasks: 2)
      allow(mock_intelligence).to receive(:calculate_productivity_score).and_return(75.5)
    end

    it 'sends notification to Claude webhook URL' do
      mock_http = double('HTTP')
      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:use_ssl=)
      allow(mock_http).to receive(:request).and_return(double('Response', code: '200'))

      # Mock the thread execution
      allow(Thread).to receive(:new).and_yield

      webhook_handler.send(:notify_claude_of_change, event_type, event_data)
    end

    it 'includes comprehensive context in notification' do
      # Mock HTTP components
      mock_http = double('HTTP')
      mock_request = double('Request')
      mock_response = double('Response', code: '200', message: 'OK')

      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:use_ssl=)
      allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
      allow(mock_request).to receive(:[]=)
      allow(mock_request).to receive(:body=)
      allow(mock_http).to receive(:request).and_return(mock_response)
      allow(Thread).to receive(:new).and_yield

      expect(mock_request).to receive(:body=) do |body|
        notification = JSON.parse(body)
        expect(notification['event_type']).to eq(event_type)
        expect(notification['event_data']).to eq(event_data)
        expect(notification['context']).to include('total_tasks', 'overdue_tasks', 'productivity_score')
      end

      webhook_handler.send(:notify_claude_of_change, event_type, event_data)
    end

    it 'logs successful notification' do
      mock_http = double('HTTP')
      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:use_ssl=)
      allow(mock_http).to receive(:request).and_return(double('Response', code: '200', message: 'OK'))
      allow(Thread).to receive(:new).and_yield

      expect(mock_logger).to receive(:info).with(/Successfully notified Claude of item:added/)
      webhook_handler.send(:notify_claude_of_change, event_type, event_data)
    end

    it 'logs failed notification' do
      mock_http = double('HTTP')
      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:use_ssl=)
      allow(mock_http).to receive(:request).and_return(double('Response', code: '500', message: 'Error'))
      allow(Thread).to receive(:new).and_yield

      expect(mock_logger).to receive(:warn).with(/Failed to notify Claude: 500 Error/)
      webhook_handler.send(:notify_claude_of_change, event_type, event_data)
    end

    it 'handles network errors gracefully' do
      allow(Net::HTTP).to receive(:new).and_raise(StandardError.new('Network error'))
      allow(Thread).to receive(:new).and_yield

      expect(mock_logger).to receive(:error).with(/Error notifying Claude: Network error/)
      webhook_handler.send(:notify_claude_of_change, event_type, event_data)
    end

    it 'does nothing when Claude webhook URL is not configured' do
      ENV['CLAUDE_WEBHOOK_URL'] = nil

      expect(Net::HTTP).not_to receive(:new)
      webhook_handler.send(:notify_claude_of_change, event_type, event_data)
    end
  end

  describe '#should_create_task_for_issue?' do
    let(:issue_data) do
      {
        'assignee' => { 'email' => 'user@example.com' },
        'team' => { 'key' => 'TEAM' }
      }
    end

    before do
      ENV['USER_EMAIL'] = 'user@example.com'
      ENV['TRACKED_LINEAR_TEAMS'] = 'TEAM1,TEAM2,TEAM'
    end

    it 'returns true when issue is assigned to the user' do
      result = webhook_handler.send(:should_create_task_for_issue?, issue_data)
      expect(result).to be true
    end

    it 'returns true when issue is in a tracked team' do
      different_user_issue = issue_data.merge('assignee' => { 'email' => 'other@example.com' })
      result = webhook_handler.send(:should_create_task_for_issue?, different_user_issue)
      expect(result).to be true
    end

    it 'returns false when issue is not assigned to user and not in tracked team' do
      untracked_issue = {
        'assignee' => { 'email' => 'other@example.com' },
        'team' => { 'key' => 'UNTRACKED' }
      }
      result = webhook_handler.send(:should_create_task_for_issue?, untracked_issue)
      expect(result).to be false
    end

    it 'handles missing assignee gracefully' do
      no_assignee_issue = issue_data.merge('assignee' => nil)
      result = webhook_handler.send(:should_create_task_for_issue?, no_assignee_issue)
      expect(result).to be true # Should still return true due to team tracking
    end
  end

  describe '#linear_priority_to_task_priority' do
    it 'maps Linear priorities to task priorities correctly' do
      expect(webhook_handler.send(:linear_priority_to_task_priority, 0)).to eq(1)
      expect(webhook_handler.send(:linear_priority_to_task_priority, 1)).to eq(2)
      expect(webhook_handler.send(:linear_priority_to_task_priority, 2)).to eq(3)
      expect(webhook_handler.send(:linear_priority_to_task_priority, 3)).to eq(4)
      expect(webhook_handler.send(:linear_priority_to_task_priority, 4)).to eq(5)
      expect(webhook_handler.send(:linear_priority_to_task_priority, 99)).to eq(1)
    end
  end

  private

  def sample_task
    {
      id: 1,
      content: 'Test task',
      priority: 3
    }
  end

  def sample_intelligence_analysis
    {
      priority_adjustment: { suggested: 4, confidence: 0.8 },
      auto_apply: false
    }
  end
end
