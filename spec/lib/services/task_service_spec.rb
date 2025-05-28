# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/services/task_service'
require_relative '../../../lib/errors'

RSpec.describe Services::TaskService do
  let(:mock_task_manager) { instance_double('TaskManager') }
  let(:mock_intelligence) { instance_double('TaskIntelligence') }
  let(:service) { described_class.new(mock_task_manager, mock_intelligence) }

  describe '#list_tasks' do
    it 'delegates to task manager' do
      filters = { status: 'active' }
      tasks = [{ id: 1, content: 'Task 1' }]

      expect(mock_task_manager).to receive(:get_tasks).with(filters).and_return(tasks)

      result = service.list_tasks(filters)
      expect(result).to eq(tasks)
    end
  end

  describe '#find_task' do
    context 'when task exists' do
      it 'returns the task' do
        task = { id: '123', content: 'Test task' }
        expect(mock_task_manager).to receive(:get_task).with('123').and_return(task)

        result = service.find_task('123')
        expect(result).to eq(task)
      end
    end

    context 'when task does not exist' do
      it 'raises NotFoundError' do
        expect(mock_task_manager).to receive(:get_task).with('999').and_return(nil)

        expect { service.find_task('999') }
          .to raise_error(TaskBrain::NotFoundError, "Task with id '999' not found")
      end
    end
  end

  describe '#create_task_with_intelligence' do
    let(:task_data) { { content: 'New task' } }
    let(:created_task) { { id: '123', content: 'New task' } }
    let(:suggestions) { { auto_apply: false, updates: {} } }
    let(:impact_analysis) { { impact: 'low' } }

    before do
      allow(mock_task_manager).to receive(:create_task).and_return(created_task)
      allow(mock_intelligence).to receive(:analyze_new_task).and_return(suggestions)
      allow(mock_intelligence).to receive(:analyze_task_impact).and_return(impact_analysis)
    end

    it 'creates task and returns with intelligence analysis' do
      result = service.create_task_with_intelligence(task_data)

      expect(result).to eq({
                             task: created_task,
                             suggestions: suggestions,
                             impact_analysis: impact_analysis
                           })
    end

    context 'with auto-apply suggestions' do
      let(:suggestions) { { auto_apply: true, updates: { priority: 4 } } }
      let(:updated_task) { { id: '123', content: 'New task', priority: 4 } }

      it 'applies suggestions automatically' do
        expect(mock_task_manager).to receive(:update_task)
          .with('123', { priority: 4 })
          .and_return(updated_task)

        result = service.create_task_with_intelligence(task_data)
        expect(result[:task]).to eq(updated_task)
      end
    end
  end

  describe '#update_task' do
    context 'when task exists' do
      it 'updates and returns the task' do
        updated_task = { id: '123', content: 'Updated' }
        expect(mock_task_manager).to receive(:update_task)
          .with('123', { content: 'Updated' })
          .and_return(updated_task)

        result = service.update_task('123', { content: 'Updated' })
        expect(result).to eq(updated_task)
      end
    end

    context 'when task does not exist' do
      it 'raises NotFoundError' do
        expect(mock_task_manager).to receive(:update_task)
          .with('999', anything)
          .and_return(nil)

        expect { service.update_task('999', {}) }
          .to raise_error(TaskBrain::NotFoundError)
      end
    end
  end

  describe '#delete_task' do
    context 'when task exists' do
      it 'deletes the task and returns true' do
        expect(mock_task_manager).to receive(:delete_task).with('123').and_return(true)

        result = service.delete_task('123')
        expect(result).to be true
      end
    end

    context 'when task does not exist' do
      it 'raises NotFoundError' do
        expect(mock_task_manager).to receive(:delete_task).with('999').and_return(false)

        expect { service.delete_task('999') }
          .to raise_error(TaskBrain::NotFoundError)
      end
    end
  end

  describe '#bulk_create_tasks' do
    let(:tasks_data) do
      [
        { content: 'Task 1' },
        { content: 'Task 2' }
      ]
    end

    it 'creates multiple tasks and returns results' do
      allow(service).to receive(:create_task_with_intelligence).and_return({
                                                                             task: { id: '1' },
                                                                             suggestions: {},
                                                                             impact_analysis: {}
                                                                           })

      results = service.bulk_create_tasks(tasks_data)

      expect(results).to all(include(success: true))
      expect(results.size).to eq(2)
    end

    it 'handles validation errors gracefully' do
      allow(service).to receive(:create_task_with_intelligence)
        .and_raise(TaskBrain::ValidationError.new(['Invalid content']))

      results = service.bulk_create_tasks([{ content: '' }])

      expect(results.first).to include(
        success: false,
        errors: ['Invalid content']
      )
    end
  end

  describe '#status_summary' do
    it 'returns task counts and activity summary' do
      expect(mock_task_manager).to receive(:count_tasks).and_return(10)
      expect(mock_task_manager).to receive(:count_overdue_tasks).and_return(2)
      expect(mock_task_manager).to receive(:count_today_tasks).and_return(3)
      expect(mock_task_manager).to receive(:count_high_priority_tasks).and_return(4)
      expect(mock_task_manager).to receive(:get_recent_activity).with(10).and_return([])
      expect(mock_task_manager).to receive(:get_upcoming_deadlines).with(5).and_return([])
      expect(mock_intelligence).to receive(:calculate_productivity_score).and_return(0.85)

      result = service.status_summary

      expect(result).to include(
        total_tasks: 10,
        overdue_tasks: 2,
        today_tasks: 3,
        high_priority: 4,
        productivity_score: 0.85
      )
    end
  end

  describe '#get_task_context' do
    let(:tasks) do
      [
        { id: 1, due_date: Date.today.to_s, status: 'active' },
        { id: 2, due_date: nil, status: 'active' },
        { id: 3, due_date: (Date.today + 1).to_s, status: 'active' }
      ]
    end

    before do
      allow(mock_task_manager).to receive(:get_tasks).and_return(tasks)
    end

    it 'returns tasks organized by date context' do
      result = service.get_task_context(Date.today.to_s)

      expect(result[:date]).to eq(Date.today.to_s)
      expect(result[:tasks][:due_today].size).to eq(1)
      expect(result[:tasks][:available_for_scheduling].size).to eq(3)
    end

    it 'raises validation error for invalid date' do
      expect { service.get_task_context('invalid-date') }
        .to raise_error(TaskBrain::ValidationError)
    end
  end
end
