# Awl - Claude Code Workspace

[Threading Needles](https://github.com/Threading-Needles)' development workflow for Claude Code, open sourced and packaged as a Claude Code plugin marketplace.

Awl is the workflow we use daily at Threading Needles for AI-assisted development. It's battle-tested on real projects and optimized for efficient, context-aware AI collaboration.

## Tech Stack & Integrations

Awl integrates with your development tools through MCP servers and CLI tools:

### Project Management & Issue Tracking
- **Linear** - Issue tracking, sprint planning, ticket lifecycle (MCP bundled with `awl-dev`, automatic OAuth)
  - `awl-dev`: Core research agents and workflow commands
  - `awl-pm`: Advanced PM workflows (cycle analysis, milestone tracking, backlog grooming)

### Version Control & Code Hosting
- **GitHub** - Pull requests, code review, repository management (CLI via `gh`)
  - `awl-dev`: PR creation, branch management, worktree workflows

### Error Monitoring & Debugging
- **PostHog** - Error tracking, session replay, stack traces, HogQL queries (MCP)
  - `awl-debugging`: PostHog error tracking MCP integration

### Product Analytics
- **PostHog** - User behavior, conversion funnels, feature analytics (MCP)
  - `awl-analytics`: PostHog MCP integration (~40k tokens when enabled)

### Documentation & Code Search
- **Context7** - Library documentation lookup (MCP, ~2k tokens)
  - `awl-dev`: Built-in, always available
- **DeepWiki** - GitHub repository documentation (MCP, ~1.5k tokens)
  - `awl-dev`: Built-in, always available
- **Exa** - Web research and external documentation (API)
  - `awl-dev`: External research agent

### Token Efficiency Strategy

**Why CLI + lightweight MCP?** Most development sessions don't need heavy integrations:

- Start with `awl-dev` (~3.5k tokens): Core workflow + Linear + GitHub
- Enable `awl-analytics` when analyzing user behavior (~+40k tokens)
- Enable `awl-debugging` when investigating production errors (~+20k tokens)
- Disable when done to free context for code and conversation

This keeps your typical session lean while having powerful tools available when needed.

## What's Inside

**Awl** is a 5-plugin system for Claude Code focused on **token efficiency**, **session-aware
MCP management**, and **persistent context** through parallel agent research, structured handoffs,
and shared memory systems.

**awl-dev** (Core - Always enabled)

- 11 research agents (codebase + infrastructure)
- 18 commands covering full dev lifecycle
- Linear MCP bundled (OAuth, no API tokens needed)
- Handoff system for context persistence
- ~3.5k context (lightweight MCPs: DeepWiki, Context7)

**awl-pm** (Optional - Enable for project management)

- Linear-focused project management workflows
- 5 commands: analyze-cycle, analyze-milestone, report-daily, groom-backlog, sync-prs
- Research-first architecture (Haiku for data, Sonnet for analysis)
- 5 specialized agents: linear-research, cycle-analyzer, milestone-analyzer, backlog-analyzer, github-linear-analyzer
- Cycle management and milestone tracking with target date feasibility
- Actionable insights and recommendations (not just data dumps)

**awl-analytics** (Optional - Enable when needed)

- PostHog MCP integration (~40k context)
- Product analytics and user behavior analysis
- Conversion funnels and cohort analysis
- 3 specialized analytics commands

**awl-debugging** (Optional - Enable when needed)

- PostHog error tracking, session replay, and HogQL
- Production error monitoring and debugging
- Stack trace analysis and session replay context
- 3 specialized debugging commands

**awl-meta** (Optional - For advanced users)

- Discover workflows from community repos
- Import and adapt patterns
- Create new workflows

## Quick Setup

```bash
# In Claude Code:
/plugin marketplace add Threading-Needles/awl
/plugin install awl-dev
```

That's it. No setup script, no config file, no API tokens — Linear authenticates via OAuth on first use.

Try it:

```bash
/awl-dev:research-codebase TICKET-123
```

Every workflow command takes a Linear ticket ID as a positional argument. Commands are stateless — no hidden "current ticket" state between runs.

See [QUICKSTART.md](QUICKSTART.md) for details.

## Installation

Alternatively, install plugins manually via Claude Code plugin system:

```bash
# Add the marketplace repository
/plugin marketplace add Threading-Needles/awl

# Install core workflow (required)
/plugin install awl-dev

# Optional: Install PM plugin (Linear project management)
/plugin install awl-pm

# Optional: Install analytics plugin (if you use PostHog)
/plugin install awl-analytics

# Optional: Install debugging plugin (PostHog error tracking)
/plugin install awl-debugging

# Optional: Install meta plugin (workflow discovery)
/plugin install awl-meta
```

### Session-Based MCP Management

Plugins automatically load/unload MCPs when enabled/disabled:

```bash
# Enable PM tools for sprint planning and cycle reviews
/plugin enable awl-pm  # Lightweight CLI-based, minimal context

# Enable analytics when analyzing user behavior
/plugin enable awl-analytics  # Loads PostHog MCP (+40k context)

# Disable when done to free context
/plugin disable awl-analytics  # Unloads PostHog MCP (-40k context)

# Enable debugging for incident response
/plugin enable awl-debugging  # Loads PostHog error tracking MCP

# Can enable multiple plugins simultaneously
/plugin enable awl-pm awl-analytics awl-debugging
```

**Why this matters**: Most development sessions don't need analytics or debugging MCPs. Starting
with just `awl-dev` keeps your context at ~3.5k tokens instead of ~65k, leaving more room for
code and conversation.

### Updating Plugins

Keep your Awl plugins up to date with bug fixes and new features:

```bash
# Update the marketplace to fetch latest from GitHub
claude plugin marketplace update awl

# Restart Claude Code to load updated plugins
# (Exit and reopen, or start a new session)
```

**When to update:**
- 🐛 **Bug fixes**: Patch versions (e.g., 3.0.0 → 3.0.1) - Fix issues like incorrect CLI syntax
- ✨ **New features**: Minor versions (e.g., 3.0.0 → 3.1.0) - New commands or capabilities
- 🔄 **Breaking changes**: Major versions (e.g., 3.0.0 → 4.0.0) - May require configuration updates

**Important:** A restart is required for plugin updates to take effect. Active sessions use the old version until you restart Claude Code.

**Check your versions:**
```bash
# List installed plugins and their versions
/plugin list
```

**Need help?**

- [Installation & Configuration Guide](QUICKSTART.md) - Complete setup, installation, and configuration
- [Claude Code Plugin Guide](https://docs.claude.com/en/docs/claude-code/plugins.md) - Official plugin documentation

## Complete Workflow

```
/awl-dev:research-codebase → /awl-dev:create-plan → /awl-dev:implement-plan → /awl-dev:validate-plan → /awl-dev:create-pr → /awl-dev:merge-pr
```

With handoffs for context persistence:

```
/awl-dev:create-handoff → /awl-dev:resume-handoff
```

Agents proactively monitor context during implementation and will prompt you to create handoffs
before running out of context, creating structured handoff documents that add to persistent memory.

**Learn More:**

- [Agentic Workflow Guide](docs/AGENTIC_WORKFLOW_GUIDE.md) - Complete guide showing research,
  planning, handoff, worktree, implementation, verify, and PR workflows
- [Context Engineering](docs/CONTEXT_ENGINEERING.md) - Token efficiency strategies and context
  management patterns
- [PR Lifecycle](docs/PR_LIFECYCLE.md) - PR creation, review, and merge workflow

## Core Philosophy

### Token Efficiency Through Structured Context

1. **Parallel Agent Research** - Multiple specialized agents research concurrently
2. **Context Compression** - Research compressed into structured summaries
3. **Focused Planning** - Planning agents work with compressed context
4. **Persistent Memory** - Handoffs preserve context across sessions

### MCP-First Integration

Uses the official Linear MCP server for rich Linear integration with structured tool calls.

## Key Features

**Context Persistence**

- Structured handoff documents for context preservation
- Research artifacts saved and referenceable
- Plan documents that persist implementation context

**Token Efficiency**

- Parallel agents compress research before synthesis
- Focused agents for specific tasks
- Context-aware handoff prompts

**Stateless Commands**

- No config files, no hidden state between runs
- Ticket ID and team key passed explicitly as arguments
- Linear MCP authenticates via OAuth on first use

## Requirements

**Core Tools**:

- Claude Code
- Git

**CLI Integrations**:

- `gh` - GitHub CLI (required for PR creation, merge, sync)

**MCP Tools** (bundled with plugins):

- Linear - Built into `awl-dev`
- Context7 & DeepWiki - Built into `awl-dev` (~3.5k tokens)
- PostHog - Built into `awl-analytics` and `awl-debugging`

Run the doctor:

```bash
/awl-dev:doctor
```

## Contributing

We welcome contributions! Open issues for bugs, workflow suggestions, or to share how you've adapted Awl to your needs.

## Documentation

- [Full Documentation](docs/) - Comprehensive guides
- [Quick Start](QUICKSTART.md) - Installation and first steps
- [Usage Guide](docs/USAGE.md) - How to use all features
- [Architecture](CLAUDE.md) - How it's built

## License

MIT - Use it however you want!

---

Built by [Threading Needles](https://github.com/Threading-Needles)
