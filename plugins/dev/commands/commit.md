---
description: Create conventional commits for session changes
category: version-control-git
tools: Bash, Read
model: inherit
version: 3.0.0
---

# Commit Changes

Create a git commit for the changes made during this session, following Awl's conventional commit
format.

**Format and type rules live in the `awl-conventional-commits` skill** — read that skill (or its
`references/conventional-commits.md`) for the full type taxonomy, scope detection rules, header
limits, and the no-Claude-attribution policy. This command is the workflow orchestration; the
skill is the spec.

## Process

### 1. Understand what changed

- Read the conversation history — what did this session accomplish?
- Run `git status` to see current working-tree state
- Run `git diff --cached` for staged changes (if any)
- Run `git diff` for unstaged changes
- Collect the changed-file list with `git diff --name-only` and `git diff --cached --name-only`

### 2. Propose type, scope, and message

Apply the rules from the `awl-conventional-commits` skill:

- Infer `type` from the nature of the changes (docs-only → `docs`, test-only → `test`, new
  feature → `feat`, bug fix → `fix`, etc.). When unclear, ask the user.
- Infer `scope` from the changed-file paths using the scope map in the skill. If changes span
  unrelated areas, omit the scope entirely.
- Extract the ticket ID from the branch name (`git branch --show-current`) using the regex
  `[A-Z]+-[0-9]+`. If found, it becomes the `Refs: TICKET-N` footer. If not, omit the footer —
  do **not** fabricate a ticket ID.
- Draft the summary in imperative mood, no trailing period, no capital leading letter, header
  ≤ 100 characters total.
- Draft a body that explains **why**, not what (the diff already shows what). Optional for
  trivial changes.

### 3. Present the plan

Show the user:

- Detected type + scope + confidence ("I think this is `feat(agents)` — changes are all in
  `plugins/dev/agents/`.")
- The generated commit message (header + body + footer)
- The files that will be staged (by name — never `-A` or `.`)

Ask: "Proceed with this commit? [Y/n/e(dit)]"

- **Y** — stage the listed files and create the commit
- **n** — abort, don't touch anything
- **e** — let the user edit the message, then re-present

### 4. Execute

- Stage files with `git add <specific-files>`. **Never** use `git add -A` or `git add .` — they
  pick up unrelated changes (e.g. `.env`, scratch files).
- Create the commit with the approved message (use a HEREDOC for multi-line messages).
- Show the result: `git log --oneline -n 1` and `git show --stat HEAD`.

## Important

- The `awl-conventional-commits` skill is authoritative on format — if this command seems to
  disagree with the skill, the skill wins.
- **Do not** add `Co-authored-by: Claude` or any attribution footer unless the user explicitly
  asks, or unless this is a commit to the Awl workspace itself (which has its own dogfooding
  policy documented in the root `CLAUDE.md`).
- Keep commits focused and atomic when possible. If the session produced logically separate
  changes, consider proposing multiple commits rather than one mega-commit.
- The user trusts your judgment — they asked you to commit. But always show the plan before
  executing so they can veto or edit.
