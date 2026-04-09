---
description: Review project roadmap and milestone progress
category: project-task-management
tools: mcp__linear__list_projects, mcp__linear__get_project, mcp__linear__list_milestones, mcp__linear__list_issues, mcp__linear__research, Read, Write, TodoWrite
model: inherit
version: 2.0.0
status: placeholder
---

# Roadmap Review

**Status**: Placeholder for v1.0 - Full implementation coming in future release

## Planned Functionality

This command will help you review your roadmap by:

1. Listing all active projects
2. Showing milestone progress for each project
3. Identifying project dependencies
4. Calculating project completion
5. Generating roadmap summary

## Current Workaround

Use the Linear MCP tools directly:

- **List projects**: `mcp__linear__list_projects`
- **Get project details**: `mcp__linear__get_project` with project ID
- **List milestones**: `mcp__linear__list_milestones`
- **List project tickets**: `mcp__linear__list_issues` with project filter
- **Complex queries**: `mcp__linear__research` with natural language

## Future Implementation

When fully implemented, this command will:

- **Project overview** - Show all projects with key metrics
- **Milestone tracking** - Group tickets by milestone with progress
- **Dependency visualization** - Show project relationships and blockers
- **Risk analysis** - Identify at-risk projects (delayed, under-resourced)
- **Timeline view** - Show project timelines and conflicts
- **Resource allocation** - Show team members assigned to projects
- **Summary generation** - Create roadmap document in `reports/milestones/`
- **Trend analysis** - Compare progress month-over-month

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

- Review roadmap **monthly** or **quarterly**
- Update **target dates** based on actual velocity
- Document **dependencies** explicitly in project descriptions
- Identify **resource constraints** early
- Communicate **delays** proactively to stakeholders
- Use **milestones** to track major deliverables
- Archive **completed projects** to reduce noise
- Link projects to **company OKRs** for alignment

## Related Commands

- `/awl-dev:cycle-plan` - Plan work within cycles for a project
- `/awl-dev:cycle-review` - Review cycle progress
- `/awl-dev:linear` - Manage individual tickets
- `/awl-dev:create-plan` - Create implementation plans for tickets
