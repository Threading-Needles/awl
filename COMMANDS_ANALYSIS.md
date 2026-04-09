# Commands Analysis

## What We Should Use Directly

### ✅ Copied to This Workspace

These are universally useful and work with any project:

1. **commit.md** - Smart git commit creation
   - Analyzes changes and creates logical commits
   - No external dependencies
   - Works with any git repository

2. **describe_pr.md** - PR description generation
   - Uses `gh` CLI (GitHub CLI)
   - Runs verification commands
   - Updates PR via GitHub API

3. **debug.md** - Debugging helper
   - Investigates logs, database, git state
   - Can be adapted for any project's logging structure
   - Helps debug without burning main context

### Previously Not Copied

These were tightly coupled to upstream infrastructure:

1. **ci_commit.md / ci_describe_pr.md** - CI-specific versions
2. **create_handoff.md / resume_handoff.md** - Session handoff (now reimplemented)
3. **research_codebase\*.md** - Variations of create_plan (consolidated)
4. **founder_mode.md** - Internal tool (not generally useful)

## Commands We Have Now

```
commands/
├── commit.md              # Git commit creation (copied from HL)
├── create_plan.md         # Interactive planning (copied from HL)
├── debug.md               # Debugging helper (copied from HL)
├── describe_pr.md         # PR description (copied from HL)
├── implement_plan.md      # Plan execution (copied from HL)
└── validate_plan.md       # Plan validation (copied from HL)
```

## Usage Notes

### commit.md

- Run after completing work
- Creates well-structured commits
- No Claude attribution (respects user authorship)

### describe_pr.md

- Requires: `gh` CLI installed
- Runs verification commands automatically
- Updates PR via GitHub API

### debug.md

- Use when hitting issues during implementation
- Investigates without burning main context
- Adapt log paths for your project structure

## Extending This

You can create project-specific commands by:

1. Copying a command to `.claude/commands/` in your project
2. Customizing for your workflow
3. Project commands take precedence over user commands

Example: Create `.claude/commands/deploy.md` for your deployment workflow.
