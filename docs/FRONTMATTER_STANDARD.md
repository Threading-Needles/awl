# Frontmatter Standard

YAML frontmatter conventions for Awl agents and commands. Claude Code itself reads only a small
subset of these fields; the rest are metadata we use for consistency, validation, and tooling.

## Agents

### Required

```yaml
---
name: { agent-name } # kebab-case, MUST match the filename (no .md)
description: { what-this-agent-does-and-when-to-use-it }
---
```

Claude Code uses `name` and `description` to decide when to invoke the agent. Everything else below
is optional — include it when it adds value.

### Recommended

```yaml
tools: { comma-separated-list }  # restricts tools; omit to grant all tools
model: { model-tier }            # see "Model assignment" below; defaults to inherit
```

### Optional metadata

```yaml
version: 1.0.0       # semver, useful for tracking changes
category: { cat }    # free-form grouping (research, analysis, pm, etc.)
color: { color }     # UI hint (e.g., cyan, emerald, rose)
```

### Example

```yaml
---
name: codebase-locator
description:
  Locates files, directories, and components relevant to a feature or task. Call this agent when
  you want to know WHERE code lives, not how it works.
tools: Grep, Glob, Bash(ls *)
model: haiku
version: 1.0.0
---
```

## Commands

### Required

```yaml
---
description: { one-line-summary }
---
```

Commands are identified by their filename — **do not** add a `name` field.

### Recommended

```yaml
tools: { comma-separated-list }  # restricts tools; omit to grant all tools
model: inherit                   # almost always inherit; see below
```

### Optional metadata

```yaml
version: 1.0.0
category: { cat }          # workflow, pm, debugging, analytics, etc.
argument-hint: { hint }    # shown to the user in the command picker
```

### Example

```yaml
---
description: Conduct comprehensive codebase research using parallel sub-agents
category: workflow
tools: Read, Write, Grep, Glob, Task, TodoWrite, Bash, mcp__linear__get_issue, mcp__linear__save_issue, mcp__linear__create_document, mcp__linear__update_document
model: inherit
version: 2.0.0
---
```

## Model assignment

Claude Code accepts these values in the `model` field:

| Value | Meaning |
|---|---|
| `inherit` | Use whatever model the parent session is using (default) |
| `haiku` | Force Haiku 4.5 — fast, cheap |
| `sonnet` | Force Sonnet 4.6 — balanced |
| `opus` | Force Opus 4.6 — deepest reasoning |

### When to override `inherit`

Most files should keep `model: inherit` so they respect the user's session-level choice. Override
only when you are confident the agent's work maps to a specific tier:

- **`haiku`** — for agents that do **pure lookup or data gathering** with no synthesis. They run
  search tools and return structured data. Examples: finding files, listing Linear tickets, running
  `gh` commands. Cheap and fast, no quality tradeoff for these tasks.
- **`sonnet`** — for agents that do **structured analysis** against a defined scoring rubric or
  schema. Examples: PM health analyzers that compute cycle/milestone scores. Balanced cost/quality.
- **`opus`** — rarely hardcoded. Prefer `inherit` so the user can choose Opus at the session level
  with `claude --model claude-opus-4-6[1m]` (1M-token context) for heavy reasoning sessions.
- **`inherit`** — the default. Deep-reasoning agents that benefit from Opus when the user chose it
  should stay on `inherit`, not hardcode `opus`, so that users running cheaper sessions aren't
  forced into a higher tier.

### Heavy reasoning workflows

For the Research → Plan → Implement flow (`/awl-dev:research-codebase`,
`/awl-dev:create-plan`, `/awl-dev:implement-plan`, `/awl-dev:debug`), start your Claude Code
session with Opus 4.6 and the 1M-token context:

```bash
claude --model claude-opus-4-6[1m]
```

Commands and `inherit`-model agents will then run against Opus 4.6 1M. Hardcoded-`haiku`/-`sonnet`
agents stay on their explicit tier to save cost where reasoning isn't needed.

## Tools

Only list tools actually used. Common ones:

**File operations:** `Read`, `Write`, `Edit`
**Search:** `Grep`, `Glob`
**Execution:** `Bash`, `Bash(<command> *)` (restricted), `Task`, `TodoWrite`
**Web:** `WebFetch`, `WebSearch`
**MCP (Linear):** `mcp__linear__get_issue`, `mcp__linear__list_issues`,
  `mcp__linear__create_document`, `mcp__linear__update_document`, `mcp__linear__get_document`,
  `mcp__linear__list_documents`, `mcp__linear__save_comment`, `mcp__linear__save_issue`,
  `mcp__linear__list_cycles`, `mcp__linear__list_projects`, `mcp__linear__research`, etc.
**MCP (DeepWiki / Context7):** `mcp__deepwiki__ask_question`,
  `mcp__deepwiki__read_wiki_structure`, `mcp__context7__get_library_docs`,
  `mcp__context7__resolve_library_id`

Restrict `Bash` when possible, e.g. `Bash(ls *)`, `Bash(gh *)`, `Bash(git *)`.

## Validation rules

1. **YAML must be well-formed** — proper indentation, no syntax errors.
2. **Agent `name` must match filename** (minus `.md`), in kebab-case.
3. **Commands must NOT have a `name` field** — filename is the identifier.
4. **`version`** (if present) must follow semver (`X.Y.Z`).
5. **Tools must be valid** — check Claude Code docs or the list above before adding new ones.

## Common mistakes

### ❌ Command with a `name` field

```yaml
---
name: create-plan          # ← commands don't have name
description: Create plans
---
```

### ✅ Command without `name`

```yaml
---
description: Create detailed implementation plans
model: inherit
---
```

### ❌ Non-semver version

```yaml
version: v1.0              # ← missing patch, leading "v"
```

### ✅ Semver

```yaml
version: 1.0.0
```

### ❌ Invented tool names

```yaml
tools: SearchFiles, FindFile, GrepFiles
```

### ✅ Real tools

```yaml
tools: Grep, Glob, Read
```

## Validation command

```bash
/awl-meta:validate-frontmatter
```

## See also

- `/awl-meta:validate-frontmatter` — validate all agents and commands
- `/awl-meta:create-workflow` — create a new agent or command with correct frontmatter
- `docs/PATTERNS.md` — agent and command design patterns
