#!/usr/bin/env ruby

require_relative 'spec/spec_helper'

# Create a mock request and test the method directly
class TestApp < Sinatra::Base
  def authenticate_request
    api_key = request.env['HTTP_AUTHORIZATION']&.sub(/^Bearer /, '')
    puts "API key extracted: #{api_key.inspect}"
    puts "ENV API key: #{ENV.fetch('API_KEY', nil).inspect}"
    result = api_key && Rack::Utils.secure_compare(api_key, ENV.fetch('API_KEY', nil))
    puts "Result: #{result}"
    result
  end
end

# Test with Rack::Test
require 'rack/test'
include Rack::Test::Methods

def app
  TestApp
end

ENV['API_KEY'] = 'test_api_key'

# Mock a request
begin
  response = app.call({
    'REQUEST_METHOD' => 'GET',
    'PATH_INFO' => '/test',
    'HTTP_AUTHORIZATION' => nil
  })
  puts "Response: #{response}"
rescue => e
  puts "Error: #{e.class}: #{e.message}"
  puts e.backtrace.first(5)
end