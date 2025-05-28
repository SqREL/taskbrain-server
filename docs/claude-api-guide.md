# 🤖 Claude API Integration Guide

Complete guide for integrating TaskBrain with Claude AI for intelligent task management and real-time productivity assistance.

## 🔗 Quick Integration

### Essential Endpoints for Claude

```javascript
// Real-time task status and overview
GET /api/claude/status

// Create intelligent tasks with AI analysis
POST /api/claude/create_task

// Get contextual recommendations
GET /api/claude/recommendations?context=morning|afternoon|planning

// Fetch smart priorities with AI scoring
GET /api/intelligence/priorities

// Get productivity analytics and insights
GET /api/analytics/productivity?period=day|week|month

// Get completion patterns and optimization data
GET /api/analytics/patterns
```

## 📊 API Response Examples

### `/api/claude/status` Response

```json
{
  "total_tasks": 15,
  "overdue_tasks": 2,
  "today_tasks": 5,
  "high_priority": 3,
  "productivity_score": 78.5,
  "recent_activity": [
    {
      "id": 123,
      "event_type": "completed",
      "content": "Review client proposal",
      "timestamp": "2025-05-28T10:30:00Z",
      "duration": 45
    }
  ],
  "next_deadlines": [
    {
      "id": 124,
      "content": "Submit quarterly report",
      "due_date": "2025-05-29T17:00:00Z",
      "priority": 5,
      "urgency_score": 9.2
    }
  ],
  "current_context": {
    "time_of_day": "morning",
    "energy_level": "high",
    "calendar_busy": false,
    "focus_mode": true,
    "optimal_work_type": "deep_focus"
  }
}
```

### `/api/claude/create_task` Request/Response

**Request:**
```json
{
  "content": "Prepare quarterly business review presentation",
  "description": "Create comprehensive Q4 review for board meeting",
  "due_date": "2025-06-01T14:00:00Z",
  "priority": 4,
  "context_tags": ["presentation", "quarterly", "board"],
  "estimated_duration": 180,
  "source": "claude"
}
```

**Response:**
```json
{
  "task": {
    "id": 125,
    "content": "Prepare quarterly business review presentation",
    "priority": 5,
    "due_date": "2025-06-01T14:00:00Z",
    "estimated_duration": 240,
    "urgency_score": 8.5,
    "intelligence_score": 92.3
  },
  "suggestions": {
    "priority_adjustment": {
      "original": 4,
      "suggested": 5,
      "reasoning": "Board meeting keyword detected, approaching deadline",
      "confidence": 0.92
    },
    "time_estimate": {
      "original": 180,
      "suggested": 240,
      "reasoning": "Presentation creation with board-level requirements typically requires 4 hours",
      "confidence": 0.85
    },
    "breakdown_suggestions": {
      "should_break_down": true,
      "suggested_subtasks": [
        "Research Q4 metrics and performance data",
        "Create presentation outline and structure", 
        "Design slides with charts and visuals",
        "Practice presentation and prepare Q&A"
      ],
      "confidence": 0.88
    },
    "optimal_schedule": {
      "suggested_time": "09:00",
      "optimal_days": ["Tuesday", "Wednesday"],
      "reasoning": "High-energy creative work best suited for morning peak hours",
      "confidence": 0.76
    },
    "dependencies": {
      "detected": [
        {
          "task_content": "Gather Q4 financial reports",
          "relationship": "prerequisite",
          "strength": 0.9
        }
      ],
      "confidence": 0.82
    },
    "auto_apply": true
  },
  "impact_analysis": {
    "dependency_impact": "High - blocks board meeting preparation",
    "team_impact": "Medium - presentation will inform team strategy decisions",
    "deadline_cascade": "Critical - no buffer time available",
    "project_criticality": 9.1
  }
}
```

### `/api/claude/recommendations` Response

```json
{
  "context": "morning",
  "timestamp": "2025-05-28T08:00:00Z",
  "energy_analysis": {
    "predicted_level": 4.2,
    "optimal_duration": "90-120 minutes",
    "work_type": "deep_focus"
  },
  "recommendations": {
    "focus_tasks": [
      {
        "id": 126,
        "content": "Complete API documentation",
        "reasoning": "High complexity task optimal for peak energy",
        "estimated_duration": 120,
        "energy_match": 0.95,
        "priority_score": 8.7
      }
    ],
    "quick_wins": [
      {
        "id": 127,
        "content": "Review and approve pull requests",
        "reasoning": "Low energy requirement, high team impact",
        "estimated_duration": 15,
        "impact": "Unblocks 3 team members",
        "efficiency_score": 9.2
      }
    ],
    "energy_matched": [
      {
        "id": 128,
        "content": "Design system architecture",
        "reasoning": "Creative work optimal for current energy level",
        "energy_level": 5,
        "optimal_time": "current",
        "creativity_factor": 0.88
      }
    ],
    "calendar_aware": [
      {
        "id": 129,
        "content": "Prepare for 10 AM standup",
        "reasoning": "Meeting in 2 hours, preparation needed",
        "time_sensitive": true,
        "buffer_needed": 15,
        "meeting_prep_score": 8.5
      }
    ]
  },
  "productivity_insights": {
    "tip": "Morning focus: Tackle your most challenging task first - your brain is at peak performance",
    "pattern_note": "You complete complex tasks 35% faster during 9-11 AM window",
    "energy_forecast": "High energy until 11 AM, moderate until 2 PM"
  },
  "context_analysis": {
    "optimal_work_type": "deep_focus",
    "avoid_work_type": "administrative_tasks",
    "focus_duration": "90-120 minutes recommended",
    "break_suggestion": "No break needed - sustained energy available"
  }
}
```

## 🔄 Webhook Integration

### Webhook Event Types

TaskBrain sends real-time notifications to Claude via webhooks for these events:

```javascript
// Event types Claude should handle
const WEBHOOK_EVENTS = {
  'task:completed': 'Task marked as complete',
  'task:created': 'New task added to system',
  'task:updated': 'Task properties modified',
  'task:overdue': 'Task has become overdue',
  'deadline:approaching': 'Deadline within threshold',
  'productivity:milestone': 'Productivity goal achieved',
  'pattern:detected': 'New behavioral pattern identified',
  'sync:completed': 'External service sync finished',
  'intelligence:updated': 'AI recommendations refreshed'
};
```

### Webhook Payload Examples

**Task Completed:**
```json
{
  "timestamp": "2025-05-28T10:30:00Z",
  "event_type": "task:completed",
  "event_data": {
    "task_id": 123,
    "content": "Review client proposal",
    "actual_duration": 45,
    "estimated_duration": 60,
    "completion_time": "10:30",
    "energy_level_used": 3,
    "efficiency_ratio": 0.75
  },
  "context": {
    "total_tasks": 14,
    "completed_today": 3,
    "productivity_score": 82.3,
    "completion_streak": 5,
    "momentum_score": 8.7
  },
  "recommendations": [
    "Excellent efficiency! You completed this 25% faster than estimated.",
    "Consider tackling another medium-priority task while momentum is high.",
    "Your morning productivity is 15% above average today."
  ]
}
```

**Deadline Alert:**
```json
{
  "timestamp": "2025-05-28T08:00:00Z",
  "event_type": "deadline:approaching",
  "event_data": {
    "task_id": 124,
    "content": "Submit quarterly report",
    "due_date": "2025-05-29T17:00:00Z",
    "hours_remaining": 33,
    "priority": 5,
    "completion_status": "not_started",
    "estimated_work_remaining": 180
  },
  "urgency": "high",
  "impact_analysis": {
    "business_impact": "critical",
    "team_dependencies": 2,
    "cascade_risk": 0.85
  },
  "recommendations": [
    "Critical task due in 33 hours with no progress - immediate attention needed",
    "Schedule 3-hour focused block today or tomorrow morning",
    "Consider breaking into: data gathering (1h), analysis (1h), writing (1h)"
  ]
}
```

**Pattern Detection:**
```json
{
  "timestamp": "2025-05-28T14:00:00Z",
  "event_type": "pattern:detected",
  "event_data": {
    "pattern_type": "energy_optimization",
    "pattern_description": "Consistently higher task completion rate during 9-11 AM window",
    "confidence": 0.87,
    "sample_size": 23,
    "improvement_potential": "25% productivity increase"
  },
  "actionable_insights": [
    "Schedule complex tasks between 9-11 AM for optimal performance",
    "Move routine tasks to afternoon energy dip (2-3 PM)",
    "Block calendar from 9-11 AM for deep work sessions"
  ]
}
```

## 🔧 Claude Implementation Examples

### Core Integration Class

```javascript
class ClaudeTaskBrainIntegration {
  constructor(config) {
    this.baseUrl = config.baseUrl;
    this.apiKey = config.apiKey;
    this.webhookSecret = config.webhookSecret;
    this.rateLimiter = new RateLimiter();
    this.security = new SecurityManager(config);
    this.cache = new Map();
    this.isInitialized = false;
  }

  async initialize() {
    try {
      // Test connection and validate API key
      await this.testConnection();
      
      // Load user preferences and patterns
      await this.loadUserContext();
      
      // Setup webhook verification
      this.setupWebhookHandler();
      
      this.isInitialized = true;
      console.log('✅ TaskBrain integration initialized successfully');
    } catch (error) {
      console.error('❌ TaskBrain initialization failed:', error);
      throw new Error(`Integration failed: ${error.message}`);
    }
  }

  async getTaskStatus() {
    if (!this.isInitialized) await this.initialize();
    
    try {
      const response = await this.secureApiCall('/api/claude/status');
      
      // Cache the response for 60 seconds
      this.cache.set('status', {
        data: response,
        timestamp: Date.now(),
        ttl: 60000
      });
      
      return this.enrichStatusData(response);
    } catch (error) {
      return this.handleStatusError(error);
    }
  }

  async createIntelligentTask(taskData, options = {}) {
    if (!this.isInitialized) await this.initialize();
    
    try {
      // Enhance task data with context
      const enhancedTask = this.enhanceTaskData(taskData);
      
      const response = await this.secureApiCall('/api/claude/create_task', {
        method: 'POST',
        body: JSON.stringify(enhancedTask)
      });
      
      // Process AI suggestions
      const processedResponse = this.processTaskCreationResponse(response);
      
      // Learn from user preferences if enabled
      if (options.learnPreferences) {
        this.updateUserPreferences(taskData, response);
      }
      
      return processedResponse;
    } catch (error) {
      return this.handleTaskCreationError(error, taskData);
    }
  }

  async getRecommendations(context = 'auto') {
    if (context === 'auto') {
      context = this.determineCurrentContext();
    }
    
    try {
      const response = await this.secureApiCall(
        `/api/claude/recommendations?context=${context}`
      );
      
      return this.personalizeRecommendations(response);
    } catch (error) {
      return this.getFallbackRecommendations(context);
    }
  }

  // Secure API call with retry logic and rate limiting
  async secureApiCall(endpoint, options = {}) {
    // Check rate limits
    const rateLimitCheck = this.rateLimiter.canMakeRequest(endpoint);
    if (!rateLimitCheck.allowed) {
      throw new Error(`Rate limit exceeded. Retry after ${rateLimitCheck.retryAfter}s`);
    }

    const requestId = this.generateRequestId();
    const headers = {
      'Authorization': `Bearer ${this.apiKey}`,
      'Content-Type': 'application/json',
      'X-Request-ID': requestId,
      'X-Claude-Client': 'claude-integration-v1.0',
      ...options.headers
    };

    const maxRetries = 3;
    let attempt = 0;

    while (attempt < maxRetries) {
      try {
        const response = await fetch(`${this.baseUrl}${endpoint}`, {
          ...options,
          headers,
          timeout: 10000
        });

        if (!response.ok) {
          const error = await response.json();
          throw new Error(`API Error ${response.status}: ${error.message}`);
        }

        const data = await response.json();
        this.validateApiResponse(data);
        return data;

      } catch (error) {
        attempt++;
        
        if (attempt >= maxRetries) {
          throw new Error(`Failed after ${maxRetries} attempts: ${error.message}`);
        }

        // Exponential backoff
        await this.delay(Math.pow(2, attempt) * 1000);
      }
    }
  }

  // Webhook handling
  handleWebhook(webhookData) {
    try {
      // Verify webhook signature
      if (!this.verifyWebhookSignature(webhookData)) {
        throw new Error('Invalid webhook signature');
      }

      const { event_type, event_data, context } = webhookData;
      return this.processWebhookEvent(event_type, event_data, context);

    } catch (error) {
      console.error('Webhook processing error:', error);
      return { error: error.message };
    }
  }

  processWebhookEvent(eventType, eventData, context) {
    switch (eventType) {
      case 'task:completed':
        return this.handleTaskCompleted(eventData, context);
      
      case 'task:overdue':
        return this.handleTaskOverdue(eventData, context);
      
      case 'deadline:approaching':
        return this.handleDeadlineApproaching(eventData, context);
      
      case 'productivity:milestone':
        return this.handleProductivityMilestone(eventData, context);
      
      case 'pattern:detected':
        return this.handlePatternDetected(eventData, context);
      
      default:
        return this.handleGenericEvent(eventType, eventData, context);
    }
  }

  handleTaskCompleted(eventData, context) {
    const efficiency = eventData.actual_duration / eventData.estimated_duration;
    let message = `🎉 Excellent work completing "${eventData.content}"!\n\n`;

    // Efficiency analysis
    if (efficiency < 0.8) {
      message += `⚡ You finished 20%+ faster than estimated - your efficiency is improving!\n`;
    } else if (efficiency > 1.2) {
      message += `⏱️ This took longer than expected. Consider breaking similar tasks into smaller pieces.\n`;
    } else {
      message += `🎯 Perfect timing! Right on target with your estimate.\n`;
    }

    // Momentum suggestions
    if (context.completion_streak >= 3) {
      message += `\n🔥 Amazing streak! ${context.completion_streak} tasks completed today.`;
    }

    // Next action suggestion
    const nextAction = this.suggestNextAction(context);
    message += `\n\n${nextAction}`;

    return {
      type: 'success_notification',
      message: message,
      suggested_actions: ['continue_momentum', 'take_break', 'review_priorities']
    };
  }

  // Enhanced error handling with fallbacks
  handleStatusError(error) {
    console.error('Status fetch failed:', error);
    
    // Try to return cached data
    const cached = this.cache.get('status');
    if (cached && (Date.now() - cached.timestamp) < cached.ttl) {
      return {
        ...cached.data,
        status: 'cached',
        message: 'Using recent cached data due to connection issue'
      };
    }

    // Return minimal fallback
    return {
      status: 'unavailable',
      message: 'TaskBrain temporarily unavailable. Manual task management recommended.',
      fallback_mode: true,
      suggestions: [
        'Check your calendar for immediate priorities',
        'Review your todo list manually',
        'Focus on urgent items first'
      ]
    };
  }

  // Utility methods
  determineCurrentContext() {
    const hour = new Date().getHours();
    const day = new Date().getDay();
    
    if (day === 0 || day === 6) return 'weekend';
    if (hour >= 6 && hour <= 11) return 'morning';
    if (hour >= 12 && hour <= 17) return 'afternoon';
    if (hour >= 18 && hour <= 22) return 'evening';
    return 'night';
  }

  enhanceTaskData(taskData) {
    return {
      ...taskData,
      created_via: 'claude',
      creation_context: {
        time: new Date().toISOString(),
        context: this.determineCurrentContext(),
        user_energy: this.predictCurrentEnergyLevel()
      },
      intelligence_requested: true
    };
  }

  generateRequestId() {
    return `claude-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  async delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

