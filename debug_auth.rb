#!/usr/bin/env ruby

require_relative 'spec/spec_helper'

# Test the authentication directly
ENV['API_KEY'] = 'test_api_key'

# Create a mock request environment
env = {
  'REQUEST_METHOD' => 'GET',
  'PATH_INFO' => '/api/tasks',
  'HTTP_AUTHORIZATION' => nil
}

# Test what authenticate_request returns
puts "ENV API_KEY: #{ENV['API_KEY']}"
puts "Authorization header: #{env['HTTP_AUTHORIZATION']}"

# Simulate the extraction
api_key = env['HTTP_AUTHORIZATION']&.sub(/^Bearer /, '')
puts "Extracted API key: #{api_key}"
puts "API key exists: #{!api_key.nil?}"

result = api_key && ENV.fetch('API_KEY', nil) && Rack::Utils.secure_compare(api_key, ENV.fetch('API_KEY', nil))
puts "Authentication result: #{result}"