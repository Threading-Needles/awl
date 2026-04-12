# AWL Development Plugin (awl-dev)

Core development workflow commands for AI-assisted development.

## Installation

```bash
/plugin install awl-dev
```

## Prerequisites

### Required

- **Linear MCP**: The official Linear MCP server (handles authentication automatically)
- **GitHub CLI**: `brew install gh` or `gh auth login`

### Required Plugins

These plugins are required for full functionality:

| Plugin | Used By | Install |
|--------|---------|---------|
| pr-review-toolkit | `/awl-dev:implement-plan` | `/plugin install pr-review-toolkit` |

### Recommended Plugins

These plugins enhance the development experience:

| Plugin | Purpose | Install |
|--------|---------|---------|
| frontend-design | High-quality UI components | `/plugin install frontend-design` |
| feature-dev | Guided feature development | `/plugin install feature-dev` |
| commit-commands | Commit, push, PR shortcuts | `/plugin install commit-commands` |
| code-review | PR code review | `/plugin install code-review` |
| hookify | Prevent unwanted behaviors | `/plugin install hookify` |
| plugin-dev | Create custom plugins | `/plugin install plugin-dev` |
| ralph-wiggum | Loop execution patterns | `/plugin install ralph-wiggum` |

## Quick Start

Run `/awl-dev:doctor` to check your setup and get guidance on missing dependencies.

## Commands

See [commands/README.md](commands/README.md) for full command documentation.

### Core Workflow

| Command | Purpose |
|---------|---------|
| `/awl-dev:research-codebase` | Research codebase with parallel agents |
| `/awl-dev:create-plan` | Interactive planning with research |
| `/awl-dev:implement-plan` | Execute approved plans |
| `/awl-dev:validate-plan` | Verify implementation |
| `/awl-dev:create-pr` | Create PR with rich description |
| `/awl-dev:merge-pr` | Merge PR and update Linear |

### Context Persistence

| Command | Purpose |
|---------|---------|
| `/awl-dev:create-handoff` | Save context for later sessions |
| `/awl-dev:resume-handoff` | Restore previous context |

### Utilities

| Command | Purpose |
|---------|---------|
| `/awl-dev:doctor` | Check setup and diagnose issues |
| `/awl-dev:commit` | Create conventional commits |
| `/awl-dev:debug` | Debug with logs and database |

## Agents

Research agents for parallel codebase and infrastructure exploration:

| Agent | Purpose | Model |
|-------|---------|-------|
| `@awl-dev:codebase-locator` | Find files by topic | haiku |
| `@awl-dev:codebase-analyzer` | Understand implementation | inherit |
| `@awl-dev:codebase-pattern-finder` | Find code patterns | inherit |
| `@awl-dev:linear-document-locator` | Find workflow documents attached to tickets | haiku |
| `@awl-dev:linear-document-analyzer` | Extract insights from Linear documents | inherit |
| `@awl-dev:linear-research` | Research Linear tickets, cycles, projects | haiku |
| `@awl-dev:github-research` | Research PRs, issues, workflows via `gh` | haiku |
| `@awl-dev:history-reader` | Find context from completed work | inherit |
| `@awl-dev:external-research` | Research external GitHub repos and libraries | inherit |

Agents marked `inherit` follow the session's model (start Claude Code with
`claude --model claude-opus-4-6[1m]` for deep reasoning). Agents pinned to `haiku` do pure lookup
and data gathering — fast and cheap regardless of session model.

## Related Plugins

From the same marketplace:

| Plugin | Purpose |
|--------|---------|
| awl-pm | Project management (cycles, milestones) |
| awl-analytics | PostHog integration |
| awl-debugging | PostHog error tracking |
| awl-meta | Workflow discovery and creation |