### Response Formatting for Claude

```javascript
class ClaudeResponseFormatter {
  constructor(userPreferences = {}) {
    this.preferences = {
      style: userPreferences.style || 'balanced', // concise, detailed, balanced
      emojis: userPreferences.emojis !== false, // true by default
      motivation: userPreferences.motivation || 'supportive',
      detail_level: userPreferences.detail_level || 'medium'
    };
  }

  formatStatusResponse(data) {
    const { total_tasks, overdue_tasks, today_tasks, productivity_score } = data;
    
    let response = this.preferences.emojis ? 
      `## 📊 Your Task Status\n\n` : 
      `## Your Task Status\n\n`;

    // Core metrics
    response += `**Active:** ${total_tasks} tasks | **Overdue:** ${overdue_tasks} | **Due Today:** ${today_tasks}\n`;
    response += `**Productivity Score:** ${productivity_score}% ${this.getTrendIndicator(productivity_score)}\n\n`;

    // Priority recommendations
    if (data.next_deadlines && data.next_deadlines.length > 0) {
      response += this.formatPriorities(data.next_deadlines);
    }

    // Context-aware advice
    response += this.generateContextualAdvice(data);

    return response;
  }

  formatTaskCreationResponse(result) {
    const { task, suggestions } = result;
    let response = this.preferences.emojis ? 
      `## ✅ Task Created Successfully\n\n` : 
      `## Task Created Successfully\n\n`;

    response += `**Task:** ${task.content}\n`;
    response += `**Priority:** ${task.priority}/5`;
    
    if (suggestions.priority_adjustment && suggestions.priority_adjustment.confidence > 0.8) {
      response += ` (AI upgraded from ${suggestions.priority_adjustment.original})`;
    }
    response += `\n`;

    // Time estimation
    if (suggestions.time_estimate) {
      response += `**Duration:** ${suggestions.time_estimate.suggested || task.estimated_duration} minutes\n`;
    }

    // AI insights
    if (this.preferences.detail_level !== 'low') {
      response += `\n### 🧠 AI Analysis:\n`;
      response += this.formatAIInsights(suggestions);
    }

    // Auto-applied changes
    if (suggestions.auto_apply) {
      response += `\n${this.preferences.emojis ? '🤖' : ''} **Auto-Applied:** High-confidence AI suggestions have been applied.\n`;
    }

    return response;
  }

  formatRecommendations(data) {
    const { context, recommendations, productivity_insights } = data;
    
    let response = `## ${this.getContextEmoji(context)} ${this.getContextTitle(context)} Recommendations\n\n`;

    // Focus tasks
    if (recommendations.focus_tasks && recommendations.focus_tasks.length > 0) {
      response += `### 🎯 Priority Focus:\n`;
      recommendations.focus_tasks.slice(0, 3).forEach((task, index) => {
        response += `${index + 1}. **${task.content}** (${task.estimated_duration}min)\n`;
        if (this.preferences.detail_level === 'high') {
          response += `   *${task.reasoning}*\n`;
        }
      });
      response += `\n`;
    }

    // Quick wins
    if (recommendations.quick_wins && recommendations.quick_wins.length > 0) {
      response += `### ⚡ Quick Wins:\n`;
      recommendations.quick_wins.slice(0, 3).forEach(task => {
        response += `• **${task.content}** (${task.estimated_duration}min)\n`;
      });
      response += `\n`;
    }

    // Productivity tip
    if (productivity_insights && productivity_insights.tip) {
      response += `### 💡 Productivity Tip:\n${productivity_insights.tip}\n\n`;
    }

    return response;
  }

  formatWebhookResponse(eventType, eventData, context) {
    switch (eventType) {
      case 'task:completed':
        return this.formatCompletionCelebration(eventData, context);
      
      case 'task:overdue':
        return this.formatOverdueAlert(eventData, context);
      
      case 'deadline:approaching':
        return this.formatDeadlineReminder(eventData, context);
      
      default:
        return this.formatGenericUpdate(eventType, eventData);
    }
  }

  formatCompletionCelebration(eventData, context) {
    const celebration = this.preferences.emojis ? '🎉' : '';
    let message = `${celebration} Great work completing "${eventData.content}"!\n\n`;

    // Efficiency insight
    const efficiency = eventData.actual_duration / eventData.estimated_duration;
    if (efficiency < 0.8) {
      message += `${this.preferences.emojis ? '⚡' : ''} Finished 20% faster than expected!\n`;
    } else if (efficiency > 1.2) {
      message += `${this.preferences.emojis ? '⏱️' : ''} Took longer than estimated - consider smaller chunks next time.\n`;
    }

    // Motivational message
    if (this.preferences.motivation === 'supportive') {
      message += this.generateSupportiveMessage(context);
    }

    return message;
  }

  // Utility methods
  getTrendIndicator(score) {
    if (!this.preferences.emojis) return '';
    return score > 80 ? '📈' : score > 60 ? '📊' : '📉';
  }

  getContextEmoji(context) {
    if (!this.preferences.emojis) return '';
    const emojis = {
      morning: '🌅',
      afternoon: '☀️', 
      evening: '🌆',
      night: '🌙'
    };
    return emojis[context] || '⏰';
  }

  getContextTitle(context) {
    const titles = {
      morning: 'Morning',
      afternoon: 'Afternoon', 
      evening: 'Evening',
      night: 'Late Night'
    };
    return titles[context] || 'Current';
  }
}
```

## 📊 Analytics and Insights Integration

### Productivity Analytics Engine

```javascript
class ProductivityAnalytics {
  constructor(taskBrainIntegration) {
    this.integration = taskBrainIntegration;
    this.cache = new Map();
  }

  async getComprehensiveInsights(period = 'week') {
    try {
      const [productivity, patterns] = await Promise.all([
        this.integration.secureApiCall(`/api/analytics/productivity?period=${period}`),
        this.integration.secureApiCall('/api/analytics/patterns')
      ]);

      return {
        performance: this.analyzePerformance(productivity),
        patterns: this.analyzePatterns(patterns),
        recommendations: this.generateRecommendations(productivity, patterns),
        trends: this.analyzeTrends(productivity),
        goals: this.analyzeGoalProgress(productivity)
      };
    } catch (error) {
      return this.getFallbackInsights(period);
    }
  }

  analyzePerformance(data) {
    const { completion_rate, productivity_score, avg_completion_time } = data;
    
    let performance_level;
    if (productivity_score >= 85) performance_level = 'exceptional';
    else if (productivity_score >= 70) performance_level = 'strong';
    else if (productivity_score >= 55) performance_level = 'moderate';
    else performance_level = 'needs_improvement';

    return {
      level: performance_level,
      score: productivity_score,
      completion_rate: completion_rate,
      efficiency: avg_completion_time,
      strengths: this.identifyStrengths(data),
      improvements: this.identifyImprovements(data)
    };
  }

  analyzePatterns(data) {
    return {
      peak_hours: data.optimal_hours || [],
      productive_days: data.optimal_days || [],
      energy_cycles: this.analyzeEnergyCycles(data),
      task_preferences: this.analyzeTaskPreferences(data),
      completion_patterns: this.analyzeCompletionPatterns(data)
    };
  }

  generateRecommendations(productivity, patterns) {
    const recommendations = [];

    // Schedule optimization
    if (patterns.optimal_hours && patterns.optimal_hours.length > 0) {
      recommendations.push({
        type: 'schedule',
        priority: 'high',
        message: `Schedule complex tasks during your peak hours: ${patterns.optimal_hours.join(', ')}`,
        impact: 'High - 25-40% productivity increase expected'
      });
    }

    // Completion rate improvement
    if (productivity.completion_rate < 70) {
      recommendations.push({
        type: 'workflow',
        priority: 'medium',
        message: 'Consider breaking larger tasks into smaller, manageable pieces',
        impact: 'Medium - improve completion rate by 15-25%'
      });
    }

    // Energy management
    if (patterns.energy_cycles) {
      recommendations.push({
        type: 'energy',
        priority: 'medium',
        message: 'Align task difficulty with your natural energy patterns',
        impact: 'Medium - reduce fatigue and improve focus'
      });
    }

    return recommendations;
  }

  formatInsightsForClaude(insights) {
    let response = `## 📊 Productivity Analysis\n\n`;

    // Performance summary
    response += `### 🎯 Performance Summary\n`;
    response += `**Level:** ${insights.performance.level.replace('_', ' ').toUpperCase()}\n`;
    response += `**Score:** ${insights.performance.score}%\n`;
    response += `**Completion Rate:** ${insights.performance.completion_rate}%\n\n`;

    // Key patterns
    if (insights.patterns.peak_hours.length > 0) {
      response += `### ⚡ Peak Performance\n`;
      response += `**Best Hours:** ${insights.patterns.peak_hours.join(', ')}\n`;
      response += `**Optimal Days:** ${insights.patterns.productive_days.join(', ')}\n\n`;
    }

    // Top recommendations
    if (insights.recommendations.length > 0) {
      response += `### 🚀 Key Recommendations\n`;
      insights.recommendations.slice(0, 3).forEach((rec, index) => {
        response += `${index + 1}. **${rec.message}**\n`;
        response += `   *${rec.impact}*\n\n`;
      });
    }

    return response;
  }
}
```

## 🔐 Security Implementation

### Comprehensive Security Manager

```javascript
class SecurityManager {
  constructor(config) {
    this.apiKey = config.apiKey;
    this.webhookSecret = config.webhookSecret;
    this.encryptionKey = config.encryptionKey;
    this.requestLog = new Map();
  }

