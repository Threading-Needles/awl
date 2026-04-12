# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## What This Repository Is

This is a **portable collection of Claude Code agents, commands, and workflows** for AI-assisted
development distributed as plugins. It's both:

1. A **source repository** for plugin-based agents and commands
2. A **working installation** that uses its own tools (dogfooding)

The workspace uses a plugin-based architecture where agents and commands are organized in
`plugins/dev/` and `plugins/meta/`, and installed locally via `.claude/` symlinks.

## Key Architecture Concepts

### Two-Layer System

1. **Plugin Source** (`plugins/dev/`, `plugins/meta/`)
   - Canonical definitions of agents and commands
   - Edit these when making changes
   - Organized by plugin type (dev for workflows, meta for creation)

2. **Installation Layer** (`.claude/`)
   - Symlinks to local plugin directories
   - Claude Code reads plugins from here

### Stateless Commands with Linear Documents

Awl commands are **stateless**. Every workflow command takes the Linear ticket ID as a required positional argument. There is **no hidden state** — no config files, no "current ticket" tracking.

```bash
/awl-dev:research-codebase PROJ-123
/awl-dev:create-plan PROJ-123
/awl-dev:implement-plan PROJ-123
```

PR commands extract the ticket from the branch name (pattern `[A-Z]+-[0-9]+`). PM commands take the team key as `$1` (e.g., `/awl-pm:analyze-cycle ENG`).

Workflow documents (research, plans, handoffs, PR descriptions) are stored as **Linear documents** attached to tickets and queried via `mcp__linear__get_issue`:

```
Linear Ticket: PROJ-123
  ├─ Research: OAuth Implementation   ← /awl-dev:research-codebase
  ├─ Plan: OAuth Implementation       ← /awl-dev:create-plan
  ├─ Handoff: Session 2025-01-08      ← /awl-dev:create-handoff
  └─ PR: #456 - Add OAuth Support     ← /awl-dev:describe-pr
```

PM reports (cycles, milestones, daily) are saved to git in `reports/` since they're not tied to single tickets. See `plugins/dev/LINEAR_DOCUMENTS.md` for the full guide.

### Agent Philosophy

All agents follow a **documentarian, not critic** approach:

- Document what EXISTS, not what should exist
- NO suggestions for improvements unless explicitly asked
- NO root cause analysis unless explicitly asked
- NO architecture critiques or quality assessments
- Focus on answering "WHERE is X?" and "HOW does X work?"

This is critical - agents are for understanding codebases, not evaluating them.

### Command Organization

Commands are organized into namespaces for clarity and discoverability:

