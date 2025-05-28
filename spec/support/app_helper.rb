# frozen_string_literal: true

module AppHelper
  def app
    Sinatra::Application
  end

  def auth_headers
    { 'HTTP_AUTHORIZATION' => 'Bearer test_api_key' }
  end

  def claude_headers
    {
      'HTTP_AUTHORIZATION' => 'Bearer test_api_key',
      'HTTP_X_CLAUDE_API_KEY' => 'test_claude_key',
      'CONTENT_TYPE' => 'application/json'
    }
  end

  def json_headers
    { 'Content-Type' => 'application/json' }
  end

  def parse_json_response
    JSON.parse(last_response.body)
  end

  def mock_task_manager_methods
    allow($task_manager).to receive_messages(create_task: sample_task, get_task: sample_task, get_tasks: [sample_task],
                                             update_task: sample_task, delete_task: true, count_tasks: 5, count_overdue_tasks: 1, count_today_tasks: 2, count_high_priority_tasks: 1, get_recent_activity: [], get_upcoming_deadlines: [])
  end

  def mock_intelligence_methods
    allow($intelligence).to receive_messages(analyze_new_task: sample_intelligence_analysis,
                                             calculate_productivity_score: 75.5, analyze_completion_patterns: sample_patterns, general_recommendations: sample_recommendations, suggest_daily_schedule: sample_schedule, smart_reschedule: sample_reschedule_result, analyze_task_impact: sample_impact_analysis)
  end

  def mock_calendar_methods
    allow($calendar).to receive_messages(get_events_for_date: sample_calendar_events,
                                         find_available_slots: sample_availability_slots)
  end

  def sample_task
    {
      id: 1,
      content: 'Test task',
      description: 'Test description',
      priority: 3,
      due_date: Time.now + 86_400,
      created_at: Time.now,
      updated_at: Time.now,
      completed: false,
      source: 'manual',
      energy_level: 3,
      estimated_duration: 60
    }
  end

  def sample_intelligence_analysis
    {
      priority_adjustment: { suggested: 4, confidence: 0.8 },
      time_estimate: { estimate_minutes: 90, confidence: 0.7 },
      auto_apply: false
    }
  end

  def sample_patterns
    {
      optimal_hours: [9, 10, 11],
      optimal_days: [1, 2, 3],
      completion_velocity: 5.2,
      accuracy_rate: 0.85
    }
  end

  def sample_recommendations
    {
      top_priorities: [sample_task],
      quick_actions: [],
      productivity_tip: 'Focus on high-energy tasks in the morning'
    }
  end

  def sample_schedule
    {
      morning_block: [sample_task],
      afternoon_block: [],
      evening_block: [],
      buffer: []
    }
  end

  def sample_reschedule_result
    {
      feasible: true,
      conflicts: [],
      alternatives: [],
      impact_score: 0.8,
      rescheduled: true
    }
  end

  def sample_impact_analysis
    {
      dependency_impact: 'low',
      project_impact: 'medium',
      deadline_cascade: false,
      team_impact: 'none'
    }
  end

  def sample_calendar_events
    [
      {
        id: 'event_1',
        summary: 'Test Meeting',
        start_time: (Time.now + 3600).iso8601,
        end_time: (Time.now + 7200).iso8601
      }
    ]
  end

  def sample_availability_slots
    [
      {
        start: Time.now + 28_800,
        end: Time.now + 32_400,
        duration: 60
      }
    ]
  end

  def generate_todoist_signature(payload, secret = 'test_todoist_secret')
    "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, payload)}"
  end

  def generate_linear_signature(payload, secret = 'test_linear_secret')
    OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
  end
end

RSpec.configure do |config|
  config.include AppHelper
end