  generateSecureHeaders(requestId) {
    return {
      'Authorization': `Bearer ${this.apiKey}`,
      'Content-Type': 'application/json',
      'X-Request-ID': requestId,
      'X-Timestamp': Date.now().toString(),
      'X-Claude-Client': 'claude-integration-v1.0',
      'User-Agent': 'Claude-TaskBrain-Integration/1.0'
    };
  }

  async verifyWebhookSignature(payload, signature) {
    try {
      const expectedSignature = await this.computeHMAC(payload, this.webhookSecret);
      return this.constantTimeCompare(signature, `sha256=${expectedSignature}`);
    } catch (error) {
      console.error('Webhook verification failed:', error);
      return false;
    }
  }

  async computeHMAC(data, secret) {
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    );
    
    const signature = await crypto.subtle.sign(
      'HMAC', 
      key, 
      encoder.encode(data)
    );
    
    return Array.from(new Uint8Array(signature))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');
  }

constantTimeCompare(a, b) {
    if (a.length !== b.length) return false;
    
    let result = 0;
    for (let i = 0; i < a.length; i++) {
      result |= a.charCodeAt(i) ^ b.charCodeAt(i);
    }
    return result === 0;
  }

  sanitizeInput(input) {
    if (typeof input === 'string') {
      return input
        .replace(/[<>]/g, '') // Remove potential HTML
        .replace(/javascript:/gi, '') // Remove JS protocols
        .replace(/on\w+=/gi, '') // Remove event handlers
        .replace(/data:/gi, '') // Remove data URLs
        .trim()
        .slice(0, 2000); // Limit length
    }
    
    if (typeof input === 'object' && input !== null) {
      const sanitized = {};
      for (const [key, value] of Object.entries(input)) {
        sanitized[this.sanitizeInput(key)] = this.sanitizeInput(value);
      }
      return sanitized;
    }
    
    return input;
  }

  validateApiResponse(response) {
    // Check response structure
    if (!response || typeof response !== 'object') {
      throw new Error('Invalid response format');
    }

    // Check for required timestamp
    if (response.timestamp) {
      const responseTime = new Date(response.timestamp);
      const now = new Date();
      const timeDiff = Math.abs(now - responseTime);
      
      // Reject responses older than 5 minutes
      if (timeDiff > 300000) {
        throw new Error('Response timestamp too old');
      }
    }

    return true;
  }

  logRequest(requestId, endpoint, method = 'GET') {
    this.requestLog.set(requestId, {
      endpoint,
      method,
      timestamp: Date.now(),
      ip: this.getClientIP()
    });

    // Clean old logs (keep last 1000)
    if (this.requestLog.size > 1000) {
      const oldestKey = this.requestLog.keys().next().value;
      this.requestLog.delete(oldestKey);
    }
  }

  getClientIP() {
    // In browser environment, this would be handled server-side
    return 'client';
  }
}

class RateLimiter {
  constructor() {
    this.requests = new Map();
    this.limits = {
      '/api/claude/status': { max: 60, window: 60000 }, // 60/min
      '/api/claude/create_task': { max: 20, window: 60000 }, // 20/min
      '/api/claude/recommendations': { max: 30, window: 60000 }, // 30/min
      '/api/analytics/productivity': { max: 10, window: 60000 }, // 10/min
      '/api/analytics/patterns': { max: 5, window: 60000 } // 5/min
    };
  }

  canMakeRequest(endpoint, clientId = 'default') {
    const limit = this.getEndpointLimit(endpoint);
    const key = `${clientId}:${endpoint}`;
    const now = Date.now();

    if (!this.requests.has(key)) {
      this.requests.set(key, []);
    }

    const requests = this.requests.get(key);
    
    // Remove requests outside the time window
    const recentRequests = requests.filter(time => now - time < limit.window);
    
    if (recentRequests.length >= limit.max) {
      return {
        allowed: false,
        retryAfter: Math.ceil((requests[0] + limit.window - now) / 1000),
        remaining: 0,
        resetTime: requests[0] + limit.window
      };
    }

    recentRequests.push(now);
    this.requests.set(key, recentRequests);

    return {
      allowed: true,
      remaining: limit.max - recentRequests.length,
      resetTime: requests[0] + limit.window
    };
  }

  getEndpointLimit(endpoint) {
    // Find matching limit or use default
    for (const [pattern, limit] of Object.entries(this.limits)) {
      if (endpoint.includes(pattern)) {
        return limit;
      }
    }
    
    // Default limit
    return { max: 30, window: 60000 };
  }
}
```

## 📱 Mobile and Cross-Platform Optimization

### Device-Responsive Integration

```javascript
class MobileOptimizedIntegration {
  constructor(baseIntegration) {
    this.integration = baseIntegration;
    this.deviceInfo = this.detectDevice();
  }

  detectDevice() {
    if (typeof window === 'undefined') return { type: 'server' };
    
    const width = window.innerWidth;
    const userAgent = navigator.userAgent.toLowerCase();
    
    return {
      type: width <= 768 ? 'mobile' : width <= 1024 ? 'tablet' : 'desktop',
      width: width,
      isMobile: /mobile|android|iphone|ipad/.test(userAgent),
      isTouch: 'ontouchstart' in window
    };
  }

  async getOptimizedStatus() {
    const status = await this.integration.getTaskStatus();
    return this.optimizeForDevice(status);
  }

  optimizeForDevice(data) {
    const { type } = this.deviceInfo;
    
    switch (type) {
      case 'mobile':
        return this.createMobileResponse(data);
      case 'tablet':
        return this.createTabletResponse(data);
      default:
        return this.createDesktopResponse(data);
    }
  }

  createMobileResponse(data) {
    return {
      summary: this.createCompactSummary(data),
      top_priority: data.next_deadlines?.[0] || null,
      quick_action: this.getQuickAction(data),
      urgent_count: data.overdue_tasks,
      productivity_score: data.productivity_score,
      quick_commands: this.getMobileCommands()
    };
  }

  createCompactSummary(data) {
    return `📊 ${data.total_tasks} tasks • ${data.overdue_tasks} overdue • ${data.productivity_score}% productivity`;
  }

  getQuickAction(data) {
    if (data.overdue_tasks > 0) {
      return {
        type: 'urgent',
        message: `${data.overdue_tasks} overdue tasks need attention`,
        action: 'view_overdue'
      };
    }
    
    if (data.today_tasks > 0) {
      return {
        type: 'today',
        message: `${data.today_tasks} tasks due today`,
        action: 'view_today'
      };
    }

    return {
      type: 'create',
      message: 'Add a new task',
      action: 'create_task'
    };
  }

  getMobileCommands() {
    return [
      { label: '➕ Add Task', command: 'create_task' },
      { label: '📋 View Tasks', command: 'list_tasks' },
      { label: '🎯 Priorities', command: 'show_priorities' }
    ];
  }
}

// Voice interface support
class VoiceInterfaceAdapter {
  constructor(integration) {
    this.integration = integration;
    this.speechSynthesis = typeof window !== 'undefined' ? window.speechSynthesis : null;
  }

  async getSpokenSummary() {
    const status = await this.integration.getTaskStatus();
    return this.createSpokenSummary(status);
  }

  createSpokenSummary(data) {
    let summary = `You have ${data.total_tasks} active tasks. `;
    
    if (data.overdue_tasks > 0) {
      summary += `${data.overdue_tasks} tasks are overdue and need immediate attention. `;
    }
    
    if (data.today_tasks > 0) {
      summary += `${data.today_tasks} tasks are due today. `;
    }
    
    summary += `Your current productivity score is ${data.productivity_score} percent.`;
    
    // Add priority if available
    if (data.next_deadlines?.[0]) {
      summary += ` Your top priority is: ${data.next_deadlines[0].content}.`;
    }

    return {
      text: summary,
      audio_available: !!this.speechSynthesis,
      suggested_voice_commands: this.getVoiceCommands()
    };
  }

  getVoiceCommands() {
    return [
      'Create a new task',
      'What are my priorities',
      'How productive am I today',
      'What is due today',
      'Complete a task',
      'Get recommendations'
    ];
  }

