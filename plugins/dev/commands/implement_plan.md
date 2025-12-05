---
description: Implement approved technical plans from Linear documents
category: workflow
tools: Read, Write, Edit, Grep, Glob, Task, TodoWrite, Bash
model: inherit
version: 2.0.0
---

# Implement Plan

You are tasked with implementing an approved technical plan stored as a Linear document attached to
the current ticket.

## Prerequisites

Before executing, verify Linear integration is available:

```bash
# Validate plugin prerequisites (includes LINEAR_API_TOKEN check)
if [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" ]]; then
  "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" || exit 1
fi
```

## Initial Response

### Step 1: Get Current Ticket

Check workflow context for current ticket:

```bash
CURRENT_TICKET=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" get-ticket)
```

### Step 2: Handle Ticket State

**If no current ticket:**

```
I need a Linear ticket to find the implementation plan.

Please either:
1. Provide a ticket ID: `/implement-plan PROJ-123`
2. Run `/create-plan` first (which sets the current ticket)

Which would you prefer?
```

If user provides ticket, set it:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" set-ticket "$TICKET_ID"
```

**If current ticket exists:**

```
I'll implement the plan for ticket {CURRENT_TICKET}.

Let me find the implementation plan...
```

### Step 3: Find the Plan Document

Use the linear-document-locator agent to find plan documents:

```bash
linearis attachments list --issue "$CURRENT_TICKET"
```

Look for documents with title starting with "Plan:".

**If plan found:**

```
Found implementation plan for {CURRENT_TICKET}:
- Plan: {title}

Let me read the full plan...
```

Read the plan document content using linear-document-analyzer.

### Step 3a: Validate Plan Answers (Required)

After reading the plan document, check for unanswered **blocking** questions:

Look for questions marked `(blocking)` that still have the pattern: `**Answer**: _[please fill in]_`

Note: Non-blocking questions can remain unanswered - proceed with noted defaults if present.

**If unanswered blocking questions found:**

```
❌ Cannot proceed: Plan document has unanswered questions

The following questions need answers before implementation can begin:

**Q1 (blocking)**: {question text}
  → Location: Plan document attached to {CURRENT_TICKET}

**Q2 (blocking)**: {question text}
  → Location: Plan document attached to {CURRENT_TICKET}

Please answer these questions in the Linear document, then run:
  /implement-plan
```

**Hard fail** - do not proceed until all blocking questions have answers.

**If all questions answered (or no questions section):**

Continue to Step 4.

**If no plan found:**

```
No implementation plan found for {CURRENT_TICKET}.

Would you like me to:
1. Create a plan first? Run `/create-plan`
2. Check a different ticket?
```

**If multiple plans found:**

```
Found multiple plans for {CURRENT_TICKET}:
1. Plan: {title1} (created {date1})
2. Plan: {title2} (created {date2})

Which plan should I implement?
```

### Step 4: Read and Prepare

Once you have the plan document:

1. **Read the plan completely** using `linearis documents read <document-id>`
2. **Read the original ticket** using `linearis issues read "$CURRENT_TICKET"`
3. **Check for progress markers** - look for checkboxes (- [x]) to see what's done
4. **Read all files mentioned in the plan** FULLY into context
5. **Think deeply** about how the pieces fit together
6. **Create a todo list** to track your progress
7. **Update Linear ticket status**:
   ```bash
   linearis issues update "$CURRENT_TICKET" --state "In Dev"
   linearis comments create "$CURRENT_TICKET" --body "Starting implementation of plan"
   ```

## Implementation Philosophy

Plans are carefully designed, but reality can be messy. Your job is to:

- Follow the plan's intent while adapting to what you find
- Implement each phase fully before moving to the next
- Verify your work makes sense in the broader codebase context
- Update checkboxes in the plan document as you complete sections

When things don't match the plan exactly, think about why and communicate clearly. The plan is your
guide, but your judgment matters too.

If you encounter a mismatch:

- STOP and think deeply about why the plan can't be followed
- Present the issue clearly:

  ```
  Issue in Phase [N]:
  Expected: [what the plan says]
  Found: [actual situation]
  Why this matters: [explanation]

  How should I proceed?
  ```

## Updating Progress in Linear

As you complete phases, update the plan document in Linear:

```bash
# Update plan document with progress
linearis documents update "$DOCUMENT_ID" --content "${UPDATED_PLAN_CONTENT}"

