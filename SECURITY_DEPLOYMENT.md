# 🔒 TaskBrain Server - Security Implementation & Deployment Guide

## 🚨 **CRITICAL SECURITY UPDATES IMPLEMENTED**

### ✅ **Phase 1 Security Fixes (COMPLETED)**

#### 1. **CORS Policy Fixed**
- **Before:** Open CORS (`origins '*'`) - **SECURITY RISK**
- **After:** Restricted to specific origins via `ALLOWED_ORIGINS` environment variable
- **Default:** `https://claude.ai,http://localhost:3000`

#### 2. **API Authentication Added**
- **New:** API key authentication for all `/api/*` endpoints
- **Enhanced:** Separate Claude API key for `/api/claude/*` endpoints
- **Headers Required:**
  - `Authorization: Bearer your_api_key` for general API access
  - `X-Claude-API-Key: your_claude_key` for Claude endpoints

#### 3. **Webhook Security Enhanced**
- **Todoist:** HMAC-SHA256 signature verification (existing + improved)
- **Linear:** Added HMAC-SHA256 signature verification (NEW)
- **Environment Variables:** Separate webhook secrets for each service

#### 4. **Token Encryption Implemented**
- **New:** AES-256-GCM encryption for OAuth tokens in Redis
- **Security:** Encryption key via `ENCRYPTION_KEY` environment variable
- **Auto-rotation:** Tokens automatically encrypted before storage

---

## 🔧 **REQUIRED ENVIRONMENT VARIABLES**

### **Security Configuration (REQUIRED)**
```bash
# API Authentication
API_KEY=your_secure_random_api_key_32_chars_min
CLAUDE_API_KEY=your_claude_specific_api_key_32_chars_min

# Encryption for stored tokens
ENCRYPTION_KEY=your_base64_encoded_32_byte_encryption_key

# CORS Security
ALLOWED_ORIGINS=https://claude.ai,https://yourdomain.com

# Webhook Security  
TODOIST_WEBHOOK_SECRET=your_todoist_webhook_secret
LINEAR_WEBHOOK_SECRET=your_linear_webhook_secret
```

### **Generate Secure Keys**
```bash
# Generate API keys
openssl rand -hex 32

# Generate encryption key
openssl rand -base64 32

# Generate webhook secrets
openssl rand -hex 32
```

---

## 🚀 **NEW CLAUDE API ENDPOINTS**

### **Enhanced Integration Endpoints**

#### 1. **Full Context Endpoint**
```http
GET /api/claude/full_context
Headers: X-Claude-API-Key: your_claude_key
```
**Returns:** Complete task overview, productivity metrics, calendar context, capacity analysis

#### 2. **Smart Task Creation**
```http
POST /api/claude/smart_create
Headers: X-Claude-API-Key: your_claude_key
Content-Type: application/json

{
  "content": "Prepare quarterly review presentation",
  "priority": 4,
  "energy_level": 5,
  "estimated_duration": 120
}
```
**Returns:** Enhanced AI analysis, optimal scheduling, impact analysis, immediate actions

#### 3. **Bulk Task Creation**
```http
POST /api/claude/bulk_create
Headers: X-Claude-API-Key: your_claude_key
Content-Type: application/json

{
  "tasks": [
    {"content": "Task 1", "priority": 3},
    {"content": "Task 2", "priority": 4}
  ]
}
```

#### 4. **Context-Aware Daily Schedule**
```http
GET /api/claude/context/2024-01-15
Headers: X-Claude-API-Key: your_claude_key
```
**Returns:** Day-specific tasks, calendar events, schedule suggestions, availability windows

#### 5. **Intelligent Batch Rescheduling**
```http
POST /api/claude/reschedule_batch
Headers: X-Claude-API-Key: your_claude_key
Content-Type: application/json

{
  "reschedule_requests": [
    {"task_id": 123, "new_date": "2024-01-16"},
    {"task_id": 124, "new_date": "2024-01-17"}
  ]
}
```

---

## 🔧 **DEPLOYMENT STEPS**

### **1. Update Environment Variables**

Copy the new `.env.example` to `.env` and configure:

```bash
cp .env.example .env
nano .env  # Configure all security variables
```