  async speak(text, options = {}) {
    if (!this.speechSynthesis) return false;

    const utterance = new SpeechSynthesisUtterance(text);
    utterance.rate = options.rate || 1.0;
    utterance.pitch = options.pitch || 1.0;
    utterance.volume = options.volume || 1.0;

    this.speechSynthesis.speak(utterance);
    return true;
  }
}
```

## 🧪 Testing and Development Framework

### Comprehensive Test Suite

```javascript
class TaskBrainTester {
  constructor(baseUrl, apiKey) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
    this.testResults = [];
    this.startTime = Date.now();
  }

  async runFullTestSuite() {
    console.log('🧪 Starting comprehensive TaskBrain integration tests...');
    
    const testSuites = [
      { name: 'Connection Tests', fn: this.testConnection },
      { name: 'Authentication Tests', fn: this.testAuthentication },
      { name: 'Status Endpoint Tests', fn: this.testStatusEndpoint },
      { name: 'Task Creation Tests', fn: this.testTaskCreation },
      { name: 'Recommendations Tests', fn: this.testRecommendations },
      { name: 'Analytics Tests', fn: this.testAnalytics },
      { name: 'Error Handling Tests', fn: this.testErrorHandling },
      { name: 'Rate Limiting Tests', fn: this.testRateLimiting },
      { name: 'Security Tests', fn: this.testSecurity },
      { name: 'Performance Tests', fn: this.testPerformance }
    ];

    for (const suite of testSuites) {
      try {
        console.log(`Running ${suite.name}...`);
        await suite.fn.call(this);
        this.recordResult(suite.name, 'PASSED');
      } catch (error) {
        this.recordResult(suite.name, 'FAILED', error.message);
        console.error(`❌ ${suite.name} failed:`, error.message);
      }
    }

    return this.generateReport();
  }

  async testConnection() {
    const response = await fetch(`${this.baseUrl}/health`);
    this.assert(response.ok, 'Health endpoint should be accessible');
    
    const data = await response.json();
    this.assert(data.status === 'ok', 'Health check should return ok status');
  }

  async testAuthentication() {
    // Test with valid API key
    const validResponse = await fetch(`${this.baseUrl}/api/claude/status`, {
      headers: { 'Authorization': `Bearer ${this.apiKey}` }
    });
    this.assert(validResponse.ok, 'Valid API key should be accepted');

    // Test with invalid API key
    const invalidResponse = await fetch(`${this.baseUrl}/api/claude/status`, {
      headers: { 'Authorization': 'Bearer invalid_key' }
    });
    this.assert(invalidResponse.status === 401, 'Invalid API key should return 401');
  }

  async testStatusEndpoint() {
    const response = await this.authenticatedRequest('/api/claude/status');
    this.assert(response.ok, 'Status endpoint should return 200');

    const data = await response.json();
    
    // Validate response structure
    this.assert(typeof data.total_tasks === 'number', 'Should return total_tasks as number');
    this.assert(typeof data.overdue_tasks === 'number', 'Should return overdue_tasks as number');
    this.assert(typeof data.productivity_score === 'number', 'Should return productivity_score');
    this.assert(Array.isArray(data.recent_activity), 'Should return recent_activity array');
    this.assert(Array.isArray(data.next_deadlines), 'Should return next_deadlines array');
    
    // Validate data ranges
    this.assert(data.productivity_score >= 0 && data.productivity_score <= 100, 
      'Productivity score should be 0-100');
    this.assert(data.overdue_tasks <= data.total_tasks, 
      'Overdue tasks should not exceed total tasks');
  }

  async testTaskCreation() {
    const testTask = {
      content: 'Test task for API integration',
      description: 'Automated test task - safe to delete',
      priority: 3,
      estimated_duration: 30,
      source: 'api_test',
      context_tags: ['test', 'automation']
    };

    const response = await this.authenticatedRequest('/api/claude/create_task', {
      method: 'POST',
      body: JSON.stringify(testTask)
    });

    this.assert(response.ok, 'Task creation should succeed');

    const result = await response.json();
    
    // Validate response structure
    this.assert(result.task && typeof result.task.id === 'number', 
      'Should return created task with numeric ID');
    this.assert(result.task.content === testTask.content, 
      'Task content should match input');
    this.assert(result.suggestions && typeof result.suggestions === 'object', 
      'Should return AI suggestions object');
    
    // Validate AI suggestions structure
    this.assert(result.suggestions.priority_adjustment, 
      'Should include priority adjustment suggestion');
    this.assert(result.suggestions.time_estimate, 
      'Should include time estimate');
    this.assert(typeof result.suggestions.auto_apply === 'boolean', 
      'Should indicate if suggestions were auto-applied');

    // Clean up - delete the test task
    await this.deleteTestTask(result.task.id);
  }

  async testRecommendations() {
    const contexts = ['morning', 'afternoon', 'evening', 'planning'];

    for (const context of contexts) {
      const response = await this.authenticatedRequest(
        `/api/claude/recommendations?context=${context}`
      );
      
      this.assert(response.ok, `Recommendations should work for ${context} context`);

      const data = await response.json();
      this.assert(data.context === context, 'Should return correct context');
      this.assert(data.recommendations && typeof data.recommendations === 'object', 
        'Should return recommendations object');
      
      // Validate recommendation structure
      if (data.recommendations.focus_tasks) {
        this.assert(Array.isArray(data.recommendations.focus_tasks), 
          'Focus tasks should be an array');
      }
      if (data.recommendations.quick_wins) {
        this.assert(Array.isArray(data.recommendations.quick_wins), 
          'Quick wins should be an array');
      }
    }
  }

  async testAnalytics() {
    const periods = ['day', 'week', 'month'];

    for (const period of periods) {
      const response = await this.authenticatedRequest(
        `/api/analytics/productivity?period=${period}`
      );
      
      this.assert(response.ok, `Analytics should work for ${period} period`);

      const data = await response.json();
      this.assert(typeof data.completion_rate === 'number', 
        'Should return completion rate');
      this.assert(typeof data.productivity_score === 'number', 
        'Should return productivity score');
    }

    // Test patterns endpoint
    const patternsResponse = await this.authenticatedRequest('/api/analytics/patterns');
    this.assert(patternsResponse.ok, 'Patterns endpoint should work');

    const patterns = await patternsResponse.json();
    this.assert(typeof patterns === 'object', 'Should return patterns object');
  }

  async testErrorHandling() {
    // Test 404 for invalid endpoint
    const invalidResponse = await this.authenticatedRequest('/api/invalid/endpoint');
    this.assert(invalidResponse.status === 404, 'Should return 404 for invalid endpoint');

    // Test 400 for invalid task creation
    const invalidTaskResponse = await this.authenticatedRequest('/api/claude/create_task', {
      method: 'POST',
      body: JSON.stringify({}) // Missing required fields
    });
    this.assert(invalidTaskResponse.status === 400, 
      'Should return 400 for invalid task data');

    // Test malformed JSON
    const malformedResponse = await this.authenticatedRequest('/api/claude/create_task', {
      method: 'POST',
      body: 'invalid json'
    });
    this.assert(malformedResponse.status === 400, 
      'Should return 400 for malformed JSON');
  }

  async testRateLimiting() {
    // Make multiple rapid requests
    const requests = Array(15).fill().map(() => 
      this.authenticatedRequest('/api/claude/status')
    );

    const responses = await Promise.all(requests);
    const successfulRequests = responses.filter(r => r.ok).length;
    const rateLimitedRequests = responses.filter(r => r.status === 429).length;

    this.assert(successfulRequests > 0, 'Some requests should succeed');
    // Note: Rate limiting behavior depends on current load and configuration
    
    console.log(`Rate limiting test: ${successfulRequests} successful, ${rateLimitedRequests} rate-limited`);
  }

  async testSecurity() {
    // Test XSS protection
    const xssPayload = {
      content: '<script>alert("xss")</script>',
      description: 'javascript:alert("xss")'
    };

    const xssResponse = await this.authenticatedRequest('/api/claude/create_task', {
      method: 'POST',
      body: JSON.stringify(xssPayload)
    });

    if (xssResponse.ok) {
      const result = await xssResponse.json();
      this.assert(!result.task.content.includes('<script>'), 
        'Should sanitize XSS attempts');
      await this.deleteTestTask(result.task.id);
    }

    // Test SQL injection protection (basic)
    const sqlPayload = {
      content: "'; DROP TABLE tasks; --"
    };

    const sqlResponse = await this.authenticatedRequest('/api/claude/create_task', {
      method: 'POST',
      body: JSON.stringify(sqlPayload)
    });

    // Should either succeed with sanitized content or fail gracefully
    this.assert(sqlResponse.status !== 500, 'Should handle SQL injection attempts gracefully');
  }

  async testPerformance() {
    const performanceTests = [
      { endpoint: '/api/claude/status', expectedMaxTime: 1000 },
      { endpoint: '/api/claude/recommendations', expectedMaxTime: 2000 },
      { endpoint: '/api/analytics/productivity?period=week', expectedMaxTime: 3000 }
    ];

    for (const test of performanceTests) {
      const startTime = Date.now();
      const response = await this.authenticatedRequest(test.endpoint);
      const endTime = Date.now();
      const duration = endTime - startTime;

      this.assert(response.ok, `${test.endpoint} should respond successfully`);
      
      if (duration > test.expectedMaxTime) {
        console.warn(`⚠️ Performance warning: ${test.endpoint} took ${duration}ms (expected <${test.expectedMaxTime}ms)`);
      }
    }
  }

  // Helper methods
  async authenticatedRequest(endpoint, options = {}) {
    return fetch(`${this.baseUrl}${endpoint}`, {
      ...options,
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
        ...options.headers
      }
    });
  }

  async deleteTestTask(taskId) {
    try {
      await this.authenticatedRequest(`/api/tasks/${taskId}`, {
        method: 'DELETE'
      });
    } catch (error) {
      console.warn(`Failed to cleanup test task ${taskId}:`, error);
    }
  }

  assert(condition, message) {
    if (!condition) {
      throw new Error(message);
    }
  }

  recordResult(testName, status, details = null) {
    this.testResults.push({
      test: testName,
      status: status,
      details: details,
      timestamp: new Date().toISOString()
    });
  }

  generateReport() {
    const endTime = Date.now();
    const duration = endTime - this.startTime;
    
    const passed = this.testResults.filter(r => r.status === 'PASSED').length;
    const failed = this.testResults.filter(r => r.status === 'FAILED').length;
    const total = this.testResults.length;

    const report = {
      summary: {
        total_tests: total,
        passed: passed,
        failed: failed,
        success_rate: ((passed / total) * 100).toFixed(1) + '%',
        duration: duration + 'ms'
      },
      results: this.testResults,
      recommendations: this.generateRecommendations(this.testResults)
    };

    console.log(`\n📊 Test Results: ${passed}/${total} passed (${report.summary.success_rate})`);
    
    if (failed > 0) {
      console.log('❌ Failed tests:');
      this.testResults.filter(r => r.status === 'FAILED').forEach(result => {
        console.log(`  • ${result.test}: ${result.details}`);
      });
    }

    return report;
  }

  generateRecommendations(results) {
    const recommendations = [];
    const failedTests = results.filter(r => r.status === 'FAILED');

    if (failedTests.some(t => t.test.includes('Connection'))) {
      recommendations.push('Check TaskBrain server is running and accessible');
    }

    if (failedTests.some(t => t.test.includes('Authentication'))) {
      recommendations.push('Verify API key is correct and has proper permissions');
    }

    if (failedTests.some(t => t.test.includes('Performance'))) {
      recommendations.push('Consider optimizing server performance or scaling resources');
    }

    if (failedTests.length === 0) {
      recommendations.push('All tests passed! Integration is ready for production use.');
    }

    return recommendations;
  }
}

// Usage example
async function runIntegrationTests() {
  const tester = new TaskBrainTester(
    'https://your-taskbrain-server.com',
    'your-api-key'
  );

  try {
    const report = await tester.runFullTestSuite();
    console.log('Full test report:', report);
    return report;
  } catch (error) {
    console.error('Test suite failed:', error);
    throw error;
  }
}
```

## 🚀 Production Deployment Guide

### Complete Implementation Example

```javascript
// Complete production-ready integration
class ProductionTaskBrainIntegration {
  constructor(config) {
    this.config = this.validateConfig(config);
    this.security = new SecurityManager(config);
    this.rateLimiter = new RateLimiter();
    this.cache = new Map();
    this.eventHandlers = new Map();
    this.performance = new PerformanceMonitor();
    this.isInitialized = false;
    
    this.setupEventHandlers();
  }

  validateConfig(config) {
    const required = ['baseUrl', 'apiKey'];
    const missing = required.filter(key => !config[key]);
    
    if (missing.length > 0) {
      throw new Error(`Missing required config: ${missing.join(', ')}`);
    }

    return {
      baseUrl: config.baseUrl.replace(/\/$/, ''), // Remove trailing slash
      apiKey: config.apiKey,
      webhookSecret: config.webhookSecret,
      timeout: config.timeout || 10000,
      retries: config.retries || 3,
      cacheTTL: config.cacheTTL || 60000
    };
  }

  async initialize() {
    try {
      // Test connection
      await this.healthCheck();
      
      // Load initial context
      await this.loadInitialContext();
      
      // Setup performance monitoring
      this.performance.start();
      
      this.isInitialized = true;
      console.log('✅ TaskBrain integration initialized successfully');
      
      return { success: true, version: '1.0.0' };
    } catch (error) {
      console.error('❌ TaskBrain initialization failed:', error);
      throw new Error(`Integration initialization failed: ${error.message}`);
    }
  }

  async healthCheck() {
    const response = await fetch(`${this.config.baseUrl}/health`, {
      timeout: 5000
    });
    
    if (!response.ok) {
      throw new Error(`Health check failed: ${response.status}`);
    }
    
    return await response.json();
  }

  async loadInitialContext() {
    try {
      const status = await this.getTaskStatus();
      this.cache.set('initial_context', {
        data: status,
        timestamp: Date.now()
      });
    } catch (error) {
      console.warn('Could not load initial context:', error.message);
    }
  }

  setupEventHandlers() {
    this.eventHandlers.set('task:completed', this.handleTaskCompleted.bind(this));
    this.eventHandlers.set('task:overdue', this.handleTaskOverdue.bind(this));
    this.eventHandlers.set('deadline:approaching', this.handleDeadlineApproaching.bind(this));
    this.eventHandlers.set('productivity:milestone', this.handleProductivityMilestone.bind(this));
  }

  // Main API methods with comprehensive error handling
  async getTaskStatus() {
    if (!this.isInitialized) {
      await this.initialize();
    }

    const requestId = this.generateRequestId();
    
    try {
      this.performance.startRequest(requestId, 'status');
      
      // Check cache first
      const cached = this.getFromCache('status');
      if (cached) {
        this.performance.endRequest(requestId, true);
        return { ...cached, source: 'cache' };
      }

      const response = await this.secureApiCall('/api/claude/status');
      
      // Cache the response
      this.setCache('status', response, this.config.cacheTTL);
      
      this.performance.endRequest(requestId, true);
      return { ...response, source: 'api' };

    } catch (error) {
      this.performance.endRequest(requestId, false, error);
      return this.handleStatusError(error);
    }
  }

  async createIntelligentTask(taskData, options = {}) {
    if (!this.isInitialized) {
      await this.initialize();
    }

    const requestId = this.generateRequestId();
    
    try {
      this.performance.startRequest(requestId, 'create_task');
      
      // Sanitize and enhance input
      const sanitizedData = this.security.sanitizeInput(taskData);
      const enhancedData = this.enhanceTaskData(sanitizedData);
      
      const response = await this.secureApiCall('/api/claude/create_task', {
        method: 'POST',
        body: JSON.stringify(enhancedData)
      });

      // Invalidate relevant caches
      this.invalidateCache(['status', 'recommendations']);
      
      // Process response
      const processedResponse = this.processTaskCreationResponse(response);
      
      this.performance.endRequest(requestId, true);
      return processedResponse;

    } catch (error) {
      this.performance.endRequest(requestId, false, error);
      throw new Error(`Task creation failed: ${error.message}`);
    }
  }

