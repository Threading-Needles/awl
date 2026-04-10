# CLAUDE.md User Snippet

This document contains the recommended CLAUDE.md snippet for projects using the Awl plugin.

## Why Add This?

Adding Awl workflow instructions to your project's CLAUDE.md helps Claude Code understand how to work effectively with your codebase using Linear-driven development workflows.

## The Snippet

Copy the section below (between the `---` markers) into your project's CLAUDE.md:

---

## Awl Workflow Integration

This project uses [Awl](https://github.com/Threading-Needles/awl) for Linear-driven development workflows.

### Ticket-Driven Development

Always work with a Linear ticket. Every workflow command takes the ticket ID as a positional argument:

```
/awl-dev:research-codebase TICKET-123 → /awl-dev:create-plan TICKET-123 → /awl-dev:implement-plan TICKET-123
```

### Key Commands

| Command | Purpose |
|---------|---------|
| `/awl-dev:research-codebase TICKET-123` | Research codebase and save findings to Linear |
| `/awl-dev:create-plan TICKET-123` | Create implementation plan from research |
| `/awl-dev:implement-plan TICKET-123` | Execute plan with auto-validation and PR creation |
| `/awl-dev:create-handoff TICKET-123` | Save context for later sessions |
| `/awl-dev:resume-handoff TICKET-123` | Resume from saved context |
| `/awl-dev:doctor` | Check Awl setup and dependencies |

All workflow documents (research, plans, handoffs, PR descriptions) are stored as Linear documents attached to the ticket. There is no local config file, no hidden state — commands are fully stateless.

---

## Verification

After adding the snippet, run:

```bash
/awl-dev:doctor
```

This will verify that prerequisites (gh CLI) and recommended plugins are installed.
