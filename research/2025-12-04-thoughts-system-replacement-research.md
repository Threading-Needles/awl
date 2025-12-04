# Research: Thoughts System Architecture and Linear Documents Replacement Analysis

**Date**: 2025-12-04T17:30:00+01:00
**Researcher**: Claude
**Git Commit**: 9391f2309580b5f227a83332c7b158aa3b5330f1
**Branch**: main
**Repository**: awl

## Research Question

Research the codebase to understand how the thoughts system (from HumanLayer) is currently implemented and used, and what would be needed to replace it with Linear documents. This is research only - no solution proposed.

## Summary

The thoughts system is deeply integrated into Awl as a **three-layer memory architecture** that provides persistent, git-backed document storage across sessions and worktrees. It currently serves as the backbone for all workflow commands, storing research documents, implementation plans, handoffs, PR descriptions, and PM reports.

The system has two main components:
1. **HumanLayer CLI integration** - External CLI tool that manages git-backed document storage with sync capabilities
2. **Workflow-context tracking** - Internal JSON file that tracks recent documents for auto-discovery between commands

Linear offers document capabilities via the Linearis CLI that could potentially replace this system, including full CRUD operations on documents and the ability to attach documents to issues.

## Detailed Findings

### 1. Current Thoughts System Architecture

**What exists**: A three-layer memory architecture documented in `CLAUDE.md:97-147`

The three layers are:

#### Layer 1: Project Configuration (`.claude/config.json`)
- Specifies which HumanLayer config to use (`configName`)
- Contains project-specific settings (ticket prefix, Linear team, etc.)
- Points to the long-term memory repository for this project
- File: `.claude/config.json:8-11` - thoughts section with `user` and `configName`

#### Layer 2: Long-term Memory (HumanLayer thoughts repository)
- Git-backed persistent storage shared across worktrees
- Contains: `shared/research/`, `shared/plans/`, `shared/prs/`, `shared/handoffs/`
- Synced via `humanlayer thoughts sync`
- Survives across sessions and team members
- External to the project repo (symlinked in)

#### Layer 3: Short-term Memory (`.claude/.workflow-context.json`)
- Local to each worktree (not committed to git)
- Contains pointers to recent documents in long-term memory
- Enables command chaining (e.g., `/create-plan` auto-finds recent research)
- Refreshed each session

**Directory Structure Expected**:
```
thoughts/shared/
├── research/          # Research documents
├── plans/             # Implementation plans
├── handoffs/          # Session handoffs
│   ├── general/       # Handoffs without tickets
│   └── PROJ-XXX/      # Handoffs for ticket PROJ-XXX
├── prs/               # PR descriptions
└── reports/           # PM reports
    ├── cycles/        # Cycle analysis reports
    ├── milestones/    # Milestone progress reports
    ├── daily/         # Daily standup reports
    ├── backlog/       # Backlog grooming reports
    └── pr-sync/       # PR-Linear sync reports
```

---

### 2. Components That Reference Thoughts

#### Commands Using Thoughts (17 files)

| Command | File | How It Uses Thoughts |
|---------|------|---------------------|
| `/research-codebase` | `plugins/dev/commands/research_codebase.md` | Validates thoughts; saves to `thoughts/shared/research/`; spawns thoughts-locator/analyzer agents; syncs via humanlayer |
| `/create-plan` | `plugins/dev/commands/create_plan.md` | Validates thoughts; saves to `thoughts/shared/plans/`; references thoughts-locator |
| `/implement-plan` | `plugins/dev/commands/implement_plan.md` | Reads plans from `thoughts/shared/plans/`; creates handoffs on interruption |
| `/create-handoff` | `plugins/dev/commands/create_handoff.md` | Validates thoughts; saves to `thoughts/shared/handoffs/PROJ-XXX/` |
| `/resume-handoff` | `plugins/dev/commands/resume_handoff.md` | Reads from `thoughts/shared/handoffs/`; runs humanlayer sync |
| `/describe-pr` | `plugins/dev/commands/describe_pr.md` | Validates thoughts; saves to `thoughts/shared/prs/` |
| `/merge-pr` | `plugins/dev/commands/merge_pr.md` | Saves post-merge tasks to `thoughts/shared/post_merge_tasks/`; reads PR descriptions |
| `/linear` | `plugins/dev/commands/linear.md` | Creates tickets from thoughts documents; converts thoughts paths to GitHub links |
| `/workflow-help` | `plugins/dev/commands/workflow_help.md` | References thoughts-locator agent |
| `/create-worktree` | `plugins/dev/commands/create_worktree.md` | Initializes thoughts in new worktrees |
| `/pm:analyze-cycle` | `plugins/pm/commands/analyze_cycle.md` | Validates thoughts; saves to `thoughts/shared/reports/cycles/` |
| `/pm:analyze-milestone` | `plugins/pm/commands/analyze_milestone.md` | Validates thoughts; saves to `thoughts/shared/reports/milestones/` |
| `/pm:report-daily` | `plugins/pm/commands/report_daily.md` | Validates thoughts; saves to `thoughts/shared/reports/daily/` |
| `/pm:groom-backlog` | `plugins/pm/commands/groom_backlog.md` | Validates thoughts; saves to `thoughts/shared/reports/backlog/` |
| `/pm:sync-prs` | `plugins/pm/commands/sync_prs.md` | Validates thoughts; saves to `thoughts/shared/reports/pr-sync/` |
| `/discover-workflows` | `plugins/meta/commands/discover_workflows.md` | Saves to `thoughts/shared/workflows/` |
| `/create-workflow` | `plugins/meta/commands/create_workflow.md` | Uses thoughts-analyzer; records to `thoughts/shared/workflows/created.md` |

