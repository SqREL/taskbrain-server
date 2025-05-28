# 🧠 TaskBrain Server

A comprehensive Ruby-based integration server that provides real-time task awareness and intelligent task management across Todoist, Google Calendar, Linear, and Evernote. **Designed specifically to make Claude truly task-aware and productivity-focused.**

## ✨ Features

### 🔄 Real-time Task Awareness
- Live webhook integration with Todoist and Linear
- Automatic task synchronization and conflict resolution
- Real-time productivity score calculation
- Instant notification system for Claude integration

### 🤖 Intelligent Task Management
- AI-powered task prioritization based on deadlines, context, and patterns
- Smart duration estimation using content analysis
- Automatic task breakdown suggestions for complex items
- Energy-level matching with optimal scheduling times

### 🔗 Cross-Platform Integration
- **Todoist**: Complete task CRUD operations with webhooks
- **Google Calendar**: Event correlation and free/busy analysis
- **Linear**: Issue tracking and automatic task creation
- **Evernote**: Context-aware note searching and linking

### 📊 Advanced Analytics
- Productivity pattern analysis and trend tracking
- Completion velocity and estimation accuracy metrics
- Project health monitoring and dependency analysis
- Personalized productivity recommendations

## 🤖 Claude Integration Guide

TaskBrain is designed to give Claude complete awareness of your tasks and productivity patterns. Here's how to set it up:

### 1. **Initial Setup**

After installing TaskBrain, Claude needs to be configured with your server details:

```bash
# In your .env file, set your Claude webhook URL
CLAUDE_WEBHOOK_URL=https://your-claude-webhook-endpoint.com
BASE_URL=https://your-taskbrain-domain.com
```

### 2. **Claude Setup Prompts**

Use the prompts in [`claude-setup-prompts.md`](claude-setup-prompts.md) to configure Claude with your TaskBrain integration.

### 3. **Key API Endpoints for Claude**

Claude should use these endpoints to stay task-aware:

- **`GET /api/claude/status`** - Real-time task overview
- **`POST /api/claude/create_task`** - Create tasks with AI analysis
- **`GET /api/claude/recommendations`** - Get contextual suggestions
- **`GET /api/intelligence/priorities`** - AI-suggested priorities
- **`GET /api/analytics/productivity`** - Productivity metrics

### 4. **Webhook Integration**

TaskBrain automatically notifies Claude when:
- Tasks are created, updated, or completed
- Deadlines approach or are missed  
- Productivity patterns change
- New recommendations are available

### 5. **Claude Usage Examples**

Once integrated, Claude can:

```
You: "What should I focus on today?"
Claude: *checks /api/claude/status and /api/claude/recommendations*
"Based on your current 15 active tasks, I recommend focusing on:
1. Complete project proposal (due today, high priority)
2. Review Linear issues (3 blocking other team members)
3. Quick win: Update documentation (15min, low energy needed)"
```

```
You: "Create a task to prepare for tomorrow's client meeting"
Claude: *uses /api/claude/create_task with intelligent analysis*
"I've created your task with these smart suggestions:
- Priority: 4/5 (meeting keyword detected)
- Estimated duration: 60 minutes
- Optimal time: 10:00 AM (your peak focus hours)
- Breakdown: Research client background → Prepare agenda → Review materials"
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- API access tokens for your services
- (Optional) Ngrok for webhook testing

### Installation

1. **Clone and setup:**
```bash
git clone https://github.com/yourusername/taskbrain-server
cd taskbrain-server
chmod +x setup.sh
./setup.sh
```

2. **Configure environment:**
```bash
cp .env.example .env
# Edit .env with your API keys and configuration
```

3. **Start services:**
```bash
# Development
docker-compose -f docker-compose.dev.yml up -d

