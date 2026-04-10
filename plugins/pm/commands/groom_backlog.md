---
description: Groom Linear backlog to identify orphaned issues, incorrect project assignments, and health issues
category: pm
tools: Task, Read, Write
model: inherit
version: 1.0.0
---

# Groom Backlog Command

Comprehensive backlog health analysis that identifies:
- Issues without projects (orphaned)
- Issues in wrong projects (misclassified)
- Issues without estimates
- Stale issues (no activity >30 days)
- Duplicate issues (similar titles)

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
mkdir -p "reports/backlog"
```

## Process

### Step 1: Validate Team Argument

**A Linear team key is REQUIRED as the first argument.** If no team was provided, respond with:

```
I need a Linear team key to groom the backlog.

Usage: /awl-pm:groom-backlog TEAM-KEY

Example: /awl-pm:groom-backlog ENG
```

Then stop. Do not proceed without a team key.

```bash
TEAM_KEY="$1"
```

### Step 2: Spawn Research Agent

Use Task tool with `awl-dev:linear-research` agent:

```
Prompt: "Get all backlog issues for team ${TEAM_KEY} including issues with no cycle assignment"
Model: haiku
```

### Step 3: Spawn Analysis Agent

Use Task tool with `backlog-analyzer` agent:

**Input**: Backlog issues JSON from research

**Output**: Structured recommendations with:
- Orphaned issues (no project)
- Misplaced issues (wrong project)
- Stale issues (>30 days)
- Potential duplicates
- Missing estimates

### Step 4: Generate Grooming Report

Create markdown report with sections:

**Orphaned Issues** (no project):
```markdown
## 🏷️ Orphaned Issues (No Project Assignment)

### High Priority
- **TEAM-456**: "Add OAuth support"
  - **Suggested Project**: Auth & Security
  - **Reasoning**: Mentions authentication, OAuth, security tokens
  - **Action**: Move to Auth project

[... more issues ...]

### Medium Priority
[... issues ...]
```

**Misplaced Issues** (wrong project):
```markdown
## 🔄 Misplaced Issues (Wrong Project)

- **TEAM-123**: "Fix dashboard bug" (currently in: API)
  - **Should be in**: Frontend
  - **Reasoning**: UI bug, no backend changes mentioned
  - **Action**: Move to Frontend project
```

**Stale Issues** (>30 days inactive):
```markdown
## 🗓️ Stale Issues (No Activity >30 Days)

- **TEAM-789**: "Investigate caching" (last updated: 45 days ago)
  - **Action**: Review and close, or assign to current cycle
```

**Duplicates** (similar titles):
```markdown
## 🔁 Potential Duplicates

- **TEAM-111**: "User authentication bug"
- **TEAM-222**: "Authentication not working"
  - **Similarity**: 85%
  - **Action**: Review and merge
```

**Missing Estimates**:
```markdown
## 📊 Issues Without Estimates

- TEAM-444: "Implement new feature"
- TEAM-555: "Refactor old code"
  - **Action**: Add story point estimates
```

### Step 5: Interactive Review

Present recommendations and ask user:

```
📋 Backlog Grooming Report Generated

Summary:
  🏷️ Orphaned: 12 issues
  🔄 Misplaced: 5 issues
  🗓️ Stale: 8 issues
  🔁 Duplicates: 3 pairs
  📊 No Estimates: 15 issues

Would you like to:
1. Review detailed report (opens in editor)
2. Apply high-confidence recommendations automatically
3. Generate Linear update commands for manual execution
4. Skip (report saved for later)
```

### Step 6: Generate Update Commands

If user chooses option 3, generate batch update script:

Use the Linear MCP tools to apply updates:

- **Move issues to projects**: `mcp__linear__save_issue` with project field
- **Close stale issues**: `mcp__linear__save_issue` with state "Canceled"
- **Add comments**: `mcp__linear__save_comment` with explanation

Example actions:
- Move TEAM-456 to "Auth & Security" project
- Move TEAM-123 to "Frontend" project
- Close stale TEAM-789 with comment "Closing stale issue (>30 days inactive)"

```bash
# Save update script
UPDATE_SCRIPT="reports/backlog/$(date +%Y-%m-%d)-grooming-updates.sh"
mkdir -p "$(dirname "$UPDATE_SCRIPT")"
# [script contents saved here]
chmod +x "$UPDATE_SCRIPT"
```

### Step 7: Save Report

```bash
REPORT_DIR="reports/backlog"
mkdir -p "$REPORT_DIR"

REPORT_FILE="$REPORT_DIR/$(date +%Y-%m-%d)-backlog-grooming.md"

# Write formatted report to file
cat > "$REPORT_FILE" << EOF
# Backlog Grooming Report - $(date +%Y-%m-%d)

[... formatted report content ...]
EOF

echo "✅ Report saved: $REPORT_FILE"
```

## Success Criteria

### Automated Verification:
- [ ] All backlog issues fetched successfully
- [ ] Agent analysis completes without errors
- [ ] Report generated with all sections
- [ ] Update script is valid bash syntax
- [ ] Files saved to correct locations

### Manual Verification:
- [ ] Orphaned issues correctly identified
- [ ] Project recommendations make sense
- [ ] Stale issues are actually inactive
- [ ] Duplicate detection has few false positives
- [ ] Report is actionable and clear
