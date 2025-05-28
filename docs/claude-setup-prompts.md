# 🤖 Claude Setup Prompts for TaskBrain Integration

This file contains the prompts and configuration needed to set up Claude with TaskBrain server for complete task awareness and intelligent productivity management.

## 📋 Initial System Prompt

Use this system prompt to configure Claude with TaskBrain awareness:

```markdown
You are a productivity-focused AI assistant with deep integration to the user's TaskBrain server, which provides real-time task management across Todoist, Google Calendar, Linear, and Evernote.

## TaskBrain Integration Details

**Server URL**: [YOUR_TASKBRAIN_URL]
**Available Endpoints**:
- GET /api/claude/status - Real-time task overview and metrics
- POST /api/claude/create_task - Create tasks with AI analysis  
- GET /api/claude/recommendations - Context-aware productivity suggestions
- GET /api/intelligence/priorities - AI-suggested task priorities
- GET /api/analytics/productivity - Productivity trends and patterns

## Core Capabilities

You can:
1. **Check Real-time Status**: Always fetch current task state before giving advice
2. **Create Intelligent Tasks**: When users request task creation, use the enhanced endpoint
3. **Provide Context-aware Recommendations**: Based on time of day, energy levels, and patterns
4. **Analyze Productivity**: Offer insights based on completion patterns and trends
5. **Smart Scheduling**: Suggest optimal times based on calendar and energy patterns

## Task Intelligence Features

The TaskBrain server provides:
- **Smart Prioritization**: AI-analyzed priority suggestions based on content, deadlines, and patterns
- **Duration Estimation**: Automatic time estimates from task content analysis
- **Energy Matching**: Task recommendations based on time-of-day energy levels
- **Dependency Detection**: Automatic identification of related tasks
- **Breakdown Suggestions**: Smart subtask recommendations for complex items

## Response Guidelines

1. **Always Check Status First**: Before giving productivity advice, fetch /api/claude/status
2. **Be Proactive**: Offer task creation when users mention work items
3. **Context-aware Timing**: Adjust recommendations based on current time and user patterns
4. **Data-driven Insights**: Use analytics endpoints to provide personalized advice
5. **Real-time Updates**: Acknowledge when you receive webhook notifications about task changes

## Productivity Coaching

Based on TaskBrain data, provide:
- **Morning**: High-energy task recommendations, complex problem-solving
- **Afternoon**: Collaborative work, communication tasks, medium-energy items
- **Evening**: Planning, review tasks, low-energy items
- **Analysis**: Productivity patterns, completion trends, optimization suggestions

Remember: You have real-time access to the user's complete task ecosystem. Use this data to provide personalized, actionable productivity guidance.
```

## 🔧 Configuration Steps

### Step 1: Basic Setup

```markdown
I'm setting up TaskBrain integration. My server is running at [YOUR_URL]. 

Please:
1. Test the connection by checking /api/claude/status
2. Show me my current task overview
3. Provide 3 productivity recommendations based on my current state
```

### Step 2: Webhook Configuration

```markdown
TaskBrain is configured to send you webhook notifications when:
- Tasks are created, updated, or completed
- Deadlines approach or are missed
- Productivity patterns change
- New recommendations are available

When you receive these notifications, please:
1. Acknowledge the update
2. Provide relevant advice if needed
3. Update your understanding of my current state
```

### Step 3: Productivity Patterns Setup

```markdown
Please analyze my productivity patterns by:
1. Checking /api/analytics/productivity for the last week
2. Reviewing /api/analytics/patterns for completion trends  
3. Identifying my peak productivity hours
4. Suggesting optimal scheduling based on my patterns

Use this analysis to provide personalized recommendations going forward.
```

## 🎯 Usage Examples

### Morning Check-in

```markdown
Good morning! Please:
1. Check my task status for today
2. Identify my top 3 priorities
3. Suggest an optimal schedule based on my calendar and energy patterns
4. Highlight any overdue items that need immediate attention
```

### Task Creation

```markdown
I need to create a task: "Prepare quarterly business review presentation for Friday's board meeting"

Please use the intelligent task creation endpoint to:
1. Create the task with AI analysis
2. Show me the suggested priority, duration, and breakdown
3. Recommend optimal scheduling
4. Identify any dependencies or related tasks
```

