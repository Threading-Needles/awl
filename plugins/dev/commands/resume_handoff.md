---
description: Resume work from a handoff document
category: workflow
tools: Read, Bash, TodoWrite, Task
model: inherit
version: 2.0.0
---

# Resume Work from a Handoff Document

You are tasked with resuming work from a handoff document stored in Linear. These handoffs contain
critical context, learnings, and next steps from previous work sessions that need to be understood
and continued.

## Prerequisites

Before executing, verify Linear integration is available:

```bash
# Validate plugin prerequisites (includes LINEAR_API_TOKEN check)
if [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" ]]; then
  "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" || exit 1
fi
```

## Initial Response

### Step 1: Determine Ticket

**If user provided a ticket ID as parameter** (e.g., `/resume-handoff PROJ-123`):
- Set the ticket in workflow context:
  ```bash
  "${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" set-ticket "$TICKET_ID"
  ```
- Continue to Step 2

**If no parameter provided**:
- Check workflow context for current ticket:
  ```bash
  CURRENT_TICKET=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" get-ticket)
  ```

**If no current ticket:**

```
I need a Linear ticket to find handoff documents.

Please provide a ticket ID: `/resume-handoff PROJ-123`
```

### Step 2: Find Handoff Documents

Use the linear-document-locator to find handoff documents:

```bash
linearis attachments list --issue "$CURRENT_TICKET"
```

Look for documents with title starting with "Handoff:".

**If no handoff found:**

```
No handoff documents found for {CURRENT_TICKET}.

Would you like me to:
1. Check for other document types (research, plans)?
2. Start fresh implementation for this ticket?
```

**If multiple handoffs found:**

```
Found multiple handoff documents for {CURRENT_TICKET}:
1. Handoff: {title1} (created {date1})
2. Handoff: {title2} (created {date2})

Which handoff should I resume from? (Usually the most recent)
```

**If single handoff found:**

```
Found handoff for {CURRENT_TICKET}:
- Handoff: {title}

Let me read and analyze it...
```

### Step 3: Read Handoff and Related Documents

1. **Read handoff document completely** using `linearis documents read <document-id>`

2. **Find and read related documents** using linear-document-locator:
   - Research documents attached to the ticket
   - Plan documents attached to the ticket

3. **Read critical codebase files** mentioned in the handoff

## Process Steps

### Step 1: Analyze the Handoff

After reading the handoff:

1. **Extract key sections**:
   - Task(s) and their statuses
   - Recent changes
   - Learnings
   - Artifacts
   - Action items and next steps
   - Other notes

2. **Spawn focused research tasks** to verify current state:

   ```
   Task 1 - Verify recent changes:
   Check if the recent changes mentioned in the handoff still exist.
   1. Verify files mentioned in "Recent changes" section
   2. Check if the described changes are still present
   3. Look for any subsequent modifications
   4. Identify any conflicts or regressions
   Return: Current state of recent changes with file:line references
   ```

   ```
   Task 2 - Validate current codebase state:
   Verify the current state against what's described in the handoff.
   1. Check files mentioned in "Learnings" section
   2. Verify patterns and implementations still exist
   3. Look for any breaking changes since handoff
   4. Identify new related code added since handoff
   Return: Validation results and any discrepancies found
   ```

3. **Wait for ALL sub-tasks to complete** before proceeding

4. **Read critical files identified** into main context

### Step 2: Synthesize and Present Analysis

Present comprehensive analysis:

```
I've analyzed the handoff for {CURRENT_TICKET}. Here's the current situation:

**Original Tasks:**
- [Task 1]: [Status from handoff] → [Current verification]
- [Task 2]: [Status from handoff] → [Current verification]

**Key Learnings Validated:**
- [Learning with file:line reference] - [Still valid/Changed]
- [Pattern discovered] - [Still applicable/Modified]

**Recent Changes Status:**
- [Change 1] - [Verified present/Missing/Modified]
- [Change 2] - [Verified present/Missing/Modified]

**Related Documents:**
- Research: {title} - [Key insight]
- Plan: {title} - [Current phase status]

**Recommended Next Actions:**
Based on the handoff's action items and current state:
1. [Most logical next step based on handoff]
2. [Second priority action]
3. [Additional tasks discovered]

**Potential Issues Identified:**
- [Any conflicts or regressions found]
- [Missing dependencies or broken code]

Shall I proceed with [recommended action 1], or would you like to adjust the approach?
```

