---
description: Create pull request with automatic Linear integration
category: version-control-git
tools: Bash(linearis *), Bash(git *), Bash(gh *), Read, Task
model: inherit
version: 2.0.0
---

# Create Pull Request

Orchestrates the complete PR creation flow: commit → rebase → push → create → describe → link Linear
ticket.

## Prerequisites

Before executing, verify Linear integration is available:

```bash
# Validate plugin prerequisites (includes LINEAR_API_TOKEN check)
if [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" ]]; then
  "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" || exit 1
fi
```

## Configuration

Read team configuration from `.claude/config.json`:

```bash
CONFIG_FILE=".claude/config.json"
TEAM_KEY=$(jq -r '.catalyst.linear.teamKey // "PROJ"' "$CONFIG_FILE")
```

## Process:

### 1. Get Current Ticket

Check workflow context for current ticket:

```bash
CURRENT_TICKET=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" get-ticket)
```

### 2. Check for uncommitted changes

```bash
git status --porcelain
```

If there are uncommitted changes:

- Offer to commit: "You have uncommitted changes. Create commits now? [Y/n]"
- If yes: internally call `/catalyst-dev:commit` workflow
- If no: proceed (user may want to commit manually later)

### 3. Verify not on main/master branch

```bash
branch=$(git branch --show-current)
```

If on `main` or `master`:

- Error: "Cannot create PR from main branch. Create a feature branch first."
- Exit

### 4. Detect base branch

```bash
# Check which exists
if git show-ref --verify --quiet refs/heads/main; then
    base="main"
elif git show-ref --verify --quiet refs/heads/master; then
    base="master"
else
    base=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
fi
```

### 5. Check if branch is up-to-date with base

```bash
# Fetch latest
git fetch origin $base

# Check if behind
if git log HEAD..origin/$base --oneline | grep -q .; then
    echo "Branch is behind $base"
fi
```

If behind:

- Auto-rebase: `git rebase origin/$base`
- If conflicts:
  - Show conflicting files
  - Error: "Rebase conflicts detected. Resolve conflicts and run /catalyst-dev:create_pr again."
  - Exit

### 6. Check for existing PR

```bash
# Check for existing PR (capture output and exit status)
pr_output=$(gh pr view --json number,url,title,state 2>&1)
pr_status=$?

# Handle different scenarios
if [[ $pr_status -eq 0 ]]; then
    # PR exists - parse the JSON
    echo "$pr_output"
elif echo "$pr_output" | grep -q "no pull requests found"; then
    # No PR yet - this is expected, continue
    :
elif echo "$pr_output" | grep -q "not logged in"; then
    echo "Error: GitHub CLI not authenticated. Run: gh auth login" >&2
    exit 1
else
    # Some other error
    echo "Error checking for existing PR: $pr_output" >&2
    exit 1
fi
```

If PR exists:

- Show: "PR #{number} already exists: {title}\n{url}"
- Ask: "What would you like to do?\n [D] Describe/update this PR\n [S] Skip (do nothing)\n [A]
  Abort"
- If D: call `/catalyst-dev:describe_pr` and exit
- If S: exit with success message
- If A: exit
- **This is the ONLY interactive prompt in the happy path**

### 7. Extract ticket from branch name or workflow context

```bash
branch=$(git branch --show-current)

# First check workflow context
ticket=$CURRENT_TICKET

# If not in context, extract from branch pattern: PREFIX-NUMBER
if [[ -z "$ticket" && "$branch" =~ ($TEAM_KEY-[0-9]+) ]]; then
    ticket="${BASH_REMATCH[1]}"  # e.g., RCW-13
fi

# Set ticket in workflow context for subsequent commands
if [[ "$ticket" ]]; then
    "${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" set-ticket "$ticket"
fi
```

### 8. Generate PR title from branch and ticket

```bash
# Branch format examples:
# - RCW-13-implement-pr-lifecycle → "RCW-13: implement pr lifecycle"
# - feature-add-validation → "add validation"

# Extract description from branch name
if [[ "$ticket" ]]; then
    # Remove ticket prefix from branch
    desc=$(echo "$branch" | sed "s/^$ticket-//")
    # Convert kebab-case to spaces
    desc=$(echo "$desc" | tr '-' ' ')
    # Capitalize first word
    desc="$(tr '[:lower:]' '[:upper:]' <<< ${desc:0:1})${desc:1}"

    title="$ticket: $desc"
else
    # No ticket in branch
    desc=$(echo "$branch" | tr '-' ' ')
    desc="$(tr '[:lower:]' '[:upper:]' <<< ${desc:0:1})${desc:1}"
    title="$desc"
fi
```

