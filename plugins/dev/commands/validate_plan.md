---
description: Validate that implementation plans were correctly executed
category: workflow
tools: mcp__linear__get_issue, mcp__linear__save_issue, mcp__linear__save_comment, mcp__linear__create_document, mcp__linear__get_document, Read, Grep, Glob, Task, TodoWrite, Bash
model: inherit
version: 2.0.0
---

# Validate Plan

You are tasked with validating that an implementation plan was correctly executed, verifying all
success criteria and identifying any deviations or issues.

## Initial Setup

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
1. Provide a ticket ID: `/validate-plan PROJ-123`
2. Or tell me which ticket to validate

Which would you prefer?
```

If user provides ticket, set it:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" set-ticket "$TICKET_ID"
```

**If current ticket exists:**

```
I'll validate the implementation for ticket {CURRENT_TICKET}.

Let me find the plan and gather implementation evidence...
```

### Step 3: Find and Read the Plan

Use `mcp__linear__get_issue` with the ticket identifier to retrieve the issue and its attached documents. Look for documents with title starting with "Plan:".

**If plan found:**
- Read the full plan content using `mcp__linear__get_document` with the document ID

**If no plan found:**

```
No implementation plan found for {CURRENT_TICKET}.

Cannot validate without a plan. Would you like me to:
1. Check a different ticket?
2. Validate against a different source?
```

### Step 4: Gather Implementation Evidence

```bash
# Check recent commits
git log --oneline -n 20
git diff HEAD~N..HEAD  # Where N covers implementation commits

# Run comprehensive checks
cd $(git rev-parse --show-toplevel) && make check test
```

## Self-Healing Validation

After running initial checks, if any failures are detected, attempt to fix them automatically:

### Step 5: Analyze and Fix Issues

For each failing check:

1. **Analyze the failure**:
   - Parse error output to identify specific issues
   - Categorize: build error, lint error, type error, test failure

2. **Attempt automatic fix** (max 3 attempts per issue type):
   ```
   Attempt {N}/3 to fix {issue_type}:
   - Issue: {description}
   - Analyzing root cause...
   - Implementing fix...
   - Re-running check...
   ```

3. **Track results**:
   - Record what was attempted
   - Record success/failure
   - If failed after 3 attempts, document why

4. **Critical vs Non-Critical**:
   - **Critical** (build, test): Must pass to continue
   - **Non-critical** (lint warnings): Note and continue

### Step 6: Create Validation Document

Create a Linear document with validation results using `mcp__linear__create_document`. Set the title to "Validation: {FEATURE_NAME}" and include the validation content as the document body. Attach the document to the current ticket.

**Validation Document Content**:

```markdown
# Validation: {Feature Name}

**Ticket**: {CURRENT_TICKET}
**Date**: {timestamp}
**Status**: {PASS|FAIL|PARTIAL}

## Checks Run

| Check | Initial | Final | Attempts |
|-------|---------|-------|----------|
| Build | ❌ | ✅ | 2 |
| Lint | ⚠️ | ✅ | 1 |
| Type Check | ✅ | ✅ | 0 |
| Tests | ✅ | ✅ | 0 |

## Issues Fixed

### Build Error
- **Issue**: Missing import in component.ts
- **Fix**: Added import statement
- **Attempts**: 2

## Issues Not Fixed

{If any:}
### {Issue Type}
- **Issue**: {description}
- **Attempted**: {what was tried}
- **Why it failed**: {explanation}
- **Suggested action**: {manual steps}

## Final Status

{PASS: All critical checks pass}
{FAIL: Critical checks still failing - manual intervention required}
{PARTIAL: Critical pass, non-critical issues remain}
```

## Validation Process

### Step 1: Context Discovery

If starting fresh or need more context:

1. **Read the implementation plan** completely from Linear
2. **Identify what should have changed**:
   - List all files that should be modified
   - Note all success criteria (automated and manual)
   - Identify key functionality to verify

3. **Spawn parallel research tasks** to discover implementation:

   ```
   Task 1 - Verify database changes:
   Research if migration [N] was added and schema changes match plan.
   Check: migration files, schema version, table structure
   Return: What was implemented vs what plan specified

   Task 2 - Verify code changes:
   Find all modified files related to [feature].
   Compare actual changes to plan specifications.
   Return: File-by-file comparison of planned vs actual

   Task 3 - Verify test coverage:
   Check if tests were added/modified as specified.
   Run test commands and capture results.
   Return: Test status and any missing coverage
   ```

### Step 2: Systematic Validation

For each phase in the plan:

1. **Check completion status**:
   - Look for checkmarks in the plan (- [x])
   - Verify the actual code matches claimed completion

2. **Run automated verification**:
   - Execute each command from "Automated Verification"
   - Document pass/fail status
   - If failures, investigate root cause

3. **Assess manual criteria**:
   - List what needs manual testing
   - Provide clear steps for user verification

4. **Think deeply about edge cases**:
   - Were error conditions handled?
   - Are there missing validations?
   - Could the implementation break existing functionality?

### Step 3: Generate Validation Report

**Before generating report, check context usage**:

Create comprehensive validation summary:

