---
description: Debug production errors using PostHog error tracking, session replay, and HogQL
category: debugging
tools: Task, TodoWrite
model: inherit
version: 2.0.0
---

# Debug Production Error

Investigate production errors using PostHog's error tracking, stack traces, session replay, and
HogQL queries.

## Prerequisites

- PostHog MCP must be enabled (this plugin should be enabled)
- Environment variable configured:
  - `POSTHOG_AUTH_HEADER`

## Usage

```bash
/awl-debugging:debug-production-error <error-description-or-query>

Examples:
  /awl-debugging:debug-production-error "TypeError in checkout flow"
  /awl-debugging:debug-production-error "errors from last deployment"
  /awl-debugging:debug-production-error "unhandled exceptions this week"
  /awl-debugging:debug-production-error "payment failures affecting users"
```

## What This Command Does

Uses PostHog MCP tools to:

1. Search for relevant errors via `get_error_tracking_issues`
2. Retrieve error details with stack traces via `get_error_tracking_issue`
3. Get individual error events with context via `get_error_tracking_issue_events`
4. View session replay of affected users via `get_session_replay`
5. Run HogQL queries to find patterns via `run_hogql_query`

## Available PostHog Error Tracking Tools

**Error Search & Analysis**:

- `get_error_tracking_issues` - List issues filtered by status, assignee, date range, search text
- `get_error_tracking_issue` - Get details for a specific issue (stack trace, occurrences, users)
- `get_error_tracking_issue_events` - Get individual error events with full context

**Session Replay**:

- `get_session_replay` - View what the user was doing before, during, and after the error
- Includes console logs, network requests, and user actions

**Custom Queries**:

- `run_hogql_query` - Run arbitrary HogQL (SQL-like) queries across all PostHog data
- Correlate errors with feature flags, user segments, pages, etc.

**Context**:

- `get_feature_flags` - Check which flags were active during errors
- `get_annotations` - View deployment markers relative to error timing

## Example Debugging Sessions

### Investigate Specific Error

```bash
/awl-debugging:debug-production-error "Show me the most recent TypeError with its stack trace and session replay"
```

### Search by Error Type

```bash
/awl-debugging:debug-production-error "Find all unhandled promise rejections in the last 24 hours"
```

### Deployment Issues

```bash
/awl-debugging:debug-production-error "What new errors appeared after today's deployment?"
```

### High-Impact Errors

```bash
/awl-debugging:debug-production-error "Show active errors affecting the most users"
```

## Output Format

Analysis typically includes:

**Error Overview**:

- Error message and type
- Occurrence count and trend
- First seen / last seen
- Number of users and sessions affected

**Stack Trace**:

- Full call stack with source context
- File paths and line numbers
- Source map resolution (when configured)

**Session Replay Context**:

- User actions leading to the error
- Console log output
- Network requests and responses
- Page navigations

**HogQL Pattern Analysis** (when relevant):

- Error correlation with feature flags
- Breakdown by page, browser, or user segment
- Time-series trends

## Advanced Queries

### Correlate with Feature Flags

```bash
/awl-debugging:debug-production-error "Are any errors correlated with the new-checkout feature flag?"
```

### User-Specific

```bash
/awl-debugging:debug-production-error "Show all errors for users on the enterprise plan"
```

### HogQL Investigation

```bash
/awl-debugging:debug-production-error "Run a HogQL query: count exceptions by type in the last 24 hours"
```

## Workflow Integration

### With Session Replay

After finding an error:

```bash
> "Show me the session replay for the most recent occurrence of this error"
```

### With Code Changes

After identifying root cause:

```bash
/awl-dev:create-plan "Fix the TypeError in checkout.ts based on PostHog error analysis"
```

---

**See also**: `/awl-debugging:error-impact-analysis`, `/awl-debugging:trace-analysis`
