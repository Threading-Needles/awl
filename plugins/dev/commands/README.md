# Workflow Commands

Context management and workflow tools using Linear documents.

## Commands

### `/route`

Route a ticket to the appropriate workflow based on complexity analysis.

**Usage:**

```
/route PROJ-123
```

**Process:**

- Reads the ticket from Linear (title, description, labels, priority, estimate)
- Evaluates complexity heuristics to determine: one-shot fix or full research workflow
- High confidence: auto-routes immediately with a brief explanation
- Medium/Low confidence: asks the user to choose
- Delegates to `/one-shot-fix` or `/research-codebase`

**Override:** Users can bypass the router by invoking `/one-shot-fix` or `/research-codebase`
directly.

### `/one-shot-fix`

Apply a quick fix for simple tickets without formal research or planning.

**Usage:**

```
/one-shot-fix PROJ-123
```

**Process:**

- Sets ticket to "In Dev" (skips Research/Plan phases)
- Reads the ticket and quickly assesses what needs to change
- Proposes the fix and waits for user confirmation (interactive mode)
- Implements the fix with validation (build, lint, tests)
- Creates branch, commit, and offers PR creation

**When to use:** Small bug fixes, config changes, typos, simple updates with estimate ≤ 1.

**Escape hatch:** If unexpected complexity is found, recommends escalation to the full workflow.

### `/babysit-pr`

Monitor a PR through CI, run the test plan against the deployment preview, and update the PR
when done.

**Usage:**

```
/babysit-pr [PR_NUMBER]
```

**Process:**

- Polls CI status until all checks complete (max 15 minutes)
- Auto-fixes CI failures when possible (lint, type errors — max 3 attempts)
- Extracts deployment preview URL
- Runs visual checks from the PR's test plan against the preview
- Updates PR description, marking verified test plan items as complete

**Auto-called** by `/create-pr` after PR creation. Can also be invoked standalone on any PR.

### `/awl-dev:create-handoff`

Create handoff document for passing work to another developer or session.

**Usage:**

```
/awl-dev:create-handoff
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

### `/awl-dev:resume-handoff`

Resume work from handoff document.

**Usage:**

```
/awl-dev:resume-handoff PROJ-123
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
command chaining (e.g., `/awl-dev:research-codebase` → `/awl-dev:create-plan` → `/awl-dev:implement-plan`).

## Prerequisites

- **Linear MCP**: The official Linear MCP server must be configured (handles authentication automatically)
