# Contributing to Awl

Thank you for your interest in contributing! This document provides guidelines for contributing to
Awl.

## Development Setup

### Prerequisites

- **Git** — version control
- **[Claude Code](https://claude.com/claude-code)** — to dogfood changes locally
- **[GitHub CLI](https://cli.github.com)** (`gh`) — used by PR workflow commands

### Clone

```bash
git clone git@github.com:Threading-Needles/awl.git
cd awl
```

This repo is its own working installation via symlinks in `.claude/plugins/` → `plugins/`, so any
edits to agents, commands, or scripts are immediately available the next time you restart Claude
Code.

## Code Quality

Awl is markdown + a handful of shell scripts. There is no aggregated linter, no Makefile, no CI.
Check your changes before committing:

**Shell scripts** (we have three — `plugins/dev/scripts/*.sh`, `plugins/pm/scripts/*.sh`):

```bash
shellcheck plugins/*/scripts/*.sh
bash -n plugins/*/scripts/*.sh   # syntax check
```

**Markdown** (agents, commands, docs):

- Your editor's markdown formatter is fine (most people use `prettier` on save)
- Run `/awl-meta:validate-frontmatter` from inside Claude Code to verify YAML frontmatter on all
  agent/command files

That's it — no aggregator, no runtime pins, no `.trunk` cache.

## Command and Agent Development

The canonical frontmatter spec lives in the
[`awl-frontmatter` skill](plugins/meta/skills/awl-frontmatter/) — Claude auto-loads it whenever
you edit an agent or command file, and it covers required fields, recommended fields, and the
four-tier model assignment rules (`inherit`/`haiku`/`sonnet`/`opus`). The steps below are a
quick starting point.

### Adding a New Command

1. Create markdown file in the appropriate plugin directory:
   - `plugins/dev/commands/{command-name}.md` for workflow commands
   - `plugins/pm/commands/{command-name}.md` for project-management commands
   - `plugins/meta/commands/{command-name}.md` for meta/creation commands

2. **Add frontmatter** (at minimum `description`; the rest is recommended):

   ```yaml
   ---
   description: Brief description of what the command does
   category: workflow          # free-form grouping
   tools: Read, Write, Bash, Task
   model: inherit              # respects the user's session model
   version: 1.0.0
   ---
   ```

3. Write command logic following existing patterns. Workflow commands take the Linear ticket ID as
   a required positional argument (`$1`); PM commands take the team key as `$1`. Commands are
   **stateless** — no config file reads, no hidden state between runs.

4. Restart Claude Code and test: `/your-command-name TICKET-123`

5. Run `/awl-meta:validate-frontmatter` to check formatting

### Adding a New Agent

1. Create markdown file in `plugins/dev/agents/{agent-name}.md` (or `plugins/pm/agents/`)

2. **Add frontmatter** (at minimum `name` + `description`; the rest is recommended):

   ```yaml
   ---
   name: agent-name            # must match filename (kebab-case)
   description: What this agent does and when Claude should invoke it
   tools: Grep, Glob, Read     # restrict where it makes sense
   model: inherit              # or haiku/sonnet — see awl-frontmatter skill
   ---
   ```

3. Write agent logic as a **documentarian, not a critic** — agents describe what exists, they do
   not suggest improvements or critique the code they read. See `CLAUDE.md` for the agent philosophy.

4. Restart Claude Code and test by invoking from a command or `@agent-name`

5. Run `/awl-meta:validate-frontmatter` to check formatting

## Shell Script Guidelines

1. **Use `set -euo pipefail`** for strict mode
2. **Quote variables**: `"${var}"`
3. **Use `[[` for conditionals**, not `[`
4. **Prefer functions** over inline code
5. **Run `shellcheck`** before committing

## Git Workflow

### Branch Naming

Use the Linear ticket prefix:

```
{PREFIX}-{NUMBER}-{description}
```

Examples:

- `ENG-19-add-code-quality-tooling`
- `PROJ-20-improve-documentation`

PR commands (`/awl-dev:create-pr`, `/awl-dev:merge-pr`) extract the ticket from the branch name
automatically, so the naming matters.

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description
```

Examples:

- `feat(commands): add new debug command`
- `fix(agents): correct locator glob pattern`
- `docs: update contributing guide`
- `chore: update dependencies`

### Pull Requests

1. Create PR from your branch to `main` (`/awl-dev:create-pr` handles this)
2. Request review if needed
3. Squash-merge when approved (`/awl-dev:merge-pr` handles this)

## Documentation

When making changes:

1. **Update relevant docs** in `docs/` directory
2. **Update `plugins/*/README.md`** if adding to a plugin namespace
3. **Update `CLAUDE.md`** if changing architecture or adding an ADR

### Key documentation files

- `README.md` — project overview and quick start
- `QUICKSTART.md` — installation and first-use walkthrough
- `CLAUDE.md` — instructions for Claude Code (architecture, ADRs)
- `docs/` — comprehensive guides (USAGE, AGENTIC_WORKFLOW_GUIDE, PR_LIFECYCLE, etc.)
- `plugins/dev/README.md`, `plugins/pm/README.md`, `plugins/meta/README.md` — per-plugin docs

## Testing

Awl has no automated test suite — this repo is markdown and shell scripts, and testing is
dogfooding.

1. Edit a command or agent under `plugins/`
2. Restart Claude Code to reload the plugin
3. Test the command against a real Linear ticket: `/awl-dev:your-command TICKET-123`
4. Verify the behavior matches expectations

## Getting Help

- **Documentation**: see `docs/` and `CLAUDE.md`
- **Issues**: https://github.com/Threading-Needles/awl/issues
- **Questions**: open a discussion on GitHub

## License

By contributing, you agree that your contributions will be licensed under the same license as this
project (MIT).
