# Awl Debugging Plugin

Production error monitoring and debugging powered by PostHog MCP integration.

## What This Plugin Provides

**PostHog MCP Integration**: Error tracking, session replay, and HogQL queries for comprehensive
debugging.

**Commands**:

- `/awl-debugging:debug-production-error` - Investigate errors with stack traces and session replay
- `/awl-debugging:error-impact-analysis` - Assess error severity, scope, and user impact
- `/awl-debugging:trace-analysis` - Session replay analysis and performance debugging

## When to Enable This Plugin

Enable `awl-debugging` when you need to:

- Debug production errors and exceptions
- Investigate error spikes or incidents
- Analyze stack traces and user context
- Assess error impact on users
- Watch session replays of error occurrences
- Run HogQL queries to find error patterns

Disable when you're doing regular development work to save context.

## Installation

```bash
# Install from marketplace
/plugin install awl-debugging@awl

# Enable for current session
/plugin enable awl-debugging

# Disable when done
/plugin disable awl-debugging
```

## Prerequisites

### Environment Variable

Set your PostHog authentication header:

```bash
# Add to ~/.zshrc or ~/.bashrc
export POSTHOG_AUTH_HEADER="Bearer phx_YOUR_PERSONAL_API_KEY"
```

To get your token:

1. Log into PostHog (eu.posthog.com or us.posthog.com)
2. Go to Settings -> Personal API Keys
3. Create a new key with appropriate permissions
4. Use format: `Bearer phx_...`

### PostHog Access

- Must have access to a PostHog project with error tracking enabled
- Recommended: Admin or Member role for full error access

## Usage Examples

### Debug Specific Error

```bash
# Enable plugin
/plugin enable awl-debugging

# Investigate error
/awl-debugging:debug-production-error "TypeError in checkout flow"

# View session replay for context
> "Show me the session replay for the user who hit this error"

# Disable when done
/plugin disable awl-debugging
```

### Assess Error Impact

```bash
/plugin enable awl-debugging

/awl-debugging:error-impact-analysis "payment gateway errors last 7 days"

/plugin disable awl-debugging
```

### Session Replay Investigation

```bash
/plugin enable awl-debugging

/awl-debugging:trace-analysis "What was the user doing before the crash?"

/plugin disable awl-debugging
```

### Combined with Analytics

Enable both plugins for comprehensive incident analysis:

```bash
/plugin enable awl-debugging
/plugin enable awl-analytics

# Analyze error impact on user behavior
> "How many users who hit error X today went on to complete checkout vs abandon?"

/plugin disable awl-debugging awl-analytics
```

## Context Management

**Best practice**: Enable only during incidents/debugging, disable immediately after.

**Check context usage**:

```bash
/context  # Shows MCP token breakdown
```

## Available PostHog Debugging Tools

When enabled, this plugin provides access to:

**Error Tracking**:

- List and filter error tracking issues by status, assignee, date range
- Get detailed error information with stack traces
- View individual error events with full context
- Search errors by message, type, or pattern

**Session Replay**:

- Watch what users did before, during, and after errors
- View console logs and network requests from the session
- Link errors to specific session replays via session ID

**HogQL Queries**:

- Run arbitrary SQL-like queries across all PostHog data
- Correlate errors with feature flags, user segments, pages
- Aggregate error patterns and trends
- Cross-reference errors with analytics data

**Feature Flags**:

- Check which feature flags were active during errors
- Identify errors correlated with specific flag states
- Debug rollout issues

**Annotations**:

- Create annotations for incident timelines
- Track deployment markers relative to error spikes

## Tips

1. **Start with error list** - Use `get_error_tracking_issues` to find relevant errors
2. **Check session replay** - Every error links to a session showing user actions
3. **Use HogQL for patterns** - Query across all data to find correlations
4. **Check feature flags** - Errors may correlate with flag states
5. **Create annotations** - Mark incidents on your PostHog timeline

## Troubleshooting

### "PostHog MCP not available"

- Plugin may not be enabled: `/plugin enable awl-debugging`
- Check environment variable: `echo $POSTHOG_AUTH_HEADER`
- Verify token format: `Bearer phx_...`

### "Authentication failed"

- Token may be expired or invalid
- Check PostHog project access
- Regenerate Personal API Key in PostHog

### "Error tracking not available"

- Enable error tracking in your PostHog project settings
- Ensure your PostHog SDK is configured to capture exceptions

## Related Plugins

- **awl-dev** - Core development workflow (always enabled)
- **awl-analytics** - PostHog product analytics (shares same PostHog backend)
- **awl-meta** - Workflow discovery and creation

## Version

2.0.0

## License

MIT

## Support

Issues: https://github.com/Threading-Needles/awl/issues Docs:
https://github.com/Threading-Needles/awl
