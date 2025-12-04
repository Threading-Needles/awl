# Linear Document Conventions

This document defines the conventions for storing workflow documents in Linear.

## Document Types

All workflow documents are stored as Linear documents attached to their associated ticket.

| Type | Title Pattern | Icon | Color (Hex) | Purpose |
|------|---------------|------|-------------|---------|
| Research | `Research: {description}` | `Search` | `#eb5757` (red-orange) | Codebase research findings |
| Plan | `Plan: {description}` | `Compass` | `#f2c94c` (yellow) | Implementation plans |
| Validation | `Validation: {description}` | `CheckCircle` | `#27ae60` (green) | Validation results and fixes |
| Handoff | `Handoff: {description}` | `Send` | `#9b51e0` (purple) | Session context transfer |
| PR Description | `PR: {description}` | `CodeBlock` | `#2f80ed` (blue) | Pull request documentation |

## Creating Documents

### Research Document

```bash
# Get team key from config
TEAM_KEY=$(jq -r '.catalyst.linear.teamKey // "PROJ"' .claude/config.json)

linearis documents create \
  --title "Research: Authentication Flow" \
  --team "${TEAM_KEY}" \
  --content "$(cat research.md)" \
  --attach-to "PROJ-123" \
  --icon "Search" \
  --color "#eb5757"
```

### Implementation Plan

```bash
linearis documents create \
  --title "Plan: OAuth Implementation" \
  --team "${TEAM_KEY}" \
  --content "$(cat plan.md)" \
  --attach-to "PROJ-123" \
  --icon "Compass" \
  --color "#f2c94c"
```

### Validation Document

```bash
linearis documents create \
  --title "Validation: OAuth Implementation" \
  --team "${TEAM_KEY}" \
  --content "$(cat validation.md)" \
  --attach-to "PROJ-123" \
  --icon "CheckCircle" \
  --color "#27ae60"
```

### Handoff Document

```bash
linearis documents create \
  --title "Handoff: Session 2025-12-04" \
  --team "${TEAM_KEY}" \
  --content "$(cat handoff.md)" \
  --attach-to "PROJ-123" \
  --icon "Send" \
  --color "#9b51e0"
```

### PR Description

```bash
linearis documents create \
  --title "PR: Add OAuth Support" \
  --team "${TEAM_KEY}" \
  --content "$(cat pr.md)" \
  --attach-to "PROJ-123" \
  --icon "CodeBlock" \
  --color "#2f80ed"
```

## Querying Documents

### List All Documents Attached to a Ticket

```bash
linearis attachments list --issue PROJ-123
```

### Find Specific Document Type

```bash
# Find research documents
linearis attachments list --issue PROJ-123 | jq '.[] | select(.title | startswith("Research:"))'

# Find plans
linearis attachments list --issue PROJ-123 | jq '.[] | select(.title | startswith("Plan:"))'

# Find handoffs
linearis attachments list --issue PROJ-123 | jq '.[] | select(.title | startswith("Handoff:"))'
```

### Read Document Content

```bash
linearis documents read <document-id>
```

## Workflow Integration

### Entry Point

All workflows start with a ticket ID. The first command (`/research-codebase PROJ-123`) sets the current ticket in workflow context.

### Document Discovery

Subsequent commands query Linear for documents on the current ticket:

```
/research-codebase PROJ-123
  └─→ Creates: Research document attached to PROJ-123
  └─→ Sets: currentTicket = PROJ-123

/create-plan (no args needed)
  └─→ Reads: currentTicket from workflow-context
  └─→ Queries: Linear for Research documents on PROJ-123
  └─→ Creates: Plan document attached to PROJ-123

/implement-plan (no args needed)
  └─→ Reads: currentTicket from workflow-context
  └─→ Queries: Linear for Plan documents on PROJ-123
  └─→ Implements the plan
```

### Workflow Context

The workflow context file (`.claude/.workflow-context.json`) stores only the current ticket:

```json
{
  "currentTicket": "PROJ-123"
}
```

## Best Practices

1. **Always attach to a ticket** - Every document must be attached to a Linear issue
2. **Use consistent title patterns** - Prefix with document type for easy filtering
3. **Include timestamps in handoffs** - Helps identify most recent handoff
4. **Keep descriptions concise** - Title should summarize the document purpose

## Icon Reference

Valid Linear document icons (case-sensitive, PascalCase):

**Document Types:**
- `Search` - Research/investigation
- `Compass` - Planning/navigation
- `CodeBlock` - Code/technical
- `Send` - Handoff/transfer
- `Book` - Documentation
- `Bookmark` - Reference
- `Folder` - Organization

**Actions:**
- `Rocket` - Launch/deploy
- `Bolt` - Quick/fast
- `Fire` - Hot/urgent
- `Terminal` - Command line
- `Wrench` - Configuration

**Communication:**
- `Chat` - Discussion
- `Comment` - Feedback
- `Users` - Team
- `Team` - Collaboration
- `Link` - Connection

**Status:**
- `Alert` - Warning
- `Shield` - Security
- `Lock` - Private
- `Bug` - Issues
- `Clock` - Time-related
- `Calendar` - Scheduled

**Objects:**
- `Box` - Package
- `Home` - Main
- `Pin` - Location
- `World` - Global
- `Dollar` - Finance
- `Cart` - Commerce
- `Shop` - Store

**Nature:**
- `Sun` - Day/active
- `Moon` - Night/inactive
- `Cloud` - Cloud services
- `Leaf` - Growth
- `Tree` - Structure
- `Flower` - Design
- `Heart` - Favorite

## Color Reference

Linear uses hex color codes. Recommended palette:

| Color | Hex | Use Case |
|-------|-----|----------|
| Red-Orange | `#eb5757` | Research, investigation |
| Yellow | `#f2c94c` | Planning, in progress |
| Blue | `#2f80ed` | Code, technical |
| Purple | `#9b51e0` | Handoffs, transfers |
| Green | `#4cb782` | Complete, success |
| Orange | `#f2994a` | Warnings, attention |
| Gray | `#95a2b3` | Inactive, archived |
| Indigo | `#5e6ad2` | Default, neutral |
