#!/usr/bin/env ruby

require_relative 'spec/spec_helper'
require 'json'

puts "Testing API validation flow..."

# Test invalid factory
invalid_data = FactoryBot.build(:invalid_task_data)
puts "Invalid data hash: #{invalid_data.inspect}"

# Convert to JSON like API would
json_string = invalid_data.to_json
puts "JSON string: #{json_string}"

# Parse like the API would
parsed_data = JSON.parse(json_string)
puts "Parsed data: #{parsed_data.inspect}"

# Test validation
require_relative 'lib/validation_utils'
result = ValidationUtils.validate_and_parse_json(json_string)
puts "Validation result: #{result.inspect}"