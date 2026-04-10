# Usage Guide

A comprehensive guide to using Awl for AI-assisted development.

## Table of Contents

- [Initial Setup](#initial-setup)
- [Using Research Agents](#using-research-agents)
- [Workflow Commands](#workflow-commands)
- [Concrete Examples](#concrete-examples)

---

## Initial Setup

### Step 1: Install Awl Plugin

Install Awl via the Claude Code plugin marketplace:

```bash
# Add the marketplace repository
/plugin marketplace add Threading-Needles/awl

# Install awl-dev (main workflow)
/plugin install awl-dev

# Optionally install awl-meta (workflow discovery)
/plugin install awl-meta
```

This makes all agents and commands available in Claude Code across all projects.

---

## Using Research Agents

Agents are specialized AI experts that Claude Code can delegate to. They follow the principle of
**focused, read-only research**.

### Available Agents

#### codebase-locator

Finds files and directories relevant to a feature or task.

**When to use:**

- Finding all files related to a feature
- Locating test files
- Discovering configuration files
- Mapping directory structure

**Example:**

```
@awl-dev:codebase-locator find all files related to authentication
```

**What it does:**

- Uses Grep, Glob, and Bash(ls) to search
- Returns categorized file paths
- Groups by purpose (implementation, tests, config, etc.)
- Does NOT read file contents

**Output:**

```
## File Locations for Authentication

### Implementation Files
- src/auth/authenticator.js - Main authentication logic
- src/auth/session-manager.js - Session handling
- src/middleware/auth.js - Auth middleware

### Test Files
- src/auth/__tests__/authenticator.test.js
- e2e/auth.spec.js

### Configuration
- config/auth.json
```

#### codebase-analyzer

Analyzes HOW code works with detailed implementation analysis.

**When to use:**

- Understanding complex logic
- Tracing data flow
- Identifying integration points
- Learning how a feature works

**Example:**

```
@awl-dev:codebase-analyzer explain how the authentication flow works from login to session creation
```

**What it does:**

- Reads files to understand logic
- Traces function calls and data flow
- Returns detailed analysis with file:line references
- Documents patterns and conventions

**Output includes:**

- Entry points with line numbers
- Step-by-step data flow
- Key functions and their purposes
- Configuration and dependencies

#### codebase-pattern-finder

Finds similar implementations and code patterns to model after.

**When to use:**

- Finding examples of similar features
- Discovering coding conventions
- Locating test patterns
- Understanding best practices in the codebase

**Example:**

```
@awl-dev:codebase-pattern-finder show me examples of pagination implementations
```

**What it does:**

- Searches for similar code
- Extracts actual code snippets
- Shows multiple variations
- Includes test examples

**Output includes:**

- Concrete code examples
- Multiple pattern variations
- Test patterns
- Usage locations

### Agent Best Practices

**Spawn Multiple Agents in Parallel**

Research agents work independently, so spawn multiple for comprehensive research:

```
I need to understand the payment system.

@awl-dev:codebase-locator find all payment-related files
@awl-dev:codebase-pattern-finder show me similar payment implementations
```

**Be Specific in Your Requests**

Good:

```
@awl-dev:codebase-analyzer trace how a webhook is validated and processed in the webhook handler
```

Bad:

```
@awl-dev:codebase-analyzer look at webhooks
```

**Use the Right Agent for the Job**

- **Finding files?** → codebase-locator
- **Understanding logic?** → codebase-analyzer
- **Finding examples?** → codebase-pattern-finder

---

## Workflow Commands

Commands are slash commands that execute multi-step workflows.

### /awl-dev:create_plan

Creates comprehensive implementation plans through interactive research and collaboration.

**Basic Usage:**

```
/awl-dev:create_plan
```

Claude will ask for task details and guide you through the planning process.

**The Process:**

1. **Context Gathering**
   - Reads Linear ticket and any attached documents FULLY
   - Spawns parallel research agents:
     - codebase-locator for finding files
     - codebase-analyzer for understanding current implementation
   - Reads all discovered files into main context

2. **Initial Analysis**
   - Presents understanding with file:line references
   - Asks targeted questions that research couldn't answer
   - Verifies assumptions

3. **Research & Discovery**
   - Creates research todo list
   - Spawns specialized agents for deep investigation
   - Waits for all research to complete
   - Presents findings and design options

4. **Plan Structure**
   - Proposes phase breakdown
   - Gets feedback on structure
   - Iterates until aligned

5. **Detailed Writing**
   - Saves plan as Linear document attached to the current ticket
   - Includes both automated and manual success criteria
   - Documents what's NOT being done (scope control)
   - References all relevant files with line numbers

6. **Review & Iteration**
   - Presents plan for review
   - Iterates based on feedback

**Plan Structure:**

```markdown
# Feature Implementation Plan

## Overview

[Brief description]

## Current State Analysis

[What exists, what's missing, key constraints]

## Desired End State

[Specification and verification criteria]

## What We're NOT Doing

[Explicit out-of-scope items]

## Phase 1: [Name]

### Overview

### Changes Required

### Success Criteria

#### Automated Verification

- [ ] Tests pass: `make test`

#### Manual Verification

- [ ] Feature works in UI

## Testing Strategy

## References
```

### /awl-dev:implement_plan

Executes an approved implementation plan phase by phase.

**Usage:**

```
/awl-dev:implement_plan
```

Automatically finds the plan from the Linear document attached to the current ticket.

**The Process:**

1. **Initialization**
   - Reads plan from Linear completely
   - Checks for existing checkmarks (resume capability)
   - Reads original ticket and referenced files FULLY
   - Creates todo list for tracking

2. **Implementation**
   - Implements each phase fully before moving to next
   - Updates checkboxes in plan as work completes
   - Runs automated verification at natural stopping points
   - Adapts to reality while following plan's intent

3. **Verification**
   - Runs success criteria checks
   - Fixes issues before proceeding
   - Updates progress in plan file

**Resuming Work:**

If plan has checkmarks, implementation picks up from first unchecked item:

```markdown
## Phase 1: Database Schema

- [x] Add migration file
- [x] Run migration
- [ ] Add indexes ← Resumes here
```

**Handling Mismatches:**

If reality doesn't match the plan:

```
Issue in Phase 2:
Expected: Configuration in config/auth.json
Found: Configuration moved to environment variables
Why this matters: Plan assumes JSON editing

How should I proceed?
```

### /awl-dev:validate_plan

Verifies implementation correctness and identifies deviations.

**Usage:**

```
/awl-dev:validate_plan
```

**The Process:**

1. **Context Discovery**
   - Locates the plan (from commits or user input)
   - Reviews git commits for changes
   - Reads plan completely

2. **Parallel Research**
   - Spawns agents to verify each aspect:
     - Database changes
     - Code changes
     - Test coverage
   - Compares actual vs planned

3. **Automated Verification**
   - Runs all success criteria commands
   - Documents pass/fail status
   - Investigates failures

4. **Validation Report**

```markdown
## Validation Report: Rate Limiting

### Implementation Status

✓ Phase 1: Database Schema - Fully implemented ✓ Phase 2: API Endpoints - Fully implemented ⚠️ Phase
3: UI Components - Partially implemented

### Automated Verification Results

✓ Tests pass: `make test` ✗ Linting issues: `make lint` (3 warnings)

### Code Review Findings

#### Matches Plan:

- Migration adds rate_limits table
- API returns 429 on exceeded limits

#### Deviations:

- Used Redis instead of in-memory (improvement)

#### Potential Issues:

- Missing index on user_id column

### Manual Testing Required:

- [ ] Verify UI shows rate limit errors
- [ ] Test with 1000+ requests
```

**When to Use:**

- After implementing a plan
- Before creating a PR
- During code review
- To verify completeness

---

## Stateless Commands

Awl commands are **stateless**. Every workflow command takes the Linear ticket ID as a required positional argument. There is no `.claude/config.json`, no `.workflow-context.json`, no hidden "current ticket" state.

```bash
# Step 1: Research
/awl-dev:research-codebase PROJ-123
> How does authentication work?

# Step 2: Create plan (queries Linear for research attached to PROJ-123)
/awl-dev:create-plan PROJ-123

# Step 3: Implement (queries Linear for plan attached to PROJ-123)
/awl-dev:implement-plan PROJ-123

# Step 4: Create handoff
/awl-dev:create-handoff PROJ-123

# Later: Resume work
/awl-dev:resume-handoff PROJ-123
```

PR commands extract the ticket from the branch name (pattern `[A-Z]+-[0-9]+`) and from PR title/body. PM commands take the team key as their first argument (e.g., `/awl-pm:analyze-cycle ENG`).

### Benefits

- **No setup**: Install plugin, pass ticket ID, go
- **No hidden state**: Each command is fully self-contained
- **Composable**: Commands work the same in any context (worktree, fresh session, CI)

---

## Concrete Examples

### Example 1: Implementing a New Feature from Scratch

**Scenario**: Add rate limiting to an API

**Step 1: Research and Plan**

```
# In Claude Code - research the codebase for the ticket
/awl-dev:research_codebase ENG-1234

# Create implementation plan (auto-finds research from Linear)
/awl-dev:create_plan
```

Claude will:

1. Read the ticket
2. Research current authentication system
3. Find similar rate limiting examples
4. Ask clarifying questions
5. Create detailed plan with phases

**Step 2: Review and Refine Plan**

Review the plan in Linear, give feedback. Claude iterates until the plan is solid.

**Step 3: Implement the Plan**

```
/awl-dev:implement_plan
```

Claude implements phase by phase, checking boxes as it progresses.

**Step 4: Validate Implementation**

```
/awl-dev:validate_plan
```

Claude runs all success criteria and generates validation report.

**Step 5: Commit and Push**

```bash
git add .
git commit -m "Implement rate limiting (ENG-1234)"
git push
```

### Example 2: Using Research Agents for Investigation

**Scenario**: Debugging a complex issue

```
# In Claude Code

I need to understand why webhooks are failing intermittently.

# Spawn parallel research
@awl-dev:codebase-locator find all webhook-related files
@awl-dev:codebase-analyzer trace the webhook processing flow from receipt to completion
```

Claude spawns agents simultaneously:

**Agent 1 Result (codebase-locator):**

```
## Webhook Files
### Implementation
- src/webhooks/handler.js
- src/webhooks/validator.js
- src/webhooks/processor.js

### Tests
- tests/webhooks/handler.test.js
```

**Agent 2 Result (codebase-analyzer):**

```
## Webhook Flow Analysis
1. Request arrives: handler.js:23
2. Signature validation: validator.js:15-34
3. Async processing: processor.js:45
4. Database update: processor.js:67

Key finding: No timeout handling in processor.js:45
```

---

## Tips and Tricks

### Resuming Interrupted Work

Plans track progress with checkboxes. If interrupted:

```
/awl-dev:implement_plan
```

Claude automatically finds the plan from Linear and resumes from first unchecked item.

### Sharing Agents Across Team

Commit your custom agents to the project:

```bash
cd ~/projects/my-app
mkdir -p .claude/plugins/custom/agents
cp ~/.claude/plugins/custom/agents/custom-agent.md .claude/plugins/custom/agents/
git add .claude/plugins/custom/agents/custom-agent.md
git commit -m "Add custom agent"
```

Team members get the agent on next pull!

---

## Troubleshooting

### Agent Not Found

```bash
# Check plugin installation
ls ~/.claude/plugins/
ls .claude/plugins/

# Reinstall if needed
/plugin update awl-dev
```

### Plan Checkboxes Not Updating

Claude updates plans using the Edit tool. If checkboxes aren't updating:

- Verify plan file exists and is readable
- Check file permissions
- Ensure plan follows correct markdown checkbox format: `- [ ]` or `- [x]`

---

## Next Steps

- See [BEST_PRACTICES.md](BEST_PRACTICES.md) for patterns that work
- See [PATTERNS.md](PATTERNS.md) for creating custom agents
- See [CONTEXT_ENGINEERING.md](CONTEXT_ENGINEERING.md) for deeper principles
