# frozen_string_literal: true

require_relative '../errors'

module Services
  class IntelligenceService
    def initialize(task_manager, intelligence, calendar)
      @task_manager = task_manager
      @intelligence = intelligence
      @calendar = calendar
    end

    def priorities
      @intelligence.suggest_priorities
    end

    def daily_schedule(date = nil)
      date ||= Date.today.to_s
      @intelligence.suggest_daily_schedule(date)
    end

    def analyze_overdue_tasks
      @intelligence.overdue_analysis
    end

    def smart_reschedule_task(task_id, new_date)
      @intelligence.smart_reschedule(task_id, new_date)
    end

    def batch_reschedule_tasks(reschedule_requests)
      reschedule_requests.map do |request|
        task_id = request['task_id']
        new_date = request['new_date']

        begin
          result = @intelligence.smart_reschedule(task_id, new_date)
          result.merge(task_id: task_id, success: true)
        rescue StandardError => e
          { task_id: task_id, success: false, error: e.message }
        end
      end
    end

    def recommendations(context = 'general')
      case context
      when 'morning'
        @intelligence.morning_recommendations
      when 'afternoon'
        @intelligence.afternoon_recommendations
      when 'planning'
        @intelligence.planning_recommendations
      else
        @intelligence.general_recommendations
      end
    end

    def full_context
      {
        tasks: {
          active: @task_manager.get_tasks(status: 'active'),
          overdue: @task_manager.get_tasks(due_date: 'overdue'),
          today: @task_manager.get_tasks(due_date: 'today'),
          high_priority: @task_manager.get_tasks.select { |t| t[:priority] >= 4 }
        },
        productivity: {
          score: @intelligence.calculate_productivity_score,
          patterns: @intelligence.analyze_completion_patterns,
          recommendations: @intelligence.general_recommendations
        },
        calendar: @calendar.get_events_for_date(Date.today.to_s),
        capacity: analyze_current_capacity,
        recent_activity: @task_manager.get_recent_activity(10),
        upcoming_deadlines: @task_manager.get_upcoming_deadlines(10)
      }
    end

    def context_for_date(date)
      parsed_date = Date.parse(date)

      {
        date: date,
        tasks: get_tasks_for_date(parsed_date),
        calendar_events: @calendar.get_events_for_date(date),
        schedule_suggestions: @intelligence.suggest_daily_schedule(date),
        availability_windows: @calendar.find_available_slots(date, 60),
        energy_optimization: get_energy_recommendations_for_date(parsed_date)
      }
    rescue ArgumentError
      raise TaskBrain::ValidationError, ['Invalid date format']
    end

    private

    def analyze_current_capacity
      active_tasks = @task_manager.get_tasks(status: 'active')
      total_estimated_time = active_tasks.sum { |t| t[:estimated_duration] || 60 }

      {
        total_active_tasks: active_tasks.length,
        estimated_total_hours: (total_estimated_time / 60.0).round(1),
        capacity_status: determine_capacity_status(total_estimated_time),
        recommendation: get_capacity_recommendation(total_estimated_time)
      }
    end

    def determine_capacity_status(minutes)
      case minutes
      when 0..480 then 'light'
      when 481..960 then 'moderate'
      when 961..1440 then 'heavy'
      else 'overloaded'
      end
    end

    def get_capacity_recommendation(minutes)
      case minutes
      when 0..240
        'You have light workload. Good time to take on additional tasks or focus on long-term projects.'
      when 241..480
        'Moderate workload. Maintain current pace and prioritize effectively.'
      when 481..720
        'Heavy workload. Consider deferring non-essential tasks.'
      else
        'Overloaded schedule. Urgent need to reschedule or delegate tasks.'
      end
    end

    def get_tasks_for_date(parsed_date)
      {
        due_today: @task_manager.get_tasks.select do |t|
          t[:due_date] && Date.parse(t[:due_date].to_s) == parsed_date
        end,
        available_for_scheduling: @task_manager.get_tasks(status: 'active').select do |t|
          t[:due_date].nil? || Date.parse(t[:due_date].to_s) >= parsed_date
        end
      }
    end

    def get_energy_recommendations_for_date(_date)
      hour = Time.now.hour

      {
        current_energy_level: estimate_current_energy_level(hour),
        optimal_task_types: get_optimal_task_types_for_hour(hour),
        energy_forecast: generate_daily_energy_forecast,
        recommendations: get_time_specific_recommendations(hour)
      }
    end

    def estimate_current_energy_level(hour)
      case hour
      when 6..9 then 4
      when 9..12 then 5
      when 12..14 then 3
      when 14..17 then 4
      when 17..20 then 2
      else 1
      end
    end

    def get_optimal_task_types_for_hour(hour)
      case hour
      when 6..12
        ['complex analysis', 'creative work', 'problem solving']
      when 12..17
        %w[meetings collaboration communication]
      when 17..21
        ['planning', 'review', 'administrative tasks']
      else
        ['light tasks', 'personal development']
      end
    end

    def generate_daily_energy_forecast
      (6..22).map do |hour|
        {
          hour: hour,
          energy_level: estimate_current_energy_level(hour),
          recommended_activities: get_optimal_task_types_for_hour(hour)
        }
      end
    end

    def get_time_specific_recommendations(hour)
      case hour
      when 6..9
        'Morning peak: Tackle your most challenging and important tasks now.'
      when 9..12
        'Optimal focus time: Perfect for deep work and complex problem-solving.'
      when 12..14
        'Post-lunch dip: Good time for lighter tasks and social activities.'
      when 14..17
        'Afternoon recovery: Ideal for meetings, calls, and collaborative work.'
      when 17..20
        'Evening wind-down: Review progress, plan tomorrow, handle admin tasks.'
      else
        'Low energy period: Focus on rest and light personal tasks.'
      end
    end
  end
end