  async getContextualRecommendations(context = 'auto') {
    if (!this.isInitialized) {
      await this.initialize();
    }

    const requestId = this.generateRequestId();
    
    try {
      this.performance.startRequest(requestId, 'recommendations');
      
      if (context === 'auto') {
        context = this.determineCurrentContext();
      }

      // Check cache
      const cacheKey = `recommendations:${context}`;
      const cached = this.getFromCache(cacheKey);
      if (cached) {
        this.performance.endRequest(requestId, true);
        return { ...cached, source: 'cache' };
      }

      const response = await this.secureApiCall(
        `/api/claude/recommendations?context=${context}`
      );

      // Cache with shorter TTL for recommendations
      this.setCache(cacheKey, response, 30000); // 30 seconds
      
      this.performance.endRequest(requestId, true);
      return { ...response, source: 'api' };

    } catch (error) {
      this.performance.endRequest(requestId, false, error);
      return this.getFallbackRecommendations(context);
    }
  }

  // Webhook handling
  processWebhook(webhookData) {
    try {
      // Verify signature
      if (!this.security.verifyWebhookSignature(
        webhookData.payload, 
        webhookData.signature
      )) {
        throw new Error('Invalid webhook signature');
      }

      const { event_type, event_data, context } = JSON.parse(webhookData.payload);
      
      // Get appropriate handler
      const handler = this.eventHandlers.get(event_type);
      if (handler) {
        return handler(event_data, context);
      }

      return this.handleGenericEvent(event_type, event_data, context);

    } catch (error) {
      console.error('Webhook processing error:', error);
      return {
        success: false,
        error: error.message,
        event_type: 'error'
      };
    }
  }

  // Event handlers
  handleTaskCompleted(eventData, context) {
    // Invalidate relevant caches
    this.invalidateCache(['status', 'recommendations']);
    
    const efficiency = eventData.actual_duration / eventData.estimated_duration;
    let message = `🎉 Excellent work completing "${eventData.content}"!\n\n`;

    if (efficiency < 0.8) {
      message += `⚡ You finished 20%+ faster than estimated - your efficiency is improving!\n`;
    } else if (efficiency > 1.2) {
      message += `⏱️ This took longer than expected. Consider breaking similar tasks into smaller pieces.\n`;
    } else {
      message += `🎯 Perfect timing! Right on target with your estimate.\n`;
    }

    // Add momentum insight
    if (context.completion_streak >= 3) {
      message += `\n🔥 Amazing! You're on a ${context.completion_streak}-task completion streak today!`;
    }

    // Suggest next action
    const nextAction = this.suggestNextAction(context);
    message += `\n\n${nextAction}`;

    return {
      type: 'task_completed',
      message: message,
      productivity_boost: efficiency < 0.8,
      suggested_actions: ['continue_momentum', 'take_break', 'review_priorities']
    };
  }

  handleTaskOverdue(eventData, context) {
    // Invalidate caches
    this.invalidateCache(['status', 'recommendations']);
    
    const urgencyLevel = this.assessUrgency(eventData);
    let message = `⚠️ "${eventData.content}" is now ${eventData.hours_overdue} hours overdue.\n\n`;

    // Generate action plan
    const actionPlan = this.generateOverdueActionPlan(eventData, context);
    message += actionPlan;

    return {
      type: 'task_overdue',
      message: message,
      urgency: urgencyLevel,
      task_id: eventData.task_id,
      hours_overdue: eventData.hours_overdue,
      suggested_actions: this.getOverdueActions(eventData)
    };
  }

  handleDeadlineApproaching(eventData, context) {
    const timeRemaining = eventData.hours_remaining;
    let message = `⏰ Deadline Alert: "${eventData.content}" is due in ${timeRemaining} hours.\n\n`;

    const strategy = this.generateDeadlineStrategy(eventData, timeRemaining);
    message += strategy;

    return {
      type: 'deadline_approaching',
      message: message,
      time_critical: timeRemaining < 24,
      task_id: eventData.task_id,
      hours_remaining: timeRemaining,
      preparation_tips: this.getPreparationTips(eventData)
    };
  }

  handleProductivityMilestone(eventData, context) {
    const achievement = context.achievement;
    let message = `🏆 Productivity Milestone Achieved!\n\n${achievement}\n\n`;

    const encouragement = this.generateEncouragement(achievement, context);
    message += encouragement;

    return {
      type: 'productivity_milestone',
      message: message,
      achievement: achievement,
      streak_info: context.streak_info,
      next_goal: context.next_milestone
    };
  }

  // Utility methods
  async secureApiCall(endpoint, options = {}) {
    // Rate limiting check
    const rateLimitCheck = this.rateLimiter.canMakeRequest(endpoint);
    if (!rateLimitCheck.allowed) {
      throw new Error(`Rate limit exceeded. Retry after ${rateLimitCheck.retryAfter}s`);
    }

    const requestId = this.generateRequestId();
    const headers = this.security.generateSecureHeaders(requestId);

    let attempt = 0;
    const maxRetries = this.config.retries;

    while (attempt < maxRetries) {
      try {
        const response = await fetch(`${this.config.baseUrl}${endpoint}`, {
          ...options,
          headers: { ...headers, ...options.headers },
          timeout: this.config.timeout
        });

        if (!response.ok) {
          const errorData = await response.json().catch(() => ({}));
          throw new Error(`API Error ${response.status}: ${errorData.message || response.statusText}`);
        }

        const data = await response.json();
        this.security.validateApiResponse(data);
        
        // Log successful request
        this.security.logRequest(requestId, endpoint, options.method || 'GET');
        
        return data;

      } catch (error) {
        attempt++;
        
        if (attempt >= maxRetries) {
          throw new Error(`Failed after ${maxRetries} attempts: ${error.message}`);
        }

        // Exponential backoff with jitter
        const delay = Math.pow(2, attempt) * 1000 + Math.random() * 1000;
        await this.delay(delay);
      }
    }
  }

  // Cache management
  getFromCache(key) {
    const cached = this.cache.get(key);
    if (!cached) return null;

    if (Date.now() - cached.timestamp > cached.ttl) {
      this.cache.delete(key);
      return null;
    }

    return cached.data;
  }

  setCache(key, data, ttl = this.config.cacheTTL) {
    this.cache.set(key, {
      data: data,
      timestamp: Date.now(),
      ttl: ttl
    });

    // Clean old cache entries
    if (this.cache.size > 100) {
      const entries = Array.from(this.cache.entries());
      const expired = entries.filter(([_, value]) => 
        Date.now() - value.timestamp > value.ttl
      );
      
      expired.forEach(([key]) => this.cache.delete(key));
    }
  }

  invalidateCache(keys) {
    if (Array.isArray(keys)) {
      keys.forEach(key => this.cache.delete(key));
    } else {
      this.cache.delete(keys);
    }
  }

  // Error handling with fallbacks
  handleStatusError(error) {
    console.error('Status fetch failed:', error);
    
    // Try cached data first
    const cached = this.getFromCache('status');
    if (cached) {
      return {
        ...cached,
        source: 'cache',
        status: 'degraded',
        message: 'Using cached data due to connection issue'
      };
    }

    // Return minimal fallback
    return {
      status: 'unavailable',
      message: 'TaskBrain temporarily unavailable',
      fallback_mode: true,
      total_tasks: 0,
      overdue_tasks: 0,
      today_tasks: 0,
      productivity_score: 0,
      suggestions: [
        'Check your calendar for immediate priorities',
        'Review your todo list manually',
        'Focus on urgent items first'
      ]
    };
  }

  getFallbackRecommendations(context) {
    const fallbackRecommendations = {
      morning: {
        focus_tasks: [{ content: 'Tackle your most challenging task first', reasoning: 'Peak energy hours' }],
        productivity_tip: 'Morning is optimal for deep, focused work'
      },
      afternoon: {
        focus_tasks: [{ content: 'Handle communication and meetings', reasoning: 'Good collaborative energy' }],
        productivity_tip: 'Afternoon is great for teamwork and communication'
      },
      evening: {
        focus_tasks: [{ content: 'Plan tomorrow and wrap up loose ends', reasoning: 'Wind-down period' }],
        productivity_tip: 'Evening is perfect for planning and organization'
      }
    };

    return {
      context: context,
      recommendations: fallbackRecommendations[context] || fallbackRecommendations.morning,
      source: 'fallback',
      message: 'Using offline recommendations due to connection issue'
    };
  }

  // Helper methods
  determineCurrentContext() {
    const hour = new Date().getHours();
    const day = new Date().getDay();
    
    if (day === 0 || day === 6) return 'weekend';
    if (hour >= 6 && hour <= 11) return 'morning';
    if (hour >= 12 && hour <= 17) return 'afternoon';
    if (hour >= 18 && hour <= 22) return 'evening';
    return 'night';
  }

  enhanceTaskData(taskData) {
    return {
      ...taskData,
      created_via: 'claude',
      creation_context: {
        time: new Date().toISOString(),
        context: this.determineCurrentContext(),
        user_timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
      },
      intelligence_requested: true,
      client_version: '1.0.0'
    };
  }

  processTaskCreationResponse(response) {
    const { task, suggestions, impact_analysis } = response;
    
    return {
      task: task,
      ai_insights: {
        priority_optimized: suggestions.priority_adjustment?.confidence > 0.8,
        time_estimated: suggestions.time_estimate?.confidence > 0.7,
        breakdown_suggested: suggestions.breakdown_suggestions?.should_break_down,
        auto_applied: suggestions.auto_apply
      },
      suggestions: suggestions,
      impact: impact_analysis,
      success: true
    };
  }

  suggestNextAction(context) {
    const hour = new Date().getHours();
    const completedToday = context.completed_today || 0;
    const remaining = context.total_tasks - completedToday;

    if (completedToday >= 5 && hour > 16) {
      return "🌟 Fantastic productivity today! Consider wrapping up or planning tomorrow.";
    } else if (hour >= 9 && hour <= 11 && context.high_priority_remaining > 0) {
      return "🎯 Perfect time to tackle another high-priority task during peak focus hours.";
    } else if (remaining > 0 && context.momentum_score > 7) {
      return "⚡ Great momentum! Consider completing another task while you're in the flow.";
    } else {
      return "✨ Take a moment to celebrate your progress and plan your next move.";
    }
  }

  generateOverdueActionPlan(eventData, context) {
    const hours = eventData.hours_overdue;
    let plan = "";

    if (hours < 24) {
      plan = "**Immediate Action Required:**\n";
      plan += "• Schedule focused time block today\n";
      plan += "• Break task into smaller 30-minute chunks\n";
      plan += "• Eliminate distractions and work intensively\n";
    } else {
      plan = "**Critical Recovery Plan:**\n";
      plan += "• Assess if deadline can be negotiated\n";
      plan += "• Delegate portions if possible\n";
      plan += "• Focus on minimum viable completion\n";
      plan += "• Communicate proactively with stakeholders\n";
    }

    return plan;
  }

  generateDeadlineStrategy(eventData, timeRemaining) {
    let strategy = "";

    if (timeRemaining <= 4) {
      strategy = "**Urgent Sprint Mode:**\n";
      strategy += "• Clear your schedule immediately\n";
      strategy += "• Focus solely on this task\n";
      strategy += "• Aim for good enough, not perfect\n";
    } else if (timeRemaining <= 24) {
      strategy = "**Today's Priority:**\n";
      strategy += "• Schedule dedicated time block\n";
      strategy += "• Gather all necessary resources\n";
      strategy += "• Set mini-deadlines for progress\n";
    } else {
      strategy = "**Strategic Planning:**\n";
      strategy += "• Break into daily milestones\n";
      strategy += "• Schedule work during peak hours\n";
      strategy += "• Build in buffer time for review\n";
    }

    return strategy;
  }

