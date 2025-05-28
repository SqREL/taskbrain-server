# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/integrations/linear'

RSpec.describe LinearIntegration do
  let(:api_key) { 'test_linear_api_key' }
  let(:integration) { described_class.new(api_key) }

  describe '#initialize' do
    it 'sets API key and headers' do
      expect(integration.instance_variable_get(:@api_key)).to eq(api_key)
      expect(integration.instance_variable_get(:@headers)).to include('Authorization' => api_key)
    end
  end

  describe '#get_issues' do
    it 'fetches issues with GraphQL query' do
      mock_response = {
        'data' => {
          'issues' => {
            'nodes' => [
              {
                'id' => 'issue_1',
                'title' => 'Test Issue',
                'priority' => 3
              }
            ]
          }
        }
      }

      allow(described_class).to receive(:post).and_return(
        double('Response', success?: true, dig: mock_response['data']['issues']['nodes'])
      )

      result = integration.get_issues
      expect(result).to be_an(Array)
    end

    it 'returns empty array when request fails' do
      allow(described_class).to receive(:post).and_return(
        double('Response', success?: false)
      )

      result = integration.get_issues
      expect(result).to eq([])
    end

    it 'includes correct headers in request' do
      expect(described_class).to receive(:post).with(
        '/graphql',
        {
          headers: {
            'Authorization' => api_key,
            'Content-Type' => 'application/json'
          },
          body: anything
        }
      ).and_return(double('Response', success?: true, dig: []))

      integration.get_issues
    end
  end

  describe '#get_issue' do
    let(:issue_id) { 'test_issue_id' }

    it 'fetches single issue by ID' do
      mock_issue = {
        'id' => issue_id,
        'title' => 'Test Issue',
        'state' => { 'name' => 'In Progress' }
      }
      
      mock_response = {
        'data' => {
          'issue' => mock_issue
        }
      }

      allow(described_class).to receive(:post).and_return(
        double('Response', success?: true, :[] => mock_response['data'], dig: mock_issue)
      )

      result = integration.get_issue(issue_id)
      expect(result).to include(id: issue_id)
    end

    it 'returns nil when issue not found' do
      allow(described_class).to receive(:post).and_return(
        double('Response', success?: false, dig: nil)
      )

      result = integration.get_issue(issue_id)
      expect(result).to be_nil
    end
  end

  describe '#create_issue' do
    let(:issue_data) { { 'title' => 'New Issue', 'teamId' => 'team_123' } }

    it 'creates issue with GraphQL mutation' do
      mock_response = {
        'data' => {
          'issueCreate' => {
            'success' => true,
            'issue' => {
              'id' => 'new_issue_id',
              'title' => 'New Issue'
            }
          }
        }
      }

      allow(described_class).to receive(:post).and_return(
        double('Response', success?: true, dig: mock_response['data']['issueCreate']['issue'])
      )

      result = integration.create_issue(issue_data)
      expect(result).to include('id' => 'new_issue_id')
    end

    it 'returns nil when creation fails' do
      allow(described_class).to receive(:post).and_return(
        double('Response', success?: false, dig: nil)
      )

      result = integration.create_issue(issue_data)
      expect(result).to be_nil
    end
  end

  describe '#get_teams' do
    it 'fetches teams list' do
      mock_teams = [
        { 'id' => 'team_1', 'name' => 'Team 1', 'key' => 'T1' }
      ]

      allow(described_class).to receive(:post).and_return(
        double('Response', success?: true, dig: mock_teams)
      )

      result = integration.get_teams
      expect(result).to eq(mock_teams)
    end

    it 'returns empty array when request fails' do
      allow(described_class).to receive(:post).and_return(
        double('Response', success?: false)
      )

      result = integration.get_teams
      expect(result).to eq([])
    end
  end

  describe '#format_issue' do
    let(:raw_issue) do
      {
        'id' => 'issue_123',
        'identifier' => 'TSK-123',
        'title' => 'Test Issue',
        'priority' => 3,
        'state' => { 'name' => 'In Progress', 'type' => 'started' },
        'assignee' => { 'name' => 'John Doe', 'email' => 'john@example.com' },
        'team' => { 'name' => 'Test Team', 'key' => 'TST' },
        'labels' => {
          'nodes' => [
            { 'name' => 'bug', 'color' => '#ff0000' }
          ]
        }
      }
    end

    it 'formats issue data correctly' do
      result = integration.send(:format_issue, raw_issue)

      expect(result).to include(
        id: 'issue_123',
        identifier: 'TSK-123',
        title: 'Test Issue',
        priority: 3,
        state: 'In Progress',
        state_type: 'started',
        assignee: 'John Doe',
        assignee_email: 'john@example.com',
        team_name: 'Test Team',
        team_key: 'TST'
      )

      expect(result[:labels]).to eq([{ name: 'bug', color: '#ff0000' }])
    end

    it 'handles missing optional fields gracefully' do
      minimal_issue = {
        'id' => 'issue_123',
        'title' => 'Minimal Issue'
      }

      result = integration.send(:format_issue, minimal_issue)
      expect(result[:id]).to eq('issue_123')
      expect(result[:title]).to eq('Minimal Issue')
      expect(result[:assignee]).to be_nil
    end
  end

  describe '#linear_priority_to_task_priority' do
    it 'maps Linear priorities correctly' do
      expect(integration.send(:linear_priority_to_task_priority, 0)).to eq(1)
      expect(integration.send(:linear_priority_to_task_priority, 1)).to eq(2)
      expect(integration.send(:linear_priority_to_task_priority, 2)).to eq(3)
      expect(integration.send(:linear_priority_to_task_priority, 3)).to eq(4)
      expect(integration.send(:linear_priority_to_task_priority, 4)).to eq(5)
      expect(integration.send(:linear_priority_to_task_priority, 99)).to eq(1)
    end
  end

  describe '#create_task_from_issue' do
    let(:issue_id) { 'issue_123' }

    before do
      allow(integration).to receive(:get_issue).with(issue_id).and_return(
        {
          id: issue_id,
          title: 'Test Issue',
          description: 'Issue description',
          priority: 3,
          due_date: '2024-01-15',
          team_key: 'TST',
          labels: [{ name: 'bug' }, { name: 'urgent' }]
        }
      )
    end

    it 'creates task data from Linear issue' do
      result = integration.create_task_from_issue(issue_id)

      expect(result).to include(
        content: 'Test Issue',
        description: 'Issue description',
        priority: 4,  # Linear priority 3 (High) converts to task priority 4
        due_date: '2024-01-15',
        external_id: issue_id,
        source: 'linear'
      )

      expect(result[:context_tags]).to include('development', 'TST')
      expect(result[:labels]).to eq(%w[bug urgent])
    end

    it 'returns nil when issue not found' do
      allow(integration).to receive(:get_issue).and_return(nil)

      result = integration.create_task_from_issue(issue_id)
      expect(result).to be_nil
    end

    it 'handles missing optional fields' do
      allow(integration).to receive(:get_issue).and_return(
        {
          id: issue_id,
          title: 'Minimal Issue',
          priority: 2
        }
      )

      result = integration.create_task_from_issue(issue_id)
      expect(result[:content]).to eq('Minimal Issue')
      expect(result[:priority]).to eq(3)  # Linear priority 2 (Medium) converts to task priority 3
      expect(result[:context_tags]).to eq(['development'])
    end
  end
end