- **workflow/** - Core research/plan/implement/validate flow
- **dev/** - Development workflow (commit, debug, PR descriptions)
- **linear/** - Linear ticket management and PR lifecycle
- **project/** - Project-level operations (worktrees, updates)
- **handoff/** - Context persistence across sessions
- **meta/** - Workflow discovery, creation, validation

All commands:

- Orchestrate multi-step processes via sub-agents
- Use Linear documents for persistent context
- Are stateless — take ticket/team as positional arguments
- Spawn parallel sub-agents for efficiency

## Common Development Tasks

### Building and Testing

This workspace has no build process - it's markdown files and bash scripts.

**Testing changes:**

1. Edit source files in `plugins/dev/agents/`, `plugins/dev/commands/`, etc.
2. Changes are immediately available (same repo)
3. Restart Claude Code to reload
4. Test by invoking the agent/command

### Distribution and Installation

**Awl is distributed as a Claude Code plugin:**

```bash
# Add to marketplace
/plugin marketplace add Threading-Needles/awl

# Install development workflow plugin
/plugin install awl-dev

# Optional: Install meta/workflow creation plugin
/plugin install awl-meta
```

**For development on Awl itself:**

This repository is both the source and a working installation (dogfooding).

**Plugin Installation (Dogfooding)**:

```bash
# The workspace has symlinks in .claude/plugins/ pointing to the plugin source
ls -la .claude/plugins/
# dev -> ../../plugins/dev
# meta -> ../../plugins/meta
```

This means:

- ✅ Changes to `plugins/dev/` or `plugins/meta/` are immediately available
- ✅ No hardcoded commands/agents in `.claude/` - uses plugin system like users do
- ✅ Restart Claude Code to reload after editing plugins
- ✅ True dogfooding - we use Awl exactly as users do

### Linear Integration (REQUIRED)

The Linear MCP server (`https://mcp.linear.app/mcp`) is bundled in the `awl-dev` plugin's
`.mcp.json` and connects automatically when the plugin is enabled. On first use, Claude Code
opens a browser for OAuth consent. No API tokens needed.

See the `awl-linear-workflow` skill (`plugins/dev/skills/awl-linear-workflow/`) for the state
machine, document conventions, and embedded questions format.

## Directory Structure

```
awl/
├── plugins/                 # Plugin packages distributed via the marketplace
│   ├── dev/                 # Core development workflow (awl-dev)
│   │   ├── agents/          # 9 research agents (codebase, Linear, GitHub, external)
│   │   ├── commands/        # 17 workflow commands (research/plan/implement/PR/etc.)
│   │   ├── skills/          # awl-linear-workflow, awl-pr-lifecycle, awl-conventional-commits
│   │   ├── scripts/         # check-prerequisites.sh, frontmatter-utils.sh
│   │   ├── CLAUDE_MD_SNIPPET.md  # snippet users paste into their own CLAUDE.md
│   │   ├── README.md
│   │   └── .claude-plugin/  # plugin.json, .mcp.json (Linear MCP)
│   ├── pm/                  # Project management (awl-pm)
│   │   ├── agents/          # 6 PM analysis agents (cycle, milestone, initiative, backlog, github-linear, linear-research)
│   │   ├── commands/        # 7 PM commands (analyze/groom/sync/report/update)
│   │   ├── scripts/
│   │   ├── README.md
│   │   └── .claude-plugin/
│   ├── meta/                # Workflow discovery and creation (awl-meta)
│   │   ├── commands/        # discover/import/create/validate-frontmatter
│   │   ├── skills/          # awl-frontmatter
│   │   ├── scripts/
│   │   ├── README.md
│   │   └── .claude-plugin/
│   ├── debugging/           # PostHog error tracking (awl-debugging)
│   │   ├── commands/
│   │   ├── README.md
│   │   └── .claude-plugin/  # plugin.json, .mcp.json (PostHog MCP)
│   └── analytics/           # PostHog product analytics (awl-analytics)
│       ├── commands/
│       ├── README.md
│       └── .claude-plugin/  # plugin.json, .mcp.json (PostHog MCP)
├── docs/                    # Documentation (USAGE, PATTERNS, CONTEXT_ENGINEERING, etc.)
├── reports/                 # PM reports (git-tracked, not in Linear)
├── .claude/                 # Local Claude Code installation
│   └── plugins/             # Symlinks to plugin source (dogfooding)
├── README.md                # Overview and quick start
├── QUICKSTART.md            # 5-minute setup guide
└── CLAUDE.md                # This file
```

## Core Workflows

### Route (Smart Entry Point)

```
/route PROJ-123
```

The router reads the ticket, assesses complexity, and delegates to the right path:

- **One-shot fix**: Simple tickets (small bugs, config changes, typos) → `/one-shot-fix`
- **Full research**: Complex tickets (features, refactors, multi-system changes) → `/research-codebase`

High confidence decisions auto-route immediately. Uncertain decisions ask the user to choose.
Users can always bypass the router by invoking either command directly.

### One-Shot Fix (Quick Path)

```
/one-shot-fix PROJ-123
```

For simple tickets that don't need formal research or planning:

- Reads ticket, quickly assesses what needs to change
- Proposes fix and waits for confirmation (interactive mode)
- Implements fix with validation (build, lint, tests)
- Creates branch, commit, and offers PR creation
- Skips "Research in Progress" and "Plan in Progress" — goes straight to "In Dev"
- Escalates to full workflow if unexpected complexity is found

### Research → Plan → Implement (Full Workflow)

**1. Research Phase:**

```
/awl-dev:research-codebase PROJ-123
> "How does authentication work in the API?"
```

- Spawns parallel sub-agents (locator, analyzer, pattern-finder)
- Documents what exists with file:line references
- Saves to Linear as "Research: ..." document attached to PROJ-123

**2. Planning Phase:**

```
/awl-dev:create-plan PROJ-123
```

- Queries Linear for research attached to PROJ-123
- Interactive planning with user (when in interactive mode)
- Includes automated AND manual success criteria
- Saves to Linear as "Plan: ..." document attached to PROJ-123

**3. Implementation Phase (AUTOMATED):**

```
/awl-dev:implement-plan PROJ-123
```

- Queries Linear for the plan attached to PROJ-123
- Implements each phase sequentially
- Updates checkboxes in Linear document as work completes
- **Auto-validates** (self-healing, creates "Validation: ..." doc)
- **Auto-creates PR** (commits, pushes, creates PR)
- **Auto-reviews** (runs pr-review-toolkit)
- **Auto-remediates** (fixes all review items, max 3 attempts each)
- **Squashes commits** into clean history
- Reports completion with any items needing manual attention

**Output**: Clean PR ready for human review, all documents linked in Linear:
- Research: ...
- Plan: ...
- Validation: ...
- PR: ...

### Parallel Development

Use Claude Code's native worktree support for parallel work:

```bash
claude --worktree feature-name    # Creates isolated worktree
claude -w feature-name            # Short form
```

Worktrees are auto-cleaned if no changes are made. Claude prompts to keep/remove when changes exist.

**Key benefit:** Multiple features in progress, context shared via Linear documents.

### Workflow Discovery

Discover and import workflows from external repos:

```
/awl-meta:discover-workflows
> Research Claude Code repositories for workflow patterns

/awl-meta:import-workflow
> Import workflow from repository X and adapt it

/awl-meta:create-workflow
> Create new agent/command based on discovered patterns
```

## Important Files to Read

When understanding the system:

1. **README.md** - High-level overview and philosophy
2. **docs/USAGE.md** - Comprehensive usage guide with examples
3. **docs/AGENTIC_WORKFLOW_GUIDE.md** - Agent patterns and best practices
4. **plugins/dev/agents/codebase-locator.md** - Example of agent structure
5. **plugins/dev/commands/create_plan.md** - Example of command structure

## Frontmatter Standard

All agents and commands use YAML frontmatter:

**Agents:**

```yaml
---
name: agent-name
description: What this agent does
tools: Grep, Glob, Read
model: inherit
---
```

**Commands:**

```yaml
---
description: What this command does
category: workflow|utility
tools: Read, Write, Task, TodoWrite
model: inherit
version: 1.0.0
---
```

Use `/awl-meta:validate-frontmatter` to check consistency.

## Dependencies

**Required:**

- Claude Code (claude.ai/code)
- Git
- Bash
- Official Linear MCP server (available through Claude Code)

**Optional:**

- GitHub CLI (`gh`) - For PR creation and GitHub operations

**Setup:**

The Linear MCP server is bundled with the `awl-dev` plugin. On first use, Claude Code opens
a browser for OAuth authentication. No API tokens or CLI tools needed.

## Update Strategy

**When improving Awl:**

1. Edit plugin files in `plugins/dev/` or `plugins/meta/`
2. Test locally (symlinks make changes immediately available)
3. Commit to workspace
4. Publish plugin updates to marketplace
5. Users update with `/plugin update awl-dev`

**Plugin Distribution:**

- Agents and commands are bundled in `plugins/dev/` and `plugins/meta/`
- Users get updates via Claude Code plugin system

## Integration Points

### Linear Integration

- `/awl-dev:linear` command for ticket management
- Linear MCP server bundled with `awl-dev`, OAuth on first use

### PM Plugin (awl-pm)

For project management workflows with Linear:

- `/awl-pm:analyze-cycle` - Cycle health report
- `/awl-pm:analyze-milestone` - Milestone progress and target date assessment
- `/awl-pm:report-daily` - Quick daily standup summary
- `/awl-pm:groom-backlog` - Backlog analysis
- `/awl-pm:sync-prs` - GitHub-Linear correlation

**Features**:
- Cycle management with health scoring
- Project milestone tracking toward target dates
- Backlog grooming and cleanup
- GitHub-Linear PR sync

**Setup**: Install with `/plugin install awl-pm`
**Docs**: See `plugins/pm/README.md`
**Architecture**: Research-first (Haiku for data, Sonnet for analysis)
**Philosophy**: All reports provide actionable insights, not just data dumps

### External Research

- External research via `external-research` agent
- Queries GitHub repositories for patterns
- Web search for documentation and best practices

## Architecture Decision Records

Brief records of key architectural decisions made in this project.

### ADR-001: Plugin-Based Distribution

**Decision**: Distribute Awl as Claude Code plugins instead of git clone/install.

**Rationale**:

- Users get updates via `/plugin update awl-dev`
- No manual git pulls or symlink setup
- Plugin marketplace provides discoverability

**Consequences**:

- Plugin structure must be maintained in `plugins/dev/`, `plugins/pm/`, `plugins/meta/`
- Breaking changes require version management
- Users can install only what they need (dev / pm / meta / analytics / debugging)

---

### ADR-002: Linear Documents for Workflow Context

**Decision**: Store workflow documents (research, plans, handoffs, PRs) as Linear documents attached
to tickets instead of filesystem-based storage.

**Rationale**:

- All workflow artifacts are naturally tied to tickets
- Team members can see documents in Linear UI
- No filesystem path management
- Documents automatically shared across worktrees

**Consequences**:

- Requires Linear (via official MCP server) for all workflow commands
- Commands query Linear by ticket ID to find documents
- PM reports still go to git (not ticket-specific)

---

### ADR-003: Stateless Commands

**Decision**: All workflow commands are stateless. The Linear ticket ID is passed as a required positional argument to every command. There is no `.claude/config.json`, no `.workflow-context.json`, no hidden "current ticket" state.

**Rationale**:

- Each stage runs in a clean context, so there's no benefit to persistent state
- Stateful "current ticket" tracking caused bugs (wrong worktree, forgot to reset, etc.)
- The team key can always be derived from the ticket ID; nothing else is load-bearing
- Zero setup: install plugin, pass ticket ID, go
- Branch name acts as natural fallback for PR commands (pattern `[A-Z]+-[0-9]+`)

**Consequences**:

- Every workflow command takes the ticket as `$1`
- PM commands take the team key as `$1` (e.g., `/awl-pm:analyze-cycle ENG`)
- No setup script, no config file to maintain
- `pr-create` / `pr-merge` / `describe-pr` extract the ticket from branch/title
- Linear MCP authenticates via OAuth — no API tokens stored anywhere

## Context Management Principles

Based on Anthropic's context engineering:

1. **Context is precious** - Use specialized agents, not monoliths
2. **Just-in-time loading** - Load context dynamically
3. **Sub-agent architecture** - Parallel research > sequential
4. **Structured persistence** - Save to Linear documents, not conversation memory
5. **Read files fully** - No partial reads of key documents
6. **Wait for agents** - Don't proceed until research completes

See `docs/CONTEXT_ENGINEERING.md` for details.

## Common Patterns

### Spawning Parallel Agents

When researching, spawn multiple agents at once:

```
@awl-dev:codebase-locator find authentication files
@awl-dev:linear-document-locator find research for PROJ-123
@awl-dev:codebase-analyzer analyze auth flow
```

### Reading Files Fully

Always read key documents without limit/offset:

```
Read tool: file_path only, no limit/offset
```

### Using TodoWrite for Planning

Break down complex tasks:

```
TodoWrite:
1. Research existing implementation
2. Design new approach
3. Implement changes
4. Run tests
5. Validate against success criteria
```

### Argument Handling

Commands take the ticket ID (or team key for PM commands) as their first positional argument:

```bash
# Validate the argument
if [[ -z "$1" ]]; then
  echo "Usage: /awl-dev:research-codebase TICKET-123"
  exit 1
fi
TICKET_ID="$1"
```

## Testing and Validation

**Testing agents:**

1. Make changes to `plugins/dev/agents/*.md`
2. Restart Claude Code (symlinks ensure changes are visible)
3. Invoke with `@awl-dev:name task description`
4. Verify output matches expected behavior

**Testing commands:**

1. Make changes to `plugins/dev/commands/*.md` or `plugins/meta/commands/*.md`
2. Restart Claude Code (symlinks ensure changes are visible)
3. Invoke with `/command-name args`
4. Verify workflow executes correctly

**Plugin structure:**

- `plugins/dev/` - Core development workflow commands and research agents
- `plugins/meta/` - Workflow discovery and creation commands

**Validating frontmatter:**

```
/awl-meta:validate-frontmatter
```

**Testing plugin installation:**

```bash
/plugin list
# Should show awl-dev and optionally awl-meta

# Test a command
/awl-dev:research-codebase
```

## Key Principles When Editing

1. **Agents are documentarians** - Never suggest improvements unless asked
2. **Commands are workflows** - Orchestrate, don't implement
3. **Stateless** - Take parameters as positional args, never read config files
4. **Read fully, not partially** - Especially tickets, plans, research
5. **Spawn parallel agents** - Maximize efficiency
6. **Wait for completion** - Don't synthesize partial results
7. **Preserve context** - Save to Linear documents, not just memory

## User CLAUDE.md Snippet

When users install Awl in their projects, they may add a workflow snippet to their project's CLAUDE.md to help Claude Code understand how to use Awl commands.

**For projects using Awl**, add this to your CLAUDE.md:

```markdown
## Awl Workflow Integration

This project uses [Awl](https://github.com/Threading-Needles/awl) for Linear-driven development workflows.

### Ticket-Driven Development

Always work with a Linear ticket. Every workflow command takes the ticket ID as a positional argument:

/awl-dev:research-codebase TICKET-123 → /awl-dev:create-plan TICKET-123 → /awl-dev:implement-plan TICKET-123

### Key Commands

| Command | Purpose |
|---------|---------|
| `/awl-dev:research-codebase TICKET-123` | Research codebase and save findings to Linear |
| `/awl-dev:create-plan TICKET-123` | Create implementation plan from research |
| `/awl-dev:implement-plan TICKET-123` | Execute plan with auto-validation and PR creation |
| `/awl-dev:create-handoff TICKET-123` | Save context for later sessions |
| `/awl-dev:resume-handoff TICKET-123` | Resume from saved context |
| `/awl-dev:doctor` | Check Awl setup and dependencies |

All workflow documents (research, plans, handoffs, PR descriptions) are stored as Linear documents attached to the ticket. There is no local config file or hidden state.
```

## Getting Help

- Check `docs/` for comprehensive guides
- Review `README.md` for philosophy
- Read `QUICKSTART.md` for setup
- Use `/awl-dev:workflow-help` for interactive guidance
- Examine plugin source in `plugins/dev/` and `plugins/meta/`

## Version Control

This workspace tracks:

- Agent definitions
- Command workflows
- Documentation
- PM reports (`reports/` directory)

**Examples in command docs use `TICKET-123` or `PROJ-123` as placeholders.** Real ticket IDs are passed by users at command invocation time — they never live in the source.
