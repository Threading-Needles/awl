# Awl PM Plugin

Linear-focused project management plugin with cycle management, initiative analysis, status updates, backlog grooming, GitHub-Linear correlation, and team analytics.

## Overview

The Awl PM plugin provides AI-powered project management workflows that integrate Linear issue tracking with GitHub pull requests. It focuses on actionable insights rather than raw data dumps.

**Philosophy**: Every report includes specific recommendations, not just metrics. PMs should know exactly what action to take after reading any report.

## Features

### Cycle Management
- **Health Scoring**: Progress vs time, blocker impact, at-risk issue detection
- **Capacity Analysis**: Team workload distribution and availability
- **Risk Identification**: Blocked issues, stalled work, scope creep
- **Actionable Recommendations**: Prioritized next steps

### Backlog Health
- **Orphan Detection**: Issues without project assignments
- **Project Classification**: AI-powered project recommendations
- **Staleness Tracking**: Issues inactive >30 days
- **Duplicate Detection**: Similar issue identification

### GitHub-Linear Sync
- **PR Correlation**: Match PRs to Linear issues via branch names, descriptions, attachments
- **Gap Identification**: Orphaned PRs, orphaned issues
- **Merge Automation**: Auto-close candidates with generated commands
- **Stale PR Detection**: PRs open >14 days

### Initiative Management
- **Portfolio Health**: Aggregate health scoring across project portfolios
- **Cross-Project Risks**: Dependency conflicts, resource contention, off-track projects
- **Strategic Recommendations**: Timeline adjustments, resource allocation, scope decisions
- **Target Date Feasibility**: Initiative-level completion projections

### Status Updates
- **Automated Composition**: Gathers recent activity, blockers, and progress automatically
- **Project & Initiative**: Post updates for either entity type
- **Health Assessment**: Auto-calculated onTrack/atRisk/offTrack with override option
- **Preview & Approve**: Review before posting to Linear

### Daily Standups
- **Yesterday's Deliveries**: Completed issues and merged PRs
- **Current Work**: Team member assignments and progress
- **Availability**: Who needs work assigned
- **Quick Blockers**: Immediate attention items

## Commands

### Cycle Management
- `/awl-pm:analyze-cycle` - Analyze cycle health with actionable insights
  - Health assessment (🟢/🟡/🔴)
  - Risk identification (blockers, at-risk issues)
  - Team capacity analysis
  - Specific recommendations

### Milestone Management
- `/awl-pm:analyze-milestone` - Analyze milestone health toward target date
  - Target date feasibility assessment
  - Progress tracking (actual vs expected)
  - Risk identification (behind schedule, blockers)
  - Specific recommendations (adjust timeline, reduce scope)

### `/awl-pm:analyze-cycle`
Generate comprehensive cycle health report with recommendations.

**What it does**:
- Spawns linear-research agent to fetch active cycle data (Haiku)
- Spawns cycle-analyzer agent for health assessment (Sonnet)
- Generates progress metrics, risk factors, capacity analysis
- Provides specific, prioritized recommendations

**Output**: Health report saved to `reports/cycles/`

**Example**:
```
🟡 Cycle Health: Sprint 2025-W04 - At Risk

Takeaway: Cycle is 45% complete with 3 days remaining. We're tracking
slightly behind (projected 63% completion). Main risks: 2 blocked issues
and Dave has no assigned work.

Priority Actions:
  1. Escalate TEAM-461 blocker (external dependency, 6 days)
  2. Pair Bob with senior dev on TEAM-462 (dependency conflict)
  3. Assign 2 backlog issues to Dave (no active work)
```

### Initiative Management
- `/awl-pm:analyze-initiative` - Analyze initiative health across project portfolio
  - Strategic health assessment (🟢/🟡/🔴)
  - Project portfolio status table
  - Cross-project risk identification
  - Strategic recommendations

