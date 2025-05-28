# frozen_string_literal: true

require 'httparty'
require 'openssl'

class TodoistIntegration
  include HTTParty
  base_uri 'https://api.todoist.com'

  def initialize(client_id, client_secret)
    @client_id = client_id
    @client_secret = client_secret
  end

  def exchange_code(code)
    response = self.class.post('/oauth/access_token', {
                                 body: {
                                   client_id: @client_id,
                                   client_secret: @client_secret,
                                   code: code
                                 }
                               })

    if response.success?
      {
        success: true,
        access_token: response['access_token']
      }
    else
      {
        success: false,
        error: response['error'] || 'Authentication failed'
      }
    end
  end

  def setup_webhook(access_token)
    webhook_url = "#{ENV.fetch('BASE_URL', nil)}/webhooks/todoist"

    response = self.class.post('/rest/v2/webhooks', {
                                 headers: {
                                   'Authorization' => "Bearer #{access_token}",
                                   'Content-Type' => 'application/json'
                                 },
                                 body: {
                                   target_url: webhook_url,
                                   event_types: ['item:added', 'item:updated', 'item:completed', 'item:deleted']
                                 }.to_json
                               })

    response.success?
  end

  def get_tasks(access_token, project_id: nil, filter: nil)
    params = {}
    params[:project_id] = project_id if project_id
    params[:filter] = filter if filter

    response = self.class.get('/rest/v2/tasks', {
                                headers: { 'Authorization' => "Bearer #{access_token}" },
                                query: params
                              })

    response.success? ? response.parsed_response : []
  end

  def create_task(access_token, task_data)
    response = self.class.post('/rest/v2/tasks', {
                                 headers: {
                                   'Authorization' => "Bearer #{access_token}",
                                   'Content-Type' => 'application/json'
                                 },
                                 body: task_data.to_json
                               })

    response.success? ? response.parsed_response : nil
  end

  def update_task(access_token, task_id, updates)
    response = self.class.post("/rest/v2/tasks/#{task_id}", {
                                 headers: {
                                   'Authorization' => "Bearer #{access_token}",
                                   'Content-Type' => 'application/json'
                                 },
                                 body: updates.to_json
                               })

    response.success?
  end

  def complete_task(access_token, task_id)
    response = self.class.post("/rest/v2/tasks/#{task_id}/close", {
                                 headers: { 'Authorization' => "Bearer #{access_token}" }
                               })

    response.success?
  end

  def get_projects(access_token)
    response = self.class.get('/rest/v2/projects', {
                                headers: { 'Authorization' => "Bearer #{access_token}" }
                              })

    response.success? ? response.parsed_response : []
  end

  def verify_webhook_signature(payload, signature, secret)
    expected_signature = OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
    Rack::Utils.secure_compare(signature, expected_signature)
  end
end
