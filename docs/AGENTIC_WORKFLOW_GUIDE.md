# Agentic Coding Workflow Guide

A comprehensive guide to using AI-assisted development workflows effectively with Claude Code.

**Version**: 1.0.0 **Last Updated**: 2025-01-08 **Based on**: Advanced Context
Engineering & 12 Factor Agents

## Table of Contents

1. [Overview](#overview)
2. [Complete Workflow](#complete-workflow)
3. [Context Management](#context-management)
4. [File Naming Conventions](#file-naming-conventions)
5. [Handoff System](#handoff-system)
6. [Prompting Best Practices](#prompting-best-practices)
7. [Common Patterns](#common-patterns)

---

## Overview

### Philosophy

**"Frequent Intentional Compaction"** - Design the entire workflow around context management,
keeping utilization in the **40-60% range**.

###

Core Principles

1. **Document, Don't Evaluate** - AI describes what EXISTS, not what should exist
2. **Human-in-the-Loop** - Clear checkpoints between phases
3. **Context as Precious Resource** - Clear context between phases
4. **Parallel Sub-Agents** - Focused tasks, isolated contexts
5. **Structured Persistence** - Save all context to Linear documents

### Benefits

- Handle 300k+ LOC codebases effectively
- Ship a week's worth of work in a day
- Maintain code quality through structured reviews
- 50%+ productivity improvements
- Reduced token consumption
- Avoid "spinning out" on errors

---

## Complete Workflow

### Phase Overview

```
Research → Plan → [Handoff] → Implement → Validate → PR → Done
   ↓         ↓                    ↓          ↓         ↓
Clear    Clear                 Clear     Clear    Clear
Context  Context               Context   Context  Context
```

**Key**: Clear context between EVERY phase for optimal performance.

---

### Phase 1: Research

**When**: Ticket requires codebase understanding before planning

**Command**: `/research-codebase`

**Process**:

1. Provide research question
2. AI spawns parallel sub-agents
3. Review findings
4. Ask follow-up questions (appended to same doc)

**Output**: Linear document "Research: ..." attached to the ticket

**Context Management**:

- ✅ **CLEAR CONTEXT** after research document is created
- **Why**: Research loads many files - compacting keeps next phase efficient

**Human Checkpoint**:

- Read research document completely
- Verify findings match your understanding
- Note any areas needing clarification

---

### Phase 2: Planning

**When**: After research OR directly from ticket if codebase is well-understood

**Command**: `/create-plan`

**Process**:

1. Provide ticket or task description
2. Reference research doc if exists
3. AI spawns parallel research agents
4. Review plan structure
5. Approve detailed plan

**Output**: Linear document "Plan: ..." attached to the ticket

**Context Management**:

- ✅ **CLEAR CONTEXT** after plan is approved
- **Why**: Planning involves extensive research - start implementation fresh

**Human Checkpoint**:

- Read implementation plan completely
- Verify phases are properly scoped
- Check success criteria are measurable
- Approve before moving to implementation

**Critical**: "Achieve review and alignment at the plan stage to prevent rework"

---

### Phase 3: Handoff Creation (Optional)

**When**: Before implementation if you need to:

- Pause work for later
- Transfer to another session
- Switch machines
- Context is getting full (>60%)

**Commands**: `/create-handoff` or manually create

**Process**:

1. Document current state
2. List action items
3. Reference critical files
4. Save to Linear

**Output**: Linear document "Handoff: ..." attached to the ticket

**Context Management**:

- ✅ **CLEAR CONTEXT** after handoff created
- **Why**: Handoff captures all needed context - fresh session resumes efficiently

---

### Phase 4: Parallel Development (Optional)

**When**: Ready to implement and want isolation from main development

> **Parallel Development**: Use Claude Code's native worktree support:
> ```bash
> claude --worktree feature-name    # Creates isolated worktree
> claude -w feature-name            # Short form
> ```
> Worktrees are auto-cleaned if no changes are made.

---

### Phase 5: Implementation

**When**: With approved plan

**Command**: `/implement-plan`

**Process**:

1. AI reads complete plan
2. Implements Phase 1
3. Runs automated verification
4. Updates checkboxes
5. Human reviews
6. Repeat for each phase

**Context Management**:

- ⚠️ **MAY clear context between phases** if context fills >60%
- ✅ **CLEAR CONTEXT** after implementation complete
- **Why**: Implementation can accumulate errors/attempts - fresh session for validation

**Human Checkpoints**:

- After EACH phase completes
- Review code changes
- Verify automated checks passed
- Approve moving to next phase

**Iteration**: If issues found, fix and re-verify before proceeding

---

### Phase 6: Validation

**When**: After all implementation phases complete

**Command**: `/validate-plan` (if exists) or manual validation

**Process**:

1. Run all automated tests
2. Verify all success criteria met
3. Perform manual testing steps
4. Document any deviations

**Context Management**:

- ✅ **CLEAR CONTEXT** after validation complete
- **Why**: PR creation benefits from clean, focused context

**Human Checkpoint**:

- All tests passing
- Manual verification complete
- Ready for code review

---

### Phase 7: PR Creation & Description

**When**: Implementation validated and ready for review

**Commands**:

```bash
/awl-dev:commit                    # Create commit
gh pr create --fill        # Create PR
/describe-pr              # Generate PR description
```

**PR Description**: Linear document "PR: ..." attached to the ticket

**Process**:

1. Create well-structured commit
2. Push to remote
3. Create PR
4. Generate comprehensive PR description
5. Link to Linear ticket (if applicable)

**Context Management**:

- ✅ **CLEAR CONTEXT** after PR created
- **Why**: Work complete - fresh session for next task

---

## Context Management

### The "40-60% Rule"

**Target**: Keep context utilization between **40-60%**

**How to Check**:

**For Users**:

```bash
/context
```

This command shows:

- Token usage breakdown by component
- Total tokens used
- **Percentage of context window used/remaining**

**For Agents** (Automatic):

- Agents receive real-time token updates after every tool call
- See: `<system_warning>Token usage: X/200000; Y remaining</system_warning>`
- Can proactively warn when approaching limits
- Trained to adjust behavior based on remaining context
- **Agents can self-monitor and suggest clearing context**

**Why**:

- Maintains AI performance quality
- Prevents context exhaustion
- Enables focused, efficient work
- Avoids "spinning out" on errors
- Facilitates better decision making

### When to Clear Context

**✅ ALWAYS Clear Between Phases:**

- Research → Planning
- Planning → Implementation
- Implementation → Validation
- Validation → PR Creation

**✅ Clear During Phase If:**

- Context reaches >60% utilization (check with `/context`)
- AI starts repeating same errors
- Need to "reset" the approach
- Creating a handoff
- Work trajectory changes significantly
- `/context` shows high token usage in messages component

**✅ Clear For:**

- Starting new ticket
- Resuming from handoff
- Switching tasks
- Major phase transitions

### How to Clear Context

**In Claude Code**:

1. Save all outputs (research doc, plan, code changes)
2. Close current conversation
3. Start new conversation
4. Load needed context (plan file, research doc) when ready

**Benefits of Clearing**:

- Fresh perspective
- Reduced token usage
- Better error handling
- Faster responses
- More focused recommendations

---

## Document Naming Conventions

All workflow documents are stored as Linear documents attached to tickets. The naming convention
uses title prefixes for easy discovery:

| Document Type | Title Format | Example |
|---------------|-------------|---------|
| Research | "Research: ..." | "Research: OAuth Implementation" |
| Plan | "Plan: ..." | "Plan: OAuth Implementation" |
| Handoff | "Handoff: ..." | "Handoff: Session 2025-01-08" |
| PR Description | "PR: ..." | "PR: #456 - Add OAuth Support" |
| Validation | "Validation: ..." | "Validation: OAuth Implementation" |

Documents are discovered by querying Linear via `linearis attachments list --issue PROJ-123`.

---

## Handoff System

### What Are Handoffs?

Context transfer documents that enable work to be paused, resumed, or transferred while preserving
critical context.

### When to Create Handoffs

- **Pausing work** for later resumption
- **Context >60%** - frequent intentional compaction
- **Blocked** by technical challenges
- **Need input** from another expert
- **Switching machines** or sessions
- **End of day** - resume tomorrow
- **Implementation deviates** significantly from plan

### Handoff Document Structure

```yaml
---
date: 2025-01-08
researcher: Ryan
git_commit: abc123def456
branch: PROJ-123-feature
repository: my-project
topic: Implement OAuth2 support
tags: [handoff, oauth, authentication, PROJ-123]
status: in_progress
---

# Handoff: OAuth2 Implementation

**Created**: 2025-01-08 14:30:45 PST
**Branch**: PROJ-123-feature
**Commit**: abc123def456

## Current Task

Implementing OAuth2 support per plan "Plan: OAuth Implementation" (Linear doc on PROJ-123)

## Progress

Completed:
- ✅ Phase 1: Database schema
- ✅ Phase 2: OAuth provider integration
- ⏳ Phase 3: Token validation (in progress)

## Critical References

- Implementation plan: Linear document "Plan: OAuth Implementation" on PROJ-123
- Research: Linear document "Research: Auth System" on PROJ-123
- Key files:
  - `src/auth/oauth-provider.ts:45` - Provider configuration
  - `src/auth/token-validator.ts:120` - Token validation (working on this)

## Recent Changes

- Added OAuth2 provider configuration
- Implemented token exchange flow
- Started token validation middleware

## Learnings

- OAuth state parameter must be cryptographically random
- Token expiry should be configurable per environment
- Need to handle refresh token rotation

## Blockers/Questions

- Waiting on: Decision about refresh token storage (database vs Redis)
- Question: Should we support PKCE flow for mobile apps?

## Next Steps

1. Complete token validation middleware
2. Add tests for OAuth flow
3. Update documentation
4. Run automated checks: `make check test`

## Action Items

- [ ] Implement token expiry check
- [ ] Add refresh token handling
- [ ] Write unit tests for validator
- [ ] Update API documentation

## Artifacts Created

- Database migration: `migrations/20250108_oauth_tables.sql`
- Config file: `config/oauth-providers.json`
- Test fixtures: `tests/fixtures/oauth-tokens.json`
```

### Resuming from Handoff

**Command**: `/resume-handoff` (with ticket number)

**Process**:

1. Read handoff document from Linear
2. Read linked research/plans from Linear
3. Spawn parallel verification tasks to check current state
4. Present comprehensive analysis
5. Propose next actions
6. Get approval to proceed

**Example**:

```bash
/resume-handoff PROJ-123
# Finds latest handoff attached to this ticket in Linear
```

---

## Prompting Best Practices

### Core Philosophy: "Document, Don't Evaluate"

The AI's role is to DOCUMENT what exists, not critique or suggest improvements.

### Best Practices

#### 1. Be Specific

**Good**:

```
Research how authentication works in src/auth/:
1. Find all files related to login flow
2. Document the session management approach with file:line references
3. Map out where tokens are validated
```

**Bad**:

```
Look at auth and tell me about it
```

#### 2. Request File References

**Always ask for**:

- Specific file paths
- Line numbers
- Code examples with context

**Example**:

```
Include file:line references for all findings
Format: `path/to/file.ext:123`
```

#### 3. Read Files Fully

**Critical**: ALWAYS read complete files before analysis

**Good**:

```
Read the entire implementation plan from the Linear document attached to PROJ-123
```

**Bad**:

```
Read the plan (with limit/offset)
```

#### 4. Use Parallel Sub-Agents

**Efficient**:

```
Spawn 3 parallel research tasks:
1. codebase-locator: Find auth-related files
2. codebase-analyzer: Understand login flow
3. pattern-finder: Find similar implementations
```

**Inefficient**:

```
First find the files, then analyze them, then find patterns
(sequential - 3x slower)
```

#### 5. Clear Success Criteria

**Good**:

```
Success criteria for Phase 1:
- [ ] Migration runs: `make migrate`
- [ ] Tests pass: `make test`
- [ ] Linting clean: `make lint`
- [ ] Manual: Login flow works in UI
```

**Bad**:

```
Make sure it works
```

### Anti-Patterns to Avoid

**❌ NEVER Ask AI To:**

- "Improve this code"
- "What's wrong with this implementation?"
- "How should we refactor this?"
- "Identify problems or issues"
- "Critique the architecture"
- "Recommend which pattern is better"

**✅ INSTEAD Ask:**

- "Document how this code works"
- "Explain the current implementation"
- "Map out the existing architecture"
- "Show examples of both patterns"

---

## Common Patterns

### Pattern 1: Quick Research → Plan → Implement

**Use When**: Small, well-understood tasks

```bash
# 1. Research (optional if codebase familiar)
/research-codebase PROJ-123
> "How does rate limiting work?"
# CLEAR CONTEXT

# 2. Plan
/create-plan
> "Add rate limiting to API endpoints"
# CLEAR CONTEXT

# 3. Implement
/implement-plan
# CLEAR CONTEXT

# 4. PR
/awl-dev:commit && gh pr create --fill && /describe-pr
```

### Pattern 2: Complex Feature with Handoffs

**Use When**: Large, multi-day tasks

```bash
# Day 1 - Research
/research-codebase PROJ-123
> "Understand OAuth2 implementation patterns"
/create-handoff
# END OF DAY - CLEAR CONTEXT

# Day 2 - Planning
/resume-handoff PROJ-123
/create-plan
> Reference research doc
/create-handoff
# END OF DAY - CLEAR CONTEXT

# Day 3 - Implementation Phase 1
/resume-handoff PROJ-123
/implement-plan
# Complete Phase 1 only
/create-handoff
# END OF DAY - CLEAR CONTEXT

# Day 4 - Implementation Phase 2-3
/resume-handoff PROJ-123
/implement-plan  # Continues from checkboxes
# Complete remaining phases
# CLEAR CONTEXT

# Day 5 - Validation & PR
/validate-plan
/awl-dev:commit && gh pr create --fill && /describe-pr
```

### Pattern 3: Parallel Multi-Task

**Use When**: Working on multiple tickets

```bash
# Terminal 1 - Task A (using native worktree)
claude --worktree feature-a
/implement-plan

# Terminal 2 - Task B (using native worktree)
claude --worktree feature-b
/implement-plan

# Terminal 3 - Task C (research only)
claude
/research-codebase PROJ-789
> "How does X work?"
```

Each Claude Code session is isolated with its own context.

---

## Headless Workflow (Agentic Mode)

### Overview

When running Claude Code with `claude -p` (headless/print mode), interactive questioning via
`AskUserQuestion` is not available. The mode-aware workflow commands adapt by embedding questions
directly in Linear documents.

### How It Works

```
Headless: claude -p "/research-codebase TN-123"
                     ↓
         Research executes autonomously
                     ↓
         Questions embedded in Research doc
                     ↓
         Ticket status → "Spec Needed"
                     ↓
         User answers in Linear UI
                     ↓
Headless: claude -p "/create-plan"
                     ↓
         Validates Research answers
                     ↓
         If unanswered → Hard fail with list
         If answered → Proceeds to planning
```

### Mode Detection

Commands detect their execution mode automatically:

```bash
MODE=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" detect-mode)
# Returns "interactive" or "headless"
```

**Interactive mode** (TTY detected):
- Uses `AskUserQuestion` tool for clarifications
- Waits for user responses
- Presents options and discusses trade-offs

**Headless mode** (no TTY):
- Uses ticket title/description as context
- Makes reasonable decisions based on research
- Embeds questions in Linear documents

### Embedded Questions Format

When questions arise in headless mode, they're embedded in the document:

```markdown
## Questions for User

@Assignee Name - Please answer before proceeding to /create-plan:

> **Q1 (blocking)**: What authentication method should we use?
> **Context**: This affects security model and token storage.
> **Options**: A) JWT B) Session-based C) OAuth2
> **Answer**: _[please fill in]_
```

### Answer Validation

Downstream commands check for unanswered questions:

- `/create-plan` validates Research document answers
- `/implement-plan` validates Plan document answers

**If unanswered questions found:**

```
❌ Cannot proceed: Research document has unanswered questions

**Q1 (blocking)**: What authentication method should we use?
  → Location: Research document attached to TN-123

Please answer in Linear, then run: /create-plan
```

### Status Convention

When a document contains unanswered questions:
- Ticket status is set to **"Spec Needed"**
- This signals the ticket is blocked pending human input
- User can filter by this status to find tickets needing attention

### Agentic Workflow Example

```bash
# 1. Start research in headless mode
claude -p "/research-codebase TN-123"
# → Creates Research doc with embedded questions
# → Sets ticket to "Spec Needed"

# 2. User answers questions in Linear UI
# → Opens Research doc, fills in answers

# 3. Continue with planning
claude -p "/create-plan"
# → Validates Research answers
# → Creates Plan doc (may have its own questions)

# 4. If Plan has questions, answer them in Linear

# 5. Continue with implementation
claude -p "/implement-plan"
# → Validates Plan answers
# → Implements phases
# → Auto-validates, creates PR, runs review
```

### Best Practices

1. **Keep questions minimal** - Only ask what truly needs human input
2. **Provide options** - When possible, offer A/B/C choices
3. **Include context** - Explain why the question matters
4. **Mark blocking vs non-blocking** - Help prioritize
5. **Use "Spec Needed" status** - Makes tracking easy

### Reference

See `plugins/dev/LINEAR_DOCUMENTS.md` for the complete embedded questions specification.

---

## Additional Resources

### Official Documentation

- [Anthropic Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)

### Repository Documentation

- [Workflow Discovery System](WORKFLOW_DISCOVERY_SYSTEM.md)
- [Frontmatter Standard](FRONTMATTER_STANDARD.md)
- [Main README](../README.md)

### Configuration

- `.claude/config.json` - Project-specific settings

---

## Quick Reference

### Context Clearing Checklist

- [ ] After creating research document
- [ ] After approving implementation plan
- [ ] After creating handoff
- [ ] After completing implementation
- [ ] Before validation phase
- [ ] After creating PR
- [ ] When `/context` shows >60% usage
- [ ] When AI starts repeating errors

### Context Monitoring Commands

```bash
/context              # Show detailed token usage breakdown
/clear                # Clear context and start fresh session
```

### Command Quick Reference

```bash
/research-codebase           # Document existing system
/create-plan                 # Create implementation plan
/create-handoff              # Pause/transfer work
/resume-handoff <path>       # Resume from handoff
/implement-plan <plan-path>  # Execute plan
/validate-plan               # Verify implementation
/awl-dev:commit                      # Create commit
/describe-pr                 # Generate PR description
```

### Document Naming Quick Reference

All documents are stored in Linear with title prefixes:

```
Research:   "Research: <description>"
Plans:      "Plan: <description>"
Handoffs:   "Handoff: <description>"
PRs:        "PR: #<number> - <description>"
Validation: "Validation: <description>"
```

---

**Remember**: Context is precious. Clear it frequently. Let Linear documents be your memory.