#### Dedicated Thoughts Agents (2 files)

| Agent | File | Purpose |
|-------|------|---------|
| `thoughts-locator` | `plugins/dev/agents/thoughts-locator.md` | Discovers documents in thoughts/ directory; searches shared/user/global; handles searchable/ path translation |
| `thoughts-analyzer` | `plugins/dev/agents/thoughts-analyzer.md` | Extracts HIGH-VALUE insights from thoughts documents; filters aggressively |

#### Scripts Using Thoughts/HumanLayer (10+ files)

| Script | File | Purpose |
|--------|------|---------|
| `validate-thoughts-setup.sh` | `scripts/validate-thoughts-setup.sh` | Validates `thoughts/shared` exists with required subdirectories |
| `init-project.sh` | `scripts/humanlayer/init-project.sh` | Initializes project with thoughts via `humanlayer thoughts init` |
| `setup-thoughts.sh` | `scripts/humanlayer/setup-thoughts.sh` | Initial HumanLayer thoughts setup |
| `add-client-config` | `scripts/humanlayer/add-client-config` | Creates per-client HumanLayer configs |
| `setup-personal-thoughts.sh` | `scripts/humanlayer/setup-personal-thoughts.sh` | Personal thoughts setup |
| `workflow-context.sh` | `plugins/dev/scripts/workflow-context.sh` | Manages `.workflow-context.json` state |
| `update-workflow-context.sh` | `plugins/dev/hooks/update-workflow-context.sh` | Hook that auto-tracks document writes |
| `create-worktree.sh` | `plugins/dev/scripts/create-worktree.sh` | Initializes thoughts in new worktrees |
| `check-prerequisites.sh` | `plugins/dev/scripts/check-prerequisites.sh` | Lists humanlayer as prerequisite |

---

### 3. Workflow-Context System Details

**What exists**: Auto-tracking system for document discovery between commands

**Primary Files**:
- `plugins/dev/scripts/workflow-context.sh:1-99` - Main utility script
- `plugins/dev/hooks/update-workflow-context.sh:1-73` - Hook that triggers on file writes
- `plugins/dev/hooks.toml:1-116` - Defines 8 hooks (Write + Edit for 4 document types)
- `.claude/.workflow-context.json` - State file (not committed)

**How It Works**:

1. **Hooks** watch for Write/Edit on `thoughts/shared/(research|plans|handoffs|prs)/*`
2. **Hook script** extracts document type and ticket from path
3. **workflow-context.sh** updates JSON state with document path
4. **Commands** call `workflow-context.sh recent <type>` to find recent documents

**JSON Structure** (`.claude/.workflow-context.json`):
```json
{
  "lastUpdated": "2025-10-28T22:30:00Z",
  "currentTicket": "PROJ-123",
  "mostRecentDocument": {
    "type": "research",
    "path": "thoughts/shared/research/2025-10-28-PROJ-123-auth.md",
    "created": "2025-10-28T22:30:00Z",
    "ticket": "PROJ-123"
  },
  "workflow": {
    "research": [...],
    "plans": [...],
    "handoffs": [...],
    "prs": []
  }
}
```

**Operations Available**:
- `init` - Initialize context file
- `add <type> <path> <ticket>` - Add document to tracking
- `recent <type>` - Get most recent document of type
- `most-recent` - Get most recent document (any type)
- `ticket <ticket>` - Get all documents for a ticket

---

### 4. HumanLayer CLI Integration

**What exists**: External CLI dependency for git-backed document persistence

