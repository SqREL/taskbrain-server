#!/usr/bin/env ruby

require_relative 'spec/spec_helper'

# Test the auth in RSpec context
require 'rack/test'

class TestRunner
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
end

ENV['API_KEY'] = 'test_api_key'
ENV['DEBUG_TESTS'] = 'true'

runner = TestRunner.new

puts "ENV API_KEY: #{ENV['API_KEY']}"
puts "Testing with valid auth header..."

runner.get '/api/tasks', {}, { 'Authorization' => 'Bearer test_api_key' }

puts "Status: #{runner.last_response.status}"
puts "Body: #{runner.last_response.body}"

# Let's also test with HTTP_AUTHORIZATION directly
puts "\nTesting with HTTP_AUTHORIZATION header..."
runner.get '/api/tasks', {}, { 'HTTP_AUTHORIZATION' => 'Bearer test_api_key' }

puts "Status: #{runner.last_response.status}"
puts "Body: #{runner.last_response.body}"