# Awl - Claude Code Workspace

A development workflow for Claude Code, open sourced and packaged as a Claude Code plugin marketplace.

This is the workspace I use daily for AI-assisted development. It's battle-tested on real projects
and optimized for efficient, context-aware AI collaboration. I'm sharing it so others can use it,
fork it, and contribute ideas back.

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

### Deployment & Infrastructure
- **Railway** - Deployment logs, service health, environment variables (CLI via `railway`)
  - `awl-dev`: Railway research agent for deployment investigation

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

- Start with `awl-dev` (~3.5k tokens): Core workflow + Linear + GitHub + Railway
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

## Quick Setup (5 Minutes)

Get started in 5 minutes with the unified setup script:

```bash
# Download the setup script
curl -O https://raw.githubusercontent.com/Threading-Needles/awl/main/setup-awl.sh
chmod +x setup-awl.sh

# Run it (requires interactive input)
./setup-awl.sh
```

This script will guide you through:
- Prerequisites check and installation (jq, etc.)
- Project configuration (ticket prefix, project name)
- Integration setup (Linear, PostHog, Railway, Exa)

**Then install the plugins:**

```bash
# In Claude Code:
/plugin marketplace add Threading-Needles/awl
/plugin install awl-dev

# Restart Claude Code
```

You're ready! Try `/awl-dev:research-codebase` in your next session.

**Recommended**: Add the Awl workflow snippet to your project's CLAUDE.md. See
[CLAUDE.md Setup](QUICKSTART.md#claudemd-setup) for the copy-paste snippet.

See [QUICKSTART.md](QUICKSTART.md) for detailed setup instructions.

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
- [Linear Workflow Automation](docs/LINEAR_WORKFLOW_AUTOMATION.md) - Linear MCP integration for ticket
  → branch → PR → merge lifecycle

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

**Secure Configuration**

- Template system prevents committing secrets
- `.gitignore` protection for sensitive files
- No hardcoded credentials

## Requirements

**Core Tools**:

- Claude Code
- Git
- jq

**CLI Integrations** (optional but recommended):

- `gh` - GitHub CLI
- `railway` - Railway deployments
**MCP Tools** (bundled with plugins):

- Context7 & DeepWiki - Built into `awl-dev` (~3.5k tokens)
- PostHog - Built into `awl-analytics` and `awl-debugging`

Run the prerequisite check:

```bash
/check_prerequisites
```

## Contributing

**This is my personal workflow workspace**, primarily built for my own development style and
preferences. That said, I'm happy to:

- **Discuss ideas** - Open issues with workflow suggestions or improvements
- **See your forks** - Adapt it to your needs and share what you built
- **Fix bugs** - If something's broken, let me know
- **Learn together** - Share your workflow patterns and approaches

**Important**: I may not accept PRs that change core workflows or add features I don't personally
use, since this is the workspace I rely on daily. But I **love** seeing how others adapt these
patterns to their own needs!

**Best approach**: Fork it, make it yours, and share what you learned. That's how we all get
better!

## Documentation

- [Full Documentation](docs/) - Comprehensive guides
- [Quick Start](QUICKSTART.md) - 5-minute setup
- [Usage Guide](docs/USAGE.md) - How to use all features
- [Commands](COMMANDS_ANALYSIS.md) - Complete command reference
- [Architecture](CLAUDE.md) - How it's built

## License

MIT - Use it however you want!

## Contributing

You're welcome to use Awl as-is, fork it, or adapt the patterns to your own needs. Some decisions are opinionated, so think of it as a starting point rather than a one-size-fits-all solution — take what works, adapt what doesn't.

---

Built by [Threading Needles](https://github.com/Threading-Needles)

Want to chat about workflows, contribute ideas, or share your fork? Open an issue or discussion!