**CLI Commands Used**:
- `humanlayer thoughts init` - Initialize thoughts for a project
- `humanlayer thoughts sync` - Sync documents (git-backed)
- `humanlayer thoughts status` - Check sync status
- `humanlayer config add` - Add named configurations

**Config Paths**:
- `~/.config/humanlayer/config.json` - Default config
- `~/.config/humanlayer/config-{name}.json` - Named configs (per-project)
- `~/.humanlayer/` - Runtime data (logs, daemon.db, daemon.sock)

**Installation Methods Documented**:
- `pip install humanlayer`
- `pipx install humanlayer`
- `brew install humanlayer/tap/humanlayer`
- `npm install -g @humanlayer/cli`

**Key Behavior**:
- Creates `thoughts/` as symlink to external git repo
- Enables sharing across worktrees
- Provides team collaboration via git
- Sync command commits and pushes changes

---

### 5. Linear Document Capabilities (via Linearis CLI)

**What exists**: Full CRUD operations on Linear documents

**Available Commands**:
```
linearis documents create [options]    - Create a new document
linearis documents update <docId>      - Update existing document
linearis documents read <docId>        - Read a document
linearis documents list [options]      - List documents
linearis documents delete <docId>      - Delete (trash) a document
```

**Create Options**:
- `--title <title>` - Document title
- `--content <content>` - Document content (markdown)
- `--project <project>` - Project name or ID
- `--team <team>` - Team key or name
- `--icon <icon>` - Document icon
- `--color <color>` - Icon color
- `--attach-to <issue>` - Attach document to issue (e.g., ABC-123)

**Attachment Operations**:
```
linearis attachments create [options]  - Create attachment on issue
linearis attachments list [options]    - List attachments on issue
linearis attachments delete <id>       - Delete attachment
```

**Attachment Create Options**:
- `--issue <issue>` - Issue identifier (e.g., ABC-123)
- `--url <url>` - URL to attach
- `--title <title>` - Attachment title
- `--subtitle <subtitle>` - Attachment subtitle
- `--comment <comment>` - Add comment with attachment (markdown)
- `--icon-url <iconUrl>` - Icon URL

---

### 6. Key Integration Points to Consider

**Document Types Currently Stored**:

| Type | Path | Created By | Purpose |
|------|------|------------|---------|
| Research | `thoughts/shared/research/` | `/research-codebase` | Codebase analysis findings |
| Plans | `thoughts/shared/plans/` | `/create-plan` | Implementation plans |
| Handoffs | `thoughts/shared/handoffs/` | `/create-handoff` | Session context transfer |
| PR Descriptions | `thoughts/shared/prs/` | `/describe-pr` | PR documentation |
| Cycle Reports | `thoughts/shared/reports/cycles/` | `/pm:analyze-cycle` | Sprint health |
| Milestone Reports | `thoughts/shared/reports/milestones/` | `/pm:analyze-milestone` | Milestone progress |
| Daily Reports | `thoughts/shared/reports/daily/` | `/pm:report-daily` | Standup summaries |
| Backlog Reports | `thoughts/shared/reports/backlog/` | `/pm:groom-backlog` | Backlog analysis |
| PR Sync Reports | `thoughts/shared/reports/pr-sync/` | `/pm:sync-prs` | GitHub-Linear correlation |
| Workflows | `thoughts/shared/workflows/` | `/discover-workflows` | Workflow patterns |

**Naming Conventions**:
- Research: `YYYY-MM-DD-PROJ-XXX-description.md` or `YYYY-MM-DD-description.md`
- Plans: `YYYY-MM-DD-PROJ-XXXX-description.md`
- Handoffs: `PROJ-XXX/YYYY-MM-DD_HH-MM-SS_description.md`
- Reports: `YYYY-MM-DD-cycle-N-status.md` (varies by type)

**Ticket Extraction Pattern**:
```bash
if [[ "$FILENAME" =~ ([A-Z]+-[0-9]+) ]]; then
  TICKET="${BASH_REMATCH[1]}"
fi
```

---

### 7. Documentation Files Referencing Thoughts

| File | Content |
|------|---------|
| `CLAUDE.md` | Three-layer memory architecture, ADRs for thoughts decisions |
| `docs/THOUGHTS_SETUP.md` | Setup guide, troubleshooting |
| `docs/CONFIGURATION.md.old` | Per-project HumanLayer config |
| `docs/MULTI_CONFIG_GUIDE.md` | Multi-client setup |
| `docs/HUMANLAYER_COMMANDS_ANALYSIS.md` | HumanLayer command analysis |
| `README.md` | Lists HumanLayer as dependency |
| `QUICKSTART.md` | Installation instructions |
| `plugins/dev/WORKFLOW_CONTEXT.md` | Complete workflow-context guide |

---

## Architecture Documentation

