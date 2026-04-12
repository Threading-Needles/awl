---
name: awl-linear-workflow
description: Linear ticket state machine and workflow document conventions for Awl. Defines the Backlog → Research → Plan → In Dev → In Review → Done lifecycle, the "status update FIRST" rollback discipline, and the Research/Plan/Validation/Handoff/PR document naming patterns used to attach workflow artifacts to tickets. Use this skill whenever Claude sees a Linear ticket reference (PROJ-123, ENG-45, etc.), is about to call any mcp__linear__ tool, transitions ticket status, creates or queries a workflow document attached to a ticket, or starts/finishes work that maps to a ticket. Make sure to apply this skill even when the user didn't invoke an Awl command — any mention of a Linear ticket is enough to trigger it.
---

# Awl Linear Workflow

Awl tracks every unit of work in Linear. Tickets move through a small state machine, and workflow
artifacts (research findings, plans, validation results, handoffs, PR descriptions) live as Linear
documents attached to the ticket. This skill is the single source of truth for both.

## Three rules that are load-bearing

1. **Status update FIRST, before any real work.** When a command starts, the very first Linear
   action is to transition the ticket to the next state (e.g. `/awl-dev:research-codebase` moves
   Backlog → Research in Progress before spawning any agents). On failure, roll back. See
   `references/workflow-states.md` for the full rollback table.

2. **Workflow documents attach to the ticket, not the filesystem.** Research, plans, validation
   results, handoffs, and PR descriptions are Linear documents created with
   `mcp__linear__create_document` and attached via `mcp__linear__create_attachment`. There is no
   local `.claude/workflow-context.json` or similar — the ticket is the context.

3. **Title prefixes are the index.** Document discovery works by filtering attached documents by
   title prefix. If the prefix is wrong, downstream commands cannot find the document. See the
   table below.

## State machine (summary)

```
Backlog
  │ /awl-dev:research-codebase
  ▼
Research in Progress ──(unanswered questions)──▶ Spec Needed
  │ /awl-dev:create-plan
  ▼
Plan in Progress
  │ /awl-dev:implement-plan
  ▼
In Dev
  │ /awl-dev:create-pr (success)
  ▼
In Review
  │ /awl-dev:merge-pr (success)
  ▼
Done
```

Every arrow is a status update that happens **before** the command does its real work. On failure,
the command rolls back to the previous state and adds a Linear comment explaining why. For the
full transition table (including rollback targets for downstream commands like `validate-plan`
and `describe-pr`), read `references/workflow-states.md`.

## Document types

| Type | Title prefix | Created by | Consumed by |
|---|---|---|---|
| Research | `Research: ...` | `/awl-dev:research-codebase` | `/awl-dev:create-plan` |
| Plan | `Plan: ...` | `/awl-dev:create-plan` | `/awl-dev:implement-plan` |
| Validation | `Validation: ...` | `/awl-dev:validate-plan` | `/awl-dev:implement-plan` (self-heal) |
| Handoff | `Handoff: ...` | `/awl-dev:create-handoff` | `/awl-dev:resume-handoff` |
| PR Description | `PR: ...` | `/awl-dev:describe-pr` | `/awl-dev:create-pr`, GitHub |

Icons, colors, and per-type creation examples live in `references/linear-documents.md`. Use the
exact icon + color for each document type so that Linear renders them consistently in the UI.

## Workflow for "I just saw a Linear ticket"

When Claude encounters a ticket ID (user message, branch name, argument), the standard recon is:

1. `mcp__linear__get_issue` with the ticket ID — loads title, description, status, assignee,
   labels, and the list of attached documents.
2. Filter the attached documents by title prefix to find what's already been done.
3. Read the most relevant document(s) with `mcp__linear__get_document` — typically the latest
   `Research:` or `Plan:` depending on workflow phase.
4. Decide what the next action is based on current status (see state machine above).

Don't skip step 1. Operating on a stale assumption about the ticket is the most common source of
workflow bugs.

## Headless mode: embedded questions

When a workflow command runs in headless mode (`claude -p`) and research/planning produces
questions that need human input, the questions are embedded **in the document itself**, not asked
via `AskUserQuestion`:

- Ticket status moves to **Spec Needed**
- Questions live in a `## Questions for User` section with blocking/non-blocking markers
- The next command validates that blocking questions are answered before proceeding

See `references/linear-documents.md` for the exact question format, answer-detection pattern, and
assignee-mention conventions.

## References

- **`references/workflow-states.md`** — full state machine diagram, per-command status transitions,
  rollback targets, and Linear workspace configuration.
- **`references/linear-documents.md`** — per-type creation examples, full icon/color reference,
  embedded questions format, and document discovery patterns.

Read these inline when the summary above isn't enough — they are the canonical specifications and
should not drift from this SKILL.md.
