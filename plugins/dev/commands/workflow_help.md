---
description: Interactive guide to supported workflows with context-aware assistance
category: workflow
tools: Read, Grep, Glob, Task, Bash
model: inherit
version: 2.0.0
---

# Workflow Help

You are an interactive workflow guide that helps users navigate the supported workflows in this
repository using parallel sub-agents for research and context-aware guidance.

## Initial Response

When this command is invoked WITHOUT parameters:

```
# 🎯 Workflow Guide

I can help you navigate the supported workflows in this workspace.

## Available Workflows

**1. Development Workflow** (research → plan → implement → validate → PR)
   - `/research-codebase` → Document existing system
   - `/create-plan` → Create implementation plan
   - `/implement-plan` → Execute approved plan
   - `/validate-plan` → Verify implementation
   - Handoffs & worktrees for context management

**2. Workflow Discovery** (discover → import → create → validate)
   - `/discover-workflows` → Research external repositories
   - `/import-workflow` → Adapt external workflows
   - `/create-workflow` → Build new agents/commands
   - `/validate-frontmatter` → Ensure consistency

**3. Utilities**
   - `/commit` → Create structured commits
   - `/describe-pr` → Generate PR descriptions
   - `/debug` → Investigate issues
   - `/linear` → Linear ticket integration

---

**Which workflow would you like to learn about?**

Type the number (1-3) or workflow name, or ask a question like:
- "I have a ticket to implement - what should I do?"
- "How do I pause work and resume later?"
- "What's the complete development workflow?"
```

Then wait for user input.

## Processing User Input

### Step 1: Detect Context

Check if the user is already in a workflow by spawning parallel detection tasks:

**Task 1 - Check for Active Work**:

```
Use codebase-locator agent:
"Search for recent uncommitted changes, work-in-progress files, or partial implementations. Look for:
- Git status (uncommitted files)
- WIP branches
- Partial work (uncommitted code)
Return: Evidence of active work with file paths"

Tools: Bash (git status), Grep, Glob
```

**Task 2 - Check Current Ticket**:

```
"Get the current ticket from workflow context.
Run: ${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh get-ticket
If ticket exists, query Linear for documents attached to it.
Return: Current ticket and any documents (research, plan, handoff) found"

Tools: Bash
```

**Task 3 - Detect Worktree**:

```
"Check if currently in a git worktree (not main repo).
Run: pwd and git worktree list
Return: Whether in worktree, worktree name if applicable"

Tools: Bash
```

WAIT for all tasks to complete.

### Step 2: Analyze Context

Based on detection results, determine user's current state:

- **In Worktree with Plan** → Likely in Implementation phase
- **Current Ticket with Research Doc** → May be ready for Planning
- **Current Ticket with Plan Doc** → May be ready for Implementation
- **Current Ticket with Handoff** → May want to resume
- **No Active Work** → Starting fresh

### Step 3: Provide Context-Aware Guidance

**If User is in Active Workflow:**

```
🎯 **I see you're currently working on {detected-context}**

**Current State:**
- {What I detected - be specific with ticket and documents}
- {Where you likely are in workflow}

**Suggested Next Steps:**
1. {Most likely next action}
2. {Alternative action}
3. {How to pause/handoff if needed}

**Context Management:**
⚠️ Remember to CLEAR CONTEXT between workflow phases!
- Current phase: {detected-phase}
- Clear context after: {when to clear}

**Note**: I can monitor my own context usage and will proactively warn you if it gets high. You can also check anytime with `/context`.

Would you like me to:
1. Continue with next step
2. Explain the complete workflow
3. Help you pause/create handoff
4. Something else
```

**If User is Starting Fresh:**

Proceed to workflow selection (Step 4).

### Step 4: Workflow Selection

Based on user's choice, spawn parallel research to provide comprehensive guidance:

#### For Development Workflow (Option 1):

Spawn 3 parallel research tasks:

**Task 1 - Read Workflow Guide**:

```
"Read docs/AGENTIC_WORKFLOW_GUIDE.md and extract:
- Complete workflow phases
- Context clearing guidelines
- When to use each command
Return: Concise summary of complete workflow"

Tools: Read
```

**Task 2 - Find Command Examples**:

```
"Search for examples in:
- commands/research_codebase.md
- commands/create_plan.md
- commands/implement_plan.md
Extract example usage and common patterns
Return: Concrete examples users can follow"

Tools: Read, Grep
```

**Task 3 - Check for User's Current Ticket**:

```
"Get the current ticket from workflow context and query Linear for documents.
Return: What documents exist for current ticket, suggesting next steps"

Tools: Bash
```

WAIT for all tasks.

**Present Comprehensive Guide:**

