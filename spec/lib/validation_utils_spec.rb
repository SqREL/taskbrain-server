# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/validation_utils'

RSpec.describe ValidationUtils do
  describe '.validate_task_data' do
    context 'with valid task data' do
      let(:valid_data) { build(:task_data) }

      it 'returns no errors for valid data' do
        errors = described_class.validate_task_data(valid_data)
        expect(errors).to be_empty
      end

      it 'accepts minimal valid data' do
        minimal_data = { 'content' => 'Test task' }
        errors = described_class.validate_task_data(minimal_data)
        expect(errors).to be_empty
      end
    end

    context 'with invalid task data' do
      it 'returns error for missing content' do
        data = build(:task_data, content: nil)
        errors = described_class.validate_task_data(data)
        expect(errors).to include(/Content is required/)
      end

      it 'returns error for empty content' do
        data = build(:task_data, content: '   ')
        errors = described_class.validate_task_data(data)
        expect(errors).to include(/Content is required/)
      end

      it 'returns error for content too long' do
        data = build(:task_data, content: 'a' * 1001)
        errors = described_class.validate_task_data(data)
        expect(errors).to include(/Content must be less than 1000 characters/)
      end

      it 'returns error for invalid priority' do
        data = build(:task_data, priority: 10)
        errors = described_class.validate_task_data(data)
        expect(errors).to include(/Priority must be an integer between 1 and 5/)
      end

      it 'returns error for non-integer priority' do
        data = build(:task_data, priority: 'high')
        errors = described_class.validate_task_data(data)
        expect(errors).to include(/Priority must be an integer between 1 and 5/)
      end

      it 'returns error for invalid energy level' do
        data = build(:task_data, energy_level: 6)
        errors = described_class.validate_task_data(data)
        expect(errors).to include(/Energy level must be an integer between 1 and 5/)
      end

      it 'returns error for negative estimated duration' do
        data = build(:task_data, estimated_duration: -30)
        errors = described_class.validate_task_data(data)
        expect(errors).to include(/Estimated duration must be a positive integer/)
      end

      it 'returns error for non-array labels' do
        data = build(:task_data, labels: 'not an array')
        errors = described_class.validate_task_data(data)
        expect(errors).to include(/Labels must be an array of strings/)
      end

      it 'returns error for labels with non-string elements' do
        data = build(:task_data, labels: ['valid', 123, 'also_valid'])
        errors = described_class.validate_task_data(data)
        expect(errors).to include(/Labels must be an array of strings/)
      end

      it 'returns error for description too long' do
        data = build(:task_data, description: 'a' * 5001)
        errors = described_class.validate_task_data(data)
        expect(errors).to include(/Description must be less than 5000 characters/)
      end
    end

    context 'with multiple validation errors' do
      it 'returns all validation errors' do
        data = {
          'content' => '',
          'priority' => 10,
          'energy_level' => 'invalid'
        }
        errors = described_class.validate_task_data(data)
        expect(errors.length).to eq(3)
        expect(errors).to include(/Content is required/)
        expect(errors).to include(/Priority must be an integer/)
        expect(errors).to include(/Energy level must be an integer/)
      end
    end
  end

  describe '.validate_and_parse_json' do
    context 'with valid JSON' do
      it 'returns parsed data for valid JSON and data' do
        json_string = build(:task_data).to_json
        result = described_class.validate_and_parse_json(json_string)
        expect(result).to have_key(:data)
        expect(result[:data]).to include('content')
      end

      it 'sanitizes the data' do
        data = { 'content' => '<script>alert("test")</script>Task content' }
        json_string = data.to_json
        result = described_class.validate_and_parse_json(json_string)
        expect(result[:data]['content']).not_to include('<script>')
        expect(result[:data]['content']).to include('Task content')
      end
    end

    context 'with invalid JSON' do
      it 'returns error for malformed JSON' do
        result = described_class.validate_and_parse_json('{ invalid json }')
        expect(result).to have_key(:errors)
        expect(result[:errors]).to include(/Invalid JSON/)
      end

      it 'returns error for empty body' do
        result = described_class.validate_and_parse_json('')
        expect(result).to have_key(:errors)
        expect(result[:errors]).to include(/Request body is required/)
      end

      it 'returns error for nil body' do
        result = described_class.validate_and_parse_json(nil)
        expect(result).to have_key(:errors)
        expect(result[:errors]).to include(/Request body is required/)
      end
    end

    context 'with valid JSON but invalid data' do
      it 'returns validation errors' do
        invalid_data = build(:invalid_task_data)
        json_string = invalid_data.to_json
        result = described_class.validate_and_parse_json(json_string)
        expect(result).to have_key(:errors)
        expect(result[:errors]).to include(/Content is required/)
      end
    end
  end

  describe '.sanitize_task_data' do
    it 'sanitizes string content' do
      data = {
        'content' => '<script>alert("test")</script>Clean content',
        'description' => 'Description with  multiple   spaces'
      }
      sanitized = described_class.sanitize_task_data(data)
      expect(sanitized['content']).to eq('scriptalert(test)/scriptClean content')
      expect(sanitized['description']).to eq('Description with multiple spaces')
    end

    it 'preserves safe numeric values' do
      data = {
        'content' => 'Test',
        'priority' => 4,
        'energy_level' => 3,
        'estimated_duration' => 90
      }
      sanitized = described_class.sanitize_task_data(data)
      expect(sanitized['priority']).to eq(4)
      expect(sanitized['energy_level']).to eq(3)
      expect(sanitized['estimated_duration']).to eq(90)
    end

    it 'sanitizes arrays of strings' do
      data = {
        'content' => 'Test',
        'labels' => ['<script>bad</script>good', 'normal label'],
        'context_tags' => %w[work urgent]
      }
      sanitized = described_class.sanitize_task_data(data)
      expect(sanitized['labels']).to eq(['scriptbad/scriptgood', 'normal label'])
      expect(sanitized['context_tags']).to eq(%w[work urgent])
    end

    it 'limits string length' do
      data = {
        'content' => 'a' * 1500,
        'description' => 'b' * 1500
      }
      sanitized = described_class.sanitize_task_data(data)
      expect(sanitized['content'].length).to eq(1000)
      expect(sanitized['description'].length).to eq(1000)
    end
  end

  describe '.validate_filters' do
    it 'returns no errors for valid filters' do
      params = { priority: '3', due_date: 'today', status: 'active' }
      errors = described_class.validate_filters(params)
      expect(errors).to be_empty
    end

    it 'returns error for invalid priority filter' do
      params = { priority: '10' }
      errors = described_class.validate_filters(params)
      expect(errors).to include(/Priority filter must be between 1 and 5/)
    end

    it 'returns error for invalid due_date filter' do
      params = { due_date: 'invalid_date' }
      errors = described_class.validate_filters(params)
      expect(errors).to include(/Due date filter must be one of/)
    end

    it 'returns error for invalid status filter' do
      params = { status: 'invalid_status' }
      errors = described_class.validate_filters(params)
      expect(errors).to include(/Status filter must be one of/)
    end

    it 'returns multiple errors for multiple invalid filters' do
      params = { priority: '10', status: 'invalid' }
      errors = described_class.validate_filters(params)
      expect(errors.length).to eq(2)
    end
  end
end