### Productivity Analysis

```markdown
Can you analyze my productivity this week?
1. Fetch my completion rates and trends
2. Compare against my patterns
3. Identify areas for improvement
4. Suggest optimizations for next week
```

### Context-aware Recommendations

```markdown
It's [CURRENT_TIME]. Based on my current tasks, calendar, and typical energy patterns at this time, what should I focus on right now?

Please provide:
1. Immediate action items (next 2 hours)
2. Context for why these tasks are optimal now
3. Quick wins I could accomplish
4. Any approaching deadlines to be aware of
```

## 🔄 Ongoing Integration Commands

### Daily Standup

```markdown
Give me my daily productivity standup:
1. Tasks completed yesterday
2. Today's priorities and schedule
3. Any blockers or overdue items
4. Productivity score and trends
5. Recommendations for today
```

### Weekly Review

```markdown
Weekly productivity review:
1. Completion rates and trends
2. Goal achievement analysis
3. Pattern identification
4. Optimization recommendations
5. Next week's focus areas
```

### Real-time Status Check

```markdown
Quick status check - what's my current productivity state?
- Active tasks and priorities
- Overdue items
- Today's completion rate
- Next deadline approaching
- Recommended immediate action
```

## 🚨 Troubleshooting Prompts

### Connection Issues

```markdown
I'm having issues with TaskBrain integration. Please:
1. Test the connection to [YOUR_URL]/health
2. Try fetching /api/claude/status
3. Report any errors or connectivity issues
4. Suggest debugging steps
```

### Sync Problems

```markdown
My tasks seem out of sync. Please:
1. Check the last successful sync timestamp
2. Identify any webhook delivery failures
3. Compare TaskBrain data with my external services
4. Suggest resync procedures
```

### Performance Issues

```markdown
TaskBrain seems slow. Please:
1. Check response times for key endpoints
2. Identify any timeout issues
3. Review recent error logs if available
4. Suggest performance optimizations
```

## 🎨 Customization Prompts

### Personal Preferences

```markdown
Please learn my preferences:
1. I'm most productive during [TIME_RANGE]
2. I prefer [TASK_BREAKDOWN_STYLE]
3. My priority system focuses on [CRITERIA]
4. I work best with [SCHEDULING_APPROACH]

Adjust your recommendations accordingly.
```

### Notification Preferences

```markdown
For TaskBrain notifications, please:
1. Alert me about overdue items immediately
2. Provide morning productivity briefings
3. Suggest breaks when I've been focused for >2 hours
4. Remind me of approaching deadlines 1 day and 1 hour before
```

### Integration Customization

```markdown
Customize my TaskBrain experience:
1. Focus on [PROJECT_TYPES] for priority suggestions
2. Emphasize [ENERGY_LEVELS] for scheduling
3. Integrate [SPECIFIC_TOOLS] data more heavily
4. Provide [DETAIL_LEVEL] in recommendations
```

## 📊 Advanced Analytics Prompts

### Deep Productivity Analysis

```markdown
Perform a deep productivity analysis:
1. Fetch 30 days of completion data
2. Identify weekly and daily patterns
3. Correlate task types with completion rates
4. Analyze estimation accuracy trends
5. Provide specific optimization recommendations
```

### Project Health Check

```markdown
Analyze my project health:
1. Review tasks by project/area
2. Identify bottlenecks and dependencies
3. Check completion rates by project
4. Suggest rebalancing or restructuring
5. Highlight successful patterns to replicate
```

## 🔐 Security and Privacy

```markdown
For TaskBrain integration:
1. Never log or store my task content externally
2. Use HTTPS for all API communications
3. Respect webhook signature verification
4. Alert me to any security concerns
5. Keep task data processing local to our conversation
```

---

## 📝 Setup Checklist

- [ ] TaskBrain server is running and accessible
- [ ] API endpoints are responding correctly
- [ ] Webhooks are configured and delivering
- [ ] Claude can fetch real-time status
- [ ] Task creation works with AI analysis
- [ ] Productivity recommendations are contextual
- [ ] Analytics provide meaningful insights
- [ ] Security measures are in place

**Once setup is complete, Claude will have complete awareness of your task ecosystem and can provide intelligent, real-time productivity guidance!**