# Production
docker-compose up -d
```

4. **Access dashboard:**
Open http://localhost:3000 to view the intelligent task dashboard.

5. **Configure Claude:**
Follow the prompts in [`claude-setup-prompts.md`](claude-setup-prompts.md) to integrate with Claude.

## 🔧 Configuration

### Required API Keys

Create accounts and obtain API keys for:

- **Todoist**: [Developer Console](https://developer.todoist.com)
- **Google Calendar**: [Google Cloud Console](https://console.cloud.google.com)
- **Linear**: [Linear Settings](https://linear.app/settings/api)
- **Evernote**: [Developer Portal](https://dev.evernote.com)

### Environment Variables

Key configuration options in `.env`:

```bash
# Core APIs
TODOIST_CLIENT_ID=your_todoist_client_id
GOOGLE_CLIENT_ID=your_google_client_id
LINEAR_API_KEY=your_linear_api_key

# Claude Integration
CLAUDE_WEBHOOK_URL=https://your-claude-endpoint.com
BASE_URL=https://your-domain.com

# User Settings
USER_EMAIL=your.email@example.com
TRACKED_LINEAR_TEAMS=TEAM1,TEAM2
```

## 📡 API Endpoints

### Claude Integration Endpoints

- `GET /api/claude/status` - Current task overview and metrics
- `POST /api/claude/create_task` - Create task with AI analysis
- `GET /api/claude/recommendations` - Context-aware suggestions

### Task Management

- `GET /api/tasks` - List tasks with filtering
- `POST /api/tasks` - Create new task
- `PUT /api/tasks/:id` - Update existing task
- `DELETE /api/tasks/:id` - Delete task

### Intelligence Features

- `GET /api/intelligence/priorities` - AI-suggested priorities
- `GET /api/intelligence/schedule` - Optimal daily schedule
- `POST /api/intelligence/reschedule` - Smart rescheduling

### Analytics

- `GET /api/analytics/productivity` - Productivity metrics
- `GET /api/analytics/patterns` - Completion patterns

## 🎯 Claude Integration Details

### Real-time Status Updates

TaskBrain provides Claude with comprehensive task awareness:

```json
{
  "total_tasks": 15,
  "overdue_tasks": 2,
  "today_tasks": 5,
  "productivity_score": 78.5,
  "recent_activity": [...],
  "next_deadlines": [...],
  "recommendations": {
    "focus_tasks": [...],
    "quick_wins": [...],
    "energy_matched": [...]
  }
}
```

### Intelligent Task Creation

When Claude creates tasks, TaskBrain provides:
- Priority suggestions based on content analysis
- Duration estimates from keyword patterns
- Optimal scheduling recommendations
- Dependency detection and breakdown suggestions

### Webhook Notifications

Claude receives real-time notifications when:
- Tasks are created, updated, or completed
- Deadlines approach or are missed
- Productivity patterns change
- New recommendations are available

### Context-Aware Responses

TaskBrain enables Claude to provide context-aware responses:

- **Morning**: "Based on your energy patterns, tackle high-priority tasks now"
- **Afternoon**: "Perfect time for collaboration - 3 Linear issues need team input"
- **Evening**: "Light tasks recommended - review tomorrow's calendar and plan priorities"

## 🔗 Webhook Setup

### Todoist Webhooks

1. Go to Todoist App Console
2. Add webhook URL: `https://your-domain.com/webhooks/todoist`
3. Select events: `item:added`, `item:updated`, `item:completed`, `item:deleted`

### Linear Webhooks

1. Go to Linear Settings → API
2. Add webhook URL: `https://your-domain.com/webhooks/linear`
3. Select events: Issue created, updated, deleted

## 🏗️ Architecture

### Core Components

- **TaskManager**: Central task operations and database management
- **TaskIntelligence**: AI-powered analysis and recommendations
- **WebhookHandler**: Real-time event processing and Claude notifications
- **Integrations**: Service-specific API clients and data transformers

### Database Schema

- **tasks**: Core task data with intelligence metadata
- **task_events**: Audit trail and pattern analysis
- **user_patterns**: Machine learning insights and preferences

### Technology Stack