### Current Data Flow

```
User invokes command (e.g., /research-codebase)
       ↓
Command validates thoughts system exists
       ↓
Command performs work, generates document
       ↓
Document written to thoughts/shared/{type}/
       ↓
Claude Code hook fires (PostToolUse on Write)
       ↓
update-workflow-context.sh extracts metadata
       ↓
workflow-context.sh updates .workflow-context.json
       ↓
User syncs: humanlayer thoughts sync
       ↓
Documents committed to external git repo

Later:
User invokes next command (e.g., /create-plan)
       ↓
Command calls workflow-context.sh recent research
       ↓
Returns path to recent research document
       ↓
Command offers to use it as context
```

### Current Patterns

**Pattern 1: Prerequisite Validation**
All commands start with:
```bash
if [[ ! -d "thoughts/shared" ]]; then
  echo "ERROR: Thoughts system not configured"
  exit 1
fi
```

**Pattern 2: Document Writing**
Commands write to specific paths:
```bash
REPORT_FILE="thoughts/shared/reports/cycles/$(date +%Y-%m-%d)-cycle-${N}-status.md"
cat > "$REPORT_FILE" << EOF
...content...
EOF
```

**Pattern 3: Workflow Context Tracking**
After writing, commands update context:
```bash
"${SCRIPT_DIR}/workflow-context.sh" add reports "$REPORT_FILE" "${TICKET_ID:-null}"
```

**Pattern 4: Agent Spawning**
Commands spawn `thoughts-locator` and `thoughts-analyzer` agents to search/analyze documents.

---

## Code References

### Core Implementation Files

- `.claude/config.json:8-11` - Thoughts configuration section
- `plugins/dev/scripts/workflow-context.sh:1-99` - Context management utility
- `plugins/dev/hooks/update-workflow-context.sh:1-73` - Auto-tracking hook
- `plugins/dev/hooks.toml:1-116` - Hook definitions
- `scripts/validate-thoughts-setup.sh:1-72` - Validation script
- `scripts/humanlayer/init-project.sh:1-165` - Project initialization

### Agent Files

- `plugins/dev/agents/thoughts-locator.md:1-141` - Document finder agent
- `plugins/dev/agents/thoughts-analyzer.md:1-168` - Document analysis agent

### Key Command Files

- `plugins/dev/commands/research_codebase.md` - Research workflow
- `plugins/dev/commands/create_plan.md` - Planning workflow
- `plugins/dev/commands/create_handoff.md` - Handoff creation
- `plugins/pm/commands/analyze_cycle.md` - Cycle analysis (PM)

---

## Key Observations

### What Thoughts Provides

1. **Persistent Storage**: Documents survive across sessions via git
2. **Auto-Discovery**: Workflow-context enables command chaining without manual paths
3. **Team Sharing**: Git-backed enables collaboration
4. **Worktree Sharing**: Same thoughts across feature branches (via symlinks)
5. **Structured Organization**: Consistent directory structure for different document types
6. **Ticket Association**: Automatic ticket extraction from filenames
7. **Searchability**: thoughts-locator agent can find relevant documents

### What Linear Documents Provide

1. **Project Association**: Documents can be linked to Linear projects
2. **Issue Attachment**: Documents can be attached directly to issues
3. **Native Linear UI**: Documents visible in Linear interface
4. **API Access**: Full CRUD via Linearis CLI
5. **Team Visibility**: All team members see documents in Linear

### Gaps to Consider

1. **Workflow-Context Equivalent**: Would need new mechanism for auto-discovery
2. **Local File Access**: Linear documents are remote; current system reads local files
3. **Hooks**: Current hooks watch local filesystem; would need different approach
4. **Git History**: Local git provides version history; Linear has its own versioning
5. **Offline Access**: Current system works offline; Linear requires connectivity
6. **Bulk Operations**: Current system uses filesystem; Linear requires API calls
7. **Agent Integration**: thoughts-locator/analyzer agents read local files

---

## Open Questions (for Further Investigation)

1. How would commands read Linear documents during execution (API latency)?
2. How would workflow-context auto-discovery work with remote documents?
3. What happens to hooks that watch local filesystem paths?
4. How would worktree sharing work without local symlinks?
5. What's the document ID scheme in Linear for referencing?
6. Can Linear documents be fetched/cached locally for better performance?
7. How would offline scenarios be handled?
8. What about documents that aren't tied to issues (general research)?

---

## Related Research

- See `CLAUDE.md:97-147` for three-layer memory architecture documentation
- See `docs/THOUGHTS_SETUP.md` for current setup guide
- See `plugins/dev/WORKFLOW_CONTEXT.md` for auto-discovery documentation
