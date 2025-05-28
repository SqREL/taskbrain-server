# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Ruby/Sinatra Server
- **Run server**: `asdf exec bundle exec ruby server.rb` (development)
- **Run with auto-reload**: `asdf exec bundle exec rerun server.rb`
- **Run background jobs**: `asdf exec bundle exec sidekiq`
- **Run tests**: `asdf exec bundle exec rspec`
- **Run specific test**: `asdf exec bundle exec rspec spec/path/to/spec.rb`
- **Lint code**: `asdf exec bundle exec rubocop`
- **Lint with auto-fix**: `asdf exec bundle exec rubocop -a`

### Frontend (JavaScript/Webpack)
- **Build production**: `npm run build`
- **Watch mode**: `npm run dev`

### Docker Commands
- **Development**: `docker-compose -f docker-compose.dev.yml up -d`
- **Production**: `docker-compose up -d`
- **View logs**: `docker-compose logs task_server`

## Architecture Overview

### Core Structure
The application is a Ruby/Sinatra API server with intelligent task management features:

- **server.rb**: Main Sinatra application with API endpoints and authentication middleware
- **lib/task_manager.rb**: Central task CRUD operations and database management
- **lib/task_intelligence.rb**: AI-powered task analysis, prioritization, and scheduling
- **lib/integrations/**: Service-specific API clients (Todoist, Google Calendar, Linear)
- **lib/integrations/webhook_handler.rb**: Real-time webhook processing and Claude notifications
- **lib/security_utils.rb**: Token encryption and security utilities
- **lib/validation_utils.rb**: Input validation and sanitization

### Authentication System
The API uses two authentication layers:
- General API endpoints (`/api/*`): Require `Authorization: Bearer {API_KEY}` header
- Claude-specific endpoints (`/api/claude/*`): Require `X-Claude-API-Key: {CLAUDE_API_KEY}` header

### Database Architecture
- PostgreSQL with Sequel ORM
- Redis for caching and encrypted token storage
- Key tables: tasks, task_events, user_patterns

### Integration Flow
1. External services (Todoist, Linear) send webhooks to `/webhooks/*` endpoints
2. WebhookHandler processes events with signature verification
3. TaskManager updates database and triggers intelligence analysis
4. TaskIntelligence provides AI recommendations and scheduling
5. Claude receives notifications via configured webhook URL

### Key API Endpoint Groups
- `/api/tasks/*`: Basic CRUD operations
- `/api/intelligence/*`: AI-powered prioritization and scheduling
- `/api/claude/*`: Enhanced endpoints for Claude integration with full context
- `/api/analytics/*`: Productivity metrics and patterns
- `/webhooks/*`: Incoming webhook handlers with security verification

## Testing Approach

The test suite uses RSpec with mock objects for external dependencies:
- MockDB, MockRedis for database/cache testing
- MockTaskManager, MockIntelligence for unit testing
- WebMock for HTTP request stubbing
- SimpleCov for code coverage reporting

Run tests with coverage: Tests will generate coverage report in `coverage/` directory.

## Security Considerations

All OAuth tokens are encrypted using AES-256-GCM before Redis storage. Webhook signatures are verified using HMAC-SHA256. CORS is configured via ALLOWED_ORIGINS environment variable.

## Environment Variables

Critical environment variables that must be set:
- API_KEY, CLAUDE_API_KEY: Authentication keys
- ENCRYPTION_KEY: Base64-encoded 32-byte key for token encryption
- TODOIST_WEBHOOK_SECRET, LINEAR_WEBHOOK_SECRET: Webhook signature verification
- ALLOWED_ORIGINS: Comma-separated list of allowed CORS origins

## Ruby Development Best Practices

### Code Style Guidelines
- Use Ruby 3.x features where appropriate (pattern matching, Data objects for immutable structures)
- Prefer keyword arguments for methods with multiple parameters for clarity
- Use `frozen_string_literal: true` pragma in all Ruby files for performance
- Follow Ruby naming conventions: snake_case for methods/variables, CamelCase for classes

### Common Patterns in This Codebase
- **Service Objects**: Task operations are encapsulated in service classes (TaskManager, TaskIntelligence)
- **Middleware Pattern**: Authentication is handled via Sinatra middleware, not in individual routes
- **Dependency Injection**: Mock objects are injected for testing rather than using global state
- **Error Handling**: Use specific exception classes and rescue at appropriate levels

### Security Patterns
- **Never use string interpolation with user input in SQL/commands**
- Use parameterized queries with Sequel ORM
- Validate all input using ValidationUtils before processing
- Use `\A` and `\z` for regex boundaries, not `^` and `$`
- Avoid `send` and `eval` with any user-controlled input

### Testing Patterns
- Each spec file should test a single class/module
- Use `let` and `let!` for test data setup
- Mock external dependencies (HTTP calls, Redis, DB) for unit tests
- Integration tests should use database transactions for cleanup

### Performance Considerations
- Use Redis for frequently accessed data (tokens, temporary state)
- Implement pagination for list endpoints
- Use Sidekiq for background processing of heavy operations
- Cache expensive AI analysis results with appropriate TTL

### Sinatra-Specific Patterns
- Use `before` filters for authentication/common setup
- Keep routes thin - delegate logic to service objects
- Use `halt` for early returns with proper status codes
- Configure CORS properly for each environment

### Common Debugging Commands
- **Check Sinatra routes**: `asdf exec bundle exec ruby -r./server -e 'puts Sinatra::Application.routes'`
- **Interactive console**: `asdf exec bundle exec irb -r ./server`
- **Database console**: `asdf exec bundle exec sequel postgres://localhost/taskbrain_development`