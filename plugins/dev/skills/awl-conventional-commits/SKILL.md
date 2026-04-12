---
name: awl-conventional-commits
description: Conventional commit format rules for Awl — commit types (feat/fix/perf/revert for changelog; docs/style/refactor/test/build/ci/chore for internal), scope detection from changed-file paths, header format (max 100 chars, imperative mood, no trailing period), body and footer conventions, Linear ticket footer extraction from branch names, and the Awl-specific rule against adding `Co-authored-by: Claude` attribution to plain commits. Use this skill whenever Claude is about to run `git commit`, being asked to write or fix a commit message, invoking `/awl-dev:commit`, or reviewing commit messages in a PR. Make sure to use this skill whenever a commit is about to be created, even if the user didn't explicitly ask for format guidance — writing commits in the wrong format breaks changelog generation.
---

# Awl Conventional Commits

Every commit in an Awl-managed repo follows the conventional-commits format. This skill defines
the exact shape, the type taxonomy, the scope detection rules, and the Awl-specific attribution
policy. The full spec (with all examples) lives in `references/conventional-commits.md`.

## The format

```
<type>(<scope>): <short summary>

<body — optional, explain WHY>

<footer — ticket reference>
```

## Type reference (memorise these)

**Changelog types** — these appear in release notes:

- `feat` — new feature
- `fix` — bug fix
- `perf` — performance improvement
- `revert` — revert a previous commit

**Internal types** — not in changelog:

- `docs`, `style`, `refactor`, `test`, `build`, `ci`, `chore`

Pick the most specific type that honestly describes the commit. Don't use `feat` for a bug fix
to make it show up in the changelog.

## Scope detection

Scopes come from the changed-file paths, not from the user's imagination. Common Awl mappings:

| File pattern | Scope |
|---|---|
| `plugins/dev/agents/*.md` | `agents` |
| `plugins/*/commands/*.md` | `commands` |
| `plugins/*/skills/*` | `skills` |
| `plugins/*/scripts/*` | `scripts` |
| `docs/*.md` | `docs` |
| `.claude/` | `claude` |

If the diff spans unrelated areas, **omit the scope** — don't invent a meta-scope like `all` or
`multi`.

## The 100-character header rule

`<type>(<scope>): <summary>` must be ≤ 100 characters total. If the summary is long, trim it
rather than overflowing. Detail goes in the body, not the header.

Summary style:

- Imperative mood: "add X", not "added X" or "adds X"
- No trailing period
- No capitalised first letter
- Describes what the commit does, not what the old code was doing

## The ticket footer

Extract the ticket ID from the current branch name with the regex `[A-Z]+-[0-9]+`. Branches are
named `{TICKET}-{description}` (e.g. `PROJ-13-implement-oauth`). Append the ticket to the commit
as:

```
Refs: PROJ-13
```

If the branch doesn't match the pattern, omit the footer — **don't fabricate** a ticket ID.

## Awl-specific: no Claude attribution on plain commits

Regular commit messages made through `/awl-dev:commit` or ambient commit work **MUST NOT** include
`Co-authored-by: Claude ...` or any attribution to the AI assistant. Write the commit as if the
user wrote it themselves.

**Exception**: this repo (the Awl workspace itself) uses `Co-Authored-By: Claude Opus 4.6 (1M
context)` for its own dogfooding commits, per the repo-level policy in `CLAUDE.md`. That policy
applies only to Awl-development commits inside this workspace. For every other project that uses
Awl, the default is no attribution.

If the user explicitly asks for an attribution footer, honour the request.

## Quick example

**Branch**: `PROJ-13-add-oauth-support`
**Changed files**: `plugins/dev/commands/create_plan.md`, `plugins/dev/agents/codebase-analyzer.md`
**Detected type**: `feat` (new capability)
**Detected scope**: spans both `commands/` and `agents/` → omit scope

Message:

```
feat: add OAuth planning support to create-plan workflow

Updates create-plan to detect OAuth-flavoured tickets and to
spawn codebase-analyzer with OAuth-specific research prompts.
The analyzer's documentarian philosophy is preserved — it still
only describes existing auth code, doesn't recommend libraries.

Refs: PROJ-13
```

## References

- **`references/conventional-commits.md`** — full spec with the complete type reference, every
  scope-detection pattern, more examples (feature/fix/docs/chore/refactor), the ticket footer
  rules, and the attribution policy written out in full. Read this when the summary above isn't
  enough — it's the canonical document.
