---
description: Validate and fix frontmatter consistency across all Awl agents and commands
category: workflow-discovery
tools: Read, Edit, Glob, Grep
model: inherit
version: 2.0.0
workspace_only: true
---

# Validate Frontmatter

You validate YAML frontmatter across all agents and commands in this repository against the
canonical standard in `docs/FRONTMATTER_STANDARD.md`.

## The canonical standard

Before validating, read `docs/FRONTMATTER_STANDARD.md` — it is the single source of truth for
required fields, recommended fields, model tiers, and naming rules. This command enforces that
standard; it does not define its own.

## Initial response

When invoked:

```
I'll validate frontmatter across all Awl plugins (dev, pm, meta, debugging, analytics).

Mode:
1. Validate all (report only)
2. Validate and auto-fix what's safe
3. Validate a specific file (pass path as argument)

Which mode?
```

## Process

### Step 1 — Load the standard

Read `docs/FRONTMATTER_STANDARD.md` so your validation rules match the current standard exactly.
Do not hardcode rules from memory — they drift over time.

### Step 2 — Discover files

Glob for every agent and command file across all plugins:

```
plugins/*/agents/*.md
plugins/*/commands/*.md
```

Exclude README files from validation (they are documentation, not agents/commands).

### Step 3 — Parse and validate each file

For each file, extract the frontmatter block (between the first two `---` lines) and check:

**Agents (`plugins/*/agents/*.md`):**

- `name` field is present
- `name` value matches the filename (minus `.md`) in kebab-case
- `description` field is present and non-empty
- If `model` is set, it is one of: `inherit`, `haiku`, `sonnet`, `opus`
- If `version` is set, it follows semver `X.Y.Z`
- Tools in the `tools:` list are plausible (no obviously invented names like `SearchFiles`,
  `FindFile`, `GrepFiles`)
- YAML is well-formed

**Commands (`plugins/*/commands/*.md`):**

- `description` field is present and non-empty
- Commands must NOT have a `name` field (filename is the identifier)
- If `model` is set, it is one of: `inherit`, `haiku`, `sonnet`, `opus`
- If `version` is set, it follows semver `X.Y.Z`
- Tools in the `tools:` list are plausible
- YAML is well-formed

**Category field**: Free-form per the current standard — don't flag unusual categories, just
record them for the distribution report.

### Step 4 — Present the report

Group issues by severity:

```markdown
# Frontmatter validation report

**Scanned**: {agents-count} agents, {commands-count} commands across {plugin-count} plugins

## Critical issues (must fix)

### plugins/{plugin}/agents/{name}.md
- ❌ `name` field ("foo") does not match filename ("bar")
- ❌ Missing required `description`

### plugins/{plugin}/commands/{name}.md
- ❌ Has a `name:` field — commands identify by filename; remove it
- ❌ YAML is malformed (line 3: unclosed list)

## Warnings

### plugins/{plugin}/agents/{name}.md
- ⚠️ Unknown tool `FooBar` — did you mean `Bash`?
- ⚠️ `version: v1.0` is not semver; should be `1.0.0`

## Model distribution

- inherit: {count}
- haiku: {count}
- sonnet: {count}
- opus: {count}

## Category distribution

- workflow: {count}
- pm: {count}
- version-control-git: {count}
- ...
```

### Step 5 — Auto-fix mode (if requested)

If the user chose mode 2, offer to auto-fix these safe cases:

- `version: v1.0` → `version: 1.0.0`
- `version: 1.0` → `version: 1.0.0`
- Command has `name: ...` → remove the line
- Missing `model: inherit` on a command → add it (only if absent)

Do NOT auto-fix things that need human judgment:

- Missing `description`
- Mismatched agent `name`/filename (needs human decision which is right)
- Unknown tool names (could be a new tool, could be a typo)
- Malformed YAML

Show the diff before applying and ask for confirmation.

### Step 6 — Single-file mode

If the user passed a specific path as an argument, validate only that file and present a
per-issue report without the distribution summary.

## Important notes

- **The canonical standard lives in `docs/FRONTMATTER_STANDARD.md`** — update that file when the
  rules change, not this command.
- **Use relative paths** — never hardcode absolute paths like `/Users/someone/...`.
- **Be lenient with optional fields** — `category`, `version`, `color`, `argument-hint` are all
  optional metadata. Missing them is not an error.
- **Don't invent rules** — if the standard doesn't require something, don't flag it.

## Integration

- `/awl-meta:create-workflow` — creates new agents/commands that should pass this validation
- `/awl-meta:import-workflow` — imports external workflows and should run this after adaptation
- `docs/FRONTMATTER_STANDARD.md` — the rules this command enforces
