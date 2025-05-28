# frozen_string_literal: true

class ValidationUtils
  def self.validate_task_data(data)
    errors = []

    # Helper method to get value with either string or symbol key
    get_value = ->(hash, key) { hash[key] || hash[key.to_sym] }

    # Required fields
    content = get_value.call(data, 'content')
    unless content.is_a?(String) && content.strip.length.positive?
      errors << 'Content is required and must be a non-empty string'
    end

    # Content length check
    errors << 'Content must be less than 1000 characters' if content&.length && content.length > 1000

    # Priority validation
    priority = get_value.call(data, 'priority')
    if priority && (!priority.is_a?(Integer) || !(1..5).include?(priority))
      errors << 'Priority must be an integer between 1 and 5'
    end

    # Due date validation
    due_date = get_value.call(data, 'due_date')
    if due_date && !valid_date_format?(due_date)
      errors << 'Due date must be a valid ISO 8601 date or natural language'
    end

    # Energy level validation
    energy_level = get_value.call(data, 'energy_level')
    if energy_level && (!energy_level.is_a?(Integer) || !(1..5).include?(energy_level))
      errors << 'Energy level must be an integer between 1 and 5'
    end

    # Estimated duration validation
    estimated_duration = get_value.call(data, 'estimated_duration')
    if estimated_duration && (!estimated_duration.is_a?(Integer) || estimated_duration <= 0)
      errors << 'Estimated duration must be a positive integer (minutes)'
    end

    # Labels validation
    labels = get_value.call(data, 'labels')
    if labels && (!labels.is_a?(Array) || labels.any? { |l| !l.is_a?(String) })
      errors << 'Labels must be an array of strings'
    end

    # Context tags validation
    context_tags = get_value.call(data, 'context_tags')
    if context_tags && (!context_tags.is_a?(Array) || context_tags.any? do |t|
      !t.is_a?(String)
    end)
      errors << 'Context tags must be an array of strings'
    end

    # Description length check
    description = get_value.call(data, 'description')
    if description && description.length > 5000
      errors << 'Description must be less than 5000 characters'
    end

    errors
  end

  def self.validate_and_parse_json(body)
    return { errors: ['Request body is required'] } if body.nil? || body.strip.empty?

    begin
      data = JSON.parse(body)
      errors = validate_task_data(data)

      if errors.any?
        { errors: errors }
      else
        { data: sanitize_task_data(data) }
      end
    rescue JSON::ParserError => e
      { errors: ["Invalid JSON: #{e.message}"] }
    end
  end

  def self.sanitize_task_data(data)
    sanitized = {}

    # Helper method to get value with either string or symbol key
    get_value = ->(hash, key) { hash[key] || hash[key.to_sym] }

    # Sanitize strings
    sanitized['content'] = sanitize_string(get_value.call(data, 'content'))
    sanitized['description'] = sanitize_string(get_value.call(data, 'description')) if get_value.call(data, 'description')
    sanitized['project_id'] = sanitize_string(get_value.call(data, 'project_id')) if get_value.call(data, 'project_id')

    # Safe copy of validated fields
    sanitized['priority'] = get_value.call(data, 'priority') if get_value.call(data, 'priority')
    sanitized['energy_level'] = get_value.call(data, 'energy_level') if get_value.call(data, 'energy_level')
    sanitized['estimated_duration'] = get_value.call(data, 'estimated_duration') if get_value.call(data, 'estimated_duration')
    sanitized['due_date'] = get_value.call(data, 'due_date') if get_value.call(data, 'due_date')

    # Sanitize arrays
    labels = get_value.call(data, 'labels')
    sanitized['labels'] = labels&.map { |l| sanitize_string(l) }&.compact if labels
    context_tags = get_value.call(data, 'context_tags')
    sanitized['context_tags'] = context_tags&.map { |t| sanitize_string(t) }&.compact if context_tags
    dependencies = get_value.call(data, 'dependencies')
    sanitized['dependencies'] = dependencies if dependencies.is_a?(Array)

    # Copy other safe fields
    sanitized['source'] = get_value.call(data, 'source') if get_value.call(data, 'source')
    sanitized['external_id'] = get_value.call(data, 'external_id') if get_value.call(data, 'external_id')

    sanitized
  end

  def self.validate_filters(params)
    errors = []

    errors << 'Priority filter must be between 1 and 5' if params[:priority] && !params[:priority].match?(/^[1-5]$/)

    if params[:due_date] && !%w[today week overdue].include?(params[:due_date])
      errors << 'Due date filter must be one of: today, week, overdue'
    end

    if params[:status] && !%w[active completed].include?(params[:status])
      errors << 'Status filter must be one of: active, completed'
    end

    errors
  end

  def self.valid_date_format?(date_string)
    return false unless date_string.is_a?(String)

    # Try parsing as ISO 8601
    DateTime.parse(date_string)
    true
  rescue ArgumentError
    # Try with Chronic for natural language
    require 'chronic'
    !Chronic.parse(date_string).nil?
  rescue StandardError
    false
  end

  def self.sanitize_string(str)
    return nil unless str.is_a?(String)

    # Remove potentially dangerous characters and normalize whitespace
    str.strip
       .gsub(/[<>\"']/, '') # Remove basic HTML/script chars
       .gsub(/\s+/, ' ')    # Normalize whitespace
       .slice(0, 1000)      # Limit length
  end
end
