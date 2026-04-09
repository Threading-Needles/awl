---
description: Analyze initiative health across projects with strategic insights, target date assessment, cross-project risk analysis, and recommendations
category: pm
tools: Task, Read, Write, TodoWrite
model: inherit
version: 1.0.0
---

# Analyze Initiative Command

Generates a comprehensive **health report** for a Linear initiative across its project portfolio.

**Reports Include**:
- 🟢🟡🔴 Health assessment with strategic overview
- 📊 Project portfolio status (all projects with progress)
- 🎯 Actionable takeaways (what needs attention NOW)
- ⚠️ Cross-project risk identification (off-track, dependencies, resource gaps)
- 💡 Strategic recommendations (intervention, timeline, staffing)

**Philosophy**: Provide strategic insights for initiative owners, not just project-level data dumps.

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
mkdir -p "reports/initiatives"
```

## Process

### Step 1: Gather Configuration and Initiative Identifier

**Option A: User provides initiative name**
```bash
INITIATIVE_NAME="Q2 Platform Modernization"
```

**Option B: Interactive prompt**
```
Which initiative would you like to analyze?
- Initiative name: [user input]
```

If no name provided, use `mcp__linear__research` to list active initiatives and let user choose.

### Step 2: Spawn Research Tasks (Parallel)

Spawn 2 parallel research tasks using Task tool with `awl-pm:linear-research` agent:

**Task 1 - Get initiative details with projects**:
```
Use mcp__linear__research with message:
"Get initiative '${INITIATIVE_NAME}' with all its projects, including each project's progress, status, lead, target date, and milestones"
```

**Task 2 - Get recent status updates**:
```
Use mcp__linear__research with message:
"Get the most recent status updates for initiative '${INITIATIVE_NAME}' and its projects from the last 30 days"
```

Wait for both tasks to complete.

If initiative not found or ambiguous, report error and ask user to clarify.

### Step 3: Spawn Analysis Agent

Use Task tool with `initiative-analyzer` agent:

**Input**:
- Initiative data from research Task 1
- Status updates from research Task 2
- Current date: $(date +%Y-%m-%d)

**Agent returns**:
Structured markdown with:
- Health score and strategic assessment
- Project portfolio table
- Risk factors (off-track projects, target date, resources, staleness)
- Prioritized recommendations

### Step 4: Format Report

Format the analyzer output into final report:

```markdown
# Initiative Health Report: [Initiative Name]

**Owner**: [Owner name]
**Status**: [Planned/Active/Completed]
**Target Date**: [YYYY-MM-DD] ([X] days remaining)
**Projects**: [N] total
**Generated**: [YYYY-MM-DD HH:MM]

---

## 🟢/🟡/🔴 Health Assessment

**Takeaway**: [One-sentence strategic summary]

**Current State**:
- Portfolio: [X] on track, [Y] at risk, [Z] off track
- Progress: [Overall completion estimate]
- Target: [On track / Behind by N days / Critical]

---

## 📊 Project Portfolio

[Project status table from analyzer]

---

## ⚠️ Risks & Issues

[Cross-project risks, target date assessment, resource gaps]

---

## 💡 Recommendations

[Priority-ordered strategic actions]

---

## 📝 Recent Status Updates

[Last 3 status updates if available]

---

**Next Review**: [Suggested date based on target date proximity]
```

### Step 5: Save Report

```bash
REPORT_DIR="reports/initiatives"
mkdir -p "$REPORT_DIR"

# Sanitize initiative name for filename
INITIATIVE_SLUG=$(echo "$INITIATIVE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
REPORT_FILE="$REPORT_DIR/$(date +%Y-%m-%d)-${INITIATIVE_SLUG}.md"

# Write formatted report
# ...

echo "✅ Report saved: $REPORT_FILE"
```

### Step 6: Display Summary

```
🎯 Initiative Health: [Initiative Name] - [🟢/🟡/🔴]

Owner: [Name]
Target Date: [YYYY-MM-DD] ([X] days remaining)
Projects: [X] on track, [Y] at risk, [Z] off track

Priority Actions:
  1. [Action 1]
  2. [Action 2]
  3. [Action 3]

Full report: reports/initiatives/YYYY-MM-DD-initiative.md
```

## Success Criteria

### Automated Verification:
- [ ] Research agent fetches initiative data successfully
- [ ] Analyzer agent produces structured output
- [ ] Report file created in expected location
- [ ] No errors when initiative exists

### Manual Verification:
- [ ] Health score accurately reflects initiative state
- [ ] Project portfolio table is complete and accurate
- [ ] Cross-project risks are identified correctly
- [ ] Recommendations are strategic and actionable
- [ ] Works with different initiative names