- **Backend**: Ruby with Sinatra framework
- **Database**: PostgreSQL with Redis caching
- **Frontend**: Vanilla JavaScript with Chart.js
- **Deployment**: Docker containers with Docker Compose

## 📊 Intelligence Features

### Smart Prioritization

The system analyzes multiple factors:
- Deadline proximity and criticality
- Content complexity and estimated effort
- Historical completion patterns
- Energy level requirements
- Project dependencies and impact

### Productivity Analytics

Track and optimize:
- Daily completion rates and trends
- Estimation accuracy improvements
- Energy level correlation with task types
- Peak productivity hours identification

### Context Awareness

Automatically considers:
- Calendar events and availability
- Linear issue assignments and deadlines
- Evernote content for task context
- Time-of-day energy patterns

## 🔒 Security

- Webhook signature verification for all external services
- Secure token storage and rotation
- CORS protection for cross-origin requests
- Input validation and SQL injection prevention

## 🚀 Production Deployment

### Docker Production Setup

```bash
# Build production image
docker-compose build

# Deploy with production settings
docker-compose up -d

# With monitoring
docker-compose --profile monitoring up -d
```

### Reverse Proxy Configuration

Use Nginx (included) for:
- SSL termination
- Load balancing
- Rate limiting
- Static file serving

## 🔧 Development

### Local Development

```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up -d

# Access development tools:
# - pgAdmin: http://localhost:8080
# - Redis Commander: http://localhost:8081
# - Mailcatcher: http://localhost:1080
# - Ngrok Dashboard: http://localhost:4040
```

### Testing

```bash
# Run tests
bundle exec rspec

# API testing
curl -X GET http://localhost:3000/api/claude/status
```

## 📈 Monitoring

### Health Checks

- `GET /health` - Service health status
- Database connectivity verification
- Redis cache availability
- External API accessibility

### Logging

- Structured JSON logging
- Request/response tracking
- Error alerting and metrics
- Performance monitoring

### Included Monitoring (Optional)

- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **Nginx**: Request monitoring and rate limiting

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests and documentation
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

## 🆘 Support

- Check the logs: `docker-compose logs task_server`
- Review API documentation
- Verify webhook configurations
- Test API keys and permissions
- Check [`claude-setup-prompts.md`](claude-setup-prompts.md) for Claude integration issues

---

**Built with ❤️ for enhanced productivity and intelligent task management with Claude AI.**

## 🔧 Configuration

### Required API Keys

Create accounts and obtain API keys for:

