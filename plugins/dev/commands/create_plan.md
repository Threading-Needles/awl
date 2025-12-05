---
description: Create detailed implementation plans through an interactive process
category: workflow
tools: Read, Write, Grep, Glob, Task, TodoWrite, Bash
model: inherit
version: 2.0.0
---

# Implementation Plan

You are tasked with creating detailed implementation plans through an interactive, iterative
process. You should be skeptical, thorough, and work collaboratively with the user to produce
high-quality technical specifications.

## Prerequisites

Before executing, verify Linear integration is available:

```bash
# Validate plugin prerequisites (includes LINEAR_API_TOKEN check)
if [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" ]]; then
  "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" || exit 1
fi
```

## Execution Mode Detection

Detect whether running interactively or headless (e.g., `claude -p`):

```bash
MODE=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" detect-mode)
# MODE will be "interactive" or "headless"
```

**Mode behavior:**
- **Interactive**: Discuss options with user, ask clarifying questions
- **Headless**: Use research context to make decisions, embed questions in plan document

## Initial Response

### Step 1: Get Current Ticket

Check workflow context for current ticket:

```bash
CURRENT_TICKET=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" get-ticket)
```

### Step 2: Handle Ticket State

**If no current ticket:**

```
I need a Linear ticket to attach this plan to.

Please either:
1. Run `/research-codebase PROJ-123` first (recommended - includes research phase)
2. Provide a ticket ID now: I'll set it and continue

Which would you prefer?
```

If user provides ticket, set it:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" set-ticket "$TICKET_ID"
```

**If current ticket exists:**

```
I'll create an implementation plan for ticket {CURRENT_TICKET}.

Let me check for existing research on this ticket...
```

### Step 3: Find Existing Research

Use the linear-document-locator agent to find research documents:

```bash
linearis attachments list --issue "$CURRENT_TICKET"
```

Look for documents with title starting with "Research:".

**If research found:**

```
I found existing research for {CURRENT_TICKET}:
- Research: {title}

I'll use this as context for the plan. Let me read it...
```

Read the research document content using linear-document-analyzer.

### Step 3a: Validate Research Answers (Required)

After reading the research document, check for unanswered **blocking** questions:

Look for questions marked `(blocking)` that still have the pattern: `**Answer**: _[please fill in]_`

Note: Non-blocking questions can remain unanswered - proceed with noted defaults if present.

**If unanswered blocking questions found:**

```
❌ Cannot proceed: Research document has unanswered questions

The following questions need answers before planning can begin:

**Q1 (blocking)**: {question text}
  → Location: Research document attached to {CURRENT_TICKET}

**Q2 (blocking)**: {question text}
  → Location: Research document attached to {CURRENT_TICKET}

Please answer these questions in the Linear document, then run:
  /create-plan
```

**Hard fail** - do not proceed until all blocking questions have answers.

**If all questions answered (or no questions section):**

Continue to Step 4.

**If no research found:**

```
No research document found for {CURRENT_TICKET}.

