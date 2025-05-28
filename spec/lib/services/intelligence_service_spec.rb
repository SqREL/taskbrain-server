# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/services/intelligence_service'
require_relative '../../../lib/errors'

RSpec.describe Services::IntelligenceService do
  let(:mock_task_manager) { instance_double('TaskManager') }
  let(:mock_intelligence) { instance_double('TaskIntelligence') }
  let(:mock_calendar) { instance_double('GoogleCalendarIntegration') }
  let(:service) { described_class.new(mock_task_manager, mock_intelligence, mock_calendar) }

  describe '#priorities' do
    it 'delegates to intelligence module' do
      priorities = [{ task_id: 1, priority: 'high' }]
      expect(mock_intelligence).to receive(:suggest_priorities).and_return(priorities)

      result = service.priorities
      expect(result).to eq(priorities)
    end
  end

  describe '#daily_schedule' do
    it 'uses today as default date' do
      expect(mock_intelligence).to receive(:suggest_daily_schedule)
        .with(Date.today.to_s)
        .and_return([])

      service.daily_schedule
    end

    it 'accepts custom date' do
      date = '2024-01-15'
      expect(mock_intelligence).to receive(:suggest_daily_schedule)
        .with(date)
        .and_return([])

      service.daily_schedule(date)
    end
  end

  describe '#analyze_overdue_tasks' do
    it 'delegates to intelligence module' do
      analysis = { count: 5, suggestions: [] }
      expect(mock_intelligence).to receive(:overdue_analysis).and_return(analysis)

      result = service.analyze_overdue_tasks
      expect(result).to eq(analysis)
    end
  end

  describe '#smart_reschedule_task' do
    it 'delegates to intelligence module' do
      expect(mock_intelligence).to receive(:smart_reschedule)
        .with('task_123', '2024-01-20')
        .and_return({ success: true })

      result = service.smart_reschedule_task('task_123', '2024-01-20')
      expect(result).to eq({ success: true })
    end
  end

  describe '#batch_reschedule_tasks' do
    let(:requests) do
      [
        { 'task_id' => '1', 'new_date' => '2024-01-20' },
        { 'task_id' => '2', 'new_date' => '2024-01-21' }
      ]
    end

    it 'processes all requests successfully' do
      allow(mock_intelligence).to receive(:smart_reschedule).and_return({ rescheduled: true })

      results = service.batch_reschedule_tasks(requests)

      expect(results).to all(include(success: true, rescheduled: true))
      expect(results.size).to eq(2)
    end

    it 'handles failures gracefully' do
      allow(mock_intelligence).to receive(:smart_reschedule)
        .with('1', anything)
        .and_raise(StandardError, 'Reschedule failed')
      allow(mock_intelligence).to receive(:smart_reschedule)
        .with('2', anything)
        .and_return({ rescheduled: true })

      results = service.batch_reschedule_tasks(requests)

      expect(results[0]).to include(success: false, error: 'Reschedule failed')
      expect(results[1]).to include(success: true)
    end
  end

  describe '#recommendations' do
    it 'returns general recommendations by default' do
      general_recs = { type: 'general', items: [] }
      expect(mock_intelligence).to receive(:general_recommendations).and_return(general_recs)

      result = service.recommendations
      expect(result).to eq(general_recs)
    end

    it 'returns context-specific recommendations' do
      morning_recs = { type: 'morning', items: [] }
      expect(mock_intelligence).to receive(:morning_recommendations).and_return(morning_recs)

      result = service.recommendations('morning')
      expect(result).to eq(morning_recs)
    end
  end

  describe '#full_context' do
    before do
      allow(mock_task_manager).to receive(:get_tasks).and_return([])
      allow(mock_task_manager).to receive(:get_recent_activity).and_return([])
      allow(mock_task_manager).to receive(:get_upcoming_deadlines).and_return([])
      allow(mock_intelligence).to receive(:calculate_productivity_score).and_return(0.8)
      allow(mock_intelligence).to receive(:analyze_completion_patterns).and_return({})
      allow(mock_intelligence).to receive(:general_recommendations).and_return({})
      allow(mock_calendar).to receive(:get_events_for_date).and_return([])
    end

    it 'aggregates data from multiple sources' do
      result = service.full_context

      expect(result).to include(:tasks, :productivity, :calendar, :capacity)
      expect(result[:tasks]).to include(:active, :overdue, :today, :high_priority)
      expect(result[:productivity]).to include(:score, :patterns, :recommendations)
    end
  end

  describe '#context_for_date' do
    let(:date) { '2024-01-15' }

    before do
      allow(mock_task_manager).to receive(:get_tasks).and_return([])
      allow(mock_calendar).to receive(:get_events_for_date).and_return([])
      allow(mock_calendar).to receive(:find_available_slots).and_return([])
      allow(mock_intelligence).to receive(:suggest_daily_schedule).and_return([])
    end

    it 'returns context for specific date' do
      result = service.context_for_date(date)

      expect(result).to include(
        date: date,
        tasks: anything,
        calendar_events: anything,
        schedule_suggestions: anything,
        availability_windows: anything,
        energy_optimization: anything
      )
    end

    it 'raises validation error for invalid date' do
      expect { service.context_for_date('invalid-date') }
        .to raise_error(TaskBrain::ValidationError, /Invalid date format/)
    end
  end

  describe 'private methods' do
    describe '#analyze_current_capacity' do
      it 'calculates capacity based on active tasks' do
        tasks = [
          { estimated_duration: 120 },
          { estimated_duration: 60 },
          { estimated_duration: nil } # defaults to 60
        ]
        allow(mock_task_manager).to receive(:get_tasks).with(status: 'active').and_return(tasks)

        result = service.send(:analyze_current_capacity)

        expect(result[:total_active_tasks]).to eq(3)
        expect(result[:estimated_total_hours]).to eq(4.0)
        expect(result[:capacity_status]).to eq('light')
      end
    end

    describe '#determine_capacity_status' do
      it 'returns correct status based on minutes' do
        expect(service.send(:determine_capacity_status, 300)).to eq('light')
        expect(service.send(:determine_capacity_status, 700)).to eq('moderate')
        expect(service.send(:determine_capacity_status, 1200)).to eq('heavy')
        expect(service.send(:determine_capacity_status, 1500)).to eq('overloaded')
      end
    end
  end
end
