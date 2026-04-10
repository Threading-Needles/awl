---
description: Generate or update PR description with incremental changes
category: version-control-git
tools: mcp__linear__get_issue, mcp__linear__save_issue, mcp__linear__save_comment, mcp__linear__create_document, mcp__linear__update_document, mcp__linear__get_document, Bash, Read, Write
model: inherit
version: 3.0.0
---

# Generate/Update PR Description

Generates or updates PR description with incremental information, auto-updates title, and links
Linear tickets. The PR description is also saved as a Linear document for persistence.

## Prerequisites

Before executing, verify Linear MCP tools are available by confirming that the
`mcp__linear__get_issue` tool is accessible. No environment variables or CLI tools are
needed for Linear integration -- all Linear operations use MCP tools directly.

## Process:

### 1. Identify target PR

**If argument provided:**

- Use that PR number: `/describe_pr 123`

**If no argument:**

```bash
# Try current branch
gh pr view --json number,url,title,state,body,headRefName,baseRefName 2>/dev/null
```

If no PR on current branch OR on main/master:

```bash
# List recent PRs
gh pr list --limit 10 --json number,title,headRefName,state
```

Ask user: "Which PR would you like to describe? (enter number)"

### 2. Extract ticket reference

**From multiple sources:**

```bash
# 1. From branch name
branch=$(gh pr view $pr_number --json headRefName -q .headRefName)
if [[ "$branch" =~ ([A-Z]+-[0-9]+) ]]; then
    ticket="${BASH_REMATCH[1]}"
fi

# 2. From PR title
title=$(gh pr view $pr_number --json title -q .title)
if [[ -z "$ticket" && "$title" =~ ([A-Z]+-[0-9]+) ]]; then
    ticket="${BASH_REMATCH[1]}"
fi

# 3. From existing PR body
body=$(gh pr view $pr_number --json body -q .body)
if [[ -z "$ticket" && "$body" =~ Refs:\ ([A-Z]+-[0-9]+) ]]; then
    ticket="${BASH_REMATCH[1]}"
fi
```

### 3. Check for existing PR description in Linear

Use `mcp__linear__get_issue` with the ticket identifier to retrieve the issue and its
attached documents. Inspect the returned documents for any with a title starting with "PR:".

### 4. Gather comprehensive PR information

```bash
# Full diff
gh pr diff $pr_number

# Commit history with messages
gh pr view $pr_number --json commits

# Changed files
gh pr view $pr_number --json files

# PR metadata
gh pr view $pr_number --json url,title,number,state,baseRefName,headRefName,author

# CI/CD status
gh pr checks $pr_number
```

### 5. Get Linear ticket context

Use `mcp__linear__get_issue` with the ticket identifier to retrieve the ticket's title,
description, status, and other metadata. Use the ticket title and description for context when
generating the PR description.

### 6. Analyze changes incrementally

**If this is an UPDATE (existing PR document found):**

- Read the existing PR document from Linear
- Extract previous commit list from metadata
- Compare with current commits
- Identify what's NEW since last description

**Analysis:**

- Identify what's NEW since last description
- Deep analysis of:
  - Code changes and architectural impact
  - Breaking changes
  - User-facing vs internal changes
  - Migration requirements
  - Security implications

### 7. Generate PR description

Use the standard PR description format:

```markdown
<!-- Auto-generated: {timestamp} -->
<!-- Last updated: {timestamp} -->
<!-- PR: #{pr_number} -->
<!-- Previous commits: {commit_list} -->

## Summary

{Brief overview of changes}

## Changes Made

### Backend Changes
{List of backend changes}

### Frontend Changes
{List of frontend changes}

## How to Verify It

### Automated Checks
- [ ] Build passes: `make build`
- [ ] Tests pass: `make test`
- [ ] Lint passes: `make lint`

### Manual Verification
- [ ] Feature works as expected
- [ ] No regressions in related features

## Related Issues/PRs

- Fixes https://linear.app/{workspace}/issue/{ticket}

## Changelog Entry

{One-line changelog entry}

## Reviewer Notes

{Notes for reviewers}

## Post-Merge Tasks

- [ ] Update documentation if needed
- [ ] Announce in relevant channels
```

**Merge descriptions intelligently:**

**Auto-generated sections (always update):**
- **Summary** - regenerate based on ALL changes
- **Changes Made** - append new changes, preserve old
- **How to Verify It** - update checklist, rerun checks
- **Changelog Entry** - update to reflect all changes

**Preserve manual edits in:**
- **Reviewer Notes** - keep existing unless explicitly empty
- **Screenshots/Videos** - never overwrite
- **Manually checked boxes** - preserve [x] marks for manual steps
- **Post-Merge Tasks** - append new, keep existing

### 8. Run verification checks

**For each checklist item in "How to Verify It":**

