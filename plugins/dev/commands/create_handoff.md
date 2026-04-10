---
description: Create handoff document for passing work to another session
category: workflow
tools: mcp__linear__create_document, mcp__linear__save_comment, Write, Bash, Read
model: inherit
version: 2.0.0
---

# Create Handoff

You are tasked with writing a handoff document to hand off your work to another agent in a new
session. The handoff will be saved as a Linear document attached to the current ticket.

## Initial Setup

### Step 1: Validate Ticket Argument

**A ticket ID is REQUIRED as the first argument.** If no ticket ID was provided, respond with:

```
I need a Linear ticket to attach this handoff to.

Usage: /awl-dev:create-handoff TICKET-123
```

Then stop. Do not proceed without a ticket ID.

Use the provided ticket ID as `TICKET_ID` throughout this command.

```
I'll create a handoff document for ticket {TICKET_ID}.
```

### Step 2: Gather Metadata

```bash
# Get current git information
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" || echo "unknown")
CURRENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
```

## Process

### 1. Analyze Current Session

Review:
- What tasks were you working on?
- What's completed vs in-progress vs planned?
- What files were modified?
- What did you learn that's important to pass on?

### 2. Write Handoff Content

Create a thorough but **concise** document. The goal is to compact and summarize context without
losing key details.

Use this template structure:

```markdown
# Handoff: {TICKET} - {very concise description}

**Date**: {current date/time with timezone}
**Ticket**: {TICKET_ID}
**Git Commit**: {commit hash}
**Branch**: {branch name}
**Repository**: {repo name}

## Task(s)

{description of the task(s) that you were working on, along with the status of each (completed, work
in progress, planned/discussed). If you are working on an implementation plan, make sure to call out
which phase you are on. Reference the plan and/or research documents attached to the ticket.}

## Critical References

{List any critical specification documents, architectural decisions, or design docs that must be
followed. Include only 2-3 most important file paths. Leave blank if none.}

## Recent Changes

{describe recent changes made to the codebase in file:line syntax}

## Learnings

{describe important things that you learned - e.g. patterns, root causes of bugs, or other important
pieces of information someone that is picking up your work after you should know. Include explicit
file paths.}

## Artifacts

{an exhaustive list of artifacts you produced or updated as filepaths and/or file:line references -
e.g. paths to feature documents, implementation plans, etc that should be read in order to resume
your work.}

## Action Items & Next Steps

{a list of action items and next steps for the next agent to accomplish based on your tasks and
their statuses}

## Other Notes

{other notes, references, or useful information - e.g. where relevant sections of the codebase are,
or other important things you learned that you want to pass on}
```

### 3. Save to Linear

Create the handoff document in Linear:

- Use `mcp__linear__create_document` to create a document with the title "Handoff: {DESCRIPTION}" and the handoff content as the body. Attach the document to the current ticket.
- Use `mcp__linear__save_comment` to add a comment to the ticket: "Handoff document created for session transfer."

### 4. Present to User

After saving:

```
✅ Handoff created and saved to Linear!

**Ticket**: {TICKET_ID}
**Linear Document**: Handoff: {description}

To resume from this handoff in a new session:

1. Clear context (start fresh session)
2. Run `/awl-dev:resume-handoff {TICKET_ID}`

The handoff document is attached to the ticket and will be automatically discovered.
```

## Important Guidelines

- **More information, not less**. This is a guideline that defines the minimum of what a handoff
  should be. Always feel free to include more information if necessary.
- **Be thorough and precise**. Include both top-level objectives, and lower-level details as
  necessary.
- **Avoid excessive code snippets**. While a brief snippet to describe some key change is important,
  avoid large code blocks or diffs; do not include one unless it's absolutely necessary. Prefer
  using `/path/to/file.ext:line` references that an agent can follow later when it's ready, e.g.
  `packages/dashboard/src/app/dashboard/page.tsx:12-24`

## Integration with Other Commands

```
/awl-dev:research-codebase PROJ-123 → research document
                  ↓
           /awl-dev:create-plan → implementation plan
                  ↓
          /awl-dev:implement-plan → code changes
                  ↓
          /awl-dev:create-handoff → handoff document (this command)
                  ↓
         /awl-dev:resume-handoff → continues work
```

**How it connects:**

- **Previous**: Can be invoked at any point during implementation
- **Next**: `/awl-dev:resume-handoff` finds the handoff via linear-document-locator
- **Workflow context**: Current ticket is used to attach the handoff

## Error Handling

**If document creation fails:**

```
⚠️ Could not create handoff document in Linear.

Please verify:
1. You have access to this Linear workspace
2. The ticket {TICKET_ID} exists

The handoff content is shown above - you can manually save it if needed.
```

## Status Update Convention

This command does NOT update ticket status - it simply saves context for session transfer. The ticket status remains in its current state ("In Dev", "In Progress", etc.) until the next session decides what to do.

On failure, there is no rollback needed since no status was changed. Simply report the error and allow the user to retry or save the content manually.
