# frozen_string_literal: true

module RequestHelpers
  def authenticate_request
    api_key = request.env['HTTP_AUTHORIZATION']&.sub(/^Bearer /, '')
    auth_service.verify_api_key(api_key)
  end

  def authenticate_claude_request
    claude_key = request.env['HTTP_X_CLAUDE_API_KEY']
    auth_service.verify_claude_api_key(claude_key)
  end

  def json_body
    request.body.rewind
    body = request.body.read

    return {} if body.nil? || body.strip.empty?

    JSON.parse(body)
  rescue JSON::ParserError => e
    raise TaskBrain::ValidationError, ["Invalid JSON: #{e.message}"]
  end

  def validate_json_body
    ValidationUtils.validate_and_parse_json(request.body.read)
  end

  def json_error(error, status = 400)
    halt status, { 'Content-Type' => 'application/json' }, { error: error }.to_json
  end

  def json_response(data, status = 200)
    halt status, { 'Content-Type' => 'application/json' }, data.to_json
  end
end
