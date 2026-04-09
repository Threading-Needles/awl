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
   - Configuration file (`config.json`)
   - Claude Code reads plugins from here

### Linear Documents System

Workflow documents (research, plans, handoffs, PR descriptions) are stored as **Linear documents**
attached to tickets:

- **Research**: Created by `/awl-dev:research-codebase`, titled "Research: ..."
- **Plans**: Created by `/awl-dev:create-plan`, titled "Plan: ..."
- **Handoffs**: Created by `/awl-dev:create-handoff`, titled "Handoff: ..."
- **PR Descriptions**: Created by `/awl-dev:describe-pr`, titled "PR: ..."

Documents are discovered by querying Linear via `mcp__linear__get_issue` with the ticket ID.

### Workflow State Management

Commands track the current ticket via `.claude/.workflow-context.json`:

**Purpose**: Enable workflow commands to auto-discover documents attached to the current ticket.

**How it works**:

- `/awl-dev:research-codebase PROJ-123` sets ticket → saves research to Linear
- `/awl-dev:create-plan` reads research from Linear → saves plan to Linear
- `/awl-dev:implement-plan` reads plan from Linear → implements phases
- `/awl-dev:create-handoff` saves handoff to Linear
- `/awl-dev:resume-handoff PROJ-123` finds handoff from Linear

**Structure**:

```json
{
  "lastUpdated": "2025-10-26T10:30:00Z",
  "currentTicket": "PROJ-123"
}
```

**Key benefit**: Commands chain together by querying Linear for documents attached to the current
ticket. No file paths to remember.

**Management**: Set via `workflow-context.sh set-ticket`, read via `workflow-context.sh get-ticket`.
Tracked per-worktree (not committed to git).

### Linear Documents Architecture

Awl uses Linear documents attached to tickets for persistent workflow context:

**How It Works:**

```
┌─────────────────────────────────────┐
│  Linear Ticket: PROJ-123            │
│  ├─ Research: OAuth Implementation  │ ← From /awl-dev:research-codebase
│  ├─ Plan: OAuth Implementation      │ ← From /awl-dev:create-plan
│  ├─ Handoff: Session 2025-01-08     │ ← From /awl-dev:create-handoff
│  └─ PR: #456 - Add OAuth Support    │ ← From /awl-dev:describe-pr
└─────────────────────────────────────┘
          │
          ├──→ Queried via: mcp__linear__get_issue(id: PROJ-123)
          │
          ▼
┌─────────────────────────────────────┐
│  .claude/.workflow-context.json     │
│  {                                  │
│    "currentTicket": "PROJ-123"      │ ← Tracks active ticket
│  }                                  │
└─────────────────────────────────────┘
```

**Benefits:**

- All workflow documents attached to the relevant ticket
- Easy to find: query by ticket ID
- Team collaboration: everyone sees same documents
- No file path management
- Documents survive across sessions and worktrees

**Example Flow:**

1. `/awl-dev:research-codebase PROJ-123` sets ticket, creates "Research: ..." document
2. `/awl-dev:create-plan` queries PROJ-123 for research, creates "Plan: ..." document
3. `/awl-dev:implement-plan` queries PROJ-123 for plan, implements phases
4. `/awl-dev:describe-pr` creates "PR: ..." document
5. `/awl-dev:create-handoff` creates "Handoff: ..." document if pausing work

All documents attached to the same ticket for easy discovery.

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
- Are configuration-driven (see `.claude/config.json`)
- Spawn parallel sub-agents for efficiency

## Common Development Tasks

### Building and Testing

This workspace has no build process - it's markdown files and bash scripts.

**Testing changes:**

1. Edit source files in `agents/` or `commands/`
2. Changes are immediately available (same repo)
3. Restart Claude Code to reload
4. Test by invoking the agent/command

### Distribution and Installation

**Awl is distributed as a Claude Code plugin:**

```bash
# Add to marketplace
/plugin marketplace add ralfschimmel/awl

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

### Configuration System

Awl uses a **two-layer config system** to keep secrets out of git:

**Layer 1: Project Config** (`.claude/config.json` - safe to commit):
```json
{
  "projectKey": "acme",
  "project": {
    "ticketPrefix": "ACME",
    "name": "Acme Corp Project"
  },
  "awl": {
    "linear": {
      "teamKey": "ACME"
    }
  }
}
```

**Benefits**:
- ✅ Secrets never in git
- ✅ Multiple projects per machine (work/personal/clients)
- ✅ `.claude/config.json` only has non-sensitive metadata

**Switching projects**: Just update `projectKey` and team settings in `.claude/config.json`

Commands read config to customize behavior per-project.

### Linear Integration (REQUIRED)

Awl **requires** Linear for workflow document storage. This provides:

- 📁 **Persistent context**: Research, plans, handoffs stored as Linear documents
- 🔄 **Team collaboration**: Documents attached to tickets are visible to all
- 🎫 **Ticket-centric**: All workflow artifacts tied to the work they support

**Prerequisites:**

1. Install `awl-dev` plugin (bundles the Linear MCP server automatically)

**Validation:**

The Linear MCP server (`https://mcp.linear.app/mcp`) is bundled in the `awl-dev` plugin's
`.mcp.json` and connects automatically when the plugin is enabled. On first use, Claude Code
opens a browser for OAuth consent. No API tokens needed - authentication is automatic.

