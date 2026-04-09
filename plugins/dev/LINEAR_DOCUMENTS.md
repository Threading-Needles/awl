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

Use `mcp__linear__create_document` with:
- **title**: `"Research: Authentication Flow"`
- **content**: The research findings in markdown
- **icon**: `"Search"`
- **color**: `"#eb5757"`

Then attach to the ticket using `mcp__linear__create_attachment`.

### Implementation Plan

Use `mcp__linear__create_document` with:
- **title**: `"Plan: OAuth Implementation"`
- **content**: The plan in markdown
- **icon**: `"Compass"`
- **color**: `"#f2c94c"`

Then attach to the ticket using `mcp__linear__create_attachment`.

### Validation Document

Use `mcp__linear__create_document` with:
- **title**: `"Validation: OAuth Implementation"`
- **content**: The validation results in markdown
- **icon**: `"CheckCircle"`
- **color**: `"#27ae60"`

Then attach to the ticket using `mcp__linear__create_attachment`.

### Handoff Document

Use `mcp__linear__create_document` with:
- **title**: `"Handoff: Session 2025-12-04"`
- **content**: The handoff context in markdown
- **icon**: `"Send"`
- **color**: `"#9b51e0"`

Then attach to the ticket using `mcp__linear__create_attachment`.

### PR Description

Use `mcp__linear__create_document` with:
- **title**: `"PR: Add OAuth Support"`
- **content**: The PR description in markdown
- **icon**: `"CodeBlock"`
- **color**: `"#2f80ed"`

Then attach to the ticket using `mcp__linear__create_attachment`.

## Querying Documents

### List All Documents Attached to a Ticket

Use `mcp__linear__get_issue` with the ticket identifier (e.g., `PROJ-123`) to retrieve issue details including attached documents.

### Find Specific Document Type

After retrieving the issue, filter attached documents by their title prefix:
- **Research documents**: Title starts with `"Research:"`
- **Plans**: Title starts with `"Plan:"`
- **Handoffs**: Title starts with `"Handoff:"`

### Read Document Content

Use `mcp__linear__get_document` with the document ID to read its full content.

## Workflow Integration

### Entry Point

All workflows start with a ticket ID. The first command (`/awl-dev:research-codebase PROJ-123`) sets the current ticket in workflow context.

### Document Discovery

Subsequent commands query Linear for documents on the current ticket:

```
/awl-dev:research-codebase PROJ-123
  └─→ Creates: Research document attached to PROJ-123
  └─→ Sets: currentTicket = PROJ-123

/awl-dev:create-plan (no args needed)
  └─→ Reads: currentTicket from workflow-context
  └─→ Queries: Linear for Research documents on PROJ-123
  └─→ Creates: Plan document attached to PROJ-123

/awl-dev:implement-plan (no args needed)
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

## Embedded Questions

When running in headless mode (`claude -p`), workflow commands cannot use the interactive
`AskUserQuestion` tool. Instead, questions are embedded directly in Research and Plan documents
for async answering via the Linear UI.

### Question Format

Questions are embedded in a dedicated section within the document:

```markdown
## Questions for User

@{Assignee Name} - Please answer before proceeding to {next command}:

> **Q1 (blocking)**: What authentication method should we use?
> **Context**: This affects security model and token storage approach.
> **Options**: A) JWT with refresh tokens B) Session-based C) OAuth2
> **Answer**: _[please fill in]_

> **Q2 (non-blocking)**: Should we add rate limiting to this endpoint?
> **Context**: Current traffic is low but may grow.
> **Answer**: _[please fill in]_
```

### Question Types

| Type | Format | Behavior |
|------|--------|----------|
| Blocking | `**Q1 (blocking)**:` | Workflow hard-fails if unanswered |
| Non-blocking | `**Q2 (non-blocking)**:` | Workflow proceeds with defaults noted |

### Answer Detection

The workflow checks for the placeholder pattern to detect unanswered questions:

```
**Answer**: _[please fill in]_
```

When a user answers, they replace the placeholder:

```
**Answer**: B) Session-based - better fits our existing infrastructure
```

### Workflow Integration

1. **Research Phase** (`/awl-dev:research-codebase` in headless mode):
   - Embeds questions in "Questions for User" section
   - Sets ticket status to "Spec Needed"
   - Mentions assignee for notification

2. **Plan Phase** (`/awl-dev:create-plan`):
   - Validates Research document for unanswered questions
   - Hard-fails with list if blocking questions remain unanswered
   - Embeds its own questions with same pattern

3. **Implementation Phase** (`/awl-dev:implement-plan`):
   - Validates Plan document for unanswered questions
   - Hard-fails with list and document link if found

### Status Convention

When a document contains unanswered questions:
- Set ticket status to **"Spec Needed"**
- This signals the ticket is blocked pending human input

### Assignee Mention

If the ticket has an assignee, mention them in the questions section:

```markdown
@John Smith - Please answer before proceeding to /awl-dev:create-plan:
```

If no assignee, omit the mention:

```markdown
Please answer before proceeding to /awl-dev:create-plan:
```

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
