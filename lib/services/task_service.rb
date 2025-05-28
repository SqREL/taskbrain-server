# frozen_string_literal: true

require_relative '../errors'

module Services
  class TaskService
    def initialize(task_manager, intelligence)
      @task_manager = task_manager
      @intelligence = intelligence
    end

    def list_tasks(filters = {})
      @task_manager.get_tasks(filters)
    end

    def find_task(id)
      task = @task_manager.get_task(id)
      raise TaskBrain::NotFoundError.new('Task', id) unless task

      task
    end

    def create_task_with_intelligence(task_data)
      task = @task_manager.create_task(task_data)
      suggestions = @intelligence.analyze_new_task(task)

      # Auto-apply intelligent suggestions if confidence is high
      task = @task_manager.update_task(task[:id], suggestions[:updates]) if suggestions[:auto_apply]

      {
        task: task,
        suggestions: suggestions,
        impact_analysis: @intelligence.analyze_task_impact(task)
      }
    end

    def update_task(id, task_data)
      task = @task_manager.update_task(id, task_data)
      raise TaskBrain::NotFoundError.new('Task', id) unless task

      task
    end

    def delete_task(id)
      success = @task_manager.delete_task(id)
      raise TaskBrain::NotFoundError.new('Task', id) unless success

      true
    end

    def bulk_create_tasks(tasks_data)
      tasks_data.map.with_index do |task_data, index|
        result = create_task_with_intelligence(task_data)
        result.merge(index: index, success: true)
      rescue TaskBrain::ValidationError => e
        { index: index, errors: e.errors, success: false }
      rescue StandardError => e
        { index: index, errors: [e.message], success: false }
      end
    end

    def get_task_context(date)
      parsed_date = Date.parse(date)

      {
        date: date,
        tasks: {
          due_today: @task_manager.get_tasks.select do |t|
            t[:due_date] && Date.parse(t[:due_date].to_s) == parsed_date
          end,
          available_for_scheduling: @task_manager.get_tasks(status: 'active').select do |t|
            t[:due_date].nil? || Date.parse(t[:due_date].to_s) >= parsed_date
          end
        }
      }
    rescue ArgumentError
      raise TaskBrain::ValidationError, ['Invalid date format']
    end

    def status_summary
      {
        total_tasks: @task_manager.count_tasks,
        overdue_tasks: @task_manager.count_overdue_tasks,
        today_tasks: @task_manager.count_today_tasks,
        high_priority: @task_manager.count_high_priority_tasks,
        recent_activity: @task_manager.get_recent_activity(10),
        next_deadlines: @task_manager.get_upcoming_deadlines(5),
        productivity_score: @intelligence.calculate_productivity_score
      }
    end
  end
end
