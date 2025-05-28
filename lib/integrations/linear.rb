# frozen_string_literal: true

require 'httparty'

class LinearIntegration
  include HTTParty
  base_uri 'https://api.linear.app'

  def initialize(api_key)
    @api_key = api_key
    @headers = {
      'Authorization' => api_key,
      'Content-Type' => 'application/json'
    }
  end

  def get_issues(team_id: nil, project_id: nil, state: nil)
    query = build_issues_query(team_id: team_id, project_id: project_id, state: state)

    response = self.class.post('/graphql', {
                                 headers: @headers,
                                 body: { query: query }.to_json
                               })

    if response.success?
      issues = response.dig('data', 'issues', 'nodes') || []
      issues.map { |issue| format_issue(issue) }
    else
      []
    end
  end

  def get_issue(issue_id)
    query = <<~GRAPHQL
      query GetIssue($id: String!) {
        issue(id: $id) {
          id
          identifier
          title
          description
          priority
          estimate
          state {
            name
            type
          }
          assignee {
            name
            email
          }
          team {
            name
            key
          }
          project {
            name
          }
          labels {
            nodes {
              name
              color
            }
          }
          dueDate
          createdAt
          updatedAt
          url
        }
      }
    GRAPHQL

    response = self.class.post('/graphql', {
                                 headers: @headers,
                                 body: {
                                   query: query,
                                   variables: { id: issue_id }
                                 }.to_json
                               })

    return unless response.success? && response.dig('data', 'issue')

    format_issue(response['data']['issue'])
  end

  def create_issue(issue_data)
    mutation = <<~GRAPHQL
      mutation CreateIssue($input: IssueCreateInput!) {
        issueCreate(input: $input) {
          success
          issue {
            id
            identifier
            title
            url
          }
        }
      }
    GRAPHQL

    response = self.class.post('/graphql', {
                                 headers: @headers,
                                 body: {
                                   query: mutation,
                                   variables: { input: issue_data }
                                 }.to_json
                               })

    return unless response.success? && response.dig('data', 'issueCreate', 'success')

    response.dig('data', 'issueCreate', 'issue')
  end

  def update_issue(issue_id, updates)
    mutation = <<~GRAPHQL
      mutation UpdateIssue($id: String!, $input: IssueUpdateInput!) {
        issueUpdate(id: $id, input: $input) {
          success
          issue {
            id
            identifier
            title
          }
        }
      }
    GRAPHQL

    response = self.class.post('/graphql', {
                                 headers: @headers,
                                 body: {
                                   query: mutation,
                                   variables: {
                                     id: issue_id,
                                     input: updates
                                   }
                                 }.to_json
                               })

    response.success? && response.dig('data', 'issueUpdate', 'success')
  end

  def teams
    query = <<~GRAPHQL
      query GetTeams {
        teams {
          nodes {
            id
            name
            key
            description
          }
        }
      }
    GRAPHQL

    response = self.class.post('/graphql', {
                                 headers: @headers,
                                 body: { query: query }.to_json
                               })

    if response.success?
      response.dig('data', 'teams', 'nodes') || []
    else
      []
    end
  end

  def get_projects(team_id: nil)
    query = if team_id
              <<~GRAPHQL
                query GetProjects($teamId: String!) {
                  team(id: $teamId) {
                    projects {
                      nodes {
                        id
                        name
                        description
                        state
                        progress
                        targetDate
                      }
                    }
                  }
                }
              GRAPHQL
            else
              <<~GRAPHQL
                query GetProjects {
                  projects {
                    nodes {
                      id
                      name
                      description
                      state
                      progress
                      targetDate
                      team {
                        name
                        key
                      }
                    }
                  }
                }
              GRAPHQL
            end

    variables = team_id ? { teamId: team_id } : {}

    response = self.class.post('/graphql', {
                                 headers: @headers,
                                 body: {
                                   query: query,
                                   variables: variables
                                 }.to_json
                               })

    if response.success?
      if team_id
        response.dig('data', 'team', 'projects', 'nodes') || []
      else
        response.dig('data', 'projects', 'nodes') || []
      end
    else
      []
    end
  end

  def search_issues(query_text, limit: 20)
    query = <<~GRAPHQL
      query SearchIssues($query: String!, $first: Int!) {
        searchIssues(query: $query, first: $first) {
          nodes {
            id
            identifier
            title
            description
            priority
            state {
              name
              type
            }
            team {
              name
              key
            }
            url
          }
        }
      }
    GRAPHQL

    response = self.class.post('/graphql', {
                                 headers: @headers,
                                 body: {
                                   query: query,
                                   variables: {
                                     query: query_text,
                                     first: limit
                                   }
                                 }.to_json
                               })

    if response.success?
      issues = response.dig('data', 'searchIssues', 'nodes') || []
      issues.map { |issue| format_issue(issue) }
    else
      []
    end
  end

  def get_workflow_states(team_id)
    query = <<~GRAPHQL
      query GetWorkflowStates($teamId: String!) {
        team(id: $teamId) {
          states {
            nodes {
              id
              name
              type
              color
              position
            }
          }
        }
      }
    GRAPHQL

    response = self.class.post('/graphql', {
                                 headers: @headers,
                                 body: {
                                   query: query,
                                   variables: { teamId: team_id }
                                 }.to_json
                               })

    if response.success?
      response.dig('data', 'team', 'states', 'nodes') || []
    else
      []
    end
  end

  def create_task_from_issue(issue_id)
    issue = get_issue(issue_id)
    return nil unless issue

    {
      content: issue[:title],
      description: issue[:description],
      priority: linear_priority_to_task_priority(issue[:priority]),
      due_date: issue[:due_date],
      external_id: issue[:id],
      source: 'linear',
      context_tags: ['development', issue[:team_key]].compact,
      labels: issue[:labels]&.map { |l| l[:name] } || []
    }
  end

  private

  def build_issues_query(team_id: nil, project_id: nil, state: nil)
    filters = []
    filters << "team: { id: { eq: \"#{team_id}\" } }" if team_id
    filters << "project: { id: { eq: \"#{project_id}\" } }" if project_id
    filters << "state: { type: { eq: #{state} } }" if state

    filter_clause = filters.any? ? "filter: { #{filters.join(', ')} }" : ''

    <<~GRAPHQL
      query GetIssues {
        issues(#{filter_clause}) {
          nodes {
            id
            identifier
            title
            description
            priority
            estimate
            state {
              name
              type
            }
            assignee {
              name
              email
            }
            team {
              name
              key
            }
            project {
              name
            }
            labels {
              nodes {
                name
                color
              }
            }
            dueDate
            createdAt
            updatedAt
            url
          }
        }
      }
    GRAPHQL
  end

  def format_issue(issue)
    {
      id: issue['id'],
      identifier: issue['identifier'],
      title: issue['title'],
      description: issue['description'],
      priority: issue['priority'],
      estimate: issue['estimate'],
      state: issue['state']&.dig('name'),
      state_type: issue['state']&.dig('type'),
      assignee: issue['assignee']&.dig('name'),
      assignee_email: issue['assignee']&.dig('email'),
      team_name: issue['team']&.dig('name'),
      team_key: issue['team']&.dig('key'),
      project_name: issue['project']&.dig('name'),
      labels: issue['labels']&.dig('nodes')&.map { |l| { name: l['name'], color: l['color'] } },
      due_date: issue['dueDate'],
      created_at: issue['createdAt'],
      updated_at: issue['updatedAt'],
      url: issue['url']
    }
  end

  def linear_priority_to_task_priority(linear_priority)
    case linear_priority
    when 0 then 1 # No priority -> Low
    when 1 then 2 # Low -> Medium-Low
    when 2 then 3 # Medium -> Medium
    when 3 then 4 # High -> High
    when 4 then 5 # Urgent -> Critical
    else 1
    end
  end
end