# Add progress comment to ticket
linearis comments create "$CURRENT_TICKET" --body "Completed Phase {N}: {phase name}"
```

**Checkbox Convention**: Use `- [x]` for completed items, `- [ ]` for pending items.

## Verification Approach

After implementing a phase:

- Run the success criteria checks (usually `make check test` covers everything)
- Fix any issues before proceeding
- Update the Linear plan document with checkboxes for completed work
- Add a comment to the ticket summarizing what was completed
- **Check context usage** - monitor token consumption

Don't let verification interrupt your flow - batch it at natural stopping points.

## Context Management During Implementation

**Monitor context proactively throughout implementation**:

**After Each Phase**:

```
✅ Phase {N} complete!

## 📊 Context Status
Current usage: {X}% ({Y}K/{Z}K tokens)

{If >60%}:
⚠️ **Context Alert**: We're at {X}% usage.

**Recommendation**: Create a handoff before continuing to Phase {N+1}.

**Why?** Implementation accumulates context:
- File reads
- Code changes
- Test outputs
- Error messages
- Context clears ensure continued high performance

**Options**:
1. ✅ Create handoff and clear context (recommended)
   - Use `/create-handoff` to generate handoff document in Linear
   - Includes what's done, what's next, key learnings
2. Continue to next phase (if close to completion)