  generateRequestId() {
    return `claude-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  async delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // Performance monitoring
  getPerformanceMetrics() {
    return this.performance.getMetrics();
  }

  // Cleanup method
  destroy() {
    this.cache.clear();
    this.eventHandlers.clear();
    this.performance.stop();
    this.isInitialized = false;
  }
}

class PerformanceMonitor {
  constructor() {
    this.metrics = new Map();
    this.alerts = [];
    this.isRunning = false;
  }

  start() {
    this.isRunning = true;
    this.startTime = Date.now();
  }

  stop() {
    this.isRunning = false;
  }

  startRequest(requestId, endpoint) {
    if (!this.isRunning) return;
    
    this.metrics.set(requestId, {
      endpoint: endpoint,
      startTime: performance.now(),
      memoryStart: this.getMemoryUsage()
    });
  }

  endRequest(requestId, success = true, error = null) {
    if (!this.isRunning) return;
    
    const metric = this.metrics.get(requestId);
    if (!metric) return;

    const endTime = performance.now();
    const duration = endTime - metric.startTime;
    const memoryEnd = this.getMemoryUsage();

    const result = {
      ...metric,
      endTime: endTime,
      duration: duration,
      memoryUsed: memoryEnd - metric.memoryStart,
      success: success,
      error: error
    };

    this.analyzePerformance(result);
    this.metrics.delete(requestId);

    return result;
  }

  analyzePerformance(result) {
    // Alert on slow requests (>3 seconds)
    if (result.duration > 3000) {
      this.alerts.push({
        type: 'SLOW_REQUEST',
        endpoint: result.endpoint,
        duration: result.duration,
        timestamp: Date.now()
      });
    }

    // Alert on high memory usage (>10MB increase)
    if (result.memoryUsed > 10 * 1024 * 1024) {
      this.alerts.push({
        type: 'HIGH_MEMORY_USAGE',
        endpoint: result.endpoint,
        memoryUsed: result.memoryUsed,
        timestamp: Date.now()
      });
    }

    // Keep only recent alerts (last 50)
    if (this.alerts.length > 50) {
      this.alerts = this.alerts.slice(-50);
    }
  }

  getMemoryUsage() {
    if (typeof performance !== 'undefined' && performance.memory) {
      return performance.memory.usedJSHeapSize;
    }
    return 0;
  }

  getMetrics() {
    return {
      uptime: this.isRunning ? Date.now() - this.startTime : 0,
      active_requests: this.metrics.size,
      recent_alerts: this.alerts.slice(-10),
      memory_usage: this.getMemoryUsage()
    };
  }
}
```

## 📚 Complete Usage Examples

### Basic Integration Setup

```javascript
// Initialize TaskBrain integration
const taskBrain = new ProductionTaskBrainIntegration({
  baseUrl: 'https://your-taskbrain-server.com',
  apiKey: 'your-secure-api-key',
  webhookSecret: 'your-webhook-secret',
  timeout: 10000,
  retries: 3,
  cacheTTL: 60000
});

// Initialize the integration
async function setupClaude() {
  try {
    await taskBrain.initialize();
    console.log('✅ Claude TaskBrain integration ready!');
    
    // Get initial status
    const status = await taskBrain.getTaskStatus();
    console.log('📊 Current status:', status);
    
    return true;
  } catch (error) {
    console.error('❌ Setup failed:', error);
    return false;
  }
}
```

### Morning Productivity Briefing

```javascript
async function getMorningBriefing() {
  try {
    const [status, recommendations] = await Promise.all([
      taskBrain.getTaskStatus(),
      taskBrain.getContextualRecommendations('morning')
    ]);

    const briefing = formatMorningBriefing(status, recommendations);
    return briefing;
  } catch (error) {
    return {
      error: true,
      message: 'Could not fetch morning briefing',
      fallback: 'Start with your highest priority task for today'
    };
  }
}

function formatMorningBriefing(status, recommendations) {
  return `## 🌅 Good Morning! Your Productivity Briefing

📊 **Status**: ${status.total_tasks} active tasks, ${status.productivity_score}% productivity score

🎯 **Today's Focus**:
${recommendations.recommendations.focus_tasks.slice(0, 3).map((task, i) => 
  `${i + 1}. ${task.content} (${task.estimated_duration}min)`
).join('\n')}

⚡ **Quick Wins**: ${recommendations.recommendations.quick_wins.length} available
⏰ **Urgent**: ${status.overdue_tasks} overdue items need attention

💡 **Tip**: ${recommendations.productivity_insights.tip}`;
}
```

### Intelligent Task Creation

```javascript
async function createTaskWithAI(userInput) {
  try {
    // Parse user input into task data
    const taskData = parseUserInput(userInput);
    
    // Create task with AI analysis
    const result = await taskBrain.createIntelligentTask(taskData, {
      learnPreferences: true
    });

    // Format response for user
    return formatTaskCreationResult(result);
  } catch (error) {
    return {
      error: true,
      message: `Could not create task: ${error.message}`,
      suggestion: 'Try a simpler task description'
    };
  }
}

function parseUserInput(input) {
  // Simple parsing logic - could be enhanced with NLP
  const dueDateMatch = input.match(/(?:due|by|before)\s+(.+?)(?:\s|$)/i);
  const priorityMatch = input.match(/(?:priority|urgent|important)/i);
  
  return {
    content: input.replace(/(?:due|by|before)\s+.+/i, '').trim(),
    due_date: dueDateMatch ? parseDueDate(dueDateMatch[1]) : null,
    priority: priorityMatch ? 4 : 3,
    source: 'claude'
  };
}

function formatTaskCreationResult(result) {
  if (result.error) {
    return `❌ Task creation failed: ${result.message}`;
  }

  let response = `✅ **Task Created**: ${result.task.content}\n`;
  response += `🎯 **Priority**: ${result.task.priority}/5`;
  
  if (result.ai_insights.priority_optimized) {
    response += ' (AI optimized)';
  }
  
  response += `\n⏱️ **Estimated**: ${result.task.estimated_duration} minutes\n`;

  if (result.ai_insights.breakdown_suggested) {
    response += `\n💡 **AI Suggestion**: Break this task into smaller parts for better completion rate\n`;
  }

  if (result.suggestions.optimal_schedule) {
    response += `📅 **Best Time**: ${result.suggestions.optimal_schedule.suggested_time}\n`;
  }

  return response;
}
```

### Real-time Webhook Handling

```javascript
// Express.js webhook endpoint example
app.post('/webhooks/taskbrain', express.raw({type: 'application/json'}), (req, res) => {
  try {
    const signature = req.headers['x-taskbrain-signature'];
    const payload = req.body.toString();

    // Process webhook with TaskBrain integration
    const result = taskBrain.processWebhook({
      payload: payload,
      signature: signature
    });

    // Send response to user if it's actionable
    if (result.type !== 'error' && result.message) {
      notifyUser(result);
    }

    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Webhook processing failed:', error);
    res.status(400).json({ error: error.message });
  }
});

function notifyUser(webhookResult) {
  // Implementation depends on your notification system
  console.log('📢 TaskBrain Update:', webhookResult.message);
  
  // Could send to Claude, user interface, email, etc.
  sendToClaudeInterface({
    type: 'taskbrain_update',
    data: webhookResult
  });
}
```

### Analytics and Insights

```javascript
async function getProductivityInsights(period = 'week') {
  try {
    const analytics = new ProductivityAnalytics(taskBrain);
    const insights = await analytics.getComprehensiveInsights(period);
    
    return analytics.formatInsightsForClaude(insights);
  } catch (error) {
    return `Unable to fetch productivity insights: ${error.message}`;
  }
}

async function generateWeeklyReport() {
  const insights = await getProductivityInsights('week');
  const currentStatus = await taskBrain.getTaskStatus();
  
  return `## 📊 Weekly Productivity Report

${insights}

### 📈 Current Momentum
- **Active Tasks**: ${currentStatus.total_tasks}
- **Completion Rate**: ${currentStatus.productivity_score}%
- **Today's Progress**: ${currentStatus.completed_today || 0} tasks completed

### 🎯 Week Ahead Preparation
- **High Priority Items**: ${currentStatus.high_priority}
- **Upcoming Deadlines**: ${currentStatus.next_deadlines.length}
- **Recommended Focus**: Schedule complex tasks during peak hours

*Report generated at ${new Date().toLocaleString()}*`;
}
```

## 🔧 Troubleshooting Guide

### Common Issues and Solutions

```javascript
class TaskBrainTroubleshooter {
  static async diagnose(integration) {
    const issues = [];
    const fixes = [];

    try {
      // Test connection
      await integration.healthCheck();
    } catch (error) {
      issues.push('Connection failed');
      fixes.push('Check server URL and network connectivity');
    }

    try {
      // Test authentication
      await integration.getTaskStatus();
    } catch (error) {
      if (error.message.includes('401')) {
        issues.push('Authentication failed');
        fixes.push('Verify API key is correct and active');
      }
    }

    // Check performance
    const metrics = integration.getPerformanceMetrics();
    if (metrics.recent_alerts.some(a => a.type === 'SLOW_REQUEST')) {
      issues.push('Slow API responses');
      fixes.push('Consider upgrading server or optimizing requests');
    }

    return {
      healthy: issues.length === 0,
      issues: issues,
      recommended_fixes: fixes,
      metrics: metrics
    };
  }

  static getCommonSolutions() {
    return {
      'Connection timeout': [
        'Check if TaskBrain server is running',
        'Verify firewall settings',
        'Test with curl or browser',
        'Check DNS resolution'
      ],
      'Invalid API key': [
        'Regenerate API key in TaskBrain settings',
        'Verify key is copied correctly',
        'Check key permissions',
        'Ensure key is not expired'
      ],
      'Rate limit exceeded': [
        'Reduce request frequency',
        'Implement exponential backoff',
        'Cache responses when possible',
        'Contact admin for limit increase'
      ],
      'Webhook signature mismatch': [
        'Verify webhook secret is correct',
        'Check timestamp tolerance',
        'Ensure payload is not modified',
        'Test with webhook testing tool'
      ]
    };
  }
}
```

## 📖 Best Practices Summary

### Production Checklist

- ✅ **Security**: API keys secured, webhook signatures verified, inputs sanitized
- ✅ **Error Handling**: Graceful degradation, retry logic, fallback responses
- ✅ **Performance**: Caching implemented, rate limiting respected, requests optimized  
- ✅ **Monitoring**: Performance tracking, error logging, health checks
- ✅ **Testing**: Comprehensive test suite, integration tests, error scenarios
- ✅ **Documentation**: API examples, troubleshooting guide, setup instructions

### Integration Success Factors

1. **Robust Error Handling**: Always provide fallbacks and graceful degradation
2. **Intelligent Caching**: Cache responses appropriately to reduce API calls
3. **Security First**: Never compromise on authentication and input validation
4. **Performance Monitoring**: Track metrics and optimize continuously
5. **User Experience**: Provide immediate feedback even when APIs are slow
6. **Comprehensive Testing**: Test all scenarios including edge cases

---

## 🎉 Conclusion

This comprehensive API integration guide provides everything needed to create a robust, production-ready integration between Claude and TaskBrain. The implementation includes:

- **Complete TypeScript/JavaScript examples** for all integration scenarios
- **Security best practices** with authentication and input validation
- **Performance optimization** with caching and monitoring
- **Error handling** with graceful fallbacks
- **Real-time features** via webhook integration
- **Mobile optimization** for cross-platform usage
- **Testing framework** for validation and debugging

With this integration, Claude becomes truly task-aware and can provide intelligent, context-sensitive productivity assistance based on real-time data from your complete task management ecosystem! 🚀# 🤖 Claude API Integration Guide

Complete guide for integrating TaskBrain with Claude AI for intelligent task management and real-time productivity assistance.

## 🔗 Quick Integration

### Essential Endpoints for Claude

```javascript
// Real-time task status and overview
GET /api/claude/status

// Create intelligent tasks with AI analysis
POST /api/claude/create_task

// Get contextual recommendations
GET /api/claude/recommendations?context=morning|afternoon|planning

// Fetch smart priorities with AI scoring
GET /api/intelligence/priorities

// Get productivity analytics and insights
GET /api/analytics/productivity?period=day|week|month

// Get completion patterns and optimization data
GET /api/analytics/patterns
```

## 📊 API Response Examples

### `/api/claude/status` Response

```json
{
  "total_tasks": 15,
  "overdue_tasks": 2,
  "today_tasks": 5,
  "high_priority": 3,
  "productivity_score": 78.5,
  "recent_activity": [
    {
      "id": 123,
      "event_type": "completed",
      "content": "Review client proposal",
      "timestamp": "2025-05-28T10:30:00Z",
      "duration": 45
    }
  ],
  "next_deadlines": [
    {
      "id": 124,
      "content": "Submit quarterly report",
      "due_date": "2025-05-29T17:00:00Z",
      "priority": 5,
      "urgency_score": 9.2
    }
  ],
  "current_context": {
    "time_of_day": "morning",
    "energy_level": "high",
    "calendar_busy": false,
    "focus_mode": true,
    "optimal_work_type": "deep_focus"
  }
}
```

### `/api/claude/create_task` Request/Response

**Request:**
```json
{
  "content": "Prepare quarterly business review presentation",
  "description": "Create comprehensive Q4 review for board meeting",
  "due_date": "2025-06-01T14:00:00Z",
  "priority": 4,
  "context_tags": ["presentation", "quarterly", "board"],
  "estimated_duration": 180,
  "source": "claude"
}
```

**Response:**
```json
{
  "task": {
    "id": 125,
    "content": "Prepare quarterly business review presentation",
    "priority": 5,
    "due_date": "2025-06-01T14:00:00Z",
    "estimated_duration": 240,
    "urgency_score": 8.5,
    "intelligence_score": 92.3
  },
  "suggestions": {
    "priority_adjustment": {
      "original": 4,
      "suggested": 5,
      "reasoning": "Board meeting keyword detected, approaching deadline",
      "confidence": 0.92
    },
    "time_estimate": {
      "original": 180,
      "suggested": 240,
      "reasoning": "Presentation creation with board-level requirements typically requires 4 hours",
      "confidence": 0.85
    },
    "breakdown_suggestions": {
      "should_break_down": true,
      "suggested_subtasks": [
        "Research Q4 metrics and performance data",
        "Create presentation outline and structure", 
        "Design slides with charts and visuals",
        "Practice presentation and prepare Q&A"
      ],
      "confidence": 0.88
    },
    "optimal_schedule": {
      "suggested_time": "09:00",
      "optimal_days": ["Tuesday", "Wednesday"],
      "reasoning": "High-energy creative work best suited for morning peak hours",
      "confidence": 0.76
    },
    "dependencies": {
      "detected": [
        {
          "task_content": "Gather Q4 financial reports",
          "relationship": "prerequisite",
          "strength": 0.9
        }
      ],
      "confidence": 0.82
    },
    "auto_apply": true
  },
  "impact_analysis": {
    "dependency_impact": "High - blocks board meeting preparation",
    "team_impact": "Medium - presentation will inform team strategy decisions",
    "deadline_cascade": "Critical - no buffer time available",
    "project_criticality": 9.1
  }
}
```

### `/api/claude/recommendations` Response

```json
{
  "context": "morning",
  "timestamp": "2025-05-28T08:00:00Z",
  "energy_analysis": {
    "predicted_level": 4.2,
    "optimal_duration": "90-120 minutes",
    "work_type": "deep_focus"
  },
  "recommendations": {
    "focus_tasks": [
      {
        "id": 126,
        "content": "Complete API documentation",
        "reasoning": "High complexity task optimal for peak energy",
        "estimated_duration": 120,
        "energy_match": 0.95,
        "priority_score": 8.7
      }
    ],
    "quick_wins": [
      {
        "id": 127,
        "content": "Review and approve pull requests",
        "reasoning": "Low energy requirement, high team impact",
        "estimated_duration": 15,
        "impact": "Unblocks 3 team members",
        "efficiency_score": 9.2
      }
    ],
    "energy_matched": [
      {
        "id": 128,
        "content": "Design system architecture",
        "reasoning": "Creative work optimal for current energy level",
        "energy_level": 5,
        "optimal_time": "current",
        "creativity_factor": 0.88
      }
    ],
    "calendar_aware": [
      {
        "id": 129,
        "content": "Prepare for 10 AM standup",
        "reasoning": "Meeting in 2 hours, preparation needed",
        "time_sensitive": true,
        "buffer_needed": 15,
        "meeting_prep_score": 8.5
      }
    ]
  },
  "productivity_insights": {
    "tip": "Morning focus: Tackle your most challenging task first - your brain is at peak performance",
    "pattern_note": "You complete complex tasks 35% faster during 9-11 AM window",
    "energy_forecast": "High energy until 11 AM, moderate until 2 PM"
  },
  "context_analysis": {
    "optimal_work_type": "deep_focus",
    "avoid_work_type": "administrative_tasks",
    "focus_duration": "90-120 minutes recommended",
    "break_suggestion": "No break needed - sustained energy available"
  }
}
```

## 🔄 Webhook Integration

### Webhook Event Types

TaskBrain sends real-time notifications to Claude via webhooks for these events:

```javascript
// Event types Claude should handle
const WEBHOOK_EVENTS = {
  'task:completed': 'Task marked as complete',
  'task:created': 'New task added to system',
  'task:updated': 'Task properties modified',
  'task:overdue': 'Task has become overdue',
  'deadline:approaching': 'Deadline within threshold',
  'productivity:milestone': 'Productivity goal achieved',
  'pattern:detected': 'New behavioral pattern identified',
  'sync:completed': 'External service sync finished',
  'intelligence:updated': 'AI recommendations refreshed'
};
```

### Webhook Payload Examples

**Task Completed:**
```json
{
  "timestamp": "2025-05-28T10:30:00Z",
  "event_type": "task:completed",
  "event_data": {
    "task_id": 123,
    "content": "Review client proposal",
    "actual_duration": 45,
    "estimated_duration": 60,
    "completion_time": "10:30",
    "energy_level_used": 3,
    "efficiency_ratio": 0.75
  },
  "context": {
    "total_tasks": 14,
    "completed_today": 3,
    "productivity_score": 82.3,
    "completion_streak": 5,
    "momentum_score": 8.7
  },
  "recommendations": [
    "Excellent efficiency! You completed this 25% faster than estimated.",
    "Consider tackling another medium-priority task while momentum is high.",
    "Your morning productivity is 15% above average today."
  ]
}
```

**Deadline Alert:**
```json
{
  "timestamp": "2025-05-28T08:00:00Z",
  "event_type": "deadline:approaching",
  "event_data": {
    "task_id": 124,
    "content": "Submit quarterly report",
    "due_date": "2025-05-29T17:00:00Z",
    "hours_remaining": 33,
    "priority": 5,
    "completion_status": "not_started",
    "estimated_work_remaining": 180
  },
  "urgency": "high",
  "impact_analysis": {
    "business_impact": "critical",
    "team_dependencies": 2,
    "cascade_risk": 0.85
  },
  "recommendations": [
    "Critical task due in 33 hours with no progress - immediate attention needed",
    "Schedule 3-hour focused block today or tomorrow morning",
    "Consider breaking into: data gathering (1h), analysis (1h), writing (1h)"
  ]
}
```

**Pattern Detection:**
```json
{
  "timestamp": "2025-05-28T14:00:00Z",
  "event_type": "pattern:detected",
  "event_data": {
    "pattern_type": "energy_optimization",
    "pattern_description": "Consistently higher task completion rate during 9-11 AM window",
    "confidence": 0.87,
    "sample_size": 23,
    "improvement_potential": "25% productivity increase"
  },
  "actionable_insights": [
    "Schedule complex tasks between 9-11 AM for optimal performance",
    "Move routine tasks to afternoon energy dip (2-3 PM)",
    "Block calendar from 9-11 AM for deep work sessions"
  ]
}
```

## 🔧 Claude Implementation Examples

### Core Integration Class

```javascript
class ClaudeTaskBrainIntegration {
  constructor(config) {
    this.baseUrl = config.baseUrl;
    this.apiKey = config.apiKey;
    this.webhookSecret = config.webhookSecret;
    this.rateLimiter = new RateLimiter();
    this.security = new SecurityManager(config);
    this.cache = new Map();
    this.isInitialized = false;
  }

  async initialize() {
    try {
      // Test connection and validate API key
      await this.testConnection();
      
      // Load user preferences and patterns
      await this.loadUserContext();
      
      // Setup webhook verification
      this.setupWebhookHandler();
      
      this.isInitialized = true;
      console.log('✅ TaskBrain integration initialized successfully');
    } catch (error) {
      console.error('❌ TaskBrain initialization failed:', error);
      throw new Error(`Integration failed: ${error.message}`);
    }
  }

  async getTaskStatus() {
    if (!this.isInitialized) await this.initialize();
    
    try {
      const response = await this.secureApiCall('/api/claude/status');
      
      // Cache the response for 60 seconds
      this.cache.set('status', {
        data: response,
        timestamp: Date.now(),
        ttl: 60000
      });
      
      return this.enrichStatusData(response);
    } catch (error) {
      return this.handleStatusError(error);
    }
  }

  async createIntelligentTask(taskData, options = {}) {
    if (!this.isInitialized) await this.initialize();
    
    try {
      // Enhance task data with context
      const enhancedTask = this.enhanceTaskData(taskData);
      
      const response = await this.secureApiCall('/api/claude/create_task', {
        method: 'POST',
        body: JSON.stringify(enhancedTask)
      });
      
      // Process AI suggestions
      const processedResponse = this.processTaskCreationResponse(response);
      
      // Learn from user preferences if enabled
      if (options.learnPreferences) {
        this.updateUserPreferences(taskData, response);
      }
      
      return processedResponse;
    } catch (error) {
      return this.handleTaskCreationError(error, taskData);
    }
  }

  async getRecommendations(context = 'auto') {
    if (context === 'auto') {
      context = this.determineCurrentContext();
    }
    
    try {
      const response = await this.secureApiCall(
        `/api/claude/recommendations?context=${context}`
      );
      
      return this.personalizeRecommendations(response);
    } catch (error) {
      return this.getFallbackRecommendations(context);
    }
  }

  // Secure API call with retry logic and rate limiting
  async secureApiCall(endpoint, options = {}) {
    // Check rate limits
    const rateLimitCheck = this.rateLimiter.canMakeRequest(endpoint);
    if (!rateLimitCheck.allowed) {
      throw new Error(`Rate limit exceeded. Retry after ${rateLimitCheck.retryAfter}s`);
    }

    const requestId = this.generateRequestId();
    const headers = {
      'Authorization': `Bearer ${this.apiKey}`,
      'Content-Type': 'application/json',
      'X-Request-ID': requestId,
      'X-Claude-Client': 'claude-integration-v1.0',
      ...options.headers
    };

    const maxRetries = 3;
    let attempt = 0;

    while (attempt < maxRetries) {
      try {
        const response = await fetch(`${this.baseUrl}${endpoint}`, {
          ...options,
          headers,
          timeout: 10000
        });

        if (!response.ok) {
          const error = await response.json();
          throw new Error(`API Error ${response.status}: ${error.message}`);
        }

        const data = await response.json();
        this.validateApiResponse(data);
        return data;

      } catch (error) {
        attempt++;
        
        if (attempt >= maxRetries) {
          throw new Error(`Failed after ${maxRetries} attempts: ${error.message}`);
        }

        // Exponential backoff
        await this.delay(Math.pow(2, attempt) * 1000);
      }
    }
  }

  // Webhook handling
  handleWebhook(webhookData) {
    try {
      // Verify webhook signature
      if (!this.verifyWebhookSignature(webhookData)) {
        throw new Error('Invalid webhook signature');
      }

      const { event_type, event_data, context } = webhookData;
      return this.processWebhookEvent(event_type, event_data, context);

    } catch (error) {
      console.error('Webhook processing error:', error);
      return { error: error.message };
    }
  }

  processWebhookEvent(eventType, eventData, context) {
    switch (eventType) {
      case 'task:completed':
        return this.handleTaskCompleted(eventData, context);
      
      case 'task:overdue':
        return this.handleTaskOverdue(eventData, context);
      
      case 'deadline:approaching':
        return this.handleDeadlineApproaching(eventData, context);
      
      case 'productivity:milestone':
        return this.handleProductivityMilestone(eventData, context);
      
      case 'pattern:detected':
        return this.handlePatternDetected(eventData, context);
      
      default:
        return this.handleGenericEvent(eventType, eventData, context);
    }
  }

  handleTaskCompleted(eventData, context) {
    const efficiency = eventData.actual_duration / eventData.estimated_duration;
    let message = `🎉 Excellent work completing "${eventData.content}"!\n\n`;

    // Efficiency analysis
    if (efficiency < 0.8) {
      message += `⚡ You finished 20%+ faster than estimated - your efficiency is improving!\n`;
    } else if (efficiency > 1.2) {
      message += `⏱️ This took longer than expected. Consider breaking similar tasks into smaller pieces.\n`;
    } else {
      message += `🎯 Perfect timing! Right on target with your estimate.\n`;
    }

    // Momentum suggestions
    if (context.completion_streak >= 3) {
      message += `\n🔥 Amazing streak! ${context.completion_streak} tasks completed today.`;
    }

    // Next action suggestion
    const nextAction = this.suggestNextAction(context);
    message += `\n\n${nextAction}`;

    return {
      type: 'success_notification',
      message: message,
      suggested_actions: ['continue_momentum', 'take_break', 'review_priorities']
    };
  }

  // Enhanced error handling with fallbacks
  handleStatusError(error) {
    console.error('Status fetch failed:', error);
    
    // Try to return cached data
    const cached = this.cache.get('status');
    if (cached && (Date.now() - cached.timestamp) < cached.ttl) {
      return {
        ...cached.data,
        status: 'cached',
        message: 'Using recent cached data due to connection issue'
      };
    }

    // Return minimal fallback
    return {
      status: 'unavailable',
      message: 'TaskBrain temporarily unavailable. Manual task management recommended.',
      fallback_mode: true,
      suggestions: [
        'Check your calendar for immediate priorities',
        'Review your todo list manually',
        'Focus on urgent items first'
      ]
    };
  }

  // Utility methods
  determineCurrentContext() {
    const hour = new Date().getHours();
    const day = new Date().getDay();
    
    if (day === 0 || day === 6) return 'weekend';
    if (hour >= 6 && hour <= 11) return 'morning';
    if (hour >= 12 && hour <= 17) return 'afternoon';
    if (hour >= 18 && hour <= 22) return 'evening';
    return 'night';
  }

  enhanceTaskData(taskData) {
    return {
      ...taskData,
      created_via: 'claude',
      creation_context: {
        time: new Date().toISOString(),
        context: this.determineCurrentContext(),
        user_energy: this.predictCurrentEnergyLevel()
      },
      intelligence_requested: true
    };
  }

  generateRequestId() {
    return `claude-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  async delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

### Response Formatting for Claude

```javascript
class ClaudeResponseFormatter {
  constructor(userPreferences = {}) {
    this.preferences = {
      style: userPreferences.style || 'balanced', // concise, detailed, balanced
      emojis: userPreferences.emojis !== false, // true by default
      motivation: userPreferences.motivation || 'supportive',
      detail_level: userPreferences.detail_level || 'medium'
    };
  }

  formatStatusResponse(data) {
    const { total_tasks, overdue_tasks, today_tasks, productivity_score } = data;
    
    let response = this.preferences.emojis ? 
      `## 📊 Your Task Status\n\n` : 
      `## Your Task Status\n\n`;

    // Core metrics
    response += `**Active:** ${total_tasks} tasks | **Overdue:** ${overdue_tasks} | **Due Today:** ${today_tasks}\n`;
    response += `**Productivity Score:** ${productivity_score}% ${this.getTrendIndicator(productivity_score)}\n\n`;

    // Priority recommendations
    if (data.next_deadlines && data.next_deadlines.length > 0) {
      response += this.formatPriorities(data.next_deadlines);
    }

    // Context-aware advice
    response += this.generateContextualAdvice(data);

    return response;
  }

