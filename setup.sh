#!/bin/bash

echo "🚀 Setting up Task Management Intelligence Server..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p logs
mkdir -p data
mkdir -p public

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "📋 Creating environment file..."
    cp .env.example .env
    echo "⚠️  Please edit .env file with your API keys and configuration"
fi

# Create ngrok configuration
echo "🌐 Creating ngrok configuration..."
cat > ngrok.yml << EOF
version: "2"
authtoken: ${NGROK_AUTHTOKEN}
tunnels:
  task-server:
    addr: task_server:3000
    proto: http
    subdomain: your-task-server
EOF

# Create database initialization script
echo "🗄️ Creating database initialization..."
cat > init.sql << EOF
-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_external_id ON tasks(external_id);
CREATE INDEX IF NOT EXISTS idx_tasks_source ON tasks(source);
CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_task_events_task_id ON task_events(task_id);
CREATE INDEX IF NOT EXISTS idx_user_patterns_type ON user_patterns(pattern_type);

-- Insert default user patterns
INSERT INTO user_patterns (pattern_type, pattern_data, confidence_score) VALUES
('default_work_hours', '{"start": 9, "end": 17}', 0.8),
('default_break_duration', '{"minutes": 15}', 0.7)
ON CONFLICT DO NOTHING;
EOF

# Build and start services
echo "🔨 Building and starting services..."
docker-compose build
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo "✅ Services are running!"
    
    # Display service URLs
    echo ""
    echo "🌟 Service URLs:"
    echo "   Dashboard: http://localhost:3000"
    echo "   API: http://localhost:3000/api"
    echo "   Redis: localhost:6379"
    echo "   PostgreSQL: localhost:5432"
    
    if [ ! -z "$NGROK_AUTHTOKEN" ]; then
        echo "   Ngrok Dashboard: http://localhost:4040"
    fi
    
    echo ""
    echo "📖 Next steps:"
    echo "   1. Configure your .env file with API keys"
    echo "   2. Set up webhooks in Todoist and Linear"
    echo "   3. Authenticate with Google Calendar"
    echo "   4. Start managing tasks intelligently!"
    
else
    echo "❌ Some services failed to start. Check logs with:"
    echo "   docker-compose logs"
fi

# Function to setup API webhooks
setup_webhooks() {
    echo ""
    echo "🔗 Setting up webhooks..."
    
    # Get ngrok URL if available
    if command -v curl &> /dev/null; then
        NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o 'https://[^"]*\.ngrok\.io')
        
        if [ ! -z "$NGROK_URL" ]; then
            echo "📡 Your webhook URLs:"
            echo "   Todoist: ${NGROK_URL}/webhooks/todoist"
            echo "   Linear: ${NGROK_URL}/webhooks/linear"
            echo ""
            echo "Add these URLs to your service webhook configurations"
        fi
    fi
}

# Setup webhooks if ngrok is configured
if [ ! -z "$NGROK_AUTHTOKEN" ]; then
    setup_webhooks
fi

echo ""
echo "🎉 Setup complete! Your task intelligence server is ready."
