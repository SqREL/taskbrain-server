#!/usr/bin/env ruby

require_relative 'spec/spec_helper'
require 'stringio'

ENV['API_KEY'] = 'test_api_key'

# Test authentication failing (no auth header)
env1 = {
  'REQUEST_METHOD' => 'GET',
  'PATH_INFO' => '/api/tasks',
  'rack.input' => StringIO.new,
  'rack.errors' => StringIO.new
}

response = app.call(env1)

puts "No auth header:"
puts "Status: #{response[0]}"
puts "Body: #{response[2].join}"
puts ""

# Test authentication passing (valid auth header)
env2 = {
  'REQUEST_METHOD' => 'GET',
  'PATH_INFO' => '/api/tasks',
  'HTTP_AUTHORIZATION' => 'Bearer test_api_key',
  'rack.input' => StringIO.new,
  'rack.errors' => StringIO.new
}

response2 = app.call(env2)

puts "Valid auth header:"
puts "Status: #{response2[0]}"
puts "Body: #{response2[2].join}"