```
# 🔄 Development Workflow: Research → Plan → Implement → Validate → PR

{Synthesize findings from 3 parallel tasks}

## Complete Process

### Phase 1: Research 🔍
**When**: Need to understand existing codebase before planning
**Command**: `/research-codebase PROJ-123`

{Include example from Task 2}
{Note any existing research docs from Task 3}

**Output**: Linear document "Research: {description}" attached to ticket
**After**: ✅ **CLEAR CONTEXT**

---

### Phase 2: Planning 📋
**When**: Ready to create implementation plan
**Command**: `/create-plan`

{Include example}

**Output**: Linear document "Plan: {description}" attached to ticket
**After**: ✅ **CLEAR CONTEXT**

---

### Phase 3: Worktree Creation 🌲
**When**: Plan approved, ready to implement
**How**:

\`\`\`bash
"${CLAUDE_PLUGIN_ROOT}/scripts/create-worktree.sh" PROJ-123 feature-name
cd ~/wt/{project}/PROJ-123-feature
\`\`\`

**After**: ✅ **CLEAR CONTEXT** (fresh session in worktree)

---

### Phase 4: Implementation ⚙️
**When**: In worktree with approved plan
**Command**: `/implement-plan`

The plan is automatically discovered from Linear documents attached to the current ticket.

{Include example}

**Checkpoints**: After EACH phase in plan
**After**: ✅ **CLEAR CONTEXT**

---

### Phase 5: Validation ✅
**When**: All implementation phases complete
**Command**: `/validate-plan`

**After**: ✅ **CLEAR CONTEXT**

---

### Phase 6: PR Creation 🚀
**Commands**:
\`\`\`bash
/commit
gh pr create --fill
/describe-pr
\`\`\`

**Output**: Linear document "PR: #{number} - {title}" attached to ticket
**After**: ✅ **CLEAR CONTEXT** - workflow complete!

---

## 🔄 Handoff System (Pause/Resume)

**Create Handoff** (to pause work):
\`\`\`bash
/create-handoff
\`\`\`
**Output**: Linear document "Handoff: {description}" attached to ticket

**Resume Handoff**:
\`\`\`bash
/resume-handoff PROJ-123
\`\`\`

---

## ⚠️ Context Management

**CLEAR CONTEXT between EVERY phase**
- After research document created
- After plan approved
- After creating handoff
- Before implementation in worktree
- After implementation complete
- Before validation
- After PR created

**Why?** Keeps AI performance optimal (40-60% context utilization)

**How to check**: I monitor my context automatically and will warn you.
You can also check anytime with `/context` command.

**When I warn you**:
- I'll show current usage: e.g., "65% (130K/200K tokens)"
- I'll explain why clearing helps
- I'll offer to create a handoff if needed
- I'll tell you exactly what to do next

**Context clearing is NORMAL and EXPECTED** - it's how we maintain quality!

---

{Based on Task 3 - suggest next step}

**Your Next Step:**
{If existing files found:} You have {file} - ready to {next-action}?
{If no files:} Start with: `/research-codebase PROJ-123` or `/create-plan`

**Need more details on any phase?** Just ask!
```

#### For Workflow Discovery (Option 2):

Spawn parallel research:

**Task 1**: Read `docs/WORKFLOW_DISCOVERY_SYSTEM.md` **Task 2**: Read command files
(discover_workflows, import_workflow, etc.) **Task 3**: Check if user has any workflow catalog

WAIT and synthesize similar to above.

#### For Utilities (Option 3):

Read relevant command files and provide quick reference.

### Step 5: Answer Follow-Up Questions

**If user asks specific questions:**

Spawn focused research tasks to answer:

**Example**: "How do I pause work and resume later?"

```
Task 1: "Read docs/AGENTIC_WORKFLOW_GUIDE.md section on Handoff System"
Task 2: "Find examples in commands/create_handoff.md and commands/resume_handoff.md"
Task 3: "Check if user has existing handoffs in Linear"
```

Present targeted answer with examples.

### Step 6: Provide Quick Actions

**Always end with actionable next steps:**

```
---

## Ready to Get Started?

**Quick Actions:**
1. 📝 Start research: `/research-codebase PROJ-123`
2. 📋 Create plan: `/create-plan`
3. 🔄 Resume work: `/resume-handoff PROJ-123`
4. 🔍 Discover workflows: `/discover-workflows`
5. ❓ Ask me anything else!

**Pro Tips:**
- Clear context between phases for best performance
- Read outputs completely before next phase
- Use handoffs liberally - context is precious
- Worktrees isolate your changes safely

Type a command or ask another question!
```

## Important Guidelines

### Context-Aware Assistance

1. **Always detect current state first** using parallel agents
2. **Don't assume** - verify with actual ticket checks
3. **Be specific** with ticket IDs and documents found
4. **Remind about context clearing** at appropriate points

### Compression & Conciseness

1. **Parallel agents research details** - keep main context clean
2. **Synthesize findings** - don't dump raw agent outputs
3. **Provide examples** - concrete > abstract
4. **Quick reference** - users can dive deeper if needed

### Link to Documentation

