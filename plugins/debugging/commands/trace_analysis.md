---
description: Analyze session replays and error context using PostHog
category: debugging
tools: Task, TodoWrite
model: inherit
version: 2.0.0
---

# Trace Analysis

Investigate user sessions, error context, and performance using PostHog session replay and HogQL.

## Usage

```bash
/awl-debugging:trace-analysis <session-id-or-query>

Examples:
  /awl-debugging:trace-analysis "session for error issue abc123"
  /awl-debugging:trace-analysis "slow page loads on checkout"
  /awl-debugging:trace-analysis "user journey before crash"
  /awl-debugging:trace-analysis "network errors in payment flow"
```

## What This Analyzes

### Session Replay

- User actions (clicks, navigation, scrolling)
- Console log output during the session
- Network requests and responses
- Page load performance
- Error events within the session

### HogQL Performance Queries

- Page load times across routes
- Slow network requests
- Error rates by page or feature
- User flow bottlenecks

### Error-Session Correlation

- Which sessions had errors
- What happened before each error
- Common patterns across error sessions
- User behavior post-error (did they retry, leave, etc.)

## Example Analyses

### Session Replay for an Error

```bash
/awl-debugging:trace-analysis "Show session replay for the most recent checkout error"
```

### Performance Investigation

```bash
/awl-debugging:trace-analysis "Which pages have the slowest load times this week?"
```

### User Flow Analysis

```bash
/awl-debugging:trace-analysis "What are users doing before they hit the payment error?"
```

### Network Issues

```bash
/awl-debugging:trace-analysis "Find sessions with failed API calls to /api/checkout"
```

## Output Format

Analysis includes:

**Session Overview**:

- Session ID and duration
- User properties
- Pages visited
- Events triggered

**Console & Network**:

```
Console Log:
  [10:45:12] Fetching user profile...
  [10:45:13] Profile loaded
  [10:45:15] Submitting payment...
  [10:45:18] ERROR: PaymentError: Card declined

Network Requests:
  GET /api/user/profile → 200 (120ms)
  POST /api/payment → 402 (2.4s) ⚠️
  GET /api/retry-options → 200 (80ms)
```

**Error Context**:

- What happened in the 30 seconds before the error
- User actions leading to the error
- Any related console warnings

**HogQL Insights**:

- Aggregate patterns across sessions
- Time distribution of issues
- Affected user segments

## Advanced Analysis

### Cross-Session Patterns

```bash
/awl-debugging:trace-analysis "Common user actions before TypeError across all sessions this week"
```

### Feature Flag Correlation

```bash
/awl-debugging:trace-analysis "Compare session error rates between feature flag variants"
```

### Performance Regression

```bash
/awl-debugging:trace-analysis "HogQL: average page load time by day for the last 14 days"
```

## Integration Opportunities

### With Error Debugging

```bash
# Enable debugging plugin
/plugin enable awl-debugging

# Find the error, then trace the session
> "Get error details for the top checkout error, then show its session replay"
```

### With Code Changes

After identifying bottleneck:

```bash
/awl-dev:create-plan "Optimize the slow payment API call identified in session analysis"
```

## Tips

1. **Start with errors** - Find error issues first, then trace their sessions
2. **Check console logs** - Often reveal the root cause faster than stack traces
3. **Look at network requests** - Failed or slow API calls cause many user-facing errors
4. **Use HogQL for aggregates** - Individual sessions show specifics, HogQL shows patterns
5. **Check feature flags** - Session behavior may differ by flag variant

---

**See also**: `/awl-debugging:debug-production-error`, `/awl-debugging:error-impact-analysis`