**CRITICAL:** Generate secure values for all security-related environment variables.

### **2. Restart Services**

```bash
# Development
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.dev.yml up -d

# Production  
docker-compose down
docker-compose up -d
```

### **3. Verify Security Implementation**

Test authentication:
```bash
# Should fail (401 Unauthorized)
curl http://localhost:3000/api/tasks

# Should succeed
curl -H "Authorization: Bearer your_api_key" \
     http://localhost:3000/api/tasks

# Claude endpoint test
curl -H "X-Claude-API-Key: your_claude_key" \
     http://localhost:3000/api/claude/status
```

### **4. Configure Webhook Security**

Update your webhook URLs in external services:

**Todoist:**
- URL: `https://yourdomain.com/webhooks/todoist`
- Secret: Set `TODOIST_WEBHOOK_SECRET` value in Todoist webhook configuration

**Linear:**
- URL: `https://yourdomain.com/webhooks/linear`  
- Secret: Set `LINEAR_WEBHOOK_SECRET` value in Linear webhook configuration

---

## 🤖 **CLAUDE INTEGRATION GUIDE**

### **Authentication Setup**
Claude needs to include the Claude-specific API key:

```javascript
const headers = {
  'X-Claude-API-Key': 'your_claude_specific_api_key',
  'Content-Type': 'application/json'
};
```

### **Recommended Claude Workflow**

1. **Get Full Context:** `GET /api/claude/full_context`
2. **Create Tasks:** `POST /api/claude/smart_create`
3. **Schedule Optimization:** `GET /api/claude/context/{date}`
4. **Bulk Operations:** `POST /api/claude/bulk_create`

### **Example Claude Integration**
```javascript
// Get comprehensive task context
const context = await fetch('/api/claude/full_context', { headers });

// Create intelligent task with analysis
const taskResult = await fetch('/api/claude/smart_create', {
  method: 'POST',
  headers,
  body: JSON.stringify({
    content: 'Prepare client presentation',
    priority: 4,
    energy_level: 5
  })
});

// Get optimal scheduling suggestions
const schedule = await fetch('/api/claude/context/2024-01-15', { headers });
```

---

## 📊 **ENHANCED FEATURES**

### **Input Validation**
- Comprehensive validation for all task data
- Sanitization of string inputs
- Type checking and length limits
- Detailed error messages

### **Error Handling**
- Structured error logging with unique error IDs
- Request context tracking
- Performance monitoring
- Security event logging

### **Token Security**
- AES-256-GCM encryption for OAuth tokens
- Automatic key rotation support
- Secure storage in Redis with TTL

---

## 🔍 **SECURITY MONITORING**

### **Log Monitoring**
Monitor these security events in logs:
- Authentication failures (401 errors)
- Invalid webhook signatures  
- Encryption/decryption failures
- Unusual API access patterns

### **Health Checks**
```bash
# System health
curl http://localhost:3000/health

# API authentication test
curl -H "Authorization: Bearer invalid_key" \
     http://localhost:3000/api/tasks
# Should return 401
```

---

## ⚠️ **BREAKING CHANGES**

### **For Existing Users:**

1. **API Access:** All `/api/*` endpoints now require `Authorization: Bearer {api_key}` header
2. **Claude Access:** All `/api/claude/*` endpoints require `X-Claude-API-Key: {claude_key}` header  
3. **CORS:** Only allowed origins can access the API (configure `ALLOWED_ORIGINS`)
4. **Webhooks:** Linear webhooks now require signature verification

### **Migration Steps:**

1. Set up environment variables with secure keys
2. Update any existing API clients to include authentication headers
3. Configure webhook secrets in external services
4. Test all integrations after deployment

---

## 🎯 **NEXT STEPS**

### **Recommended Additional Security (Future)**
- Rate limiting per API key
- API key rotation mechanism  
- Audit logging for sensitive operations
- Two-factor authentication for admin operations

### **Performance Optimization (Future)**  
- Redis connection pooling
- Database query optimization
- Caching strategy enhancement
- Background job optimization

---

**🔒 Your TaskBrain server is now significantly more secure and optimized for Claude integration!**