  formatTaskCreationResponse(result) {
    const { task, suggestions } = result;
    let response = this.preferences.emojis ? 
      `## ✅ Task Created Successfully\n\n` : 
      `## Task Created Successfully\n\n`;

    response += `**Task:** ${task.content}\n`;
    response += `**Priority:** ${task.priority}/5`;
    
    if (suggestions.priority_adjustment && suggestions.priority_adjustment.confidence > 0.8) {
      response += ` (AI upgraded from ${suggestions.priority_adjustment.original})`;
    }
    response += `\n`;

    // Time estimation
    if (suggestions.time_estimate) {
      response += `**Duration:** ${suggestions.time_estimate.suggested || task.estimated_duration} minutes\n`;
    }

    // AI insights
    if (this.preferences.detail_level !== 'low') {
      response += `\n### 🧠 AI Analysis:\n`;
      response += this.formatAIInsights(suggestions);
    }

    // Auto-applied changes
    if (suggestions.auto_apply) {
      response += `\n${this.preferences.emojis ? '🤖' : ''} **Auto-Applied:** High-confidence AI suggestions have been applied.\n`;
    }

    return response;
  }

  formatRecommendations(data) {
    const { context, recommendations, productivity_insights } = data;
    
    let response = `## ${this.getContextEmoji(context)} ${this.getContextTitle(context)} Recommendations\n\n`;

    // Focus tasks
    if (recommendations.focus_tasks && recommendations.focus_tasks.length > 0) {
      response += `### 🎯 Priority Focus:\n`;
      recommendations.focus_tasks.slice(0, 3).forEach((task, index) => {
        response += `${index + 1}. **${task.content}** (${task.estimated_duration}min)\n`;
        if (this.preferences.detail_level === 'high') {
          response += `   *${task.reasoning}*\n`;
        }
      });
      response += `\n`;
    }

    // Quick wins
    if (recommendations.quick_wins && recommendations.quick_wins.length > 0) {
      response += `### ⚡ Quick Wins:\n`;
      recommendations.quick_wins.slice(0, 3).forEach(task => {
        response += `• **${task.content}** (${task.estimated_duration}min)\n`;
      });
      response += `\n`;
    }

    // Productivity tip
    if (productivity_insights && productivity_insights.tip) {
      response += `### 💡 Productivity Tip:\n${productivity_insights.tip}\n\n`;
    }

    return response;
  }

