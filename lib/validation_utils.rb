# frozen_string_literal: true

class ValidationUtils
  # Validation constraints
  CONTENT_MAX_LENGTH = 1000
  DESCRIPTION_MAX_LENGTH = 5000
  PRIORITY_RANGE = 1..5
  ENERGY_LEVEL_RANGE = 1..5
  VALID_DUE_DATE_FILTERS = %w[today week overdue].freeze
  VALID_STATUS_FILTERS = %w[active completed].freeze

  def self.validate_task_data(data)
    errors = []

    errors.concat(validate_content(data))
    errors.concat(validate_priority(data))
    errors.concat(validate_due_date(data))
    errors.concat(validate_energy_level(data))
    errors.concat(validate_duration(data))
    errors.concat(validate_labels(data))
    errors.concat(validate_context_tags(data))
    errors.concat(validate_description(data))

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
    {}.tap do |sanitized|
      sanitize_string_fields(sanitized, data)
      sanitize_numeric_fields(sanitized, data)
      sanitize_array_fields(sanitized, data)
      sanitize_other_fields(sanitized, data)
    end
  end

  def self.validate_filters(params)
    errors = []

    errors << 'Priority filter must be between 1 and 5' if params[:priority] && !params[:priority].match?(/^[1-5]$/)

    if params[:due_date] && !VALID_DUE_DATE_FILTERS.include?(params[:due_date])
      errors << "Due date filter must be one of: #{VALID_DUE_DATE_FILTERS.join(', ')}"
    end

    if params[:status] && !VALID_STATUS_FILTERS.include?(params[:status])
      errors << "Status filter must be one of: #{VALID_STATUS_FILTERS.join(', ')}"
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
       .slice(0, CONTENT_MAX_LENGTH) # Limit length
  end

  # Private validation methods
  private_class_method def self.validate_content(data)
    errors = []
    content = get_value(data, 'content')

    unless content.is_a?(String) && content.strip.length.positive?
      errors << 'Content is required and must be a non-empty string'
    end

    if content&.length && content.length > CONTENT_MAX_LENGTH
      errors << "Content must be less than #{CONTENT_MAX_LENGTH} characters"
    end

    errors
  end

  private_class_method def self.validate_priority(data)
    priority = get_value(data, 'priority')
    return [] unless priority

    unless priority.is_a?(Integer) && PRIORITY_RANGE.include?(priority)
      return ["Priority must be an integer between #{PRIORITY_RANGE.min} and #{PRIORITY_RANGE.max}"]
    end

    []
  end

  private_class_method def self.validate_due_date(data)
    due_date = get_value(data, 'due_date')
    return [] unless due_date

    valid_date_format?(due_date) ? [] : ['Due date must be a valid ISO 8601 date or natural language']
  end

  private_class_method def self.validate_energy_level(data)
    energy_level = get_value(data, 'energy_level')
    return [] unless energy_level

    unless energy_level.is_a?(Integer) && ENERGY_LEVEL_RANGE.include?(energy_level)
      return ["Energy level must be an integer between #{ENERGY_LEVEL_RANGE.min} and #{ENERGY_LEVEL_RANGE.max}"]
    end

    []
  end

  private_class_method def self.validate_duration(data)
    duration = get_value(data, 'estimated_duration')
    return [] unless duration

    unless duration.is_a?(Integer) && duration.positive?
      return ['Estimated duration must be a positive integer (minutes)']
    end

    []
  end

  private_class_method def self.validate_labels(data)
    labels = get_value(data, 'labels')
    return [] unless labels

    return ['Labels must be an array of strings'] unless labels.is_a?(Array) && labels.all? { |l| l.is_a?(String) }

    []
  end

  private_class_method def self.validate_context_tags(data)
    tags = get_value(data, 'context_tags')
    return [] unless tags

    return ['Context tags must be an array of strings'] unless tags.is_a?(Array) && tags.all? { |t| t.is_a?(String) }

    []
  end

  private_class_method def self.validate_description(data)
    description = get_value(data, 'description')
    return [] unless description && description.length > DESCRIPTION_MAX_LENGTH

    ["Description must be less than #{DESCRIPTION_MAX_LENGTH} characters"]
  end

  # Private sanitization methods
  private_class_method def self.sanitize_string_fields(sanitized, data)
    %w[content description project_id].each do |field|
      value = get_value(data, field)
      sanitized[field] = sanitize_string(value) if value
    end
  end

  private_class_method def self.sanitize_numeric_fields(sanitized, data)
    %w[priority energy_level estimated_duration].each do |field|
      value = get_value(data, field)
      sanitized[field] = value if value
    end
  end

  private_class_method def self.sanitize_array_fields(sanitized, data)
    %w[labels context_tags].each do |field|
      array = get_value(data, field)
      next unless array.is_a?(Array)

      sanitized[field] = array.map { |item| sanitize_string(item) }.compact
    end

    dependencies = get_value(data, 'dependencies')
    sanitized['dependencies'] = dependencies if dependencies.is_a?(Array)
  end

  private_class_method def self.sanitize_other_fields(sanitized, data)
    %w[due_date source external_id].each do |field|
      value = get_value(data, field)
      sanitized[field] = value if value
    end
  end

  # Helper method to get value with either string or symbol key
  private_class_method def self.get_value(hash, key)
    hash[key] || hash[key.to_sym]
  end
end