### Step 3: Create Action Plan

1. **Use TodoWrite to create task list**:
   - Convert action items from handoff into todos
   - Add any new tasks discovered during analysis
   - Prioritize based on dependencies and handoff guidance

2. **Get confirmation** before proceeding

### Step 4: Begin Implementation

1. **Update Linear ticket status**:
   ```bash
   linearis issues update "$CURRENT_TICKET" --state "In Progress"
   linearis comments create "$CURRENT_TICKET" --body "Resuming work from handoff"
   ```

2. **Start with the first approved task**

3. **Reference learnings from handoff** throughout implementation

4. **Apply patterns and approaches documented** in the handoff

5. **Update progress** as tasks are completed

## Guidelines

1. **Be Thorough in Analysis**:
   - Read the entire handoff document first
   - Verify ALL mentioned changes still exist
   - Check for any regressions or conflicts
   - Read all referenced artifacts

2. **Be Interactive**:
   - Present findings before starting work
   - Get buy-in on the approach
   - Allow for course corrections
   - Adapt based on current state vs handoff state

3. **Leverage Handoff Wisdom**:
   - Pay special attention to "Learnings" section
   - Apply documented patterns and approaches
   - Avoid repeating mistakes mentioned
   - Build on discovered solutions

4. **Track Continuity**:
   - Use TodoWrite to maintain task continuity
   - Reference the handoff document in commits
   - Document any deviations from original plan
   - Consider creating a new handoff when done

5. **Validate Before Acting**:
   - Never assume handoff state matches current state
   - Verify all file references still exist
   - Check for breaking changes since handoff
   - Confirm patterns are still valid

## Common Scenarios

### Scenario 1: Clean Continuation

- All changes from handoff are present
- No conflicts or regressions
- Clear next steps in action items
- Proceed with recommended actions

### Scenario 2: Diverged Codebase

- Some changes missing or modified
- New related code added since handoff
- Need to reconcile differences
- Adapt plan based on current state

### Scenario 3: Incomplete Handoff Work

- Tasks marked as "in_progress" in handoff
- Need to complete unfinished work first
- May need to re-understand partial implementations
- Focus on completing before new work

### Scenario 4: Stale Handoff

- Significant time has passed
- Major refactoring has occurred
- Original approach may no longer apply
- Need to re-evaluate strategy

## Integration with Other Commands

```
/research-codebase PROJ-123 → research document
                  ↓
           /create-plan → implementation plan
                  ↓
          /implement-plan → code changes
                  ↓
          /create-handoff → handoff document
                  ↓
         /resume-handoff → continues work (this command)
```

**How it connects:**

- **Previous**: Handoff created by `/create-handoff` as Linear document
- **Next**: Continues implementation, may use `/implement-plan`, `/describe-pr`
- **Workflow context**: Sets current ticket for subsequent commands

## Error Handling

**If handoff document not readable:**

```
⚠️ Could not read handoff document.

Please verify:
1. The document ID is correct
2. You have access to this Linear workspace
3. LINEAR_API_TOKEN is set correctly
```

**If ticket not found:**

```
⚠️ Ticket {TICKET_ID} not found in Linear.

Please verify:
1. The ticket ID is correct (e.g., PROJ-123)
2. You have access to this Linear team
3. LINEAR_API_TOKEN is set correctly
```

## Example Interaction Flow

```
User: /resume-handoff PROJ-123
Assistant: Let me find and analyze handoff documents for PROJ-123...

[Sets ticket in workflow context]
[Queries Linear for documents]
[Reads handoff completely]
[Spawns research tasks]
[Waits for completion]
[Reads identified files]

I've analyzed the handoff for PROJ-123. Here's the current situation...

[Presents analysis]

Shall I proceed with implementing the webhook validation fix, or would you like to adjust the approach?

User: Yes, proceed with the webhook validation
Assistant: [Creates todo list and begins implementation]
```