  formatWebhookResponse(eventType, eventData, context) {
    switch (eventType) {
      case 'task:completed':
        return this.formatCompletionCelebration(eventData, context);
      
      case 'task:overdue':
        return this.formatOverdueAlert(eventData, context);
      
      case 'deadline:approaching':
        return this.formatDeadlineReminder(eventData, context);
      
      default:
        return this.formatGenericUpdate(eventType, eventData);
    }
  }

  formatCompletionCelebration(eventData, context) {
    const celebration = this.preferences.emojis ? '🎉' : '';
    let message = `${celebration} Great work completing "${eventData.content}"!\n\n`;

    // Efficiency insight
    const efficiency = eventData.actual_duration / eventData.estimated_duration;
    if (efficiency < 0.8) {
      message += `${this.preferences.emojis ? '⚡' : ''} Finished 20% faster than expected!\n`;
    } else if (efficiency > 1.2) {
      message += `${this.preferences.emojis ? '⏱️' : ''} Took longer than estimated - consider smaller chunks next time.\n`;
    }

    // Motivational message
    if (this.preferences.motivation === 'supportive') {
      message += this.generateSupportiveMessage(context);
    }

    return message;
  }

  // Utility methods
  getTrendIndicator(score) {
    if (!this.preferences.emojis) return '';
    return score > 80 ? '📈' : score > 60 ? '📊' : '📉';
  }

  getContextEmoji(context) {
    if (!this.preferences.emojis) return '';
    const emojis = {
      morning: '🌅',
      afternoon: '☀️', 
      evening: '🌆',
      night: '🌙'
    };
    return emojis[context] || '⏰';
  }

  getContextTitle(context) {
    const titles = {
      morning: 'Morning',
      afternoon: 'Afternoon', 
      evening: 'Evening',
      night: 'Late Night'
    };
    return titles[context] || 'Current';
  }
}
```

## 📊 Analytics and Insights Integration

### Productivity Analytics Engine

```javascript
class ProductivityAnalytics {
  constructor(taskBrainIntegration) {
    this.integration = taskBrainIntegration;
    this.cache = new Map();
  }

  async getComprehensiveInsights(period = 'week') {
    try {
      const [productivity, patterns] = await Promise.all([
        this.integration.secureApiCall(`/api/analytics/productivity?period=${period}`),
        this.integration.secureApiCall('/api/analytics/patterns')
      ]);

      return {
        performance: this.analyzePerformance(productivity),
        patterns: this.analyzePatterns(patterns),
        recommendations: this.generateRecommendations(productivity, patterns),
        trends: this.analyzeTrends(productivity),
        goals: this.analyzeGoalProgress(productivity)
      };
    } catch (error) {
      return this.getFallbackInsights(period);
    }
  }

  analyzePerformance(data) {
    const { completion_rate, productivity_score, avg_completion_time } = data;
    
    let performance_level;
    if (productivity_score >= 85) performance_level = 'exceptional';
    else if (productivity_score >= 70) performance_level = 'strong';
    else if (productivity_score >= 55) performance_level = 'moderate';
    else performance_level = 'needs_improvement';

    return {
      level: performance_level,
      score: productivity_score,
      completion_rate: completion_rate,
      efficiency: avg_completion_time,
      strengths: this.identifyStrengths(data),
      improvements: this.identifyImprovements(data)
    };
  }

  analyzePatterns(data) {
    return {
      peak_hours: data.optimal_hours || [],
      productive_days: data.optimal_days || [],
      energy_cycles: this.analyzeEnergyCycles(data),
      task_preferences: this.analyzeTaskPreferences(data),
      completion_patterns: this.analyzeCompletionPatterns(data)
    };
  }

  generateRecommendations(productivity, patterns) {
    const recommendations = [];

    // Schedule optimization
    if (patterns.optimal_hours && patterns.optimal_hours.length > 0) {
      recommendations.push({
        type: 'schedule',
        priority: 'high',
        message: `Schedule complex tasks during your peak hours: ${patterns.optimal_hours.join(', ')}`,
        impact: 'High - 25-40% productivity increase expected'
      });
    }

    // Completion rate improvement
    if (productivity.completion_rate < 70) {
      recommendations.push({
        type: 'workflow',
        priority: 'medium',
        message: 'Consider breaking larger tasks into smaller, manageable pieces',
        impact: 'Medium - improve completion rate by 15-25%'
      });
    }

    // Energy management
    if (patterns.energy_cycles) {
      recommendations.push({
        type: 'energy',
        priority: 'medium',
        message: 'Align task difficulty with your natural energy patterns',
        impact: 'Medium - reduce fatigue and improve focus'
      });
    }

    return recommendations;
  }

  formatInsightsForClaude(insights) {
    let response = `## 📊 Productivity Analysis\n\n`;

    // Performance summary
    response += `### 🎯 Performance Summary\n`;
    response += `**Level:** ${insights.performance.level.replace('_', ' ').toUpperCase()}\n`;
    response += `**Score:** ${insights.performance.score}%\n`;
    response += `**Completion Rate:** ${insights.performance.completion_rate}%\n\n`;

    // Key patterns
    if (insights.patterns.peak_hours.length > 0) {
      response += `### ⚡ Peak Performance\n`;
      response += `**Best Hours:** ${insights.patterns.peak_hours.join(', ')}\n`;
      response += `**Optimal Days:** ${insights.patterns.productive_days.join(', ')}\n\n`;
    }

    // Top recommendations
    if (insights.recommendations.length > 0) {
      response += `### 🚀 Key Recommendations\n`;
      insights.recommendations.slice(0, 3).forEach((rec, index) => {
        response += `${index + 1}. **${rec.message}**\n`;
        response += `   *${rec.impact}*\n\n`;
      });
    }

    return response;
  }
}
```

## 🔐 Security Implementation

### Comprehensive Security Manager

```javascript
class SecurityManager {
  constructor(config) {
    this.apiKey = config.apiKey;
    this.webhookSecret = config.webhookSecret;
    this.encryptionKey = config.encryptionKey;
    this.requestLog = new Map();
  }

  generateSecureHeaders(requestId) {
    return {
      'Authorization': `Bearer ${this.apiKey}`,
      'Content-Type': 'application/json',
      'X-Request-ID': requestId,
      'X-Timestamp': Date.now().toString(),
      'X-Claude-Client': 'claude-integration-v1.0',
      'User-Agent': 'Claude-TaskBrain-Integration/1.0'
    };
  }

  async verifyWebhookSignature(payload, signature) {
    try {
      const expectedSignature = await this.computeHMAC(payload, this.webhookSecret);
      return this.constantTimeCompare(signature, `sha256=${expectedSignature}`);
    } catch (error) {
      console.error('Webhook verification failed:', error);
      return false;
    }
  }

  async computeHMAC(data, secret) {
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    );
    
    const signature = await crypto.subtle.sign(
      'HMAC', 
      key, 
      encoder.encode(data)
    );
    
    return Array.from(new Uint8Array(signature))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');
  }

  constantTimeCompare(a
