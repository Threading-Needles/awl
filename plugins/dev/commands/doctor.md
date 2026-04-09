---
description: Check Awl setup and diagnose missing dependencies
category: utility
mode: autonomous
tools: Bash
model: inherit
version: 1.0.0
---

# AWL Doctor

Comprehensive health check for your Awl installation.

## Output Format

Run all checks and output a structured status report:

```
🏥 AWL Doctor - Checking your setup...

## CLI Tools

✅ jq (JSON processor)
✅ gh (GitHub CLI)

## Environment Variables

✅ Linear MCP connected
❌ SENTRY_AUTH_TOKEN is not set
   → Get token: https://sentry.io/settings/api-keys/
   → Set: export SENTRY_AUTH_TOKEN=your_token

## Required Plugins (Manual Verification Needed)

Claude Code does not expose a plugin list API, so you must verify manually.

○ pr-review-toolkit
   Required for: /awl-dev:implement-plan auto-review
   → Verify: Run /pr-review-toolkit:review-pr --help
   → Install: /plugin install pr-review-toolkit

## Recommended Plugins

These plugins enhance your Awl experience:

○ frontend-design - High-quality UI components
  → Install: /plugin install frontend-design
○ feature-dev - Guided feature development
  → Install: /plugin install feature-dev
○ commit-commands - Commit, push, PR shortcuts
  → Install: /plugin install commit-commands
○ code-review - Code review automation
  → Install: /plugin install code-review
○ hookify - Behavior prevention hooks
  → Install: /plugin install hookify
○ plugin-dev - Plugin development tools
  → Install: /plugin install plugin-dev
○ ralph-wiggum - Loop execution patterns
  → Install: /plugin install ralph-wiggum

## Summary

{N} issues found:
1. {issue description}
2. {issue description}

Run the install commands above to fix these issues.
```

## Implementation

### Step 1: Header

Output the header:

```
🏥 AWL Doctor - Checking your setup...
```

### Step 2: Check CLI Tools

```bash
echo ""
echo "## CLI Tools"
echo ""

# Required tools
REQUIRED_TOOLS=("jq:JSON processor:brew install jq" "gh:GitHub CLI:brew install gh")

for tool_spec in "${REQUIRED_TOOLS[@]}"; do
    IFS=: read -r cmd name install <<< "$tool_spec"
    if command -v "$cmd" &>/dev/null; then
        echo "✅ $cmd ($name)"
    else
        echo "❌ $cmd ($name)"
        echo "   → Install: $install"
    fi
done

# Optional tools
OPTIONAL_TOOLS=("sentry-cli:Sentry CLI:curl -sL https://sentry.io/get-cli/ | sh")

for tool_spec in "${OPTIONAL_TOOLS[@]}"; do
    IFS=: read -r cmd name install <<< "$tool_spec"
    if ! command -v "$cmd" &>/dev/null; then
        echo "○ $cmd ($name) - optional"
        echo "   → Install: $install"
    fi
done
```

### Step 3: Check Environment Variables

```bash
echo ""
echo "## Environment Variables"
echo ""

echo "ℹ️  Linear integration uses the official Linear MCP server"
echo "   Verify by running a Linear command (e.g., /awl-dev:linear)"

# Optional env vars
if [[ -z "${SENTRY_AUTH_TOKEN:-}" ]]; then
    echo "○ SENTRY_AUTH_TOKEN (optional, for awl-debugging)"
    echo "   → Get token: https://sentry.io/settings/api-keys/"
fi
```

### Step 4: Check Required Plugins

```bash
echo ""
echo "## Required Plugins (Manual Verification Needed)"
echo ""
echo "Claude Code does not expose a plugin list API, so you must verify manually."
echo ""

# pr-review-toolkit is required for /awl-dev:implement-plan
echo "○ pr-review-toolkit"
echo "   Required for: /awl-dev:implement-plan auto-review"
echo "   → Verify: Run /pr-review-toolkit:review-pr --help"
echo "   → Install: /plugin install pr-review-toolkit"
```

Note: The ○ icon indicates "needs manual verification" rather than confirmed status.

### Step 5: List Recommended Plugins

```bash
echo ""
echo "## Recommended Plugins"
echo ""
echo "These plugins enhance your Awl experience:"
echo ""

RECOMMENDED=(
    "frontend-design:High-quality UI components"
    "feature-dev:Guided feature development"
    "commit-commands:Commit, push, PR shortcuts"
    "code-review:Code review automation"
    "hookify:Behavior prevention hooks"
    "plugin-dev:Plugin development tools"
    "ralph-wiggum:Loop execution patterns"
)

for plugin_spec in "${RECOMMENDED[@]}"; do
    IFS=: read -r name desc <<< "$plugin_spec"
    echo "○ $name - $desc"
    echo "  → Install: /plugin install $name"
done
```

### Step 6: Summary

Count issues found (missing required tools and env vars) and output summary:

```
echo ""
echo "## Summary"
echo ""

if [[ $issue_count -eq 0 ]]; then
    echo "✅ All required dependencies are in place!"
    echo ""
    echo "Recommended: Verify pr-review-toolkit is installed for full /awl-dev:implement-plan automation."
else
    echo "$issue_count issue(s) found:"
    # List each issue
    echo ""
    echo "Run the install commands above to fix these issues."
fi
```

## Quick Install Commands

For convenience, if issues are found, suggest a one-liner where possible:

```
## Quick Fix

Install all recommended plugins at once:

/plugin install pr-review-toolkit
/plugin install frontend-design
/plugin install feature-dev
/plugin install commit-commands
/plugin install code-review
/plugin install hookify
```
