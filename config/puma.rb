# frozen_string_literal: true

# Puma configuration for production deployment

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

# Restart workers every few requests to prevent memory bloat
worker_max_requests ENV.fetch('WORKER_MAX_REQUESTS', 1000).to_i
worker_max_requests_delta ENV.fetch('WORKER_MAX_REQUESTS_DELTA', 100).to_i

# Worker timeout
worker_timeout ENV.fetch('WORKER_TIMEOUT', 30).to_i

# Set master PID file
pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')

# Set state file
state_path ENV.fetch('STATE_PATH', 'tmp/pids/puma.state')

# Redirect output
stdout_redirect 'logs/puma.log', 'logs/puma_error.log', true

# Daemonize
daemonize ENV.fetch('DAEMONIZE', false)

# On worker boot
on_worker_boot do
  # Reconnect to database and Redis on each worker
  DB.disconnect if defined?(Sequel)

  $redis&.disconnect! if defined?(Redis)
end

# Before fork
before_fork do
  # Close database connections before forking
  DB.disconnect if defined?(Sequel)
end

# Allow puma to be restarted by `rails restart` command
plugin :tmp_restart

# Enable control server for zero-downtime deploys
if ENV.fetch('PUMA_CONTROL_URL', nil)
  activate_control_app ENV.fetch('PUMA_CONTROL_URL'), {
    auth_token: ENV.fetch('PUMA_CONTROL_TOKEN', SecureRandom.hex(16))
  }
end

# Tag for identification
tag 'task-intelligence-server'

# Lower the worker priority (niceness)
worker_process_reaper_timeout 120
worker_max_preload_time 60

# Memory management
if ENV.fetch('RACK_ENV') == 'production'
  # Force garbage collection every 5 requests
  before_request do |_env|
    @request_count ||= 0
    @request_count += 1

    GC.start(full_mark: false) if (@request_count % 5).zero?
  end
end
