---
description: Monitor a PR through CI, run the test plan against the deployment preview, and update the PR when done
category: version-control-git
tools: Read, Bash, Task, Grep, Glob
model: inherit
version: 1.0.0
argument-hint: "[PR_NUMBER]"
---

# Babysit PR

Monitor a pull request through CI completion, run the test plan against the deployment preview URL,
and update the PR description with results.

## Arguments

- `PR_NUMBER` (optional): The PR number to monitor. If omitted, uses the current branch's PR.

## Workflow

### Step 1: Identify the PR

```bash
# If no PR number provided, find PR for current branch
PR_NUMBER=${1:-$(gh pr view --json number --jq .number 2>/dev/null)}
```

If no PR found, inform the user and exit.

### Step 2: Monitor CI

Poll CI status until all checks complete or fail:

```bash
gh pr checks $PR_NUMBER
```

**Polling strategy:**

- Check every 30 seconds
- Report status changes as they happen (e.g., "Typecheck passed, waiting for Deploy Web...")
- If any check fails, report the failure immediately and investigate:
  - Get failed job logs: `gh run view <run-id> --job <job-id> --log-failed`
  - Diagnose the issue
  - If fixable (e.g., lint error, type error), fix it, commit, push, and restart monitoring
  - If not fixable, report to user and stop
- Maximum wait: 15 minutes total

**Report format during monitoring:**

```
CI Status for PR #NNN:
  Lint        pass
  Typecheck   pass
  Unit Tests  running...
  Deploy Web  pending
```

### Step 3: Get Preview URL

Once Deploy Web succeeds, extract the preview URL:

```bash
gh run view <deploy-run-id> --job <deploy-job-id> --log 2>&1 | grep "environment url"
```

If no preview URL found, check Vercel comments on the PR:

```bash
gh pr view $PR_NUMBER --json comments --jq '.comments[] | select(.body | test("vercel"; "i")) | .body'
```

If still no preview URL found (e.g., backend-only changes), skip visual checks and proceed to
Step 6.

### Step 4: Extract Test Plan

Read the PR description to find the test plan:

```bash
gh pr view $PR_NUMBER --json body --jq .body
```

Parse the `## Test plan` section. Identify:

- **Automated checks** (already verified by CI): items mentioning `pnpm build`, `pnpm test`, CI,
  etc.
- **Visual checks** (need preview URL): items mentioning "visual verification", page URLs, rendering
- **Manual checks** (need browser/human): items mentioning TinaCMS editor, interactive features

If no test plan section found, skip to Step 6.

### Step 5: Run Visual Checks

For each visual verification item in the test plan:

1. **Construct the full URL**: Combine the preview URL with the page path from the test plan
2. **Fetch and analyze**: Use WebFetch to load the page and check for:
   - Content renders correctly (no empty sections, no error messages)
   - Links are styled and functional
   - Layout appears correct (text-media blocks have both text and image sections)
   - Multi-paragraph content has proper spacing
3. **Record result**: Mark as pass/fail with details

If the Chrome browser extension is available (mcp__claude-in-chrome), prefer using it for visual
checks as it provides more accurate rendering verification. Use WebFetch as fallback.

### Step 6: Update PR Description

Update the PR description, marking completed test plan items:

```bash
gh pr edit $PR_NUMBER --body "$UPDATED_BODY"
```

Change `- [ ]` to `- [x]` for verified items. Add the preview URL if not already present.

### Step 7: Report Results

Present a summary:

```markdown
## PR #NNN Babysit Report

**CI**: All checks pass / {N} checks failed
**Preview**: {url or N/A}
**Visual Checks**: X/Y passed

### Results:
- [x] Item 1 — description of what was verified
- [x] Item 2 — description of what was verified
- [ ] Item 3 — requires manual verification (reason)

### Issues Found:
- None / list of issues

**Status**: Ready for merge / Needs attention
```

## Error Handling

**CI fails and is fixable:**

- Read the failure logs
- Fix the issue (lint, type error, etc.)
- Commit and push
- Restart monitoring from Step 2
- Max 3 fix attempts before stopping

**CI fails and is NOT fixable:**

- Report the failure with logs
- Stop monitoring
- Suggest next steps

**No preview URL available:**

- Check if Deploy Web was skipped (e.g., backend-only changes)
- Check Vercel deployment status
- Report and skip visual checks

**WebFetch returns truncated/incomplete content:**

- Try fetching a simpler page
- Note which checks could not be completed
- Suggest browser-based verification for those items

## Integration with Other Commands

```
/implement-plan → Phase B: /create_pr → Phase E: /babysit_pr
                                  or
/create_pr → (standalone) → /babysit_pr (auto-called)
                                  or
/babysit_pr PR_NUMBER (standalone manual invocation)
```

**How it connects:**

- **Previous**: Called automatically after `/create_pr` completes, or invoked manually
- **Next**: If all checks pass, PR is ready for `/merge_pr`
- **Standalone**: Can be invoked at any time on any PR

## Tips

- This command is auto-called after `/create_pr` in the standard workflow
- Combine with `/pr-review-toolkit:review-pr` for a complete pre-merge check
- The command auto-fixes CI failures when possible (max 3 attempts)
- For backend-only PRs without deploy previews, the command focuses on CI monitoring only
