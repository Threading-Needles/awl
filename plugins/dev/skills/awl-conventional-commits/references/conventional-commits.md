# Conventional Commits — Awl Spec

The full spec for conventional commit messages in Awl, including type reference, format rules,
examples, and the Awl-specific rule against Claude attribution.

## Format

```
<type>(<scope>): <short summary>

<body — optional but recommended>

<footer — ticket reference>
```

### Rules

- **Header max 100 characters** (type + scope + summary combined)
- **Type:** lowercase
- **Scope:** lowercase, derived from changed-file paths (see scope map below)
- **Summary:** imperative mood, no trailing period, no capitalised first letter
- **Body:** explain **why**, not what. Optional for simple changes.
- **Footer:** `Refs: TICKET-123` when a ticket ID can be extracted from the branch name

## Type reference

### Types that appear in CHANGELOG

| Type | Meaning |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `perf` | Performance improvement |
| `revert` | Revert a previous commit |

### Internal types (not in changelog)

| Type | Meaning |
|---|---|
| `docs` | Documentation only |
| `style` | Formatting, whitespace — no code change |
| `refactor` | Code restructuring with no behaviour change |
| `test` | Adding or updating tests |
| `build` | Build system or dependencies |
| `ci` | CI/CD configuration |
| `chore` | Maintenance tasks |

## Scope detection

Parse the changed-file paths and map to a scope. Common mappings in Awl:

| File path pattern | Scope |
|---|---|
| `plugins/dev/agents/*.md` | `agents` |
| `plugins/*/commands/*.md` | `commands` |
| `plugins/*/skills/*` | `skills` |
| `plugins/*/scripts/*` | `scripts` |
| `docs/*.md` | `docs` |
| `.claude/` | `claude` |
| Multiple dirs or root files | _empty scope_ (cross-cutting) |

Pick the scope that covers the majority of the diff. If changes span unrelated areas, omit the
scope entirely — don't invent a meta-scope.

## Ticket footer

Extract the ticket ID from the current branch name using the regex `[A-Z]+-[0-9]+`. The branch
naming convention is `{TICKET-PREFIX}-{NUMBER}-{description}` (e.g. `PROJ-13-implement-oauth`).

Add `Refs: TICKET-123` as the commit footer when a ticket is found. If the branch doesn't match
the pattern (e.g. local scratch branches), omit the footer — don't fabricate a ticket ID.

## Examples

### Feature

```
feat(agents): add codebase-pattern-finder agent

Implements new agent for finding similar code patterns across
the codebase with concrete examples and file references.

Refs: PROJ-45
```

### Fix

```
fix(commands): handle missing PR description gracefully

Previously crashed when PR document was not found in Linear.
Now provides a clear error with instructions to create one.

Refs: PROJ-78
```

### Documentation

```
docs(scripts): add README for plugin scripts

Documents all bundled scripts with usage examples
and explains when to use each installation method.

Refs: PROJ-12
```

### Chore (no ticket)

```
chore(config): update conventional commit scopes

Adds new scopes for agents and commands directories.
```

### Multi-area refactor (no scope)

```
refactor: unify Linear document creation across workflow commands

Extracts the icon/color/title-prefix logic into a shared helper
that every workflow command now calls instead of duplicating the
MCP invocation inline.

Refs: PROJ-201
```

## Awl-specific: no Claude attribution on plain commits

Regular commits made through `/awl-dev:commit` or ambient commit work **MUST NOT** include:

- `Co-authored-by: Claude ...`
- `Generated with Claude Code` footer
- Any other attribution to the AI assistant

Write commit messages as if the user wrote them. Their name is the author, full stop.

**Exception**: The root `CLAUDE.md` `/commit` command instructions (the global default that ships
with Claude Code) DO include a `Co-Authored-By: Claude Opus 4.6 (1M context)` footer for commits
made while working inside this very repository. That's the repo's own policy for dogfooding
commits. When committing to external projects through `/awl-dev:commit`, follow the user's
repository convention — which is almost always "no Claude attribution".

If the user explicitly asks for an attribution footer, honour the request. Otherwise, leave it
out.

## Why conventional commits

- **Changelog generation** — `feat`/`fix`/`perf`/`revert` commits can be automatically extracted
  into release notes
- **Scoped history** — `git log --grep="^feat(agents):"` becomes a useful query
- **Ticket traceability** — the `Refs:` footer links every commit back to a Linear ticket
- **Consistent tone** — imperative mood reads as a description of what the commit does, which
  matches how `git log` is traditionally read