### 9. Push branch

```bash
# Check if branch has upstream
if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null; then
    # No upstream, push with -u
    git push -u origin HEAD
else
    # Has upstream, check if up-to-date
    git push
fi
```

### 10. Create PR

```bash
# Minimal initial body
body="Automated PR creation. Comprehensive description generating..."

# If ticket exists, add reference
if [[ "$ticket" ]]; then
    body="$body\n\nRefs: $ticket"
fi

# Create PR
gh pr create --title "$title" --body "$body" --base "$base"
```

Capture PR number and URL from output.

### 11. Auto-call /catalyst-dev:describe_pr

Immediately call `/catalyst-dev:describe_pr` with the PR number to:

- Generate comprehensive description
- Run verification checks
- Update PR title (refined from code analysis)
- Save PR description as Linear document
- Update Linear ticket status

### 12. Update Linear ticket (if ticket found)

If ticket was extracted:

```bash
# Update ticket state to "In Review"
linearis issues update "$ticket" --state "In Review" --assignee "@me"

# Add comment with PR link
linearis comments create "$ticket" \
    --body "PR created and ready for review!\n\n**PR**: $prUrl\n\nDescription has been auto-generated with verification checks."
```

### 13. Report success

```
✅ Pull request created successfully!

**PR**: #{number} - {title}
**URL**: {url}
**Base**: {base_branch}
**Ticket**: {ticket} (moved to "In Review")
**Linear Document**: PR: #{number} - {title}

Description has been generated and verification checks have been run.
Review the PR on GitHub!
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
              /describe-pr → PR description
                  ↓
              /create-pr → creates PR on GitHub (this command)
                  ↓
              /merge-pr → merges PR
```

**How it connects:**

- **Previous**: Work is done via `/implement-plan`
- **Next**: `/merge-pr` will merge the PR and update Linear
- **Workflow context**: Ticket is used for Linear linking

## Error Handling

**On main/master branch:**

```
❌ Cannot create PR from main branch.

Create a feature branch first:
  git checkout -b TICKET-123-feature-name
```

**Rebase conflicts:**

```
❌ Rebase conflicts detected

Conflicting files:
  - src/file1.ts
  - src/file2.ts

Resolve conflicts and run:
  git add <resolved-files>
  git rebase --continue
  /catalyst-dev:create_pr
```

**GitHub CLI not configured:**

```
❌ GitHub CLI not configured

Run: gh auth login
Then: gh repo set-default
```

**Linear API token not set:**

```
❌ LINEAR_API_TOKEN not set

Set your Linear API token:
  export LINEAR_API_TOKEN=your_token

Get a token from: https://linear.app/settings/api
```

**Linear ticket not found:**

```
⚠️  Could not find Linear ticket for {ticket}

PR created successfully, but ticket not updated.
Update manually or check ticket ID.
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
      "teamKey": "RCW",
      "inReviewStatusName": "In Review"
    }
  }
}
```

## Examples

**Branch: `RCW-13-implement-pr-lifecycle`**

```
Extracting ticket: RCW-13
Generated title: "RCW-13: Implement pr lifecycle"
Creating PR...
✅ PR #2 created
Calling /catalyst-dev:describe_pr to generate description...
Saving PR description to Linear...
Updating Linear ticket RCW-13 → In Review
✅ Complete!
```

**Branch: `feature-add-validation` (no ticket)**

```
No ticket found in branch name
Generated title: "Feature add validation"
Creating PR...
✅ PR #3 created
Calling /catalyst-dev:describe_pr...
⚠️  No Linear ticket to update
✅ Complete!
```

## Remember:

- **Minimize prompts** - only ask when PR already exists
- **Auto-rebase** - keep branch up-to-date with base
- **Auto-link Linear** - extract ticket from branch, update status
- **Auto-describe** - comprehensive description generated immediately
- **Save to Linear** - PR description stored as Linear document
- **Fail fast** - stop on conflicts or errors with clear messages

**Note**: This command is typically called automatically by `/implement-plan` after validation passes.
You can also run it standalone to create a PR for existing changes.