- **Todoist**: [Developer Console](https://developer.todoist.com)
- **Google Calendar**: [Google Cloud Console](https://console.cloud.google.com)
- **Linear**: [Linear Settings](https://linear.app/settings/api)
- **Evernote**: [Developer Portal](https://dev.evernote.com)

### Environment Variables

Key configuration options in `.env`:

```bash
# Core APIs
TODOIST_CLIENT_ID=your_todoist_client_id
GOOGLE_CLIENT_ID=your_google_client_id
LINEAR_API_KEY=your_linear_api_key

# Integration
CLAUDE_WEBHOOK_URL=https://your-claude-endpoint.com
BASE_URL=https://your-domain.com

# User Settings
USER_EMAIL=your.email@example.com
TRACKED_LINEAR_TEAMS=TEAM1,TEAM2
```

## 📡 API Endpoints

### Claude Integration Endpoints

- `GET /api/claude/status` - Current task overview and metrics
- `POST /api/claude/create_task` - Create task with AI analysis
- `GET /api/claude/recommendations` - Context-aware suggestions

### Task Management

- `GET /api/tasks` - List tasks with filtering
- `POST /api/tasks` - Create new task
- `PUT /api/tasks/:id` - Update existing task
- `DELETE /api/tasks/:id` - Delete task

### Intelligence Features

- `GET /api/intelligence/priorities` - AI-suggested priorities
- `GET /api/intelligence/schedule` - Optimal daily schedule
- `POST /api/intelligence/reschedule` - Smart rescheduling

### Analytics

- `GET /api/analytics/productivity` - Productivity metrics
- `GET /api/analytics/patterns` - Completion patterns

## 🎯 Claude Integration

### Real-time Status Updates

The server provides Claude with comprehensive task awareness:

```json
{
  "total_tasks": 15,
  "overdue_tasks": 2,
  "today_tasks": 5,
  "productivity_score": 78.5,
  "recent_activity": [...],
  "next_deadlines": [...]
}
```

### Intelligent Task Creation

When Claude creates tasks, the system provides:
- Priority suggestions based on content analysis
- Duration estimates from keyword patterns
- Optimal scheduling recommendations
- Dependency detection and breakdown suggestions

### Webhook Notifications

Claude receives real-time notifications when:
- Tasks are created, updated, or completed
- Deadlines approach or are missed
- Productivity patterns change
- New recommendations are available

## 🔗 Webhook Setup

### Todoist Webhooks

1. Go to Todoist App Console
2. Add webhook URL: `https://your-domain.com/webhooks/todoist`
3. Select events: `item:added`, `item:updated`, `item:completed`, `item:deleted`

### Linear Webhooks

1. Go to Linear Settings → API
2. Add webhook URL: `https://your-domain.com/webhooks/linear`
3. Select events: Issue created, updated, deleted

## 🏗️ Architecture

### Core Components

- **TaskManager**: Central task operations and database management
- **TaskIntelligence**: AI-powered analysis and recommendations
- **WebhookHandler**: Real-time event processing and Claude notifications
- **Integrations**: Service-specific API clients and data transformers

### Database Schema

- **tasks**: Core task data with intelligence metadata
- **task_events**: Audit trail and pattern analysis
- **user_patterns**: Machine learning insights and preferences

### Technology Stack

- **Backend**: Ruby with Sinatra framework
- **Database**: PostgreSQL with Redis caching
- **Frontend**: Vanilla JavaScript with Chart.js
- **Deployment**: Docker containers with Docker Compose

## 📊 Intelligence Features

### Smart Prioritization

The system analyzes multiple factors:
- Deadline proximity and criticality
- Content complexity and estimated effort
- Historical completion patterns
- Energy level requirements
- Project dependencies and impact

### Productivity Analytics

Track and optimize:
- Daily completion rates and trends
- Estimation accuracy improvements
- Energy level correlation with task types
- Peak productivity hours identification

### Context Awareness

Automatically considers:
- Calendar events and availability
- Linear issue assignments and deadlines
- Evernote content for task context
- Time-of-day energy patterns

## 🔒 Security

- Webhook signature verification for all external services
- Secure token storage and rotation
- CORS protection for cross-origin requests
- Input validation and SQL injection prevention

## 🚀 Production Deployment

### Docker Production Setup

```bash
# Build production image
docker-compose -f docker-compose.prod.yml build

# Deploy with secrets
docker-compose -f docker-compose.prod.yml up -d
```

### Reverse Proxy Configuration

Use Nginx or Traefik for:
- SSL termination
- Load balancing
- Rate limiting
- Static file serving

## 🔧 Development

### Local Development

```bash
# Install dependencies
bundle install
npm install

# Start development server
bundle exec rerun server.rb

# Run background jobs
bundle exec sidekiq
```

### Testing

```bash
# Run tests
bundle exec rspec

# API testing
curl -X GET http://localhost:3000/api/claude/status
```

## 📈 Monitoring

### Health Checks

- `GET /health` - Service health status
- Database connectivity verification
- Redis cache availability
- External API accessibility

### Logging

- Structured JSON logging
- Request/response tracking
- Error alerting and metrics
- Performance monitoring

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests and documentation
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

## 🆘 Support

- Check the logs: `docker-compose logs`
- Review API documentation
- Verify webhook configurations
- Test API keys and permissions

---

**Built with ❤️ for enhanced productivity and intelligent task management.**
