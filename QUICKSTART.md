# Awl Installation & Configuration Guide

Complete guide to installing and configuring Awl for Claude Code.

## Table of Contents

- [Quick Start (5 Minutes)](#quick-start-5-minutes)
- [Installation](#installation)
- [Configuration](#configuration)
- [CLAUDE.md Setup](#claudemd-setup)
- [Service Integration](#service-integration)
- [Core Workflow](#core-workflow)
- [Commands & Agents Reference](#commands--agents-reference)
- [Troubleshooting](#troubleshooting)

---

## Quick Start (5 Minutes)

**Download and run setup script:**
```bash
# Download the setup script
curl -O https://raw.githubusercontent.com/Threading-Needles/awl/main/setup-awl.sh
chmod +x setup-awl.sh

# Run it (requires interactive input)
./setup-awl.sh
```

**What this does:**
- Checks/installs prerequisites (jq)
- Creates project configuration
- Prompts for API tokens (Linear, PostHog, etc.)

**Then:**
```bash
# In Claude Code:
/plugin marketplace add Threading-Needles/awl
/plugin install awl-dev

# Restart Claude Code
```

You're ready! Try `/awl-dev:research-codebase` in your next session.

---

## Installation

### Prerequisites

- **Claude Code** installed and working

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

## Configuration

Awl uses a **two-layer configuration system**:

### Setup Configuration

**Unified setup script (recommended):**

```bash
# Download and run
curl -fsSL https://raw.githubusercontent.com/Threading-Needles/awl/main/setup-awl.sh | bash
```

**What you'll be asked:**
1. Project location (existing repo or clone fresh)
2. Project key (defaults to GitHub org name)
3. Ticket prefix (e.g., "ENG", "PROJ")
4. API tokens for integrations (can skip optional ones)

**Result:**
- `.claude/config.json` (committable, no secrets)
- `~/.config/awl/config-{projectKey}.json` (API tokens)

**Idempotent:** Safe to re-run to add/update integrations.

### Layer 1: Project Config (`.claude/config.json`)

This file contains **non-sensitive** project metadata and is **safe to commit** to git.

**Location**: `.claude/config.json` (in your project root)

**Example**:
```json
{
  "awl": {
    "projectKey": "acme",
    "repository": {
      "org": "acme-corp",
      "name": "api"
    },
    "project": {
      "ticketPrefix": "ACME",
      "name": "Acme Corp Project"
    }
  }
}
```

**What goes here**:
- All Awl configuration under the `awl` key
- `awl.projectKey` - Links to your secrets config
- `awl.project.ticketPrefix` - Your Linear/project ticket prefix (e.g., "ENG", "PROJ")
- Project name and metadata

### Layer 2: Secrets Config (`~/.config/awl/`)

This file contains **API tokens and secrets** and is **never committed** to git.

**Location**: `~/.config/awl/config-{projectKey}.json`

**Example** (`~/.config/awl/config-acme.json`):
```json
{
  "awl": {
    "linear": {
      "apiToken": "lin_api_...",
      "teamKey": "ACME",
      "defaultTeam": "ACME"
    },
    "posthog": {
      "apiKey": "phx_...",
      "projectId": "..."
    },
    "exa": {
      "apiKey": "..."
    }
  }
}
```

**What goes here**:
- API tokens
- Auth tokens
- Service credentials

### Switching Between Projects

Working on multiple projects? Just change the `projectKey`:

```json
// .claude/config.json
{
  "awl": {
    "projectKey": "work"  // Change to "personal", "client-a", etc.
  }
}
```

Each project key points to a different secrets file in `~/.config/awl/`.

---

## CLAUDE.md Setup

Add Awl workflow instructions to your project's CLAUDE.md to help Claude Code understand how to work
with your codebase using Linear-driven development.

### Add the Snippet

Copy this section into your project's CLAUDE.md:

```markdown
## Awl Workflow Integration

This project uses [Awl](https://github.com/Threading-Needles/awl) for Linear-driven development
workflows.

### Ticket-Driven Development

Always work with a Linear ticket. The standard workflow is:

/awl-dev:research_codebase PROJ-123 → /awl-dev:create_plan → /awl-dev:implement_plan

Where `PROJ-123` is your Linear ticket ID (replace `PROJ` with your project's ticket prefix).

### Key Commands

| Command | Purpose |
|---------|---------|
| `/awl-dev:research_codebase` | Research codebase and save findings to Linear |
| `/awl-dev:create_plan` | Create implementation plan from research |
| `/awl-dev:implement_plan` | Execute plan with auto-validation and PR creation |
| `/awl-dev:create_handoff` | Save context for later sessions |
| `/awl-dev:resume_handoff` | Resume from saved context |
| `/awl-dev:doctor` | Check Awl setup and dependencies |

### Context Persistence

- All workflow documents (research, plans, handoffs) are stored as Linear documents attached to
  tickets
- Use `/awl-dev:create_handoff` before ending a session to save context
- Use `/awl-dev:resume_handoff PROJ-123` to resume work on a ticket

### Configuration

Project configuration is in `.claude/config.json`. See
[Awl Configuration Guide](https://github.com/Threading-Needles/awl/blob/main/docs/CONFIGURATION.md).
```

### Customize

After adding the snippet:

1. Replace `PROJ` with your actual ticket prefix (e.g., `ENG`, `ACME`)
2. Add any project-specific workflow notes

### Verify

Run `/awl-dev:doctor` to verify your setup - it will show the CLAUDE.md status.

---

## Service Integration

### Linear (Project Management)

The Linear MCP server (`https://mcp.linear.app/mcp`) is **bundled with the `awl-dev` plugin**.
No separate installation needed.

**First-time setup**: OAuth authentication happens automatically when you first use a Linear
command - Claude Code opens your browser for consent. No API tokens needed.

**Configuration**:

Project config (`.claude/config.json`):
```json
{
  "awl": {
    "project": {
      "ticketPrefix": "ENG"
    },
    "linear": {
      "teamKey": "ENG"
    }
  }
}
```

### PostHog (Analytics & Error Tracking)

Secrets config:
```json
{
  "awl": {
    "posthog": {
      "apiKey": "phc_...",
      "projectId": "12345"
    }
  }
}
```

### Exa (Web Search)

Secrets config:
```json
{
  "awl": {
    "exa": {
      "apiKey": "exa_..."
    }
  }
}
```

---

## Core Workflow

Awl provides a research → plan → implement → validate → ship workflow.

### 1. Research Phase

```
/awl-dev:research-codebase
```

Follow prompts to research your codebase. This:
- Spawns parallel research agents
- Documents what exists (no critique)
- Saves findings to Linear as a document attached to the ticket

### 2. Planning Phase

```
/awl-dev:create-plan
```

This:
- Reads research documents
- Interactively builds a plan with you
- Saves plan to Linear as a document attached to the ticket

### 3. Implementation Phase

```
/awl-dev:implement-plan
```

**Note**: If you just created a plan, omit the path - it auto-finds your most recent plan!

This:
- Reads the plan
- Implements each phase
- Runs automated tests
- Updates checkboxes

### 4. Validation Phase

```
/awl-dev:validate-plan
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

Automatically creates a PR with comprehensive description from your research and plan.

### Context Persistence

**Handoffs** save context between sessions:

```bash
# Save context
/awl-dev:create-handoff

# Resume later
/awl-dev:resume-handoff
```

### Workflow Context Auto-Discovery

Awl tracks your workflow via `.claude/.workflow-context.json`:

- `/awl-dev:research-codebase` → `/awl-dev:create-plan` references it
- `/awl-dev:create-plan` → `/awl-dev:implement-plan` auto-finds it
- `/awl-dev:create-handoff` → `/awl-dev:resume-handoff` auto-finds it

**You don't need to specify file paths** - commands remember your work!

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

### Config not being read

**Check**:
1. File exists: `ls .claude/config.json`
2. Valid JSON: `cat .claude/config.json | jq`
3. Correct location: Must be in `.claude/` directory

### Commands still use generic placeholders

Commands use `PROJ-XXX` as placeholders in examples. When you run them, they'll use your configured `ticketPrefix` from `.claude/config.json`.

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
