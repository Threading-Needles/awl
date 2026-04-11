---
name: awl-pr-lifecycle
description: Pull request lifecycle for Awl — branch naming, the commit → create-pr → describe → babysit → merge flow, Linear status transitions at each phase, PR description conventions, and the safety rules around rebasing, CI, and squash-merging. Use this skill whenever Claude is working on a feature branch (anything matching `[A-Z]+-[0-9]+-*`), running git commands that will produce a PR, creating/describing/reviewing/merging a pull request, or when a GitHub PR URL shows up in the conversation. Make sure to use this skill whenever the user is about to run `/awl-dev:commit`, `/awl-dev:create-pr`, `/awl-dev:describe-pr`, `/awl-dev:babysit-pr`, or `/awl-dev:merge-pr`, even if they don't explicitly ask for PR guidance.
---

# Awl PR Lifecycle

The Awl PR flow is five commands that stay in tight sync with Linear. This skill tells Claude when
each command fires, what Linear state it transitions to, and which safety rails must not be
bypassed.

## Branch naming is load-bearing

Branches MUST match `{TICKET-PREFIX}-{NUMBER}-{description}` (e.g. `PROJ-13-implement-oauth`).
PR commands extract the ticket from the branch name with the regex `[A-Z]+-[0-9]+`. If the ticket
isn't in the branch name, the whole PR-to-Linear automation is off.

## The five-command flow

```
/awl-dev:commit       →  conventional commit on the feature branch
/awl-dev:create-pr    →  rebase onto main, push, open PR, auto-link Linear
/awl-dev:describe-pr  →  (auto-called by create-pr; re-runnable to refresh)
/awl-dev:babysit-pr   →  (auto-called after create-pr; watches CI + runs test plan)
/awl-dev:merge-pr     →  verify → squash-merge → delete branches → Linear "Done"
```

Each command updates the ticket status as its **first** action and rolls back on failure:

| Command | Pre-status | Success status | Failure rollback |
|---|---|---|---|
| `create-pr` | In Dev | In Review | In Dev |
| `describe-pr` | — (updater only) | In Review | In Dev |
| `babysit-pr` | — (monitor only) | unchanged | unchanged |
| `merge-pr` | In Review | Done | In Review |

Full state-machine details live in the `awl-linear-workflow` skill — if Claude is changing
status, read that skill too.

## Commit format (delegated to `awl-conventional-commits`)

Conventional commits with auto-detected type and scope from changed files, ticket footer from
the branch name, header max 100 characters. See the `awl-conventional-commits` skill for the full
rules and examples. **Never** add `Co-authored-by: Claude` or attribution lines unless the user
explicitly asks.

## PR description document

The PR description is a Linear document titled `PR: {description}` attached to the ticket, with
a mirror published to GitHub. `describe-pr` preserves manual edits (Reviewer Notes, Screenshots,
manually checked boxes, Post-Merge Tasks) and regenerates auto-sections (Summary, Changes Made,
How to Verify It, Changelog Entry).

PR descriptions follow this structure — regenerate auto-sections, preserve manual sections:

```markdown
## Summary                      ← auto (regenerated)
## Changes Made                  ← auto (appends new changes)
## How to Verify It              ← auto (reruns verification)
- [x] make test
- [x] make lint
- [ ] Manual: check staging URL  ← manual box, preserved
## Changelog Entry               ← auto
## Reviewer Notes                ← manual, preserved
## Screenshots/Videos            ← manual, preserved
## Post-Merge Tasks              ← manual, preserved
```

## Safety rails (do not bypass)

1. **No force-push to main, ever.** `merge-pr` always uses squash merge via `gh pr merge --squash`.
2. **Rebase onto main before creating the PR** — `create-pr` does this automatically and hard-fails
   on conflicts. Resolve conflicts manually, don't paper over them.
3. **CI must be green before merge.** `merge-pr` blocks on red CI; the override path exists but
   requires the user to explicitly opt in.
4. **Approvals must be present** unless the user explicitly overrides.
5. **Squash merge is the only merge strategy.** Do not use merge commits or rebase-merge.
6. **Branches get deleted automatically** (local + remote) after merge, unless `--keep-branch`.

## Babysit phase

After `create-pr` opens the PR, `babysit-pr` is auto-called to:

1. Poll CI status until all checks complete (max 15 minutes)
2. Auto-fix lint/type errors when possible (max 3 attempts)
3. Extract deployment preview URL from the PR
4. Run the visual/manual items from the PR's test plan against the preview
5. Tick off verified items in the PR description

`babysit-pr` can also be run standalone on any open PR to catch up.

## Post-merge

After `merge-pr` succeeds:

- Ticket is in **Done**
- Remote and local branches deleted
- `main` is checked out and pulled
- Any `Post-Merge Tasks` items extracted from the PR description are reported to the user (they're
  not auto-created as tickets — the user decides)

## References

- **`references/pr-lifecycle.md`** — full walkthrough of each command, complete output examples,
  flag reference, troubleshooting, and integration examples. Read this when the summary above
  isn't enough.