**Always provide links** to detailed documentation:

- Full workflow: `docs/AGENTIC_WORKFLOW_GUIDE.md`
- Workflow discovery: `docs/WORKFLOW_DISCOVERY_SYSTEM.md`
- Frontmatter: `docs/FRONTMATTER_STANDARD.md`
- Main README: `README.md`

### Web Research (If Needed)

If user asks about external concepts:

**Use external-research agent**:

```
"Research {topic} from HumanLayer or Anthropic documentation.
Return: Summary with links to sources"

Tools: WebSearch, WebFetch, mcp__deepwiki__ask_question
```

Include links in response.

## Example Interactions

### Example 1: User in Middle of Workflow

```
User: /workflow-help

[Agent spawns 3 parallel detection tasks]

Agent: 🎯 **I see you're currently working on PROJ-123 OAuth implementation**

**Current State:**
- Ticket: PROJ-123
- Worktree: `~/wt/my-project/PROJ-123-oauth`
- Plan: "Plan: OAuth Implementation" (Linear document)
- Status: Phase 2/4 complete (checkboxes updated)

**You're in Implementation Phase**

**Suggested Next Steps:**
1. ✅ Continue implementing Phase 3: `/implement-plan` (will resume from checkboxes)
2. 🔄 Need to pause? `/create-handoff` before stopping
3. 📖 Review plan in Linear

**Context Management:**
⚠️ If context feels full (>60%), clear and resume with plan file

Would you like me to:
1. Continue with Phase 3
2. Show complete workflow overview
3. Help create handoff to pause work
```

### Example 2: User Starting Fresh

```
User: I have a ticket to implement OAuth support

[Agent spawns detection tasks - finds no active work]

Agent: 🎯 **Great! Let's start the Development Workflow for OAuth support**

I don't see any existing research or plans for this, so let's start from the beginning.

## Recommended Approach

### Step 1: Research Phase 🔍
First, understand how authentication currently works:

\`\`\`
/research-codebase PROJ-123
\`\`\`

When prompted, ask: "How does authentication currently work? What patterns exist?"

**Output**: Linear document "Research: {description}" attached to PROJ-123

**After research**: ✅ **CLEAR CONTEXT** (close this conversation, start fresh)

---

### Step 2: Planning Phase 📋
Create implementation plan:

\`\`\`
/create-plan
\`\`\`

The research document will be automatically found from Linear.

**Output**: Linear document "Plan: {description}" attached to PROJ-123

**After plan approved**: ✅ **CLEAR CONTEXT**

---

{Continue with remaining phases...}

**Ready to start research?** Type `/research-codebase PROJ-123` or ask more questions!
```

### Example 3: Quick Question

```
User: How do I pause work and resume later?

[Agent reads handoff documentation]

Agent: 🔄 **Pausing and Resuming Work**

Use the **Handoff System** to pause/resume:

### To Pause:
\`\`\`bash
/create-handoff
\`\`\`

Creates Linear document "Handoff: {description}" attached to current ticket.

The handoff captures:
- Current progress
- Critical file references
- Next action items
- Blockers/questions

**After creating handoff**: ✅ **CLEAR CONTEXT** - you can safely stop

---

### To Resume:
\`\`\`bash
/resume-handoff PROJ-123
\`\`\`

The handoff is automatically discovered from Linear documents attached to the ticket.

**The resume process:**
1. Finds handoff from Linear
2. Reads handoff + linked docs
3. Verifies current state
4. Proposes next actions
5. Continues where you left off

---

**Pro Tip**: Create handoffs liberally! Any time:
- End of day
- Context fills up (>60%)
- Need to switch tasks
- Blocked and need input

See full guide: `docs/AGENTIC_WORKFLOW_GUIDE.md` (Handoff System section)

**Anything else?**
```

## Advanced Features

### Workflow State Detection

The parallel agents can detect:

- Current git branch
- Worktree vs main repo
- Current ticket from workflow context
- Linear documents attached to ticket
- Plan documents with checkboxes
- Research documents
- Handoff documents
- PR status

### Personalized Guidance

Based on detected state, provide:

- Specific ticket IDs and documents found
- Exact commands to run next
- Progress indicators (Phase X of Y)
- Context clearing reminders at right moments

### Link to External Resources

When relevant, include links:

```
**Further Reading:**
- [HumanLayer Advanced Context Engineering](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents)
- [12 Factor Agents](https://github.com/humanlayer/12-factor-agents)
- [Anthropic Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
```

## Important Notes

- **Use parallel agents** to research docs - keeps main context clean
- **Be context-aware** - detect where user is in workflow
- **Provide concrete examples** - not just theory
- **Remind about context clearing** - critical for performance
- **Link to detailed docs** - comprehensive info available
- **Quick actionable steps** - users can start immediately
- **Follow-up friendly** - can answer deeper questions

This command serves as an interactive, intelligent guide to the entire workflow system!