### Status Updates
- `/awl-pm:update-status` - Generate and post status updates to Linear
  - Works for both projects and initiatives
  - Auto-gathers recent completions, blockers, progress
  - Preview before posting
  - Saves local copy to `reports/status-updates/`

### Daily Operations
- `/awl-pm:report-daily` - Quick daily standup report
  - Yesterday's deliveries
  - Current work in progress
  - Team members needing assignments
  - Quick blockers/risks

### `/awl-pm:report-daily`
Quick daily standup report (scannable in <30 seconds).

**What it does**:
- Spawns 4 parallel research agents for fast data gathering (Haiku)
- Lists current work in progress by team member
- Identifies team members needing work assignments
- Flags quick blockers and stalled issues

**Output**: Daily report saved to `reports/daily/`

**Example**:
```
📅 Team Daily - 2025-01-27

✅ Delivered yesterday: 3 issues, 2 PRs merged
🔄 In progress: 5 issues, 3 PRs open
👥 Need work: Dave, Emily (2 team members)
⚠️  Blockers: 1 issue (TEAM-461)
```

### Backlog Health
- `/awl-pm:groom-backlog` - Analyze backlog health
  - Orphaned issues (no project)
  - Misplaced issues (wrong project)
  - Stale issues (>30 days inactive)
  - Potential duplicates
  - Missing estimates

### `/awl-pm:groom-backlog`
Analyze backlog health and generate cleanup recommendations.

**What it does**:
- Spawns linear-research agent to fetch backlog issues (Haiku)
- Spawns backlog-analyzer agent for analysis (Sonnet)
- Identifies orphaned, misplaced, stale, and duplicate issues
- Generates batch update commands

**Output**: Grooming report saved to `reports/backlog/`

**Options**:
1. Review detailed report
2. Apply high-confidence recommendations automatically
3. Generate Linear update commands for manual execution
4. Skip (report saved for later)

### GitHub-Linear Sync
- `/awl-pm:sync-prs` - Correlate GitHub PRs with Linear issues
  - Orphaned PRs (no Linear issue)
  - Orphaned issues (no PR)
  - Ready to close (PR merged, issue open)
  - Stale PRs (>14 days)

### `/awl-pm:sync-prs`
Correlate GitHub PRs with Linear issues and identify gaps.

**What it does**:
- Spawns parallel research for GitHub PRs and Linear issues (Haiku)
- Spawns github-linear-analyzer agent for correlation analysis (Sonnet)
- Identifies orphaned PRs, orphaned issues, merge candidates
- Generates auto-close commands

**Output**: Correlation report saved to `reports/pr-sync/`

**Example**:
```
🔗 PR-Linear Sync Report

Health Score: 75/100
  ✅ 8 properly linked PRs
  ⚠️ 4 orphaned PRs need Linear issues
  ⚠️ 2 orphaned issues need PRs
  ✅ 2 ready to close
```

## Agents

### Research Agents
- `linear-research` (Haiku) - Gathers Linear data via MCP
  - Cycles, issues, milestones, projects
  - Natural language interface
  - Returns structured JSON
  - Optimized for speed

### Analyzer Agents (Sonnet)

### `cycle-analyzer`
**Purpose**: Transform raw cycle data into actionable health insights

**Responsibilities**:
- Calculate health scores (progress, blockers, at-risk issues)
- Identify risk factors with specific details
- Analyze team capacity and workload distribution
- Generate prioritized, actionable recommendations

**Returns**: Structured markdown with health assessment, risks, capacity, recommendations

### `milestone-analyzer`
**Purpose**: Analyze project milestone progress toward target dates

**Responsibilities**:
- Calculate health scores based on target date feasibility
- Identify risk factors (behind schedule, blockers, scope creep)
- Analyze velocity and projected completion
- Generate timeline/scope recommendations

**Returns**: Structured markdown with target date assessment, risks, velocity, recommendations

### `backlog-analyzer`
**Purpose**: Maintain healthy, well-organized Linear backlog