Would you like me to:
1. Create a plan without research (you'll provide context)
2. Run /research-codebase first (recommended)
```

### Step 4: Gather Planning Input

**Get assignee for headless mode** (used for document mentions):

```bash
ASSIGNEE=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" get-assignee "$CURRENT_TICKET")
```

**If MODE is "interactive":**

```
I'll help you create a detailed implementation plan for {CURRENT_TICKET}.

Please provide:
1. What feature/change are we implementing?
2. Any specific requirements or constraints
3. Preferred approach (if you have one)

I'll analyze this along with the research and work with you to create a comprehensive plan.
```

Then wait for the user's input.

**If MODE is "headless":**

- Use the ticket title, description, and research document as context
- Read the ticket details: `linearis issues read "$CURRENT_TICKET"`
- Make reasonable decisions based on research findings
- Track questions that arise during planning for embedding in document
- Do NOT wait for user input - proceed directly to planning steps

## Process Steps

### Step 1: Context Gathering & Initial Analysis

1. **Read the ticket details from Linear**:
   ```bash
   linearis issues read "$CURRENT_TICKET"
   ```

2. **Read any research documents** using linear-document-analyzer

3. **Spawn initial research tasks to gather codebase context**:
   - Use the **codebase-locator** agent to find all files related to the task
   - Use the **codebase-analyzer** agent to understand current implementation
   - Use the **linear-document-locator** agent to find any existing documents on this ticket

4. **Read all files identified by research tasks** FULLY into main context

5. **Present informed understanding and focused questions**:

   ```
   Based on the ticket and my research of the codebase, I understand we need to [accurate summary].

   I've found that:
   - [Current implementation detail with file:line reference]
   - [Relevant pattern or constraint discovered]
   - [Potential complexity or edge case identified]

   Questions that my research couldn't answer:
   - [Specific technical question that requires human judgment]
   - [Business logic clarification]
   - [Design preference that affects implementation]
   ```

### Step 2: Research & Discovery

After getting initial clarifications:

1. **Spawn parallel sub-tasks for comprehensive research**:

   **For local codebase:**
   - **codebase-locator** - Find specific files
   - **codebase-analyzer** - Understand implementation details
   - **codebase-pattern-finder** - Find similar features to model after

   **For external research:**
   - **external-research** - Research framework patterns and best practices

   **For existing Linear documents:**
   - **linear-document-locator** - Find related documents
   - **linear-document-analyzer** - Extract insights from documents

   **For related tickets:**
   - **linear-research** - Find similar issues or past implementations

2. **Wait for ALL sub-tasks to complete** before proceeding

3. **Present findings and design options**:

   ```
   Based on my research, here's what I found:

   **Current State:**
   - [Key discovery about existing code]
   - [Pattern or convention to follow]

   **Design Options:**
   1. [Option A] - [pros/cons]
   2. [Option B] - [pros/cons]

   **Open Questions:**
   - [Technical uncertainty]
   - [Design decision needed]

   Which approach aligns best with your vision?
   ```

### Step 3: Plan Structure Development

Once aligned on approach:

1. **Update Linear ticket status**:
   ```bash
   linearis issues update "$CURRENT_TICKET" --state "Plan in Progress"
   linearis comments create "$CURRENT_TICKET" --body "Starting implementation planning"
   ```

2. **Create initial plan outline**:

   ```
   Here's my proposed plan structure:

   ## Overview
   [1-2 sentence summary]

   ## Implementation Phases:
   1. [Phase name] - [what it accomplishes]
   2. [Phase name] - [what it accomplishes]
   3. [Phase name] - [what it accomplishes]

   Does this phasing make sense? Should I adjust the order or granularity?
   ```

3. **Get feedback on structure** before writing details

### Step 4: Detailed Plan Writing

After structure approval, create the plan document content:

````markdown
# [Feature/Task Name] Implementation Plan

**Ticket**: {CURRENT_TICKET}
**Date**: {date}
**Branch**: {branch-name}
**Repository**: {repo-name}

## Overview

[Brief description of what we're implementing and why]

## Current State Analysis

[What exists now, what's missing, key constraints discovered]

## Desired End State

[A Specification of the desired end state after this plan is complete, and how to verify it]

### Key Discoveries:

- [Important finding with file:line reference]
- [Pattern to follow]
- [Constraint to work within]

## What We're NOT Doing

[Explicitly list out-of-scope items to prevent scope creep]

## Implementation Approach

[High-level strategy and reasoning]

## Phase 1: [Descriptive Name]

### Overview

[What this phase accomplishes]

### Changes Required:

#### 1. [Component/File Group]

**File**: `path/to/file.ext`
**Changes**: [Summary of changes]

```[language]
// Specific code to add/modify
```

### Success Criteria:

#### Automated Verification:

- [ ] Migration applies cleanly: `make migrate`
- [ ] Unit tests pass: `make test-component`
- [ ] Type checking passes: `npm run typecheck`
- [ ] Linting passes: `make lint`

#### Manual Verification:

- [ ] Feature works as expected when tested via UI
- [ ] Performance is acceptable under load
- [ ] No regressions in related features

---

## Phase 2: [Descriptive Name]

[Similar structure...]

---

## Questions for User

{ONLY include this section in headless mode when questions arise during planning}

{If ASSIGNEE is set:}
@{ASSIGNEE} - Please answer before proceeding to /implement-plan:

{If no ASSIGNEE:}
Please answer before proceeding to /implement-plan:

> **Q1 (blocking)**: {Question that must be answered before implementation}
> **Context**: {Why this matters for implementation}
> **Options**: A) {option} B) {option} C) {option}
> **Answer**: _[please fill in]_

> **Q2 (non-blocking)**: {Question that helps but has a reasonable default}
> **Context**: {Background information}
> **Answer**: _[please fill in]_

{Note: Only include questions that genuinely arose during planning and affect implementation}

---

## Testing Strategy

### Unit Tests:
- [What to test]
- [Key edge cases]

### Integration Tests:
- [End-to-end scenarios]

### Manual Testing Steps:
1. [Specific step to verify feature]
2. [Another verification step]

## References

- Ticket: {CURRENT_TICKET}
- Research: (attached to ticket in Linear)
````

### Step 5: Save Plan to Linear

Create the plan document in Linear:

```bash
# Get team key from config
TEAM_KEY=$(jq -r '.awl.linear.teamKey // "PROJ"' .claude/config.json)

# Create Linear document with plan content
linearis documents create \
  --title "Plan: ${DESCRIPTION}" \
  --team "${TEAM_KEY}" \
  --content "${PLAN_CONTENT}" \
  --attach-to "${CURRENT_TICKET}" \
  --icon "Compass" \
  --color "#f2c94c"

# Add completion comment to ticket
linearis comments create "$CURRENT_TICKET" --body "Implementation plan created and attached to this ticket."
```

**In headless mode with embedded questions:**

If the document contains a "Questions for User" section with unanswered questions:

```bash
# Set ticket status to "Spec Needed" to signal human input required
linearis issues update "$CURRENT_TICKET" --state "Spec Needed"
```

Then output a clear message:

```
✅ Implementation plan created with questions pending.

**Ticket**: {CURRENT_TICKET}
**Status**: Spec Needed

The plan document has been attached to the ticket with {N} questions
that need answers before proceeding to /implement-plan.

Please answer the questions in the Linear document, then run:
  claude -p "/implement-plan"
```

### Step 6: Present Plan and Check Context

```
✅ Implementation plan created!

**Ticket**: {CURRENT_TICKET}
**Linear Document**: Plan: {description}

## 📊 Context Status

Current usage: {X}% ({Y}K/{Z}K tokens)

{If >60%}:
⚠️ **Context Alert**: We're at {X}% context usage.

**Recommendation**: Clear context before implementation phase.

**What to do**:
1. ✅ Review the plan in Linear
2. ✅ Close this session (clear context)
3. ✅ Start fresh session
4. ✅ Run `/implement-plan`

{If <60%}:
✅ Context healthy ({X}%).

---

Please review the plan and let me know:
- Are the phases properly scoped?
- Are the success criteria specific enough?
- Any technical details that need adjustment?
```

### Step 7: Iterate Based on Feedback

- Update the Linear document with changes
- Use `linearis documents update <document-id>` to modify content
- Continue refining until user is satisfied

## Important Guidelines

1. **Be Skeptical**:
   - Question vague requirements
   - Identify potential issues early
   - Ask "why" and "what about"
   - Don't assume - verify with code

2. **Be Interactive**:
   - Don't write the full plan in one shot
   - Get buy-in at each major step
   - Allow course corrections
   - Work collaboratively

3. **Be Thorough**:
   - Read all context files COMPLETELY before planning
   - Research actual code patterns using parallel sub-tasks
   - Include specific file paths and line numbers
   - Write measurable success criteria with clear automated vs manual distinction

4. **Be Practical**:
   - Focus on incremental, testable changes
   - Consider migration and rollback
   - Think about edge cases
   - Include "what we're NOT doing"

5. **Track Progress**:
   - Use TodoWrite to track planning tasks
   - Update todos as you complete research
   - Mark planning tasks complete when done

6. **No Open Questions in Final Plan**:
   - If you encounter open questions during planning, STOP
   - Research or ask for clarification immediately
   - Do NOT write the plan with unresolved questions
   - The implementation plan must be complete and actionable
   - Every decision must be made before finalizing the plan

## Success Criteria Guidelines

**Always separate success criteria into two categories:**

1. **Automated Verification** (can be run by execution agents):
   - Commands that can be run: `make test`, `npm run lint`, etc.
   - Specific files that should exist
   - Code compilation/type checking
   - Automated test suites

2. **Manual Verification** (requires human testing):
   - UI/UX functionality
   - Performance under real conditions
   - Edge cases that are hard to automate
   - User acceptance criteria

**Format example:**

```markdown
### Success Criteria:

#### Automated Verification:

- [ ] Database migration runs successfully: `make migrate`
- [ ] All unit tests pass: `go test ./...`
- [ ] No linting errors: `golangci-lint run`
- [ ] API endpoint returns 200: `curl localhost:8080/api/new-endpoint`

#### Manual Verification:

- [ ] New feature appears correctly in the UI
- [ ] Performance is acceptable with 1000+ items
- [ ] Error messages are user-friendly
- [ ] Feature works correctly on mobile devices
```

## Integration with Other Commands

```
/research-codebase PROJ-123 → research document
                  ↓
           /create-plan → implementation plan (this command)
                  ↓
          /implement-plan → code changes
                  ↓
              /describe-pr → PR created
```

**How it connects:**

- **Previous**: Gets research from Linear documents attached to ticket
- **Next**: `/implement-plan` finds plan via `linear-document-locator`
- **Workflow context**: Current ticket is already set from research phase

## Example Workflow

```bash
# After running /research-codebase PROJ-123...

/create-plan
# You:
# 1. Get current ticket from workflow context (PROJ-123)
# 2. Find research document in Linear
# 3. Read research content
# 4. Ask for planning input
# 5. Research codebase further
# 6. Create plan outline
# 7. Get user approval
# 8. Write detailed plan
# 9. Save to Linear as "Plan: {description}"
# 10. Present summary
```
