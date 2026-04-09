---
description: Sync GitHub PRs with Linear issues and identify correlation gaps
category: pm
tools: Task, Read, Write
model: inherit
version: 1.0.0
---

# Sync PRs Command

Analyzes the relationship between GitHub pull requests and Linear issues to identify:
- PRs without linked Linear issues
- Linear issues without associated PRs
- Merged PRs with open Linear issues (candidates for closure)
- Open PRs for completed Linear issues (stale PRs)

## Prerequisites Check

```bash
# 1. Determine script directory with fallback
if [[ -n "${CLAUDE_PLUGIN_ROOT}" ]]; then
  SCRIPT_DIR="${CLAUDE_PLUGIN_ROOT}/scripts"
else
  # Fallback: resolve relative to this command file
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts"
fi

# 2. Check PM plugin prerequisites
if [[ -f "${SCRIPT_DIR}/check-prerequisites.sh" ]]; then
  "${SCRIPT_DIR}/check-prerequisites.sh" || exit 1
else
  echo "⚠️ Prerequisites check skipped (script not found at: ${SCRIPT_DIR})"
fi

# 3. Ensure reports directory exists
mkdir -p "reports/pr-sync"
```

## Process

### Step 1: Spawn Research Tasks (Parallel)

```bash
# Determine script directory with fallback
if [[ -n "${CLAUDE_PLUGIN_ROOT}" ]]; then
  SCRIPT_DIR="${CLAUDE_PLUGIN_ROOT}/scripts"
else
  # Fallback: resolve relative to this command file
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts"
fi

source "${SCRIPT_DIR}/pm-utils.sh"
TEAM_KEY=$(get_team_key)
```

**Task 1 - Get GitHub PRs**:
Use `awl-dev:github-research` agent (if exists) or inline `gh` commands:
```
Get open and recently merged PRs (last 7 days)
```

**Task 2 - Get Linear Issues**:
Use Task tool with `awl-dev:linear-research` agent:
```
Prompt: "Get all in-review and in-progress issues for team ${TEAM_KEY}"
Model: haiku
```

**Wait for both tasks to complete**

### Step 2: Spawn Analysis Agent

Use Task tool with `github-linear-analyzer` agent:

**Input**:
- GitHub PRs from Task 1
- Linear issues from Task 2

**Output**:
- Linked PRs (healthy)
- Orphaned PRs (no Linear issue)
- Orphaned issues (no PR)
- Ready to close (PR merged, issue open)
- Stale PRs (>14 days)

### Step 3: Generate Sync Report

```markdown
# PR-Linear Sync Report

**Generated**: 2025-01-27
**Repository**: user/repo
**Linear Team**: TEAM

## 📊 Summary

- Open PRs: 12 (8 linked, 4 orphaned)
- Merged PRs (7d): 15 (13 linked, 2 orphaned)
- Linear issues in review: 10 (8 with PRs, 2 without)

## 🔗 Linked PRs (Healthy)

| PR | Linear Issue | Status | Author |
|----|--------------|--------|--------|
| #123 | TEAM-456 | Open | Alice |
| #124 | TEAM-457 | Merged | Bob |

## ⚠️ Orphaned PRs (No Linear Issue)

| PR | Title | Branch | Author | Action |
|----|-------|--------|--------|--------|
| #125 | "Fix bug" | fix-bug | Alice | Create Linear issue or link existing |
| #126 | "Update docs" | docs-update | Bob | Create Linear issue or link existing |

**Recommended Actions**:

Use `mcp__linear__save_issue` to create a new Linear issue:
- title: "Fix bug (from PR #125)"
- description: "Imported from PR: https://github.com/user/repo/pull/125"

Or manually link in Linear UI.

## 🏷️ Orphaned Issues (No PR)

| Issue | Title | Status | Assignee | Action |
|-------|-------|--------|----------|--------|
| TEAM-789 | "Implement feature" | In Progress | Alice | Create PR or update status |
| TEAM-790 | "Refactor code" | In Review | Bob | PR might exist with different branch name |

## ✅ Ready to Close (PR merged, issue open)

| Issue | PR | Merged | Action |
|-------|----|--------|--------|
| TEAM-456 | #123 | 2025-01-25 | Close issue |
| TEAM-457 | #124 | 2025-01-26 | Close issue |

**Auto-close actions**:

For each issue, use `mcp__linear__save_issue` to set state to "Done"
and `mcp__linear__save_comment` to add a comment linking the merged PR.

## 🕐 Stale PRs (Open >14 days)

| PR | Issue | Days Open | Author | Action |
|----|-------|-----------|--------|--------|
| #120 | TEAM-450 | 18 days | Alice | Review and merge or close |
```

### Step 4: Save Report

```bash
REPORT_DIR="reports/pr-sync"
mkdir -p "$REPORT_DIR"

REPORT_FILE="$REPORT_DIR/$(date +%Y-%m-%d)-pr-sync.md"

# Write formatted report to file
cat > "$REPORT_FILE" << EOF
# PR-Linear Sync Report - $(date +%Y-%m-%d)

[... formatted report content ...]
EOF

echo "✅ Report saved: $REPORT_FILE"
```

### Step 5: Display Summary

```
🔗 PR-Linear Sync Report

Health Score: 75/100
  ✅ 8 properly linked PRs
  ⚠️ 4 orphaned PRs need Linear issues
  ⚠️ 2 orphaned issues need PRs
  ✅ 2 ready to close

Actions available:
  1. Auto-close merged issues (generates commands)
  2. Create Linear issues for orphaned PRs
  3. View full report

Full report: reports/pr-sync/2025-01-27-pr-sync.md
```

## Success Criteria

### Automated Verification:
- [ ] GitHub PR data fetched successfully
- [ ] Linear issue data fetched successfully
- [ ] PR-ticket correlation logic executes
- [ ] Report generated with all sections
- [ ] Auto-close commands are valid

### Manual Verification:
- [ ] PR-issue matches are accurate
- [ ] Orphaned detection has minimal false positives
- [ ] Branch name extraction works correctly
- [ ] Recommendations are actionable
- [ ] Report provides clear next steps
