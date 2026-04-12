---
name: awl-frontmatter
description: YAML frontmatter standard for Awl agents and commands — required fields (name for agents, description for both), recommended fields (tools, model), optional metadata (version, category, color), the four-tier model assignment rules (inherit/haiku/sonnet/opus), and the validation rules enforced by /awl-meta:validate-frontmatter. Use this skill whenever Claude is editing or creating a file under `plugins/*/agents/*.md` or `plugins/*/commands/*.md`, writing YAML frontmatter for an Awl agent/command, running `/awl-meta:validate-frontmatter` or `/awl-meta:create-workflow`, or reviewing frontmatter in a PR diff. Make sure to use this skill whenever an Awl agent or command markdown file shows up in the context — writing incorrect frontmatter silently breaks plugin discovery.
---

# Awl Frontmatter Standard

Awl agents and commands carry YAML frontmatter that Claude Code uses to decide what to invoke and
how. This skill is the authoritative spec — `references/frontmatter-standard.md` holds the full
details, templates, and common-mistakes catalog.

## The two rules that actually break things

1. **Agents MUST have a `name` field matching the filename** (minus `.md`, kebab-case). If the
   name is missing or mismatched, Claude Code can't load the agent.
2. **Commands MUST NOT have a `name` field.** Commands are identified by filename. Adding `name:`
   to a command either gets ignored or confuses tooling.

Everything else is optional metadata that Awl uses for consistency but Claude Code doesn't
strictly require.

## Minimum viable frontmatter

**Agent:**
```yaml
---
name: my-agent-name        # required, matches filename
description: What it does  # required
---
```

**Command:**
```yaml
---
description: What it does  # required
---
```

That's the floor. Everything below is strongly recommended but technically optional.

## Full shape

**Agent (full):**
```yaml
---
name: codebase-locator
description:
  Locates files, directories, and components relevant to a feature or task. Call this agent when
  you want to know WHERE code lives, not how it works.
tools: Grep, Glob, Bash(ls *)    # restrict what the agent can do
model: haiku                     # see model tiers below
version: 1.1.0                   # optional, semver
---
```

**Command (full):**
```yaml
---
description: Conduct comprehensive codebase research using parallel sub-agents
category: workflow               # free-form grouping
tools: Read, Write, Grep, Glob, Task, TodoWrite, Bash, mcp__linear__get_issue, mcp__linear__save_issue, mcp__linear__create_document
model: inherit                   # almost always inherit
version: 2.0.0
argument-hint: "[TICKET-ID]"     # shown in the command picker
---
```

## Model tiers

Claude Code accepts four values for `model`:

| Value | When to use |
|---|---|
| `inherit` | Default. Respects the user's session model. Use this for anything that benefits from deep reasoning when the user starts Claude Code with `--model claude-opus-4-6[1m]`. |
| `haiku` | Pure lookup or data gathering. No synthesis required. Examples: `codebase-locator` (just finds files), `linear-research` (just queries Linear), `github-research` (just runs `gh` commands). |
| `sonnet` | Structured analysis against a defined rubric or schema. Examples: the PM analyzer agents (`cycle-analyzer`, `milestone-analyzer`) that compute health scores. |
| `opus` | Rarely hardcoded. Prefer `inherit` so users running cheaper sessions aren't forced into Opus. |

**Commands should almost always use `model: inherit`** — the user picked their session model for a
reason, commands shouldn't override it.

**Agents can hardcode a tier** — they have narrower scope and the tier tradeoff is more obvious.
Hardcoding `haiku` on lookup agents is how Awl saves cost.

## Common mistakes

- ❌ Command with a `name: ...` field — remove it
- ❌ Agent `name:` doesn't match the filename — rename one of them
- ❌ `version: v1.0` or `version: 1.0` — must be semver `X.Y.Z`
- ❌ `tools: SearchFiles, FindFile` — invented tool names, won't work
- ❌ Unrestricted `Bash` when you could use `Bash(git *)` / `Bash(gh *)` / `Bash(ls *)`
- ❌ `model: fast` or `model: extended` — not valid; use `haiku`/`sonnet`/`opus`/`inherit`

## Validation

Run `/awl-meta:validate-frontmatter` (which lives alongside this skill in the meta plugin) to
scan every agent and command in the workspace against this standard. It reports severities
separately (critical / warning / info) and can auto-fix a few safe cases.

## References

- **`references/frontmatter-standard.md`** — full spec with required/recommended/optional field
  tables, templates, the common-mistakes catalog with before/after examples, and the list of
  valid tool names. Read this when the summary above doesn't cover your case — it is the
  canonical document.
