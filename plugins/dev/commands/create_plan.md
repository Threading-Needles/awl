---
description: Create detailed implementation plans through an interactive process
category: workflow
tools: Read, Write, Grep, Glob, Task, TodoWrite, Bash, mcp__linear__get_issue, mcp__linear__save_issue, mcp__linear__save_comment, mcp__linear__create_document, mcp__linear__update_document, mcp__linear__get_document, mcp__linear__list_documents
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

Detect whether running interactively or headless (e.g., `CLAUDE_MODE=headless claude -p`):

```bash
MODE=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" detect-mode)
# MODE will be "interactive" or "headless"
```

**Mode behavior:**
- **Interactive**: Discuss options with user, ask clarifying questions using **AskUserQuestion** tool
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
1. Run `/awl-dev:research-codebase PROJ-123` first (recommended - includes research phase)
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

### Step 2a: Update Linear Ticket Status (FIRST)

**This MUST be the first action after confirming ticket**:

1. Use `mcp__linear__save_issue` to update the ticket state to "Plan in Progress" immediately - this is THE FIRST thing we do.
2. Use `mcp__linear__save_comment` to add a comment "Starting implementation planning" to the ticket.

### Step 3: Find Existing Research

Use `mcp__linear__get_issue` with the ticket ID to retrieve the issue and its attached documents. Look for documents with title starting with "Research:".

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
  /awl-dev:create-plan
```

**Hard fail** - do not proceed until all blocking questions have answers.

**If all questions answered (or no questions section):**

Continue to Step 3b.

**If no research found:**

```
No research document found for {CURRENT_TICKET}.

