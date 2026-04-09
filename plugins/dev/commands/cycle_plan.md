---
description: Plan work for current or next cycle using Linear and GitHub
category: project-task-management
tools: mcp__linear__list_issues, mcp__linear__list_cycles, mcp__linear__save_issue, mcp__linear__research, Bash(gh *), Read, Write, TodoWrite
model: inherit
version: 2.0.0
status: placeholder
---

# Cycle Planning

**Status**: Placeholder for v1.0 - Full implementation coming in future release

## Planned Functionality

This command will help you plan work for the current or upcoming cycle by:

1. Fetching current and next cycle information
2. Listing backlog tickets ready for planning
3. Interactively assigning tickets to cycles
4. Setting milestones and priorities
5. Generating cycle plan summary

## Current Workaround

Use the Linear MCP tools directly:

- **Get active cycle**: `mcp__linear__list_cycles` with team filter
- **List backlog tickets**: `mcp__linear__list_issues` with status filter "Backlog"
- **Assign ticket to cycle**: `mcp__linear__save_issue` with cycle field
- **Set priority**: `mcp__linear__save_issue` with priority field

### Example Workflow

```bash
# 4. Review recent PRs to understand current work
# This helps identify work done but not captured in Linear tickets
gh pr list --state merged --limit 20 --json number,title,author,mergedAt,closedAt

# Filter by date range (e.g., last 2 weeks for planning context)
gh pr list --state merged --search "merged:>=$(date -v-14d +%Y-%m-%d)" \
  --json number,title,author,mergedAt --jq '.[] | "\(.author.login): \(.title)"'

# 5. Identify who is working on what
gh pr list --state open --json number,title,author,createdAt | \
  jq 'group_by(.author.login) | map({author: .[0].author.login, prs: map({number, title})})'

# 6. Assign high-priority tickets to next cycle using Linear MCP
# Use mcp__linear__save_issue to update cycle and priority
```

## Future Implementation

When fully implemented, this command will:

- **Interactive cycle selection** - Choose current or next cycle
- **Smart backlog filtering** - Show tickets by priority and readiness
- **Batch assignment** - Select multiple tickets to assign at once
- **Capacity planning** - Estimate points/hours per ticket
- **Milestone tracking** - Group tickets by project milestones
- **PR-based work tracking** - Auto-detect work from merged/open PRs to identify:
  - Work completed but not tracked in Linear
  - Who is actively working on what
  - Team velocity based on PR activity
- **Team activity report** - Show contribution breakdown by team member
- **Summary generation** - Create cycle plan document in `reports/cycles/`

Track progress at: https://github.com/Threading-Needles/awl/issues

## Configuration

Uses `.claude/config.json`:

```json
{
  "linear": {
    "teamKey": "ENG",
    "defaultTeam": "Backend"
  }
}
```

## Tips

- Plan cycles **before they start** - gives team time to review
- Prioritize by **user impact** and **dependencies**
- Leave **buffer capacity** for bugs and urgent tasks
- Use **milestones** to group related work
- Review cycle plans in team meetings for alignment
- **Check PR activity** before planning to understand:
  - What work has been completed recently
  - Who is actively contributing
  - Untracked work that should be captured in Linear
  - Team velocity and capacity trends
