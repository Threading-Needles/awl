---
date: 2025-10-25T19:45:00+0000
author: Claude
repository: awl
topic: "Awl Final 2-Plugin Structure"
tags: [final, aligned, plugins, simple]
status: READY-FOR-PLAN
---

# Awl: 2-Plugin Structure

## Final Aligned Structure

### Plugin 1: **awl-dev** ⭐

**Everything a developer needs from understanding to shipping**

**What it contains**:

**Agents (6)** - Research is first step of dev:

- codebase-locator
- codebase-analyzer
- codebase-pattern-finder
- thoughts-locator
- thoughts-analyzer
- external-research

**Commands (15)** - Complete dev workflow:

- `/research-codebase` - Understand code (uses agents)
- `/create-plan` - Plan the solution
- `/implement-plan` - Build it
- `/validate-plan` - Verify it works
- `/commit` - Smart commits
- `/describe-pr` - PR descriptions
- `/debug` - Investigate issues
- `/create-handoff` - Pause work (clear context)
- `/resume-handoff` - Resume work (restore context)
- `/linear` - Ticket management
- `/linear-setup-workflow` - Configure Linear
- `/create-pr` - Create PR + Linear integration
- `/merge-pr` - Merge PR + Linear completion
- `/create-worktree` - Parallel work
- `/workflow-help` - Interactive guidance

**Scripts (3)**:

- `check-prerequisites.sh` - Verify HumanLayer, jq, thoughts
- `create-worktree.sh` - Worktree creation
- `frontmatter-utils.sh` - YAML utilities

**Prerequisites**:

- Required: HumanLayer CLI, jq, thoughts system
- Optional: Linear MCP

**Value**: "Research → Plan → Implement → Validate → Ship with Linear automation"

---

### Plugin 2: **awl-meta**

**Learn from the community and create workflows**

**What it contains**:

**Commands (5)**:

- `/discover-workflows` - Research external repos
- `/import-workflow` - Import and adapt
- `/create-workflow` - Create new workflows
- `/validate-frontmatter` - Validate consistency
- `/workflow-help` - Guidance (duplicate from dev)

**Scripts (1)**:

- `validate-frontmatter.sh` - Trunk linter integration

**Prerequisites**: None

**Value**: "Discover best practices and extend Awl"

---

## Structure on Disk

```
awl/
├── .claude-plugin/
│   └── marketplace.json
│
├── plugins/
│   ├── dev/                           # THE COMPLETE WORKFLOW
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── agents/                    # 6 research agents
│   │   │   ├── codebase-locator.md
│   │   │   ├── codebase-analyzer.md
│   │   │   ├── codebase-pattern-finder.md
│   │   │   ├── thoughts-locator.md
│   │   │   ├── thoughts-analyzer.md
│   │   │   └── external-research.md
│   │   ├── commands/                  # 15 commands
│   │   │   ├── research_codebase.md
│   │   │   ├── create_plan.md
│   │   │   ├── implement_plan.md
│   │   │   ├── validate_plan.md
│   │   │   ├── commit.md
│   │   │   ├── describe_pr.md
│   │   │   ├── debug.md
│   │   │   ├── create_handoff.md
│   │   │   ├── resume_handoff.md
│   │   │   ├── linear.md
│   │   │   ├── linear_setup_workflow.md
│   │   │   ├── create_pr.md
│   │   │   ├── merge_pr.md
│   │   │   ├── create_worktree.md
│   │   │   └── workflow_help.md
│   │   └── scripts/                   # 3 scripts
│   │       ├── check-prerequisites.sh
│   │       ├── create-worktree.sh
│   │       ├── frontmatter-utils.sh
│   │       └── README.md
│   │
│   └── meta/                          # WORKFLOW INSPIRATION
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── commands/                  # 5 commands
│       │   ├── discover_workflows.md
│       │   ├── import_workflow.md
│       │   ├── create_workflow.md
│       │   ├── validate_frontmatter.md
│       │   └── workflow_help.md
│       └── scripts/                   # 1 script
│           ├── validate-frontmatter.sh
│           └── README.md
│
├── hack/                              # Migration/setup tools (not in plugins)
│   ├── install-user.sh
│   ├── install-project.sh
│   ├── setup-thoughts.sh
│   └── ...
│
└── README.md
```

---

## Why This Makes Sense

### awl-dev: The Complete Dev Workflow

**Research starts dev work**:

- You research to implement a feature
- You research to fix a bug
- You research to answer a question
- Research is phase 1 of development, not a separate activity

**Handoff manages context**:

- Handoff is when you need to clear context mid-workflow
- It's a dev tool for managing Claude's context limits
- Resume brings you back to where you left off
- It's part of the flow, not separate from it

**Everything flows together**:

```
Research → Plan → Implement → Validate → Commit → PR → Merge
         ↓ (context full)
    Handoff
         ↓ (resume)
    Continue workflow
```

---

### awl-meta: Learning and Creating

**For inspiration and extension**:

- Learn how other teams structure workflows
- Discover best practices
- Create your own commands/agents
- Not part of daily dev work

**Publicly available** - anyone can learn and create

---

## Installation

### Most users (developers):

```bash
/plugin marketplace add ralfschimmel/awl
/plugin install awl-dev@awl

# One-time setup:
brew install humanlayer/tap/humanlayer jq
humanlayer thoughts init
```

**Gets**: Everything for dev workflow

---

### Power users (learning/creating):

```bash
/plugin install awl-dev@awl
/plugin install awl-meta@awl
```

**Gets**: Dev workflow + discovery/creation tools

---

## Marketplace

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "awl",
  "version": "1.0.0",
  "description": "Research-driven development workflow from Coalesce Labs",
  "owner": {
    "name": "Coalesce Labs",
    "url": "https://github.com/coalesce-labs"
  },
  "plugins": [
    {
      "name": "awl-dev",
      "source": "./plugins/dev",
      "description": "Complete development workflow: research → plan → implement → validate → ship with Linear automation. Includes research agents, planning tools, handoff system, and Linear integration.",
      "version": "1.0.0",
      "category": "development",
      "keywords": ["workflow", "research", "planning", "agents", "linear", "handoff"],
      "featured": true
    },
    {
      "name": "awl-meta",
      "source": "./plugins/meta",
      "description": "Discover, import, and create workflows: learn from community patterns and extend Awl",
      "version": "1.0.0",
      "category": "development",
      "keywords": ["meta", "discovery", "creation", "best-practices"]
    }
  ]
}
```

---

## Summary

**2 Plugins**:

1. **awl-dev** (6 agents, 15 commands, 3 scripts) - Complete dev workflow
2. **awl-meta** (5 commands, 1 script) - Workflow inspiration

**Key insights**:

- Research is the first step of dev, not separate
- Handoff is for managing context during dev, not separate
- Linear integration is part of dev workflow
- Worktrees are for dev (parallel work), not PM
- Meta is for learning/creating, not daily dev

**Ready for**: `/create-plan` to implement this structure! 🚀

---

## No More Changes

This is it - the final aligned structure. Let's move to planning!