**Why Required?**

Awl requires Linear because:
1. Workflow commands chain together via ticket documents (research → plan → implement)
2. Commands auto-find documents by querying the current ticket
3. Team members see the same documents
4. Documents survive across sessions and worktrees

**PM Reports:**

Unlike workflow documents, PM reports (cycles, milestones, daily) are saved to git in `reports/`
directory since they're not tied to single tickets.

See `plugins/dev/LINEAR_DOCUMENTS.md` for comprehensive guide.

## Directory Structure

```
awl/
├── plugins/                 # Plugin packages for distribution
│   ├── dev/                 # Development workflow plugin (awl-dev)
│   │   ├── agents/          # Specialized research agents
│   │   │   ├── codebase-locator.md
│   │   │   ├── codebase-analyzer.md
│   │   │   ├── codebase-pattern-finder.md
│   │   │   ├── linear-document-locator.md  # Find docs attached to tickets
│   │   │   ├── linear-document-analyzer.md # Analyze Linear documents
│   │   │   ├── external-research.md
│   │   │   └── README.md
│   │   ├── commands/        # Core workflow commands
│   │   │   ├── commit.md
│   │   │   ├── debug.md
│   │   │   ├── describe_pr.md
│   │   │   ├── create_plan.md
│   │   │   ├── implement_plan.md
│   │   │   ├── validate_plan.md
│   │   │   └── README.md
│   │   ├── scripts/         # Runtime scripts bundled with plugin
│   │   │   ├── check-prerequisites.sh
│   │   │   └── workflow-context.sh
│   │   ├── LINEAR_DOCUMENTS.md  # Linear documents conventions
│   │   └── plugin.json      # Plugin manifest
│   ├── pm/                  # Project management plugin (awl-pm)
│   │   ├── agents/          # PM analysis agents
│   │   │   ├── cycle-analyzer.md
│   │   │   ├── backlog-analyzer.md
│   │   │   └── github-linear-analyzer.md
│   │   ├── commands/        # PM workflow commands
│   │   │   ├── analyze_cycle.md
│   │   │   ├── analyze_milestone.md
│   │   │   ├── report_daily.md
│   │   │   ├── groom_backlog.md
│   │   │   └── sync_prs.md
│   │   ├── scripts/         # PM utility scripts
│   │   │   └── check-prerequisites.sh
│   │   ├── README.md        # PM plugin documentation
│   │   └── plugin.json      # Plugin manifest
│   └── meta/                # Meta/workflow management plugin (awl-meta)
│       ├── commands/        # Workflow discovery & creation
│       │   ├── create_workflow.md
│       │   ├── discover_workflows.md
│       │   ├── import_workflow.md
│       │   └── validate_frontmatter.md
│       ├── scripts/         # Runtime scripts for meta commands
│       │   └── validate-frontmatter.sh
│       └── plugin.json      # Plugin manifest
├── scripts/                 # One-time setup scripts (not bundled in plugins)
│   └── README.md            # Setup scripts documentation
├── docs/                    # Documentation
│   ├── USAGE.md                  # Comprehensive usage guide
│   ├── BEST_PRACTICES.md
│   ├── PATTERNS.md
│   ├── CONTEXT_ENGINEERING.md
│   ├── CONFIGURATION.md
│   ├── AGENTIC_WORKFLOW_GUIDE.md
│   ├── LINEAR_WORKFLOW_AUTOMATION.md
│   ├── FRONTMATTER_STANDARD.md
│   └── PR_LIFECYCLE.md
├── reports/                 # PM reports (git-tracked, not in Linear)
│   ├── cycles/              # Cycle analysis reports
│   ├── milestones/          # Milestone progress reports
│   ├── daily/               # Daily standup reports
│   ├── backlog/             # Backlog grooming reports
│   └── pr-sync/             # GitHub-Linear sync reports
├── .claude/                 # Local Claude Code installation
│   ├── config.json          # Configuration (generic template values)
│   ├── .workflow-context.json # Workflow state (not committed)
│   └── plugins/             # Symlinks to plugin source (dogfooding)
│       ├── dev -> ../../plugins/dev/
│       └── meta -> ../../plugins/meta/
├── README.md                # Overview and quick start
├── QUICKSTART.md            # 5-minute setup guide
└── CLAUDE.md                # This file
```

## Core Workflows

### Research → Plan → Implement (Full Automation)

**1. Research Phase:**

```
/awl-dev:research-codebase PROJ-123
> "How does authentication work in the API?"
```

- Sets current ticket to PROJ-123
- Spawns parallel sub-agents (locator, analyzer, pattern-finder)
- Documents what exists with file:line references
- Saves to Linear as "Research: ..." document attached to PROJ-123

**2. Planning Phase:**

```
/awl-dev:create-plan
```

