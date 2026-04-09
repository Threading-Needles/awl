---
description: Apply a quick fix for simple tickets without formal research or planning
category: workflow
tools: Read, Write, Edit, Grep, Glob, Task, TodoWrite, Bash, mcp__linear__get_issue, mcp__linear__save_issue, mcp__linear__save_comment
model: inherit
version: 1.0.0
argument-hint: "[TICKET-ID]"
---

# One-Shot Fix

You are tasked with applying a quick fix for a simple ticket. This command compresses the full
research → plan → implement pipeline into a single lightweight flow: read the ticket, assess what
needs to change, propose the fix, get confirmation, and implement it.

Use this for small bug fixes, config changes, typo corrections, and other tickets that don't need
formal research documents or implementation plans.

## Prerequisites

```bash
if [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" ]]; then
  "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" || exit 1
fi
```

## Execution Mode Detection

```bash
MODE=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" detect-mode)
# MODE will be "interactive" or "headless"
```

## Step 1: Ticket Handling

Check workflow context first (the router may have already set it):

```bash
CURRENT_TICKET=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" get-ticket)
```

- If a ticket ID argument is provided, use it and update context:
  ```bash
  "${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" set-ticket "$TICKET_ID"
  ```
- If no argument but context has a ticket, use that
- If neither, prompt the user:
  ```
  I need a Linear ticket to work on.

  Usage: /one-shot-fix PROJ-123
  ```

## Step 2: Update Linear Ticket Status (FIRST)

**This MUST be the first action after resolving the ticket ID.**

Skip "Research in Progress" and "Plan in Progress" — go straight to "In Dev":

Use `mcp__linear__save_issue` with the ticket ID to update the state to "In Dev".

Then use `mcp__linear__save_comment` with the ticket ID and body "Starting one-shot fix".

## Step 3: Read the Ticket

Use `mcp__linear__get_issue` with the ticket ID to retrieve the full ticket details. Read and fully understand the ticket title, description, labels, and any mentioned files or components.

## Step 4: Quick Codebase Assessment

This is a lightweight investigation — just enough to understand what needs to change.

1. **If the ticket mentions specific file paths**: Read those files directly using the Read tool
   (no sub-agents needed). Read files FULLY without limit/offset.

2. **If the ticket mentions a component/feature but not specific files**: Spawn a single
   `codebase-locator` Task agent to find the relevant files. Wait for it to complete, then read
   the identified files.

3. **If the ticket is vague**: Use Grep/Glob to search for relevant code based on keywords from
   the ticket title and description.

Keep this focused. You are not conducting comprehensive research — just finding the files that need
to change and understanding them well enough to make a targeted fix.

## Step 5: Propose the Fix

Present a concise fix proposal:

```markdown
## One-Shot Fix Proposal: {TICKET_ID}

**Ticket**: {title}

### What I Found
- {key finding 1 with file:line reference}
- {key finding 2 with file:line reference}

### Proposed Changes
1. **{file1.ext}**: {description of change}
2. **{file2.ext}**: {description of change}

### What I Will NOT Change
- {explicitly scoped-out items, if any}
```

**Interactive mode**: Wait for user confirmation before making any changes. The user can approve,
reject, or ask for modifications to the proposal.

**Headless mode**: Proceed directly to implementation.

## Step 6: Implement the Fix

Make the code changes using Edit and Write tools.

After making changes, run project validation checks:

1. **Build/compile** (if applicable)
2. **Linting** (if applicable)
3. **Type checking** (if applicable)
4. **Relevant test suites** (if applicable)

If validation fails, attempt to fix the issues (max 3 attempts per issue type). If you cannot
resolve validation failures after 3 attempts, stop and report the issue.

## Step 7: Complexity Escalation Check

If at any point during assessment or implementation you discover the ticket is more complex than
expected, **stop and recommend escalation**:

Indicators of unexpected complexity:
- Changes span more than 5 files
- Architectural decisions are needed
- The fix requires understanding multiple interconnected systems
- Validation fails repeatedly with non-trivial issues

```markdown
## Complexity Escalation

This ticket appears more complex than a one-shot fix. I recommend switching to the full workflow.

**Why**:
- {reason 1}
- {reason 2}

**Next step**: Run `/research-codebase {TICKET_ID}`

Any changes made so far are preserved on the current branch.
```

Update the ticket status back:

Use `mcp__linear__save_issue` with the ticket ID to update the state back to "Backlog".

Then use `mcp__linear__save_comment` with the ticket ID and body "One-shot fix escalated to full workflow: {REASON}".

Then stop execution.

## Step 8: Create Branch and Commit

If on main/master, create a feature branch:

```bash
BRANCH=$(git branch --show-current)
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  # Create branch using ticket ID
  git checkout -b "${TICKET_ID}-fix"
fi
```

Then invoke `/awl-dev:commit` to create a conventional commit with the changes.

## Step 9: Offer PR Creation

**Interactive mode:**

```markdown
## Fix Applied

**Ticket**: {TICKET_ID}
**Branch**: {branch}
**Changes**: {N} files modified

### Summary
{1-2 sentence description of what was changed and why}

### Verification
- Build: {PASS/FAIL/N/A}
- Lint: {PASS/FAIL/N/A}
- Tests: {PASS/FAIL/N/A}

---

What would you like to do next?

1. Create PR now (/create-pr)
2. Review the changes first (I'll show the diff)
3. Make additional changes
4. Done for now
```

Wait for user input.

**Headless mode:**

Automatically invoke `/awl-dev:create_pr` to create the pull request.

## Error Handling

### Failure Rollback

On any unrecoverable failure:

Use `mcp__linear__save_issue` with the ticket ID to update the state back to "Backlog".

Then use `mcp__linear__save_comment` with the ticket ID and body "One-shot fix failed: {ERROR_REASON}. Consider using full research workflow."

### Ticket Not Found

```
Ticket {TICKET_ID} not found in Linear.

Please verify:
1. The ticket ID is correct (e.g., PROJ-123)
2. You have access to this Linear team
```

## Important Notes

### Status Transitions

This command uses a compressed status flow:

```
Backlog → In Dev → In Review (via /create-pr)
```

It intentionally skips "Research in Progress" and "Plan in Progress" since no formal research or
plan is created.

### No Linear Documents Created

Unlike the full workflow, this command does NOT create Research or Plan documents in Linear. The
ticket description and commit messages serve as the documentation for simple fixes.

### Downstream Command Integration

This command reuses existing commands for the post-fix lifecycle:

- `/awl-dev:commit` for conventional commits
- `/awl-dev:create_pr` for PR creation (which handles describe_pr, Linear status, etc.)

The workflow context ticket is set, so downstream commands find it automatically.

### When NOT to Use This Command

- The ticket requires understanding multiple interconnected systems
- The fix involves architectural decisions
- You're unsure about the scope of changes needed
- The ticket has an estimate ≥ 3 points

In these cases, use `/research-codebase` → `/create-plan` → `/implement-plan` instead.
