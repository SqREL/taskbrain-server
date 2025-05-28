#!/usr/bin/env ruby

require_relative 'spec/spec_helper'

# Make a test request
response = app.call({
  'REQUEST_METHOD' => 'GET',
  'PATH_INFO' => '/api/tasks',
  'HTTP_AUTHORIZATION' => nil
})

puts "Status: #{response[0]}"
puts "Headers: #{response[1]}"
puts "Body: #{response[2].join}"