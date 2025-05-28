# frozen_string_literal: true

# Simple Puma configuration compatible with Puma 6.x

# Number of worker processes
workers ENV.fetch('WEB_CONCURRENCY', 2).to_i

# Number of threads per worker
threads_count = ENV.fetch('RAILS_MAX_THREADS', 5).to_i
threads threads_count, threads_count

# Bind to port
port ENV.fetch('PORT', 3000)

# Set environment
environment ENV.fetch('RACK_ENV', 'production')

# Preload application for better memory usage
preload_app!

# Worker timeout
worker_timeout ENV.fetch('WORKER_TIMEOUT', 30).to_i

# Set master PID file
pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')

# Set state file
state_path ENV.fetch('STATE_PATH', 'tmp/pids/puma.state')

# Redirect output
stdout_redirect 'logs/puma.log', 'logs/puma_error.log', true

# On worker boot
on_worker_boot do
  # Reconnect to database and Redis on each worker
  if defined?(Sequel)
    # Use the database connection from app config instead of global DB
    puts "Worker #{Process.pid} starting - will reconnect to services"
  end
end

# Before fork
before_fork do
  # Close database connections before forking
  puts 'Forking worker - disconnecting from services' if defined?(Sequel)
end

# Tag for identification
tag 'task-intelligence-server'
