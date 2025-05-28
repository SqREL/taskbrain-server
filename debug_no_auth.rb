#!/usr/bin/env ruby

require_relative 'spec/spec_helper'

# Test a simple route without authentication
require 'stringio'

env1 = {
  'REQUEST_METHOD' => 'GET',
  'PATH_INFO' => '/health',
  'rack.input' => StringIO.new,
  'rack.errors' => StringIO.new
}

response = app.call(env1)

puts "Health endpoint:"
puts "Status: #{response[0]}"
puts "Headers: #{response[1]}"
puts "Body: #{response[2].join}"
puts ""

# Test the specific endpoint that should NOT require auth
env2 = {
  'REQUEST_METHOD' => 'GET',
  'PATH_INFO' => '/api/health',
  'rack.input' => StringIO.new,
  'rack.errors' => StringIO.new
}

response2 = app.call(env2)

puts "API Health endpoint:"
puts "Status: #{response2[0]}"
puts "Headers: #{response2[1]}"
puts "Body: #{response2[2].join}"