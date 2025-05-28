#!/usr/bin/env ruby

require_relative 'spec/spec_helper'
require 'stringio'

ENV['API_KEY'] = 'test_api_key'
ENV['CLAUDE_API_KEY'] = 'test_claude_key'

# Test Claude authentication with invalid Claude key but valid API key
env = {
  'REQUEST_METHOD' => 'GET',
  'PATH_INFO' => '/api/claude/status',
  'HTTP_AUTHORIZATION' => 'Bearer test_api_key',  # Valid API key
  'HTTP_X_CLAUDE_API_KEY' => 'invalid_claude_key',  # Invalid Claude key
  'rack.input' => StringIO.new,
  'rack.errors' => StringIO.new
}

response = app.call(env)

puts "Status: #{response[0]}"
puts "Body: #{response[2].join}"