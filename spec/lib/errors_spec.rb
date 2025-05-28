# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/errors'

RSpec.describe TaskBrain::Error do
  describe TaskBrain::ValidationError do
    it 'stores errors array' do
      errors = ['Field is required', 'Invalid format']
      error = TaskBrain::ValidationError.new(errors)

      expect(error.errors).to eq(errors)
      expect(error.message).to eq('Field is required, Invalid format')
    end

    it 'handles single error string' do
      error = TaskBrain::ValidationError.new('Invalid input')

      expect(error.errors).to eq('Invalid input')
      expect(error.message).to eq('Invalid input')
    end
  end

  describe TaskBrain::NotFoundError do
    it 'stores resource type and id' do
      error = TaskBrain::NotFoundError.new('Task', '123')

      expect(error.resource_type).to eq('Task')
      expect(error.id).to eq('123')
      expect(error.message).to eq("Task with id '123' not found")
    end
  end

  describe TaskBrain::AuthenticationError do
    it 'has default message' do
      error = TaskBrain::AuthenticationError.new
      expect(error.message).to eq('Authentication failed')
    end

    it 'accepts custom message' do
      error = TaskBrain::AuthenticationError.new('Invalid token')
      expect(error.message).to eq('Invalid token')
    end
  end

  describe TaskBrain::AuthorizationError do
    it 'has default message' do
      error = TaskBrain::AuthorizationError.new
      expect(error.message).to eq('You are not authorized to perform this action')
    end

    it 'accepts custom message' do
      error = TaskBrain::AuthorizationError.new('Insufficient permissions')
      expect(error.message).to eq('Insufficient permissions')
    end
  end

  describe TaskBrain::IntegrationError do
    it 'stores integration name' do
      error = TaskBrain::IntegrationError.new('Todoist')

      expect(error.integration_name).to eq('Todoist')
      expect(error.original_error).to be_nil
      expect(error.message).to eq('Error communicating with Todoist')
    end

    it 'includes original error message' do
      original = StandardError.new('Connection timeout')
      error = TaskBrain::IntegrationError.new('Linear', original)

      expect(error.integration_name).to eq('Linear')
      expect(error.original_error).to eq(original)
      expect(error.message).to eq('Error communicating with Linear: Connection timeout')
    end
  end

  describe TaskBrain::WebhookVerificationError do
    it 'stores service name' do
      error = TaskBrain::WebhookVerificationError.new('Todoist')

      expect(error.service).to eq('Todoist')
      expect(error.message).to eq('Invalid webhook signature from Todoist')
    end
  end

  describe TaskBrain::RateLimitError do
    it 'has default message without retry_after' do
      error = TaskBrain::RateLimitError.new

      expect(error.retry_after).to be_nil
      expect(error.message).to eq('Rate limit exceeded')
    end

    it 'includes retry_after in message' do
      error = TaskBrain::RateLimitError.new(60)

      expect(error.retry_after).to eq(60)
      expect(error.message).to eq('Rate limit exceeded. Retry after 60 seconds')
    end
  end

  describe TaskBrain::ConfigurationError do
    it 'prefixes message with Configuration error' do
      error = TaskBrain::ConfigurationError.new('Missing API key')

      expect(error.message).to eq('Configuration error: Missing API key')
    end
  end
end
