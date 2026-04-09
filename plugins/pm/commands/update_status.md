---
description: Generate and post status updates for projects or initiatives to Linear, gathering recent activity and blockers automatically
category: pm
tools: Task, Read, Write, TodoWrite
model: inherit
version: 1.0.0
---

# Update Status Command

Generate and post structured status updates for projects or initiatives directly to Linear.
Automatically gathers recent activity (completed issues, merged PRs, blockers) and composes
a professional status update.

**This is a write command** - it posts content to Linear after user preview and approval.

**Philosophy**: Automate the tedious parts of status reporting while keeping humans in the loop
for accuracy and tone.

## Prerequisites Check

```bash
# 1. Determine script directory with fallback
if [[ -n "${CLAUDE_PLUGIN_ROOT}" ]]; then
  SCRIPT_DIR="${CLAUDE_PLUGIN_ROOT}/scripts"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts"
fi

# 2. Check PM plugin prerequisites
if [[ -f "${SCRIPT_DIR}/check-prerequisites.sh" ]]; then
  "${SCRIPT_DIR}/check-prerequisites.sh" || exit 1
else
  echo "⚠️ Prerequisites check skipped (script not found at: ${SCRIPT_DIR})"
fi

# 3. Ensure reports directory exists
mkdir -p "reports/status-updates"
```

## Process

### Step 1: Determine Target and Type

Ask user what to update:

```
What would you like to post a status update for?

1. Project status update
2. Initiative status update

Target name: [user input]
```

Determine the type (`project` or `initiative`) and target name.

### Step 2: Spawn Research Tasks (Parallel)

Spawn research tasks using Task tool with `awl-pm:linear-research` agent.

**For project updates** (3 parallel tasks):

**Task 1 - Project details**:
```
Use mcp__linear__research with message:
"Get project '${TARGET_NAME}' details including milestones, progress, lead, and target date"
```

**Task 2 - Recent activity**:
```
Use mcp__linear__research with message:
"List issues completed in the last 7 days for project '${TARGET_NAME}', and any issues currently in progress"
```

**Task 3 - Blockers and previous updates**:
```
Use mcp__linear__research with message:
"Find all blocked issues in project '${TARGET_NAME}', and get the most recent 3 status updates for this project"
```

**For initiative updates** (3 parallel tasks):

**Task 1 - Initiative details**:
```
Use mcp__linear__research with message:
"Get initiative '${TARGET_NAME}' with all projects, their progress, status, and leads"
```

**Task 2 - Project highlights**:
```
Use mcp__linear__research with message:
"For each project in initiative '${TARGET_NAME}', get the most important completed work and current blockers from the last 7 days"
```

**Task 3 - Previous updates**:
```
Use mcp__linear__research with message:
"Get the most recent 3 status updates for initiative '${TARGET_NAME}'"
```

Wait for all tasks to complete.

### Step 3: Compose Status Update

Generate a structured markdown status update body.

**For project updates**:

```markdown
## Progress
- [Summary of what was accomplished this period]
- [Key metrics: X/Y issues done, Z% complete]

## Completed
- TEAM-123: [Title]
- TEAM-124: [Title]

## In Progress
- TEAM-125: [Title] - [brief status]

## Blockers
- TEAM-126: [Title] - [blocker description]

## Next Steps
- [What's planned for next period]
```

**For initiative updates**:

```markdown
## Initiative Progress
- Overall: X% complete across Y projects
- [Key milestone updates]

## Project Highlights

### [Project 1 Name] - [onTrack/atRisk/offTrack]
- [Key accomplishments]

### [Project 2 Name] - [status]
- [Key accomplishments]

## Blockers & Risks
- [Cross-project risks]

## Next Steps
- [Strategic priorities for next period]
```

### Step 4: Determine Health

Based on gathered data, auto-calculate health:

- **onTrack**: Progress on schedule, no critical blockers, velocity steady
- **atRisk**: Slightly behind or blockers present but manageable
- **offTrack**: Significantly behind, critical blockers, target date at risk

Allow user to override the auto-calculated health value.

### Step 5: Preview and Confirm

Display the composed update for user review:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status Update Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type: [project/initiative]
Target: [name]
Health: [🟢 onTrack / 🟡 atRisk / 🔴 offTrack]

[Body preview]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Post this update to Linear? (yes / no / edit)
```

- **yes**: Post to Linear
- **no**: Cancel
- **edit**: Let user modify the body, then preview again

### Step 6: Post to Linear

Use `mcp__linear__research` to post the status update:

**For project updates**:
```
Use mcp__linear__research with message:
"Post a status update for project '${TARGET_NAME}' with health '${HEALTH}' and this body:

${STATUS_BODY}"
```

**For initiative updates**:
```
Use mcp__linear__research with message:
"Post a status update for initiative '${TARGET_NAME}' with health '${HEALTH}' and this body:

${STATUS_BODY}"
```

### Step 7: Save Local Copy and Confirm

Save a local copy for reference:

```bash
REPORT_DIR="reports/status-updates"
mkdir -p "$REPORT_DIR"

TYPE_SLUG="${TYPE}"  # "project" or "initiative"
TARGET_SLUG=$(echo "$TARGET_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
REPORT_FILE="$REPORT_DIR/$(date +%Y-%m-%d)-${TYPE_SLUG}-${TARGET_SLUG}.md"
```

Display confirmation:

```
✅ Status update posted to Linear!

Type: [project/initiative]
Target: [name]
Health: [🟢/🟡/🔴] [health]

Summary:
- [X] issues completed this period
- [Y] blockers flagged
- [Z] items in progress

Local copy: reports/status-updates/YYYY-MM-DD-project-name.md
```

## Success Criteria

### Automated Verification:
- [ ] Research tasks gather recent activity successfully
- [ ] Status update body is well-structured markdown
- [ ] Health value is valid (onTrack/atRisk/offTrack)
- [ ] Local copy saved to reports directory
- [ ] Post to Linear succeeds via research tool

### Manual Verification:
- [ ] Preview accurately reflects project/initiative state
- [ ] Completed items are real and recent
- [ ] Blockers are genuine and actionable
- [ ] Health assessment matches reality
- [ ] Status update appears correctly in Linear UI
- [ ] User had opportunity to review before posting
