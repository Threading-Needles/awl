---
description: Generate or update PR description with incremental changes
category: version-control-git
tools: Bash, Read, Write
model: inherit
version: 3.0.0
---

# Generate/Update PR Description

Generates or updates PR description with incremental information, auto-updates title, and links
Linear tickets. The PR description is also saved as a Linear document for persistence.

## Prerequisites

Before executing, verify Linear integration is available:

```bash
# Validate plugin prerequisites (includes LINEAR_API_TOKEN check)
if [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" ]]; then
  "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" || exit 1
fi
```

## Process:

### 1. Get Current Ticket

Check workflow context for current ticket:

```bash
CURRENT_TICKET=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" get-ticket)
```

### 2. Identify target PR

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

### 3. Extract ticket reference

**From multiple sources:**

```bash
# 1. From workflow context (most reliable)
ticket=$CURRENT_TICKET

# 2. From branch name
branch=$(gh pr view $pr_number --json headRefName -q .headRefName)
if [[ -z "$ticket" && "$branch" =~ ([A-Z]+)-([0-9]+) ]]; then
    ticket="${BASH_REMATCH[0]}"
fi

# 3. From PR title
title=$(gh pr view $pr_number --json title -q .title)
if [[ -z "$ticket" && "$title" =~ ([A-Z]+)-([0-9]+) ]]; then
    ticket="${BASH_REMATCH[0]}"
fi

# 4. From existing PR body
body=$(gh pr view $pr_number --json body -q .body)
if [[ -z "$ticket" && "$body" =~ Refs:\ ([A-Z]+-[0-9]+) ]]; then
    ticket="${BASH_REMATCH[1]}"
fi
```

**If ticket found, set in workflow context:**
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" set-ticket "$ticket"
```

### 4. Check for existing PR description in Linear

```bash
# Find existing PR documents attached to ticket
linearis attachments list --issue "$ticket"
```

Look for documents with title starting with "PR:".

### 5. Gather comprehensive PR information

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

### 6. Get Linear ticket context

```bash
# Get ticket details from Linear
linearis issues read "$ticket"
```

Use ticket title and description for context when generating the PR description.

### 7. Analyze changes incrementally

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

### 8. Generate PR description

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

### 9. Run verification checks

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

### 10. Save PR description to Linear

**Create or update Linear document:**

```bash
# Get team key from config
TEAM_KEY=$(jq -r '.catalyst.linear.teamKey // "PROJ"' .claude/config.json)

# If creating new document
linearis documents create \
  --title "PR: #${pr_number} - ${pr_title}" \
  --team "${TEAM_KEY}" \
  --content "${PR_DESCRIPTION}" \
  --attach-to "${ticket}" \
  --icon "CodeBlock" \
  --color "#2f80ed"

# If updating existing document
linearis documents update "${document_id}" \
  --content "${PR_DESCRIPTION}"
```

### 11. Update PR on GitHub

**Update title:**

```bash
# If ticket exists, format: TICKET: Descriptive title
if [[ "$ticket" ]]; then
    # Get ticket title from Linear
    ticket_title=$(linearis issues read "$ticket" | jq -r '.title')
    new_title="$ticket: ${ticket_title:0:60}"
else
    # Generate from primary change
    new_title="Brief summary of main change"
fi

gh pr edit $pr_number --title "$new_title"
```

**Update body:**

```bash
# Create temp file with description
echo "$PR_DESCRIPTION" > /tmp/pr_body.md
gh pr edit $pr_number --body-file /tmp/pr_body.md
```

### 12. Update Linear ticket

```bash
# Move to "In Review" state
linearis issues update "$ticket" --state "In Review"

# Add comment about PR description
linearis comments create "$ticket" \
    --body "PR description generated!\n\n**PR**: #${pr_number}\n**Verification**: ${checksPassedCount}/${totalChecks} automated checks passed\n\nView PR: ${prUrl}"
```

### 13. Report results

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
/research-codebase PROJ-123 → research document
                  ↓
           /create-plan → implementation plan
                  ↓
          /implement-plan → code changes
                  ↓
           /validate-plan → verification
                  ↓
              /describe-pr → PR description (this command)
                  ↓
              /create-pr → creates PR on GitHub
```

**How it connects:**

- **Previous**: Gets context from research/plan documents in Linear
- **Next**: `/create-pr` uses the description, also links to ticket
- **Workflow context**: Ticket is used throughout

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

## Configuration

Uses `.claude/config.json`:

```json
{
  "catalyst": {
    "project": {
      "ticketPrefix": "RCW"
    },
    "linear": {
      "teamId": "team-id",
      "inReviewStatusName": "In Review"
    },
    "pr": {
      "testCommand": "make test",
      "lintCommand": "make lint",
      "buildCommand": "make build"
    }
  }
}
```

## Remember:

- **No interactive prompts** - fully automated
- **Incremental updates** - preserve manual edits, append new
- **Auto-update title** - based on analysis
- **Run verification** - attempt all automated checks
- **Link Linear** - extract ticket, update status
- **Save to Linear** - PR description as document
- **Show what changed** - clear summary of updates