```
# Validation Report: {Feature Name}

**Ticket**: {CURRENT_TICKET}
**Plan**: (Linear document attached to ticket)
**Validated**: {date}
**Validation Status**: {PASS/FAIL/PARTIAL}

## 📊 Context Status
Current usage: {X}% ({Y}K/{Z}K tokens)

{If >60%}:
⚠️ **Context Alert**: Validation consumed {X}% of context.

**Recommendation**: After reviewing this report, clear context before PR creation.

**Why?** PR description generation benefits from fresh context to:
- Synthesize changes clearly
- Write concise summaries
- Avoid accumulated error context

**Next steps**:
1. Review this validation report
2. Address any failures
3. Close this session (clear context)
4. Start fresh for: `/commit` and `/describe-pr`

{If <60%}:
✅ Context healthy. Ready for PR creation.

---

{Continue with rest of validation report...}
```

```markdown
## Validation Report: [Plan Name]

### Implementation Status

✓ Phase 1: [Name] - Fully implemented
✓ Phase 2: [Name] - Fully implemented
⚠️ Phase 3: [Name] - Partially implemented (see issues)

### Automated Verification Results

✓ Build passes: `make build`
✓ Tests pass: `make test`
✗ Linting issues: `make lint` (3 warnings)

### Code Review Findings

#### Matches Plan:

- Database migration correctly adds [table]
- API endpoints implement specified methods
- Error handling follows plan

#### Deviations from Plan:

- Used different variable names in [file:line]
- Added extra validation in [file:line] (improvement)

#### Potential Issues:

- Missing index on foreign key could impact performance
- No rollback handling in migration

### Manual Testing Required:

1. UI functionality:
   - [ ] Verify [feature] appears correctly
   - [ ] Test error states with invalid input

2. Integration:
   - [ ] Confirm works with existing [component]
   - [ ] Check performance with large datasets

### Recommendations:

- Address linting warnings before merge
- Consider adding integration test for [scenario]
- Document new API endpoints
```

### Step 4: Update Linear

Add validation results to the ticket:

- Use `mcp__linear__save_comment` to add a comment to the ticket with the validation status and summary of findings.
- If all phases are complete, use `mcp__linear__save_issue` to update the ticket state to "In Review".

## Working with Existing Context

If you were part of the implementation:

- Review the conversation history
- Check your todo list for what was completed
- Focus validation on work done in this session
- Be honest about any shortcuts or incomplete items

## Important Guidelines

1. **Be thorough but practical** - Focus on what matters
2. **Run all automated checks** - Don't skip verification commands
3. **Document everything** - Both successes and issues
4. **Think critically** - Question if the implementation truly solves the problem
5. **Consider maintenance** - Will this be maintainable long-term?

## Validation Checklist

Always verify:

- [ ] All phases marked complete are actually done
- [ ] Automated tests pass
- [ ] Code follows existing patterns
- [ ] No regressions introduced
- [ ] Error handling is robust
- [ ] Documentation updated if needed
- [ ] Manual test steps are clear

## Integration with Other Commands

```
/research-codebase PROJ-123 → research document
                  ↓
           /create-plan → implementation plan
                  ↓
          /implement-plan → code changes
                  ↓
           /validate-plan → verification (this command)
                  ↓
              /describe-pr → PR created
```

**How it connects:**

- **Previous**: Finds plan from Linear documents attached to ticket
- **Next**: `/describe-pr` creates PR description, also as Linear document
- **Workflow context**: Current ticket is tracked throughout

The validation works best after commits are made, as it can analyze the git history to understand
what was implemented.

## Error Handling

**If plan not found:**

```
⚠️ No plan document found for {CURRENT_TICKET}.

Options:
1. Provide a different ticket ID
2. Run validation without a formal plan (ad-hoc verification)
```

**If ticket not found:**

```
⚠️ Ticket {TICKET_ID} not found in Linear.

Please verify:
1. The ticket ID is correct (e.g., PROJ-123)
2. You have access to this Linear team
```

Remember: Good validation catches issues before they reach production. Be constructive but thorough
in identifying gaps or improvements.

## Return Status for Chaining

When called programmatically (from implement_plan), return clear status:

**If PASS**:
```
VALIDATION_STATUS=PASS
All checks pass. Ready for PR creation.
```

**If FAIL** (critical issues remain):
```
VALIDATION_STATUS=FAIL
Critical issues could not be resolved:
- {issue 1}
- {issue 2}

Manual intervention required before PR creation.
```

**If PARTIAL** (non-critical issues remain):
```
VALIDATION_STATUS=PARTIAL
Critical checks pass. Non-critical issues noted:
- {issue 1}

Proceeding to PR creation with warnings.
```

**Note**: This command is typically called automatically by `/implement-plan` as part of the
post-implementation workflow. You can also run it standalone to validate an implementation.

## Status Update Convention

This command is a downstream command (typically called by `/implement-plan`) and does NOT update status on start. However, on failure, it should roll back to the appropriate previous state:

- Use `mcp__linear__save_issue` to update the ticket state back to "In Dev"
- Use `mcp__linear__save_comment` to add a comment explaining the validation failure and that the ticket is returning to development state
