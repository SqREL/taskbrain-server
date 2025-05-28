# frozen_string_literal: true

class ValidationUtils
  def self.validate_task_data(data)
    errors = []

    # Required fields
    unless data['content']&.is_a?(String) && data['content'].strip.length.positive?
      errors << 'Content is required and must be a non-empty string'
    end

    # Content length check
    if data['content']&.length && data['content'].length > 1000
      errors << 'Content must be less than 1000 characters'
    end

    # Priority validation
    if data['priority'] && (!data['priority'].is_a?(Integer) || !(1..5).include?(data['priority']))
      errors << 'Priority must be an integer between 1 and 5'
    end

    # Due date validation
    if data['due_date'] && !valid_date_format?(data['due_date'])
      errors << 'Due date must be a valid ISO 8601 date or natural language'
    end

    # Energy level validation
    if data['energy_level'] && (!data['energy_level'].is_a?(Integer) || !(1..5).include?(data['energy_level']))
      errors << 'Energy level must be an integer between 1 and 5'
    end

    # Estimated duration validation
    if data['estimated_duration'] && (!data['estimated_duration'].is_a?(Integer) || data['estimated_duration'] <= 0)
      errors << 'Estimated duration must be a positive integer (minutes)'
    end

    # Labels validation
    if data['labels'] && (!data['labels'].is_a?(Array) || data['labels'].any? { |l| !l.is_a?(String) })
      errors << 'Labels must be an array of strings'
    end

    # Context tags validation
    if data['context_tags'] && (!data['context_tags'].is_a?(Array) || data['context_tags'].any? { |t| !t.is_a?(String) })
      errors << 'Context tags must be an array of strings'
    end

    # Description length check
    if data['description'] && data['description'].length > 5000
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
    
    # Sanitize strings
    sanitized['content'] = sanitize_string(data['content'])
    sanitized['description'] = sanitize_string(data['description']) if data['description']
    sanitized['project_id'] = sanitize_string(data['project_id']) if data['project_id']
    
    # Safe copy of validated fields
    sanitized['priority'] = data['priority'] if data['priority']
    sanitized['energy_level'] = data['energy_level'] if data['energy_level']
    sanitized['estimated_duration'] = data['estimated_duration'] if data['estimated_duration']
    sanitized['due_date'] = data['due_date'] if data['due_date']
    
    # Sanitize arrays
    sanitized['labels'] = data['labels']&.map { |l| sanitize_string(l) }&.compact if data['labels']
    sanitized['context_tags'] = data['context_tags']&.map { |t| sanitize_string(t) }&.compact if data['context_tags']
    sanitized['dependencies'] = data['dependencies'] if data['dependencies']&.is_a?(Array)
    
    # Copy other safe fields
    sanitized['source'] = data['source'] if data['source']
    sanitized['external_id'] = data['external_id'] if data['external_id']
    
    sanitized
  end

  def self.validate_filters(params)
    errors = []
    
    if params[:priority] && !params[:priority].match?(/^[1-5]$/)
      errors << 'Priority filter must be between 1 and 5'
    end
    
    if params[:due_date] && !%w[today week overdue].include?(params[:due_date])
      errors << 'Due date filter must be one of: today, week, overdue'
    end
    
    if params[:status] && !%w[active completed].include?(params[:status])
      errors << 'Status filter must be one of: active, completed'
    end
    
    errors
  end

  private

  def self.valid_date_format?(date_string)
    return false unless date_string.is_a?(String)
    
    # Try parsing as ISO 8601
    DateTime.parse(date_string)
    true
  rescue ArgumentError
    # Try with Chronic for natural language
    require 'chronic'
    !Chronic.parse(date_string).nil?
  rescue
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