---
description: Safely merge PR with verification and Linear integration
category: version-control-git
tools: mcp__linear__get_issue, mcp__linear__save_issue, mcp__linear__save_comment, mcp__linear__get_document, Bash(git *), Bash(gh *), Read
model: inherit
version: 2.0.0
---

# Merge Pull Request

Safely merges a PR after comprehensive verification, with Linear integration and automated cleanup.

## Execution Mode Detection

Detect whether running interactively or headless (e.g., `claude -p`):

```bash
MODE=$([[ "${CLAUDE_NON_INTERACTIVE:-}" == "1" || "${CLAUDE_CODE_ENTRYPOINT:-}" == "sdk-cli" ]] && echo headless || echo interactive)
```

**Mode behavior:**

- **Interactive**: Prompt for confirmation at key decision points (CI failures, missing approvals, final merge). Allow user overrides to proceed despite warnings.
- **Headless**: Proceed automatically when all checks pass. Exit with error on any issues (CI failures, missing approvals, conflicts) with no override option.

## Process:

### 1. Identify PR to merge

**If argument provided:**

- Use that PR number: `/merge_pr 123`

**If no argument:**

```bash
# Try current branch
gh pr view --json number,url,title,state,mergeable 2>/dev/null
```

If no PR on current branch:

```bash
gh pr list --limit 10 --json number,title,headRefName,state
```

Ask: "Which PR would you like to merge? (enter number)"

### 2. Get PR details

```bash
gh pr view $pr_number --json \
  number,url,title,state,mergeable,mergeStateStatus,\
  baseRefName,headRefName,reviewDecision
```

**Extract:**

- PR number, URL, title
- Mergeable status
- Base branch (usually main)
- Head branch (feature branch)
- Review decision (APPROVED, REVIEW_REQUIRED, etc.)

### 3. Verify PR is open and mergeable

```bash
state=$(gh pr view $pr_number --json state -q .state)
mergeable=$(gh pr view $pr_number --json mergeable -q .mergeable)
```

**If PR not OPEN:**

```
❌ PR #$pr_number is $state

Only open PRs can be merged.
```

**If not mergeable (CONFLICTING):**

```
❌ PR has merge conflicts

Resolve conflicts first:
  gh pr checkout $pr_number
  git fetch origin $base_branch
  git merge origin/$base_branch
  # ... resolve conflicts ...
  git push
```

Exit with error.

### 4. Check if head branch is up-to-date with base

```bash
# Checkout PR branch
gh pr checkout $pr_number

# Fetch latest base
base_branch=$(gh pr view $pr_number --json baseRefName -q .baseRefName)
git fetch origin $base_branch

# Check if behind
if git log HEAD..origin/$base_branch --oneline | grep -q .; then
    echo "Branch is behind $base_branch"
fi
```

**If behind:**

```bash
# Auto-rebase
git rebase origin/$base_branch

# Check for conflicts
if [ $? -ne 0 ]; then
    echo "❌ Rebase conflicts"
    git rebase --abort
    exit 1
fi

# Push rebased branch
git push --force-with-lease
```

**If conflicts during rebase:**

```
❌ Rebase conflicts detected

Conflicting files:
  $(git diff --name-only --diff-filter=U)

Resolve manually:
  1. Fix conflicts in listed files
  2. git add <resolved-files>
  3. git rebase --continue
  4. git push --force-with-lease
  5. Run /merge_pr again
```

Exit with error.

### 5. Check CI/CD status

```bash
gh pr checks $pr_number
```

**Parse output for failures:**

- If all checks pass: continue
- If required checks fail: prompt user
- If optional checks fail: warn but allow

**If required checks failing:**

```
⚠️  Some required CI checks are failing

Failed checks:
  - build (required)
  - lint (required)

Passed checks:
  - test ✅
  - security ✅
```

**If MODE is "interactive":**

```
Continue merge anyway? [y/N]:
```

If user says no: exit. If user says yes: continue (user override).

**If MODE is "headless":**

```
❌ Cannot merge: Required CI checks are failing

Failed checks:
  - {list of failed checks}

Fix the failing checks and try again.
```

Exit with error code.

### 6. Check approval status

```bash
review_decision=$(gh pr view $pr_number --json reviewDecision -q .reviewDecision)
```

**Review decisions:**

- `APPROVED` - proceed
- `CHANGES_REQUESTED` - prompt user
- `REVIEW_REQUIRED` - prompt user
- `null` / empty - no reviews, prompt user

