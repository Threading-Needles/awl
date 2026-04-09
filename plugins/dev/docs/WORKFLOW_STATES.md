# Workflow State Machine

This document defines the Linear ticket state transitions for Awl workflow commands.

## State Diagram

```
                    ┌─────────────────────────────────────────────────────────────────────────┐
                    │                                                                         │
                    │  ┌──────────┐     /research_codebase      ┌──────────────────────────┐  │
                    │  │ Backlog  │ ─────────────────────────▶ │ Research in Progress      │  │
                    │  └──────────┘                            └──────────────────────────┘  │
                    │       ▲                                            │                    │
                    │       │ (failure rollback)                        │                    │
                    │       │                                            ▼                    │
                    │       │                               ┌──────────────────────────┐     │
                    │       │                               │ Spec Needed (questions)  │     │
                    │       │                               └──────────────────────────┘     │
                    │       │                                            │                    │
                    │       │                                (answers provided)               │
                    │       │                                            ▼                    │
                    │       │                     /create_plan  ┌──────────────────────────┐  │
                    │       │  ◀────────────────────────────── │ Plan in Progress         │  │
                    │       │  (failure rollback to Research)  └──────────────────────────┘  │
                    │                                                    │                    │
                    │                                                    │                    │
                    │                                      /implement_plan                    │
                    │                                                    │                    │
                    │                                                    ▼                    │
                    │                                          ┌──────────────────────────┐  │
                    │  ◀─────────────────────────────────────── │ In Dev                   │  │
                    │  (failure rollback to Plan in Progress)  └──────────────────────────┘  │
                    │                                                    │                    │
                    │                                      /create_pr (success)               │
                    │                                                    │                    │
                    │                                                    ▼                    │
                    │                                          ┌──────────────────────────┐  │
                    │  ◀─────────────────────────────────────── │ In Review                │  │
                    │  (failure rollback to In Dev)            └──────────────────────────┘  │
                    │                                                    │                    │
                    │                                      /merge_pr (success)                │
                    │                                                    │                    │
                    │                                                    ▼                    │
                    │                                          ┌──────────────────────────┐  │
                    │                                          │ Done                      │  │
                    │                                          └──────────────────────────┘  │
                    │                                                                         │
                    └─────────────────────────────────────────────────────────────────────────┘
```

## Linear States

| State | Description | Set By |
|-------|-------------|--------|
| `Backlog` | Initial/default state | (default) |
| `Research in Progress` | Research is being conducted | `/research_codebase` (on start) |
| `Spec Needed` | Questions need answers | `/research_codebase` or `/create_plan` (headless mode with questions) |
| `Plan in Progress` | Implementation plan being created | `/create_plan` (on start) |
| `In Dev` | Implementation in progress | `/implement_plan` (on start) |
| `In Review` | PR created and awaiting review | `/create_pr` (on success) |
| `Done` | PR merged and work complete | `/merge_pr` (on success) |
| `In Progress` | General work in progress | `/resume_handoff` (on start) |

## Command Status Updates

### Core Workflow Commands (Status Update on START)

| Command | Initial Status Update | Success Status | Failure Rollback |
|---------|----------------------|----------------|------------------|
| `/research_codebase` | "Research in Progress" | (stays same) | "Backlog" |
| `/create_plan` | "Plan in Progress" | (stays same) | "Research in Progress" |
| `/implement_plan` | "In Dev" | "In Review" (via create_pr) | "Plan in Progress" |

### PR Workflow Commands (Downstream - No Start Status)

| Command | Initial Status Update | Success Status | Failure Rollback |
|---------|----------------------|----------------|------------------|
| `/validate_plan` | (none - called by implement_plan) | (none) | "In Dev" |
| `/create_pr` | (none - called by implement_plan) | "In Review" | "In Dev" |
| `/describe_pr` | (none - called by create_pr) | "In Review" | "In Dev" |
| `/merge_pr` | (none) | "Done" | "In Review" |

### Handoff Commands

| Command | Initial Status Update | Success Status | Failure Rollback |
|---------|----------------------|----------------|------------------|
| `/create_handoff` | (none - preserves current state) | (none) | (none needed) |
| `/resume_handoff` | "In Progress" | (continues work) | "Backlog" |

## Key Principles

### 1. Status Update FIRST

Every command that updates status MUST do so as THE FIRST action after confirming the ticket:

```
# CORRECT - Status update is THE FIRST thing
Use mcp__linear__save_issue to set state to "Research in Progress"
# Then read files, spawn agents, etc.

# INCORRECT - Status update buried in workflow
# Read files first
# Spawn agents
# Then update status <- TOO LATE!
```

### 2. Failure Rollback

On failure, roll back to the previous logical state:

```
# Example: Research fails
Use mcp__linear__save_issue to set state back to "Backlog"
Use mcp__linear__save_comment to add "Research failed: {error reason}"
```

### 3. Downstream Commands Don't Update Start Status

Commands that are called by other commands (e.g., `validate_plan` called by `implement_plan`) don't update status on start. They only:
- Update status on success (if applicable)
- Roll back on failure to the appropriate previous state

### 4. Questions Block Progress

When research or planning generates questions that need human input:
- Status changes to "Spec Needed"
- User answers questions in Linear document
- Next command validates answers before proceeding

## Configuring Linear States

These states should be configured in your Linear workspace. If a state doesn't exist, the command will fail with a clear error message.

Recommended Linear workflow configuration:
1. Backlog (default)
2. Research in Progress
3. Spec Needed
4. Plan in Progress
5. In Dev
6. In Review
7. Done

## Related Documentation

- [LINEAR_DOCUMENTS.md](./LINEAR_DOCUMENTS.md) - Document storage conventions
- [CLAUDE.md](../../../CLAUDE.md) - Main project configuration
- [USAGE.md](../../../docs/USAGE.md) - Workflow usage guide