```bash
# Example: "- [ ] Build passes: `make build`"
# Extract command: make build

# Try to run
if command -v make >/dev/null 2>&1; then
    if make build 2>&1; then
        # Mark as checked
        checkbox="- [x] Build passes: \`make build\` ✅"
    else
        # Mark unchecked with error
        checkbox="- [ ] Build passes: \`make build\` ❌ (failed: $error)"
    fi
else
    # Can't run
    checkbox="- [ ] Build passes: \`make build\` (manual verification required)"
fi
```

**Common checks to attempt:**
- `make test` / `npm test` / `pytest`
- `make lint` / `npm run lint`
- `npm run typecheck` / `tsc --noEmit`
- `make build` / `npm run build`

### 9. Save PR description to Linear

**Create or update Linear document:**

**If creating a new document:** Use `mcp__linear__create_document` with:
- `title`: "PR: #${pr_number} - ${pr_title}"
- `content`: The full PR description in markdown
- `issueId`: The ticket identifier to attach the document to

**If updating an existing document:** Use `mcp__linear__update_document` with:
- `id`: The existing document ID found in Step 3
- `content`: The updated PR description in markdown

### 10. Update PR on GitHub

**Update title:**

If a ticket exists, use `mcp__linear__get_issue` to retrieve the ticket title (if not
already fetched in Step 5). Format the PR title as `TICKET: Descriptive title` (truncate the ticket
title to 60 characters). If no ticket exists, generate a title from the primary change.

```bash
gh pr edit $pr_number --title "$new_title"
```

**Update body:**

```bash
# Create temp file with description
echo "$PR_DESCRIPTION" > /tmp/pr_body.md
gh pr edit $pr_number --body-file /tmp/pr_body.md
```

### 11. Update Linear ticket

Use `mcp__linear__save_issue` to move the ticket to "In Review" state by setting the
appropriate status.

Use `mcp__linear__save_comment` to add a comment to the ticket with the following content:

> PR description generated!
>
> **PR**: #${pr_number}
> **Verification**: ${checksPassedCount}/${totalChecks} automated checks passed
>
> View PR: ${prUrl}

### 12. Report results

**If first-time generation:**

```
✅ PR description generated!

**PR**: #123 - {title}
**URL**: {url}
**Ticket**: {ticket}
**Verification**: {X}/{Y} automated checks passed
**Linear Document**: PR: #{pr_number} - {title}

Manual verification steps remaining:
- [ ] Test feature in staging
- [ ] Verify UI on mobile

Review PR on GitHub!
```

**If incremental update:**

```
✅ PR description updated!

**Changes since last update**:
- 3 new commits
- Added validation logic
- Updated tests

**Verification**: {X}/{Y} automated checks passed
**Sections updated**: Summary, Changes Made, How to Verify It
**Sections preserved**: Reviewer Notes, Screenshots

Review updated PR: {url}
```

## Integration with Other Commands

```
/awl-dev:research-codebase PROJ-123 → research document
                  ↓
           /awl-dev:create-plan → implementation plan
                  ↓
          /awl-dev:implement-plan → code changes
                  ↓
           /awl-dev:validate-plan → verification
                  ↓
              /awl-dev:describe-pr → PR description (this command)
                  ↓
              /awl-dev:create-pr → creates PR on GitHub
```

**How it connects:**

- **Previous**: Gets context from research/plan documents in Linear
- **Next**: `/awl-dev:create-pr` uses the description, also links to ticket
- **Ticket**: Extracted from branch name, PR title, or PR body

## Error Handling

**No PR found:**

```
❌ No PR found for current branch

Open PRs:
  #120 - Feature A (feature-a branch)
  #121 - Fix B (fix-b branch)

Which PR? (enter number)
```

**No ticket found:**

```
⚠️ No ticket ID found. PR description will be created without Linear linking.

Would you like to:
1. Provide a ticket ID to link
2. Continue without ticket linking
```

**Verification command fails:**

```
⚠️  Some automated checks failed

Failed:
- make test (exit code 1)
  Error: 2 tests failed in validation.test.ts

Passed:
- make lint ✅
- make build ✅

Fix failing tests before merge or document as known issues.
```

## Remember:

- **No interactive prompts** - fully automated
- **Incremental updates** - preserve manual edits, append new
- **Auto-update title** - based on analysis
- **Run verification** - attempt all automated checks
- **Link Linear** - extract ticket, update status
- **Save to Linear** - PR description as document
- **Show what changed** - clear summary of updates

## Status Update Convention

This command is a downstream command (typically called by `/awl-dev:create-pr`) and does NOT update status on start - it updates to "In Review" on success. However, on failure, it should roll back to the appropriate previous state:

Use `mcp__linear__save_issue` to set the ticket status back to "In Dev".

Use `mcp__linear__save_comment` to add a comment explaining the failure:

> PR description generation failed: ${ERROR_REASON}. Returning to development state.
