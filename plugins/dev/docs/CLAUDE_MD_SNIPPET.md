# CLAUDE.md User Snippet

This document contains the recommended CLAUDE.md snippet for projects using the Awl plugin.

## Why Add This?

Adding Awl workflow instructions to your project's CLAUDE.md helps Claude Code understand how to
work effectively with your codebase using Linear-driven development workflows.

## The Snippet

Copy the section below (between the `---` markers) into your project's CLAUDE.md:

---

## Awl Workflow Integration

This project uses [Awl](https://github.com/ralfschimmel/awl) for Linear-driven development
workflows.

### Ticket-Driven Development

Always work with a Linear ticket. The standard workflow is:

```
/awl-dev:research_codebase PROJ-123 → /awl-dev:create_plan → /awl-dev:implement_plan
```

Where `PROJ-123` is your Linear ticket ID (replace `PROJ` with your project's ticket prefix).

### Key Commands

| Command | Purpose |
|---------|---------|
| `/awl-dev:research_codebase` | Research codebase and save findings to Linear |
| `/awl-dev:create_plan` | Create implementation plan from research |
| `/awl-dev:implement_plan` | Execute plan with auto-validation and PR creation |
| `/awl-dev:create_handoff` | Save context for later sessions |
| `/awl-dev:resume_handoff` | Resume from saved context |
| `/awl-dev:doctor` | Check Awl setup and dependencies |

### Context Persistence

- All workflow documents (research, plans, handoffs) are stored as Linear documents attached to
  tickets
- Use `/awl-dev:create_handoff` before ending a session to save context
- Use `/awl-dev:resume_handoff PROJ-123` to resume work on a ticket

### Configuration

Project configuration is in `.claude/config.json`. See
[Awl Configuration Guide](https://github.com/ralfschimmel/awl/blob/main/docs/CONFIGURATION.md).

---

## Customization

After adding the snippet:

1. Replace `PROJ` with your actual ticket prefix (e.g., `ENG`, `ACME`)
2. Update any project-specific workflow notes
3. Run `/awl-dev:doctor` to verify your setup

## Verification

After adding the snippet, run:

```bash
/awl-dev:doctor
```

This will verify your Awl setup and show the CLAUDE.md status.