- Auto-finds research from Linear (attached to current ticket)
- Interactive planning with user (when in interactive mode)
- Includes automated AND manual success criteria
- Saves to Linear as "Plan: ..." document attached to PROJ-123

**3. Implementation Phase (AUTOMATED):**

```
/awl-dev:implement-plan
```

- Reads plan from Linear (attached to current ticket)
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
3. **docs/CONFIGURATION.md** - How config system works
4. **docs/AGENTIC_WORKFLOW_GUIDE.md** - Agent patterns and best practices
5. **plugins/dev/agents/codebase-locator.md** - Example of agent structure
6. **plugins/dev/commands/create_plan.md** - Example of command structure

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
- Local config (`.claude/config.json`) is never overwritten
- Project-specific customizations are preserved

## Integration Points

### Linear Integration

- `/awl-dev:linear` command for ticket management
- Auto-configures on first use
- Saves config to `.claude/config.json`
- See `docs/LINEAR_WORKFLOW_AUTOMATION.md`

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
- Local customizations (`.claude/config.json`) are preserved

**Consequences**:

- Plugin structure must be maintained in `plugins/dev/` and `plugins/meta/`
- Breaking changes require version management
- Users can install only what they need (dev vs meta plugins)

---

### ADR-002: Linear Documents for Workflow Context

**Decision**: Store workflow documents (research, plans, handoffs, PRs) as Linear documents attached
to tickets instead of filesystem-based storage.

**Rationale**:

- All workflow artifacts are naturally tied to tickets
- Team members can see documents in Linear UI
- No filesystem path management
- Documents automatically shared across worktrees
- Simplified architecture

**Consequences**:

- Requires Linear (via official MCP server) for all workflow commands
- Workflow-context.json only tracks `currentTicket`, not document paths
- Commands query Linear by ticket ID to find documents
- PM reports still go to git (not ticket-specific)

---

### ADR-003: Workflow-Context for Ticket Tracking

**Decision**: Store current ticket in `.claude/.workflow-context.json` for command chaining.

**Rationale**:

- Users shouldn't remember ticket IDs between commands
- `/awl-dev:research-codebase PROJ-123` → `/awl-dev:create-plan` → `/awl-dev:implement-plan` should flow naturally
- Context must be local to each worktree
- Must not contain secrets or be committed to git

**Consequences**:

- Workflow commands set/get ticket via workflow-context.sh
- Documents are discovered by querying Linear for the current ticket
- Context is lost when worktree is deleted (by design)
- Each worktree can work on a different ticket

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

### Configuration Access

Commands access config with:

```bash
CONFIG_FILE=".claude/config.json"
TICKET_PREFIX=$(jq -r '.project.ticketPrefix // "PROJ"' "$CONFIG_FILE")
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

## Deployment and Distribution

**Users install Awl via Claude Code marketplace:**

```bash
/plugin marketplace add ralfschimmel/awl
/plugin install awl-dev
```

**Setting up Linear in a new project:**

1. Install `awl-dev` plugin (bundles Linear MCP server)
2. Configure team in `.claude/config.json`:

```json
{
  "awl": {
    "linear": {
      "teamKey": "YOUR-TEAM"
    }
  }
}
```

**Sharing with team:** Team members see documents in Linear. Each team member installs the Awl
plugin independently. OAuth authentication happens automatically on first use.

## Key Principles When Editing

1. **Agents are documentarians** - Never suggest improvements unless asked
2. **Commands are workflows** - Orchestrate, don't implement
3. **Config drives behavior** - No hardcoded values
4. **Read fully, not partially** - Especially tickets, plans, research
5. **Spawn parallel agents** - Maximize efficiency
6. **Wait for completion** - Don't synthesize partial results
7. **Preserve context** - Save to Linear documents, not just memory
8. **Smart updates** - Merge workspace changes, keep local config

## User CLAUDE.md Snippet

When users install Awl in their projects, they should add a workflow snippet to their project's
CLAUDE.md. This section provides the reference snippet that users copy-paste into their own projects.

**For projects using Awl (not this repository)**, add this to your CLAUDE.md:

```markdown
## Awl Workflow Integration

This project uses [Awl](https://github.com/ralfschimmel/awl) for Linear-driven development
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
[Awl Configuration Guide](https://github.com/ralfschimmel/awl/blob/main/docs/CONFIGURATION.md).
```

**Why this exists here**: This demonstrates the "dogfooding" principle - the Awl repository itself
uses Awl workflows, but this snippet section serves as the reference for users who install Awl in
their projects.

**Progressive Disclosure**: This snippet follows Anthropic's CLAUDE.md best practices - it's minimal
(~30 lines of actual content) and references detailed documentation for users who want more.

See `plugins/dev/docs/CLAUDE_MD_SNIPPET.md` for the full user documentation with customization
instructions.

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
- Scripts
- Configuration templates (generic values)
- PM reports (`reports/` directory)

**Do NOT commit to this workspace:**

- Specific ticket prefixes (keep "PROJ")
- Linear team keys (keep generic)

**Do commit to project repos:**

- Real config values in `.claude/config.json`
- Project-specific customizations
- PM reports in `reports/`