Would you like me to:
1. Create a plan without research (you'll provide context)
2. Run /awl-dev:research-codebase first (recommended)
```

### Step 3b: Check for Existing Plan

After finding research (or deciding to proceed without it), check for existing plan documents. Use `mcp__linear__get_issue` with the ticket ID to retrieve the issue and its attached documents. Look for documents with title starting with "Plan:".

**If existing plan found:**

Store the document ID and title for later use:
```
EXISTING_PLAN_ID={document_id}
EXISTING_PLAN_TITLE={title}
```

Continue to Step 3c for iteration decision.

**If multiple plans found:**

```
Found multiple plans for {CURRENT_TICKET}:
1. Plan: {title1} (created {date1})
2. Plan: {title2} (created {date2})

Which plan should I iterate on? (enter number, or 'new' for fresh plan)
```

**If no existing plan found:**

Continue to Step 4 (create new plan flow).

### Step 3c: Decide Iteration vs New Plan (if existing plan found)

**If MODE is "interactive":**

```
I found an existing plan for {CURRENT_TICKET}:
- {EXISTING_PLAN_TITLE}

Options:
1. **Iterate existing plan** - incorporate feedback and research updates
2. **Create new plan** - start fresh (existing plan preserved)

Which would you prefer? (1 or 2)
```

Wait for user response.

**If MODE is "headless":**

Automatically choose to iterate the existing plan:
```
Found existing plan: {EXISTING_PLAN_TITLE}
Proceeding with iteration (headless mode).
```

**If user chooses "Create new plan" or no existing plan:**

Continue to Step 4 (existing flow).

**If iterating existing plan:**

Continue to Step 4b (iteration flow).

### Step 4: Gather Planning Input

**Get assignee for headless mode** (used for document mentions):

Use `mcp__linear__get_issue` with the ticket ID to retrieve the issue details, including the assignee name. Extract the assignee from the response for use in document mentions.

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
- Read the ticket details using `mcp__linear__get_issue` with the ticket ID
- Make reasonable decisions based on research findings
- Track questions that arise during planning for embedding in document
- Do NOT wait for user input - proceed directly to planning steps

### Step 4b: Iterate Existing Plan

When iterating an existing plan (instead of creating new):

#### 1. Read Existing Plan

Use `mcp__linear__get_document` with the existing plan document ID to retrieve the full plan content.

Parse the existing plan to identify:
- Current phases and their completion status (look for [x] checkboxes)
- Existing success criteria
- Any "Questions for User" section with answers
- Implementation approach and file references

#### 2. Identify Changes Needed

Compare existing plan against:
- Updated research document (if research was updated since plan creation)
- Ticket description changes
- Feedback in ticket comments
- New requirements or constraints

In headless mode, look for ticket comments containing feedback. Use `mcp__linear__get_issue` with the ticket ID to retrieve the issue details including comments.

#### 3. Generate Updated Plan

**Preserve these sections** (do not regenerate):
- Phases already marked complete [x]
- Manual verification items already checked
- User-provided answers in "Questions for User" section
- Custom notes or additions

**Update these sections:**
- Overview (if scope changed)
- Incomplete phases (incorporate feedback)
- Success criteria (add new ones if needed)
- Testing strategy (if new test requirements)

#### 4. Present Changes for Review (interactive mode only)

**If MODE is "interactive":**

```
Here are the proposed changes to the existing plan:

**Added:**
- Phase 4: New validation requirements
- Success criterion: API response time < 200ms

**Modified:**
- Phase 2: Updated approach based on research findings
- Overview: Clarified scope

**Preserved:**
- Phase 1 (already complete)
- Manual verification checklist

Does this look correct? (yes/no/edit)
```

**If MODE is "headless":**

Proceed directly to Step 5 with the updated plan content.

After Step 4b, continue to Step 5 (Save Plan to Linear) with the iteration path.

## Process Steps

### Step 1: Context Gathering & Initial Analysis

1. **Read the ticket details from Linear** using `mcp__linear__get_issue` with the ticket ID

2. **Read any research documents** using linear-document-analyzer

3. **Spawn initial research tasks to gather codebase context**:
   - Use the **codebase-locator** agent to find all files related to the task
   - Use the **codebase-analyzer** agent to understand current implementation
   - Use the **linear-document-locator** agent to find any existing documents on this ticket

4. **Read all files identified by research tasks** FULLY into main context

5. **Present informed understanding and ask focused questions**:

   Present a brief summary of your understanding, then use the **AskUserQuestion** tool for any
   questions that your research couldn't answer. Examples:
   - Technical decisions that require human judgment
   - Business logic clarifications
   - Design preferences that affect implementation

   **In interactive mode**: Always use AskUserQuestion — do NOT just print questions as text.
   Wait for answers before proceeding.

   **In headless mode**: Note questions for embedding in the plan document later.

### Step 2: Research & Discovery

After getting initial clarifications:

1. **Spawn parallel sub-tasks for comprehensive research**:

   **For local codebase:**
   - **codebase-locator** - Find specific files
   - **codebase-analyzer** - Understand implementation details
   - **codebase-pattern-finder** - Find similar features to model after

   **For historical context:**
   - **history-reader** - Find relevant decisions and patterns from completed work

   **For external research:**
   - **external-research** - Research framework patterns and best practices

   **For existing Linear documents:**
   - **linear-document-locator** - Find related documents
   - **linear-document-analyzer** - Extract insights from documents

   **For related tickets:**
   - **linear-research** - Find similar issues or past implementations

2. **Wait for ALL sub-tasks to complete** before proceeding

3. **Present findings and ask design questions**:

   Present a brief summary of your findings and the design options you've identified.

   **In interactive mode**: Use the **AskUserQuestion** tool to ask about design choices and open
   questions. Frame options clearly so the user can choose. Examples:
   - "Which approach should we use?" with concrete options
   - "Should we prioritize X or Y?"
   - Technical uncertainties that affect the plan

   Wait for the user's answers before proceeding to plan structure.

   **In headless mode**: Make reasonable decisions based on research findings and note any
   questions for the document.

### Step 3: Plan Structure Development

Once aligned on approach:

1. **Create initial plan outline**:

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

2. **Get feedback on structure** before writing details

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

{HEADLESS MODE ONLY — In interactive mode, all questions were already asked and answered via
AskUserQuestion during the planning process. Do NOT include this section in interactive mode.}

{If ASSIGNEE is set:}
@{ASSIGNEE} - Please answer before proceeding to /awl-dev:implement-plan:

{If no ASSIGNEE:}
Please answer before proceeding to /awl-dev:implement-plan:

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

**If creating new plan (no existing plan or user chose "new"):**

1. Use `mcp__linear__create_document` to create a new Linear document with the plan content. Set the title to "Plan: {DESCRIPTION}" and include the full plan markdown as the content. Attach it to the current ticket.
2. Use `mcp__linear__save_comment` to add a completion comment to the ticket: "Implementation plan created and attached to this ticket."

**If updating existing plan (iteration):**

1. Use `mcp__linear__update_document` with the existing plan document ID to update its content with the revised plan.
2. Use `mcp__linear__save_comment` to add an iteration comment to the ticket: "Implementation plan updated with latest feedback and research."

Add metadata comment at top of plan to track iterations:

```markdown
<!-- Plan iteration: {N} -->
<!-- Last updated: {timestamp} -->
<!-- Previous update: {previous_timestamp} -->
```

**In headless mode with embedded questions:**

If the document contains a "Questions for User" section with unanswered questions:

Use `mcp__linear__save_issue` to set the ticket status to "Spec Needed" to signal human input is required.

Then output a clear message:

```
✅ Implementation plan created with questions pending.

**Ticket**: {CURRENT_TICKET}
**Status**: Spec Needed

The plan document has been attached to the ticket with {N} questions
that need answers before proceeding to /awl-dev:implement-plan.

Please answer the questions in the Linear document, then run:
  CLAUDE_MODE=headless claude -p "/awl-dev:implement-plan"
```

### Step 6: Present Plan and Check Context

**If new plan created:**

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
4. ✅ Run `/awl-dev:implement-plan`

{If <60%}:
✅ Context healthy ({X}%).

---

Please review the plan and let me know:
- Are the phases properly scoped?
- Are the success criteria specific enough?
- Any technical details that need adjustment?
```

**If existing plan updated (iteration):**

```
✅ Implementation plan updated!

**Ticket**: {CURRENT_TICKET}
**Linear Document**: {EXISTING_PLAN_TITLE} (iteration #{N})

**Changes made:**
- {summary of what was updated}
- {sections preserved}

## 📊 Context Status

Current usage: {X}% ({Y}K/{Z}K tokens)

{If >60%}:
⚠️ **Context Alert**: We're at {X}% context usage.

**Recommendation**: Clear context before implementation phase.

**What to do**:
1. ✅ Review the updated plan in Linear
2. ✅ Close this session (clear context)
3. ✅ Start fresh session
4. ✅ Run `/awl-dev:implement-plan`

{If <60%}:
✅ Context healthy ({X}%).

---

Please review the updated plan and let me know:
- Do the changes address the feedback?
- Are the preserved sections still accurate?
- Any additional modifications needed?
```

### Step 7: Iterate Based on Feedback

- Update the Linear document with changes using `mcp__linear__update_document` with the document ID and revised content
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
/awl-dev:research-codebase PROJ-123 → research document
                  ↓
           /awl-dev:create-plan → implementation plan (this command)
                  ↓
          /awl-dev:implement-plan → code changes
                  ↓
              /awl-dev:describe-pr → PR created
```

**How it connects:**

- **Previous**: Gets research from Linear documents attached to ticket
- **Next**: `/awl-dev:implement-plan` finds plan via `linear-document-locator`
- **Workflow context**: Current ticket is already set from research phase

## Example Workflow

```bash
# After running /awl-dev:research-codebase PROJ-123...

/awl-dev:create-plan
# You:
# 1. Get current ticket from workflow context (PROJ-123)
# 2. Update ticket status to "Plan in Progress" (THE FIRST thing)
# 3. Find research document in Linear
# 4. Read research content
# 5. Ask for planning input
# 6. Research codebase further
# 7. Create plan outline
# 8. Get user approval
# 9. Write detailed plan
# 10. Save to Linear as "Plan: {description}"
# 11. Present summary
```

## Status Update Convention

**EVERY workflow step MUST update status as the FIRST action**:

- Step 2a updates status to "Plan in Progress" BEFORE any document lookups
- Status stays "Plan in Progress" after completion (next command advances it)
- On failure, roll back to previous state:
  1. Use `mcp__linear__save_issue` to set the ticket state back to "Research in Progress"
  2. Use `mcp__linear__save_comment` to add a comment: "Planning failed: {ERROR_REASON}"
