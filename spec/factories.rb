# frozen_string_literal: true

FactoryBot.define do
  factory :task_data, class: Hash do
    content { 'Test task content' }
    description { 'Test task description' }
    priority { 3 }
    energy_level { 3 }
    estimated_duration { 60 }
    due_date { (Time.now + 86_400).iso8601 }
    labels { %w[test sample] }
    context_tags { ['work'] }

    initialize_with { attributes }
  end

  factory :invalid_task_data, class: Hash do
    content { '' }
    priority { 10 }
    energy_level { 'invalid' }

    initialize_with { attributes }
  end

  factory :bulk_tasks_data, class: Hash do
    tasks do
      [
        { content: 'Task 1', priority: 3 },
        { content: 'Task 2', priority: 4 },
        { content: 'Task 3', priority: 2 }
      ]
    end

    initialize_with { attributes }
  end

  factory :reschedule_data, class: Hash do
    reschedule_requests do
      [
        { task_id: 1, new_date: '2024-01-15' },
        { task_id: 2, new_date: '2024-01-16' }
      ]
    end

    initialize_with { attributes }
  end

  factory :todoist_webhook_payload, class: Hash do
    event_name { 'item:added' }
    event_data do
      {
        'id' => '12345',
        'content' => 'New task from Todoist',
        'description' => 'Task description',
        'priority' => 4,
        'project_id' => 'project_123',
        'labels' => ['urgent'],
        'due' => { 'datetime' => (Time.now + 86_400).iso8601 }
      }
    end

    initialize_with { attributes.stringify_keys }
  end

  factory :linear_webhook_payload, class: Hash do
    action { 'create' }
    data do
      {
        'id' => 'issue_123',
        'identifier' => 'TSK-123',
        'title' => 'New Linear issue',
        'description' => 'Issue description',
        'priority' => 2,
        'state' => { 'name' => 'In Progress', 'type' => 'started' },
        'assignee' => { 'email' => ENV.fetch('USER_EMAIL', nil) },
        'team' => { 'key' => 'TSK', 'name' => 'Task Team' }
      }
    end

    initialize_with { attributes.stringify_keys }
  end
end
