# 🤖 Claude API Integration Guide

Complete guide for integrating TaskBrain with Claude AI for intelligent task management.

## 🔗 Quick Integration

### Essential Endpoints for Claude

```javascript
// Real-time task status
GET /api/claude/status

// Create intelligent tasks  
POST /api/claude/create_task

// Get contextual recommendations
GET /api/claude/recommendations?context=morning|afternoon|planning

// Fetch smart priorities
GET /api/intelligence/priorities

// Get productivity analytics
GET /api/analytics/productivity?period=day|week|month
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
      "timestamp": "2025-05-28T10:30:00Z"
    }
  ],
  "next_deadlines": [
    {
      "id": 124,
      "content": "Submit quarterly report",
      "due_date": "2025-05-29T17:00:00Z",
      "priority": 5
    }
  ],
  "current_context": {
    "time_of_day": "morning",
    "energy_level": "high",
    "calendar_busy": false,
    "focus_mode": true
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
  "source": "claude"
}
```

**Response:**
```json
{
  "task": {
    "id": 125,
    "content": "Prepare quarterly business review presentation",
    "priority": 4,
    "due_date": "2025-06-01T14:00:00Z",
    "estimated_duration": 180,
    "urgency_score": 8.5
  },
  "suggestions": {
    "priority_adjustment": {
      "suggested": 5,
      "reasoning": "Board meeting keyword detected, approaching deadline",
      "confidence": 0.9
    },
    "time_estimate": {
      "estimate_minutes": 180,
      "confidence": 0.8,
      "reasoning": "Presentation creation typically requires 3 hours"
    },
    "breakdown_suggestions": {
      "should_break_down": true,
      "suggested_subtasks": [
        "Research Q4 metrics and data",
        "Create presentation outline",
        "Design slides and visuals",
        "Practice and rehearse"
      ],
      "confidence": 0.85
    },
    "optimal_schedule": {
      "suggested_time": "09:00",
      "reasoning": "High-energy task best suited for morning",
      "confidence": 0.7
    }
  },
  "impact_analysis": {
    "dependency_impact": "High - blocks board meeting preparation",
    "team_impact": "Medium - presentation will inform team decisions",
    "deadline_cascade": "Critical - no buffer time available"
  }
}
```

### `/api/claude/recommendations` Response

```json
{
  "context": "morning",
  "timestamp": "2025-05-28T08:00:00Z",
  "recommendations": {
    "focus_tasks": [
      {
        "id": 126,
        "content": "Complete API documentation",
        "reasoning": "High complexity task, optimal for peak energy",
        "estimated_duration": 120,
        "energy_match": 0.95
      }
    ],
    "quick_wins": [
      {
        "id": 127,
        "content": "Review and approve pull requests",
        "reasoning": "Low energy requirement, can be done quickly",
        "estimated_duration": 15,
        "impact": "Unblocks team members"
      }
    ],
    "energy_matched": [
      {
        "id": 128,
        "content": "Design system architecture",
        "reasoning": "Creative work optimal for current energy level",
        "energy_level": 5,
        "optimal_time": "current"
      }
    ],
    "calendar_aware": [
      {
        "id": 129,
        "content": "Prepare for 10 AM standup",
        "reasoning": "Meeting in 2 hours, preparation needed",
        "time_sensitive": true,
        "buffer_needed": 15
      }
    ]
  },
  "productivity_tip": "Morning focus: Tackle your most challenging task first - your brain is at peak performance",
  "context_analysis": {
    "optimal_work_type": "deep_focus",
    "avoid_work_type": "administrative",
    "energy_level": "high",
    "focus_duration": "90-120 minutes recommended"
  }
}
```

## 🔄 Webhook Integration

### Webhook Payload Examples

TaskBrain sends these webhooks to Claude:

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
    "energy_level_used": 3
  },
  "context": {
    "total_tasks": 14,
    "completed_today": 3,
    "productivity_score": 82.3,
    "streak": 5
  },
  "recommendations": [
    "Great momentum! Consider tackling another medium-priority task.",
    "Completed 15 minutes faster than estimated - your efficiency is improving."
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
    "completion_status": "not_started"
  },
  "urgency": "high",
  "recommendations": [
    "This critical task is due in 33 hours and hasn't been started.",
    "Consider scheduling 4-6 hours for completion today.",
    "Break down into smaller tasks if needed."
  ]
}
```

## 🎯 Claude Implementation Examples

### Status Check Function

```javascript
async function getTaskStatus() {
  try {
    const response = await fetch(`${TASKBRAIN_URL}/api/claude/status`);
    const data = await response.json();
    
    return {
      summary: `You have ${data.total_tasks} active tasks, ${data.overdue_tasks} overdue, ${data.today_tasks} due today`,
      productivity: `Current productivity score: ${data.productivity_score}%`,
      next_action: data.next_deadlines[0]?.content || "No urgent deadlines",
      recommendations: data.current_context
    };
  } catch (error) {
    return { error: "Unable to fetch task status" };
  }
}
```

### Intelligent Task Creation

```javascript
async function createIntelligentTask(taskData) {
  try {
    const response = await fetch(`${TASKBRAIN_URL}/api/claude/create_task`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        ...taskData,
        source: 'claude',
        created_at: new Date().toISOString()
      })
    });
    
    const result = await response.json();
    
    return {
      task: result.task,
      ai_suggestions: result.suggestions,
      should_auto_apply: result.suggestions.auto_apply,
      breakdown: result.suggestions.breakdown_suggestions,
      optimal_time: result.suggestions.optimal_schedule
    };
  } catch (error) {
    return { error: "Failed to create task" };
  }
}
```

### Context-Aware Recommendations

```javascript
async function getRecommendations(context = 'general') {
  const currentHour = new Date().getHours();
  
  // Determine context based on time if not provided
  if (context === 'general') {
    if (currentHour >= 6 && currentHour <= 11) context = 'morning';
    else if (currentHour >= 12 && currentHour <= 17) context = 'afternoon';
    else context = 'evening';
  }
  
  try {
    const response = await fetch(
      `${TASKBRAIN_URL}/api/claude/recommendations?context=${context}`
    );
    const data = await response.json();
    
    return {
      focus_now: data.recommendations.focus_tasks[0],
      quick_wins: data.recommendations.quick_wins,
      productivity_tip: data.productivity_tip,
      optimal_work: data.context_analysis.optimal_work_type
    };
  } catch (error) {
    return { error: "Unable to fetch recommendations" };
  }
}
```

## 🔧 Error Handling

### Common Error Responses

```json
{
  "error": "Task not found",
  "code": 404,
  "details": "Task with ID 999 does not exist"
}

{
  "error": "Invalid request data",
  "code": 400,
  "details": "Content field is required",
  "validation_errors": ["content: cannot be blank"]
}

{
  "error": "Service unavailable", 
  "code": 503,
}
```
