# Awl Installation Guide

Complete guide to installing and using Awl for Claude Code.

## Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Service Integration](#service-integration)
- [Core Workflow](#core-workflow)
- [Commands & Agents Reference](#commands--agents-reference)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

```bash
# In Claude Code:
/plugin marketplace add Threading-Needles/awl
/plugin install awl-dev
```

That's it. No setup script, no config file, no API tokens.

Try it:
```bash
/awl-dev:research-codebase TICKET-123
```

Linear will OAuth in your browser on first use.

---

## Installation

### Prerequisites

- **Claude Code** installed and working
- **GitHub CLI** (`gh`) installed and authenticated (required for PR commands)

### Install Awl Plugins

Awl is distributed as a 5-plugin system. Install what you need:

```bash
# Add the marketplace
/plugin marketplace add Threading-Needles/awl

# Core workflow (required)
/plugin install awl-dev

# Optional: Project management (Linear integration)
/plugin install awl-pm

# Optional: Analytics (PostHog integration)
/plugin install awl-analytics

# Optional: Debugging (PostHog error tracking)
/plugin install awl-debugging

# Optional: Workflow discovery
/plugin install awl-meta
```

### Check Your Setup

Run `/awl-dev:doctor` to check what's installed and get guidance on missing dependencies.

### Install Recommended Plugins (Optional)

For the best experience, install these complementary plugins from the Claude Code marketplace:

```bash
# Required for full /awl-dev:implement-plan automation
/plugin install pr-review-toolkit

# Recommended for enhanced development
/plugin install frontend-design
/plugin install feature-dev
/plugin install commit-commands
/plugin install code-review
/plugin install hookify
```

### What You Get

**awl-dev** (Always enabled):
- 11 research agents
- 18 workflow commands
- Linear integration
- Handoff system
- ~3.5k context (lightweight)

**awl-pm** (Enable for project management):
- Cycle tracking, milestone planning
- Backlog grooming, daily standups
- GitHub-Linear sync

**awl-analytics** (Enable when analyzing metrics):
- PostHog MCP integration
- ~40k context when enabled

**awl-debugging** (Enable for incident response):
- PostHog error tracking, session replay, and HogQL
- Shares PostHog MCP with awl-analytics

**awl-meta** (Advanced users):
- Discover and import workflows from community

---

## Service Integration

### Linear (Project Management)

The Linear MCP server (`https://mcp.linear.app/mcp`) is **bundled with the `awl-dev` plugin**.
No separate installation needed.

**First-time setup**: OAuth authentication happens automatically when you first use a Linear
command — Claude Code opens your browser for consent. No API tokens, no config file.

### PostHog (Analytics & Error Tracking)

Bundled with `awl-analytics` and `awl-debugging` plugins. The PostHog MCP server handles its own auth.

### Exa (Web Search)

Used by the `external-research` agent. Configure via the Exa MCP server (separate plugin).

---

## Core Workflow

Awl provides a research → plan → implement → validate → ship workflow.

Every workflow command takes the Linear ticket ID as a positional argument.

### 1. Research Phase

```
/awl-dev:research-codebase TICKET-123
```

This:
- Spawns parallel research agents
- Documents what exists (no critique)
- Saves findings to Linear as a document attached to the ticket

### 2. Planning Phase

```
/awl-dev:create-plan TICKET-123
```

This:
- Queries Linear for research attached to the ticket
- Interactively builds a plan with you
- Saves plan to Linear as a document attached to the ticket

### 3. Implementation Phase

```
/awl-dev:implement-plan TICKET-123
```

This:
- Queries Linear for the plan attached to the ticket
- Implements each phase
- Runs automated tests
- Updates checkboxes

### 4. Validation Phase

```
/awl-dev:validate-plan TICKET-123
```

This:
- Verifies all success criteria
- Runs automated tests
- Documents deviations
- Provides manual testing checklist

### 5. Create PR

```
/awl-dev:create-pr
```

Automatically creates a PR with comprehensive description from research and plan. Ticket is extracted from the branch name (pattern `[A-Z]+-[0-9]+`).

### Context Persistence

**Handoffs** save context between sessions:

```bash
# Save context (always pass the ticket)
/awl-dev:create-handoff TICKET-123

# Resume later
/awl-dev:resume-handoff TICKET-123
```

---

## Commands & Agents Reference

### Common Commands

| Command | Purpose |
|---------|---------|
| `/awl-dev:research-codebase` | Research codebase and save findings |
| `/awl-dev:create-plan` | Interactive planning with research |
| `/awl-dev:implement-plan` | Execute a plan (auto-finds recent) |
| `/awl-dev:validate-plan` | Verify implementation |
| `/awl-dev:create-pr` | Create PR with rich description |
| `/awl-dev:merge-pr` | Merge PR and update Linear |
| `/awl-dev:create-handoff` | Save context for later |
| `/awl-dev:resume-handoff` | Restore previous context |

### PM Commands (awl-pm plugin)

| Command | Purpose |
|---------|---------|
| `/awl-pm:analyze-cycle` | Cycle health report |
| `/awl-pm:analyze-milestone` | Milestone progress |
| `/awl-pm:report-daily` | Daily standup summary |
| `/awl-pm:groom-backlog` | Backlog analysis |
| `/awl-pm:sync-prs` | GitHub-Linear sync |

### Research Agents

| Agent | Purpose |
|-------|---------|
| `@awl-dev:codebase-locator` | Find files by topic |
| `@awl-dev:codebase-analyzer` | Understand implementation |
| `@awl-dev:codebase-pattern-finder` | Find code examples |

**Example**:
```
@awl-dev:codebase-locator find all files related to authentication
```

---

## Troubleshooting

### Commands not showing up

1. Check plugin installation:
   ```bash
   /plugin list
   ```
2. Reinstall if needed:
   ```bash
   /plugin install awl-dev
   ```
3. Restart Claude Code

### Plugin not loading service integration

Check that you've enabled the plugin:
```bash
# Enable PM plugin for Linear
/plugin enable awl-pm

# Enable analytics for PostHog
/plugin enable awl-analytics

# Disable when done to free context
/plugin disable awl-analytics
```

---

## Next Steps

**You're ready!** Start with `/awl-dev:research-codebase` or `/awl-dev:create-plan` in your next Claude Code session.

**Learn more**:
- [USAGE.md](docs/USAGE.md) - Detailed usage guide
- [BEST_PRACTICES.md](docs/BEST_PRACTICES.md) - Workflow patterns
- [PATTERNS.md](docs/PATTERNS.md) - Create custom agents
- [CONTEXT_ENGINEERING.md](docs/CONTEXT_ENGINEERING.md) - Context management theory
- [docs/](docs/) - Full documentation

**Get help**:
- Visit [GitHub repository](https://github.com/Threading-Needles/awl)
- Check documentation in [docs/](docs/)
