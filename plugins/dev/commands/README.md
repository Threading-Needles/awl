# Workflow Commands

Context management and workflow tools using Linear documents.

## Commands

### `/create-handoff`

Create handoff document for passing work to another developer or session.

**Usage:**

```
/create-handoff
```

**Creates:**

- Handoff document in Linear attached to the current ticket
- Title format: `Handoff: {description}`
- Includes: Current state, work completed, next steps, blockers, context

**Content:**

- Current ticket/task
- Work completed (with file:line references)
- Files modified
- Next steps (prioritized)
- Known blockers
- Important context

### `/resume-handoff`

Resume work from handoff document.

**Usage:**

```
/resume-handoff PROJ-123
```

**Process:**

- Finds handoff documents attached to the ticket in Linear
- Reads full handoff document content
- Loads context (ticket, files, blockers)
- Presents next steps
- Asks how to proceed

**Benefits:**

- Quick context restoration
- No lost work
- Clear continuation path

## Use Cases

**Handoffs:**

- End of day → Resume next morning
- Developer → Developer
- Blocked work → When unblocked

**Collaboration:**

- Pair programming context
- Code review preparation
- Onboarding new team members

## Linear Document System

Commands use Linear documents attached to tickets:

| Type | Title Pattern | Icon | Color |
|------|---------------|------|-------|
| Research | `Research: ...` | document | blue |
| Plan | `Plan: ...` | list | green |
| Handoff | `Handoff: ...` | handshake | orange |
| PR Description | `PR: ...` | git-pull-request | purple |

**Discovery:** Documents are discovered by querying Linear for attachments on the current ticket.

**Workflow Context:** The current ticket is tracked in `.claude/.workflow-context.json` to enable
command chaining (e.g., `/research-codebase` → `/create-plan` → `/implement-plan`).

## Prerequisites

- **Linear MCP**: The official Linear MCP server must be configured (handles authentication automatically)