**To resume**: Start fresh session, run `/implement-plan`
(The plan document tracks progress with checkboxes - you'll resume automatically)

{If <60%}:
✅ Context healthy. Ready for Phase {N+1}.
```

**When to Warn**:

- After any phase if context >60%
- If context >70%, strongly recommend handoff
- If context >80%, STOP and require handoff
- If user is spinning on errors (3+ attempts), suggest context clear

**Educate About Phase-Based Context**:

- Explain that implementation is designed to work in chunks
- Each phase completion is a natural handoff point
- Plan document in Linear preserves progress across sessions
- Fresh context = fresh perspective on next phase

**Creating a Handoff**:

When recommending a handoff, guide the user:

1. Offer to create the handoff using `/create-handoff`
2. Handoff will be saved as a Linear document attached to the ticket
3. Include: completed phases, next steps, key learnings, file references
4. Update plan document with checkboxes for completed work

## If You Get Stuck

When something isn't working as expected:

- First, make sure you've read and understood all the relevant code
- Consider if the codebase has evolved since the plan was written
- Present the mismatch clearly and ask for guidance

Use sub-tasks sparingly - mainly for targeted debugging or exploring unfamiliar territory.

## Resuming Work

If the plan has existing checkmarks:

- Trust that completed work is done
- Pick up from the first unchecked item
- Verify previous work only if something seems off

Remember: You're implementing a solution, not just checking boxes. Keep the end goal in mind and
maintain forward momentum.

## Post-Implementation Workflow

After all plan phases complete successfully, automatically execute the following:

### Phase A: Self-Healing Validation

1. **Run validation**:
   ```
   Running validation checks...
   ```

2. **Execute self-healing** (inline, not via SlashCommand):
   - Run project-specific checks (e.g., `pnpm run build`, `pnpm run lint`, `pnpm run typecheck`)
   - Parse failures
   - Fix each issue (max 3 attempts per issue type)
   - Re-run until pass or max attempts

3. **Create Validation document**:
   ```bash
   TEAM_KEY=$(jq -r '.awl.linear.teamKey // "PROJ"' .claude/config.json)

   linearis documents create \
     --title "Validation: ${FEATURE_NAME}" \
     --team "${TEAM_KEY}" \
     --content "${VALIDATION_CONTENT}" \
     --attach-to "${CURRENT_TICKET}" \
     --icon "CheckCircle" \
     --color "#27ae60"
   ```

4. **Check status**:
   - If FAIL: Stop and report to user
   - If PASS/PARTIAL: Continue to Phase B

### Phase B: PR Creation

1. **Call /create_pr**:
   ```
   Creating pull request...
   ```

   Use SlashCommand tool to invoke `/awl-dev:create_pr`

   This will:
   - Commit all changes
   - Push to remote
   - Create PR on GitHub
   - Auto-call /describe_pr
   - Create "PR: ..." Linear document
   - Update ticket to "In Review"

2. **Capture PR details**:
   - PR number
   - PR URL
   - Branch name

### Phase C: Review and Remediation

1. **Run comprehensive review**:
   ```
   Running PR review...
   ```

   Use SlashCommand tool to invoke `/pr-review-toolkit:review-pr all`

2. **Parse review output**:
   - Extract Critical Issues
   - Extract Important Issues
   - Extract Suggestions

3. **Remediation loop** (for each item):
   ```
   Addressing review item {N}/{total}: {description}
   Attempt {attempt}/3...
   ```
   - Implement the fix/suggestion
   - Stage changes (don't commit yet)
   - Verify fix works
   - If unfixable after 3 attempts, document why

4. **Track remediation results**:
   - Items fixed
   - Items that couldn't be fixed (with explanations)

### Phase D: Finalize PR

1. **Commit remediation fixes**:
   ```bash
   git add -A
   git commit -m "fix(review): address PR review feedback

   - {fix 1}
   - {fix 2}
   ...

   🤖 Generated with Claude Code"
   ```

2. **Squash commits** (interactive rebase simulation):
   ```bash
   # Get count of commits since branch point
   COMMIT_COUNT=$(git rev-list --count origin/main..HEAD)

   # Squash all into one clean commit
   git reset --soft HEAD~${COMMIT_COUNT}
   git commit -m "${FINAL_COMMIT_MESSAGE}"
   ```

3. **Force push clean history**:
   ```bash
   git push --force-with-lease
   ```

4. **Update PR description** (if needed):
   - Call `/awl-dev:describe_pr` to refresh description

### Final Report

Present completion summary:

```markdown
✅ Implementation Complete!

**Ticket**: {CURRENT_TICKET}
**PR**: #{number} - {url}

## Workflow Summary
- ✅ Implementation: All {N} phases complete
- ✅ Validation: All checks pass (fixed {X} issues)
- ✅ PR Created: #{number}
- ✅ Review: Addressed {Y} items

## Linear Documents
- Research: {link}
- Plan: {link}
- Validation: {link}
- PR: {link}

{IF any unfixed items:}
## ⚠️ Items Requiring Manual Attention

The following items could not be automatically resolved:

1. **{Issue type}**: {description}
   - **Attempted**: {what was tried}
   - **Why it failed**: {explanation}
   - **Suggested action**: {what user should do}

{END IF}

Ready for human review!
```

### Error Handling

**Validation fails after all attempts**:
```
❌ Validation Failed

Critical issues could not be resolved:
- {issue 1}: {explanation}
- {issue 2}: {explanation}

The implementation is incomplete. Please:
1. Review the issues above
2. Fix manually or adjust the plan
3. Run `/implement-plan` again to retry
```

**PR creation fails**:
```
❌ PR Creation Failed

Error: {error message}

Changes have been committed locally. Please:
1. Check git status
2. Resolve any conflicts
3. Run `/create_pr` manually
```

**Review finds unfixable issues**:
- Continue with remaining items
- Document unfixable items in final report
- PR is still created but flagged for attention

## Integration with Other Commands

```
/research-codebase PROJ-123 → research document
                  ↓
           /create-plan → implementation plan
                  ↓
          /implement-plan → code changes (this command)
                  │
                  ├─→ [Phase A] Self-healing validation
                  │     └─→ Creates: "Validation: ..." document
                  │
                  ├─→ [Phase B] Auto-calls /create_pr
                  │     └─→ Creates: PR + "PR: ..." document
                  │
                  ├─→ [Phase C] Auto-calls /pr-review-toolkit:review-pr
                  │     └─→ Remediation loop (fix all items)
                  │
                  └─→ [Phase D] Squash & finalize
                        └─→ Clean PR ready for review
```

**How it connects:**

- **Previous**: Gets plan from Linear documents attached to ticket
- **Automatic**: Validation, PR creation, review, and remediation all happen automatically
- **Output**: Clean PR with all documents linked in Linear

## Error Handling

**If document read fails:**

```
⚠️ Could not read plan document.

Please verify:
1. The document ID is correct
2. You have access to this Linear workspace
3. LINEAR_API_TOKEN is set correctly

Try running `/create-plan` to create a new plan.
```

**If ticket not found:**

```
⚠️ Ticket {TICKET_ID} not found in Linear.

Please verify:
1. The ticket ID is correct (e.g., PROJ-123)
2. You have access to this Linear team
3. LINEAR_API_TOKEN is set correctly
```
