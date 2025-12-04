---
description: Create handoff document for passing work to another session
category: workflow
tools: Write, Bash, Read
model: inherit
version: 2.0.0
---

# Create Handoff

You are tasked with writing a handoff document to hand off your work to another agent in a new
session. The handoff will be saved as a Linear document attached to the current ticket.

## Prerequisites

Before executing, verify Linear integration is available:

```bash
# Validate plugin prerequisites (includes LINEAR_API_TOKEN check)
if [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" ]]; then
  "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" || exit 1
fi
```

## Initial Setup

### Step 1: Get Current Ticket

Check workflow context for current ticket:

```bash
CURRENT_TICKET=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" get-ticket)
```

### Step 2: Handle Ticket State

**If no current ticket:**

```
I need a Linear ticket to attach this handoff to.

Please provide a ticket ID, or if this is general work not tied to a ticket,
I can create a standalone handoff document.

Options:
1. Provide a ticket ID (e.g., PROJ-123)
2. Create general handoff (no ticket attachment)
```

If user provides ticket, set it:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" set-ticket "$TICKET_ID"
```

**If current ticket exists:**

```
I'll create a handoff document for ticket {CURRENT_TICKET}.
```

### Step 3: Gather Metadata

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
**Ticket**: {CURRENT_TICKET}
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

```bash
# Get team key from config
TEAM_KEY=$(jq -r '.awl.linear.teamKey // "PROJ"' .claude/config.json)

# Create Linear document with handoff content
linearis documents create \
  --title "Handoff: ${DESCRIPTION}" \
  --team "${TEAM_KEY}" \
  --content "${HANDOFF_CONTENT}" \
  --attach-to "${CURRENT_TICKET}" \
  --icon "Send" \
  --color "#9b51e0"

# Add comment to ticket
linearis comments create "$CURRENT_TICKET" --body "Handoff document created for session transfer."
```

### 4. Present to User

After saving:

```
✅ Handoff created and saved to Linear!

**Ticket**: {CURRENT_TICKET}
**Linear Document**: Handoff: {description}

To resume from this handoff in a new session:

1. Clear context (start fresh session)
2. Run `/resume-handoff {CURRENT_TICKET}`

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
/research-codebase PROJ-123 → research document
                  ↓
           /create-plan → implementation plan
                  ↓
          /implement-plan → code changes
                  ↓
          /create-handoff → handoff document (this command)
                  ↓
         /resume-handoff → continues work
```

**How it connects:**

- **Previous**: Can be invoked at any point during implementation
- **Next**: `/resume-handoff` finds the handoff via linear-document-locator
- **Workflow context**: Current ticket is used to attach the handoff

## Error Handling

**If document creation fails:**

```
⚠️ Could not create handoff document in Linear.

Please verify:
1. LINEAR_API_TOKEN is set correctly
2. You have access to this Linear workspace
3. The ticket {CURRENT_TICKET} exists

The handoff content is shown above - you can manually save it if needed.
```

**If no ticket and user wants standalone handoff:**

For general work not tied to a ticket, create the handoff as a comment or note, but encourage
attaching to a ticket for better discoverability:

```
⚠️ Handoffs work best when attached to tickets for easy discovery.

Would you like me to:
1. Create a new ticket for this work and attach the handoff?
2. Display the handoff content for manual saving?
```