**Responsibilities**:
- Project assignment analysis (orphaned, misplaced issues)
- Staleness detection (>30 days inactive)
- Duplicate detection (similar titles/descriptions)
- Estimation gap identification

**Returns**: Structured markdown with categorized recommendations and confidence scores

### `initiative-analyzer`
**Purpose**: Analyze initiative health across project portfolios

**Responsibilities**:
- Calculate health scores (portfolio progress, project health distribution, strategic risk)
- Identify cross-project risk factors (off-track projects, resource gaps, staleness)
- Assess target date feasibility at initiative level
- Generate strategic recommendations (intervention, timeline, staffing)

**Returns**: Structured markdown with health assessment, portfolio status, risks, recommendations

### `github-linear-analyzer`
**Purpose**: Ensure proper GitHub-Linear correlation

**Responsibilities**:
- Match PRs to Linear issues via multiple methods
- Identify orphaned PRs and issues
- Flag stale PRs (>14 days open)
- Detect merge candidates (PR merged, issue open)

**Returns**: Correlation report with health score and actionable commands

## Prerequisites

### Required Tools

1. **Linear MCP**: The official Linear MCP server (handles authentication automatically)

2. **GitHub CLI** (required for `sync_prs`, optional for others)
   ```bash
   brew install gh  # macOS
   ```
   See: https://cli.github.com

### Configuration

None. PM commands are **stateless** — every command takes the Linear team key as a positional argument:

```bash
/awl-pm:analyze-cycle ENG
/awl-pm:report-daily ENG
/awl-pm:sync-prs ENG
/awl-pm:groom-backlog ENG
```

Milestone, initiative, and status commands take their target name interactively or as an argument. No config file needed.

## Installation

### Via Claude Code Marketplace (Coming Soon)

```bash
/plugin marketplace add Threading-Needles/awl
/plugin install awl-pm
```

### Local Development

```bash
# Clone the repository
git clone https://github.com/Threading-Needles/awl.git

# Create symlink in your project
mkdir -p .claude/plugins
ln -s /path/to/awl/plugins/pm .claude/plugins/pm

# Restart Claude Code
```

## Verification

Check that the plugin is installed:

```bash
/plugin list
# Should show: awl-pm

# Run prerequisite check
cd /path/to/your/project
./plugins/pm/scripts/check-prerequisites.sh
```

## Usage Patterns

### Daily Workflow

**Morning Standup**:
```bash
/awl-pm:report-daily ENG
```
- See what shipped yesterday
- Review current work
- Identify blockers
- Assign work to available team members

### Weekly Review

**Start of Week**:
```bash
/awl-pm:analyze-cycle ENG
```
- Assess cycle health
- Review capacity
- Address blockers
- Plan capacity adjustments

**Mid-Week**:
```bash
/awl-pm:sync-prs ENG
```

### Strategic Review

**Bi-Weekly/Monthly**:
```bash
/awl-pm:analyze-initiative
```
- Assess initiative health across projects
- Identify cross-project risks
- Review target date feasibility
- Decide on interventions

**Weekly Status Posts**:
```bash
/awl-pm:update-status
```
- Auto-compose project/initiative status updates
- Review and post to Linear
- Keep stakeholders informed
- Check GitHub-Linear correlation
- Close merged issues
- Create missing Linear issues

**End of Week**:
```bash
/awl-pm:groom-backlog ENG
```
- Clean up orphaned issues
- Categorize new issues
- Remove stale issues
- Prepare next cycle

## Troubleshooting

### "Linear MCP not available"

Ensure the official Linear MCP server is configured in your Claude Code settings. The MCP server handles authentication automatically via OAuth.

### "No active cycle found"

Verify you have an active cycle in Linear using the `mcp__linear__list_cycles` tool, or create a cycle in the Linear UI.

## Contributing

Contributions welcome! See the main Awl repository for contribution guidelines.

## License

MIT License - see LICENSE file in main repository

## Support

- GitHub Issues: https://github.com/Threading-Needles/awl/issues
