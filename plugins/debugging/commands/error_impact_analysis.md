---
description: Analyze the impact and scope of production errors using PostHog
category: debugging
tools: Task, TodoWrite
model: inherit
version: 2.0.0
---

# Error Impact Analysis

Assess the severity, reach, and business impact of production errors using PostHog error tracking
and HogQL analytics.

## Usage

```bash
/awl-debugging:error-impact-analysis <error-or-timeframe>

Examples:
  /awl-debugging:error-impact-analysis "checkout errors last 7 days"
  /awl-debugging:error-impact-analysis "critical errors this week"
  /awl-debugging:error-impact-analysis "impact of recent deployment"
  /awl-debugging:error-impact-analysis "errors affecting premium users"
```

## What This Analyzes

### Quantitative Impact

- Number of occurrences (via `get_error_tracking_issues`)
- Number of users and sessions affected
- Error rate over time (via `run_hogql_query`)
- Breakdown by page, browser, or user segment

### Qualitative Impact

- Error severity based on affected user workflows
- Business function impact (checkout, signup, etc.)
- User experience degradation assessment

### Trend Analysis

- Is it increasing or decreasing? (via HogQL time-series)
- When did it start? (first_seen from error tracking)
- Related to specific deployment? (via `get_annotations`)
- Correlation with feature flags? (via `get_feature_flags`)

## Example Analyses

### Error Category Impact

```bash
/awl-debugging:error-impact-analysis "Overall impact of all payment-related errors this month"
```

### Deployment Health

```bash
/awl-debugging:error-impact-analysis "Compare error rates before and after today's deployment"
```

### User Segment Impact

```bash
/awl-debugging:error-impact-analysis "How are errors affecting enterprise vs free tier users?"
```

### Time-Based Analysis

```bash
/awl-debugging:error-impact-analysis "Error spike analysis for the last 6 hours"
```

## Output Format

Analysis includes:

**Scope**:

- Total occurrences
- Unique users affected
- Unique sessions affected
- Breakdown by page/feature

**Severity Assessment**:

- Error frequency and trend
- User impact score
- Business criticality
- Blocking vs non-blocking

**Trends** (via HogQL):

- Occurrence over time
- Peak times
- Growth rate
- Comparison to baseline

**Feature Flag Correlation**:

- Are errors concentrated in specific flag variants?
- Did a flag rollout coincide with error increase?

**Prioritization**:

- Recommendation on urgency
- Comparison with other active errors
- ROI of fixing

## HogQL Queries Used

This command leverages HogQL for deep analysis:

```sql
-- Error count by type in last 24 hours
SELECT properties.$exception_type, count()
FROM events
WHERE event = '$exception'
  AND timestamp > now() - interval 1 day
GROUP BY properties.$exception_type
ORDER BY count() DESC

-- Error trend over 7 days
SELECT toDate(timestamp) as day, count()
FROM events
WHERE event = '$exception'
  AND timestamp > now() - interval 7 day
GROUP BY day
ORDER BY day

-- Errors by feature flag state
SELECT properties.$feature_flag_response, count()
FROM events
WHERE event = '$exception'
  AND timestamp > now() - interval 7 day
GROUP BY properties.$feature_flag_response
```

## Integration with Analytics

Enable both plugins for deeper impact analysis:

```bash
/plugin enable awl-debugging
/plugin enable awl-analytics

/awl-debugging:error-impact-analysis "How many users who hit error X churned vs users who didn't?"
```

This combines:

- PostHog error tracking (who hit the error)
- PostHog analytics (did they churn, convert, etc.)

## Incident Response Workflow

### 1. Assess Impact

```bash
/awl-debugging:error-impact-analysis "new spike in errors at 3pm"
```

### 2. Determine Severity

Based on output:

- **Critical**: >1000 users, blocking checkout/signup
- **High**: >100 users, degraded experience
- **Medium**: <100 users, minor inconvenience
- **Low**: <10 users, edge case

### 3. Investigate Root Cause

```bash
/awl-debugging:debug-production-error "Get details and session replay for the top impacting error"
```

### 4. Track Resolution

```bash
> "After fix, compare error rates before and after using HogQL"
```

## Tips for Impact Analysis

1. **Consider timeframe** - "last hour" for incidents, "last week" for trends
2. **Segment users** - Impact on paid vs free users may differ
3. **Check feature flags** - Errors may be flag-specific
4. **Use HogQL** - Custom queries for precise impact measurement
5. **Create annotations** - Mark incident start/end on PostHog timeline

---

**See also**: `/awl-debugging:debug-production-error`, `/awl-debugging:trace-analysis`