**If not approved:**

```
⚠️  PR has not been approved

Review status: $review_decision
```

**If MODE is "interactive":**

```
Continue merge anyway? [y/N]:
```

If user says no: exit. If user says yes: continue (user override).

**If MODE is "headless":**

```
❌ Cannot merge: PR has not been approved

Review status: $review_decision

Approve the PR first and try again.
```

Exit with error code.

### 7. Extract ticket reference

```bash
branch=$(gh pr view $pr_number --json headRefName -q .headRefName)
title=$(gh pr view $pr_number --json title -q .title)

# From branch (pattern: PREFIX-NUMBER)
if [[ "$branch" =~ ([A-Z]+-[0-9]+) ]]; then
    ticket="${BASH_REMATCH[1]}"
fi

# From title if not in branch
if [[ -z "$ticket" ]] && [[ "$title" =~ ([A-Z]+-[0-9]+) ]]; then
    ticket="${BASH_REMATCH[1]}"
fi
```

### 8. Show merge summary

```
About to merge:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 PR:      #$pr_number - $title
 From:    $head_branch
 To:      $base_branch
 Commits: $commit_count
 Files:   $file_count changed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Reviews: $review_status
 CI:      $ci_status
 Ticket:  $ticket (will move to Done)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Merge strategy: Squash and merge
```

**If MODE is "interactive":**

```
Proceed? [Y/n]:
```

**If MODE is "headless":**

```
Proceeding with merge (all checks passed)...
```

Proceed automatically to merge execution.

### 9. Execute squash merge

```bash
gh pr merge $pr_number --squash --delete-branch
```

**Always:**

- Squash merge (combines all commits into one)
- Delete remote branch automatically

**Capture merge commit SHA:**

```bash
merge_sha=$(git rev-parse HEAD)
```

### 10. Update Linear ticket

If ticket found and not using `--no-update`:

Use `mcp__linear__save_issue` to move the ticket state to "Done".

Use `mcp__linear__save_comment` to add a merge comment with details:
"PR merged! PR: #{prNumber} - {prTitle}, Merge commit: {mergeSha}, Merged into: {baseBranch}"

### 11. Delete local branch and update base

```bash
# Switch to base branch
git checkout $base_branch

# Pull latest (includes merge commit)
git pull origin $base_branch

# Delete local feature branch
git branch -d $head_branch

# Confirm deletion
echo "✅ Deleted local branch: $head_branch"
```

**Always delete local branch** - no prompt (remote already deleted).

### 12. Extract post-merge tasks from Linear

**Read PR description from Linear:**

Use `mcp__linear__get_issue` with the ticket ID to find attached documents.

Look for document with title starting with "PR:".

**If PR document found:**

Use `mcp__linear__get_document` to read the document content and extract the
"Post-Merge Tasks" section.

**If tasks exist:**

```
📋 Post-merge tasks from PR description:
- [ ] Update documentation
- [ ] Monitor error rates in production
- [ ] Notify stakeholders

These tasks are recorded in the Linear document for reference.
```

### 13. Report success summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PR #$pr_number merged successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Merge details:
  Strategy:     Squash and merge
  Commit:       $merge_sha
  Base branch:  $base_branch (updated)
  Merged by:    @$user

Cleanup:
  Remote branch: $head_branch (deleted)
  Local branch:  $head_branch (deleted)

Linear:
  Ticket:  $ticket → Done ✅
  Comment: Added with merge details

Next steps:
  - Monitor deployment
  - Check CI/CD pipeline
  - Verify in production

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Flags

**`--no-update`** - Don't update Linear ticket

```bash
/merge_pr 123 --no-update
```

**`--keep-branch`** - Don't delete local branch

```bash
/merge_pr 123 --keep-branch
```

## Remember:

- **Always squash merge** - clean history
- **Always delete branches** - no orphan branches
- **Rely on CI** - no local test run; trust `gh pr checks`
- **Auto-rebase** - keep up-to-date with base
- **Fail fast** - stop on conflicts
- **Update Linear** - move ticket to Done automatically
- **Clear summary** - show what happened
- **Only prompt for exceptions** - approvals missing, CI failing

## Status Update Convention

This command updates ticket status to "Done" on successful merge. On failure, it should roll back to the appropriate previous state:

On failure, use `mcp__linear__save_issue` to roll back the ticket state to "In Review" and
`mcp__linear__save_comment` to add a comment explaining the failure.
