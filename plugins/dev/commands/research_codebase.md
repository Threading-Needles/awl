---
description: Conduct comprehensive codebase research using parallel sub-agents
category: workflow
tools: Read, Write, Grep, Glob, Task, TodoWrite, Bash
model: inherit
version: 2.0.0
---

# Research Codebase

You are tasked with conducting comprehensive research across the codebase to answer user questions
by spawning parallel sub-agents and synthesizing their findings.

## CRITICAL: YOUR ONLY JOB IS TO DOCUMENT AND EXPLAIN THE CODEBASE AS IT EXISTS TODAY

- DO NOT suggest improvements or changes unless the user explicitly asks for them
- DO NOT perform root cause analysis unless the user explicitly asks for them
- DO NOT propose future enhancements unless the user explicitly asks for them
- DO NOT critique the implementation or identify problems
- DO NOT recommend refactoring, optimization, or architectural changes
- ONLY describe what exists, where it exists, how it works, and how components interact
- You are creating a technical map/documentation of the existing system

## Prerequisites

Before executing, verify Linear integration is available:

```bash
# Validate plugin prerequisites (includes LINEAR_API_TOKEN check)
if [[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" ]]; then
  "${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh" || exit 1
fi
```

## Execution Mode Detection

Detect whether running interactively or headless (e.g., `claude -p`):

```bash
MODE=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" detect-mode)
# MODE will be "interactive" or "headless"
```

**Mode behavior:**
- **Interactive**: Ask user for research focus using AskUserQuestion, discuss findings
- **Headless**: Use ticket title/description as research focus, embed questions in document

## Initial Setup

When this command is invoked:

1. **Check for ticket ID argument**
2. **If no ticket ID provided**, respond with:

```
I need a Linear ticket to attach this research to.

Please either:
1. Provide a ticket ID: `/research-codebase PROJ-123`
2. Let me create a new ticket for this research

Which would you prefer?
```

3. **If ticket ID provided**, set it in workflow context and proceed:

```bash
# Set current ticket for subsequent commands
"${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" set-ticket "$TICKET_ID"
```

4. **Get assignee for headless mode** (used for document mentions):

```bash
ASSIGNEE=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" get-assignee "$TICKET_ID")
```

5. **Branch based on mode**:

**If MODE is "interactive":**

```
I'm ready to research the codebase for ticket {TICKET_ID}.

Please provide your research question or area of interest, and I'll analyze it thoroughly
by exploring relevant components and connections.
```

Then wait for the user's research query.

**If MODE is "headless":**

- Read the ticket details: `linearis issues read "$TICKET_ID"`
- Use the ticket title and description as the research focus
- Proceed directly to research steps (no user prompt needed)
- Track questions that arise during research for embedding in document

## Steps to Follow After Receiving the Research Query

### Step 0: Update Linear Ticket Status (FIRST)

**This MUST be the first action after receiving the research query**:

```bash
# Update ticket state immediately - this is THE FIRST thing we do
linearis issues update "$TICKET_ID" --state "Research in Progress"
linearis comments create "$TICKET_ID" --body "Starting research: ${RESEARCH_QUESTION:-Analyzing ticket}"
```

### Step 1: Read Any Directly Mentioned Files First

- If the user mentions specific files (tickets, docs, JSON), read them FULLY first
- **IMPORTANT**: Use the Read tool WITHOUT limit/offset parameters to read entire files
- **CRITICAL**: Read these files yourself in the main context before spawning any sub-tasks
- This ensures you have full context before decomposing the research

### Step 2: Analyze and Decompose the Research Question

- Break down the user's query into composable research areas
- Take time to think deeply about the underlying patterns, connections, and architectural
  implications the user might be seeking
- Identify specific components, patterns, or concepts to investigate
- Create a research plan using TodoWrite to track all subtasks
- Consider which directories, files, or architectural patterns are relevant

### Step 3: Spawn Parallel Sub-Agent Tasks for Comprehensive Research

Create multiple Task agents to research different aspects concurrently.

We have specialized agents that know how to do specific research tasks:

**For codebase research:**

- Use the **codebase-locator** agent to find WHERE files and components live
- Use the **codebase-analyzer** agent to understand HOW specific code works (without critiquing it)
- Use the **codebase-pattern-finder** agent to find examples of existing patterns (without
  evaluating them)

**IMPORTANT**: All agents are documentarians, not critics. They will describe what exists without
suggesting improvements or identifying issues.

**For existing Linear documents on this ticket:**

- Use the **linear-document-locator** agent to find any existing documents attached to the ticket
- Use the **linear-document-analyzer** agent to extract insights from relevant documents

**For external research (only if user explicitly asks):**

- Use the **external-research** agent for external documentation and resources
- IF you use external research agents, instruct them to return LINKS with their findings, and
  INCLUDE those links in your final report

**For Linear tickets (if relevant):**

- Use the **linear-research** agent to get full details of a specific ticket
- Use the **linear-research** agent to find related tickets or historical context

The key is to use these agents intelligently:

- Start with locator agents to find what exists
- Then use analyzer agents on the most promising findings to document how they work
- Run multiple agents in parallel when they're searching for different things
- Each agent knows its job - just tell it what you're looking for
- Don't write detailed prompts about HOW to search - the agents already know
- Remind agents they are documenting, not evaluating or improving

**Example of spawning parallel research tasks:**

```
I'm going to spawn 3 parallel research tasks:

Task 1 - Find WHERE components live:
"Use codebase-locator to find all files related to [topic]. Focus on [specific directories if known]."

Task 2 - Understand HOW it works:
"Use codebase-analyzer to analyze [specific component] and document how it currently works. Include data flow and key integration points."

Task 3 - Find existing patterns:
"Use codebase-pattern-finder to find similar implementations of [pattern] in the codebase. Show concrete examples."
```

### Step 4: Wait for All Sub-Agents to Complete and Synthesize Findings

- **IMPORTANT**: Wait for ALL sub-agent tasks to complete before proceeding
- Compile all sub-agent results
- Prioritize live codebase findings as primary source of truth
- Connect findings across different components
- Document specific file paths and line numbers (format: `file.ext:line`)
- Explain how components interact with each other
- Include temporal context where relevant (e.g., "This was added in commit abc123")
- Mark all research tasks as complete in TodoWrite

### Step 5: Gather Metadata for the Research Document

Collect metadata for the research document:

- Get current date/time
- Get git commit hash: `git rev-parse HEAD`
- Get current branch: `git branch --show-current`
- Get repository name from working directory

### Step 6: Generate Research Document Content

Create a structured research document with the following format:

```markdown
# Research: {User's Research Question}

**Ticket**: {TICKET_ID}
**Date**: {date/time with timezone}
**Git Commit**: {commit-hash}
**Branch**: {branch-name}
**Repository**: {repo-name}

## Research Question

{Original user query, verbatim}

## Summary

{High-level documentation of what you found. 2-3 paragraphs explaining the current state of the
system in this area. Focus on WHAT EXISTS, not what should exist.}

## Detailed Findings

### {Component/Area 1}

**What exists**: {Describe the current implementation}

- File location: `path/to/file.ext:123`
- Current behavior: {what it does}
- Key functions/classes: {list with file:line references}

**Connections**: {How this component integrates with others}

- Calls: `other-component.ts:45` - {description}
- Used by: `consumer.ts:67` - {description}

**Implementation details**: {Technical specifics without evaluation}

### {Component/Area 2}

{Same structure as above}

### {Component/Area N}

{Continue for all major findings}

## Questions for User

{ONLY include this section in headless mode when questions arise during research}

{If ASSIGNEE is set:}
@{ASSIGNEE} - Please answer before proceeding to /create-plan:

{If no ASSIGNEE:}
Please answer before proceeding to /create-plan:

> **Q1 (blocking)**: {Question that must be answered before planning}
> **Context**: {Why this matters for the plan}
> **Options**: A) {option} B) {option} C) {option}
> **Answer**: _[please fill in]_

> **Q2 (non-blocking)**: {Question that helps but has a reasonable default}
> **Context**: {Background information}
> **Answer**: _[please fill in]_

{Note: Only include questions that genuinely arose during research and affect planning}

## Code References

Quick reference of key files and their roles:

- `path/to/file1.ext:123-145` - {What this code does}
- `path/to/file2.ext:67` - {What this code does}
- `path/to/file3.ext:200-250` - {What this code does}

## Architecture Documentation

{Document the current architectural patterns, conventions, and design decisions observed in the
code. This is descriptive, not prescriptive.}

### Current Patterns

- **Pattern 1**: {How it's implemented in the codebase}
- **Pattern 2**: {How it's implemented in the codebase}

### Data Flow

{Document how data moves through the system in this area}

Component A → Component B → Component C
{Describe what happens at each step}

### Key Integrations

{Document how different parts of the system connect}

## Open Questions

{Areas that would benefit from further investigation - NOT problems to fix, just areas where
understanding could be deepened}

- {Question 1}
- {Question 2}
```

### Step 7: Save Research Document to Linear

Create the research document in Linear attached to the ticket:

```bash
# Get team key from config
TEAM_KEY=$(jq -r '.awl.linear.teamKey // "PROJ"' .claude/config.json)

# Create Linear document with research content
linearis documents create \
  --title "Research: ${DESCRIPTION}" \
  --team "${TEAM_KEY}" \
  --content "${DOCUMENT_CONTENT}" \
  --attach-to "${TICKET_ID}" \
  --icon "Search" \
  --color "#eb5757"

# Add completion comment to ticket
linearis comments create "$TICKET_ID" --body "Research complete! Document attached to this ticket."
```

**In headless mode with embedded questions:**

If the document contains a "Questions for User" section with unanswered questions:

```bash
# Set ticket status to "Spec Needed" to signal human input required
linearis issues update "$TICKET_ID" --state "Spec Needed"
```

Then output a clear message:

```
✅ Research complete with questions pending.

**Ticket**: {TICKET_ID}
**Status**: Spec Needed

The research document has been attached to the ticket with {N} questions
that need answers before proceeding to /create-plan.

Please answer the questions in the Linear document, then run:
  claude -p "/create-plan"
```

### Step 8: Present Findings to User

**Present to user:**

```markdown
✅ Research complete!

**Ticket**: {TICKET_ID}
**Linear Document**: Research: {description}

## Summary

{2-3 sentence summary of key findings}

## Key Files

{Top 3-5 most important file references}

## What I Found

{Brief overview - save details for the document}

---

## 📊 Context Status

Current usage: {X}% ({Y}K/{Z}K tokens)

{If >60%}: ⚠️ **Recommendation**: Context is getting full. For best results in the planning phase, I
recommend clearing context now.

**Options**:

1. ✅ Clear context now (recommended) - Close this session and start fresh for planning
2. Create handoff to pause work
3. Continue anyway (may impact performance)

**Why clear?** Fresh context ensures optimal AI performance for the planning phase, which will load
additional files and research.

{If <60%}: ✅ Context healthy. Ready to proceed to planning phase if needed.

---

Would you like me to:

1. Dive deeper into any specific area?
2. Create an implementation plan based on this research?
3. Explore related topics?
```

### Step 9: Handle Follow-Up Questions

If the user has follow-up questions:

1. **Update the existing Linear document** with new findings
2. Use `linearis documents update <document-id>` to append content
3. **Spawn new sub-agents as needed** for the follow-up research

```bash
# Update existing research document
linearis documents update "$DOCUMENT_ID" \
  --content "${UPDATED_CONTENT}"

# Add comment about the update
linearis comments create "$TICKET_ID" --body "Research updated with follow-up findings."
```

## Important Notes

### Ticket Required

- This command REQUIRES a ticket ID
- If user doesn't provide one, offer to create a new ticket
- All research documents are attached to the ticket in Linear

### Proactive Context Management

**Monitor Your Context Throughout Research**:

- Check token usage after spawning parallel agents
- After synthesis phase, check context again
- **If context >60%**: Warn user and recommend handoff

### Parallel Execution

- ALWAYS use parallel Task agents for efficiency
- Don't wait for one agent to finish before spawning the next
- Spawn all research tasks at once, then wait for all to complete

### Research Philosophy

- Always perform fresh codebase research - never rely solely on existing docs
- Existing Linear documents provide historical context, not primary source
- Focus on concrete file paths and line numbers - make it easy to navigate
- Research documents should be self-contained and understandable months later

### Sub-Agent Prompts

- Be specific about what to search for
- Specify directories to focus on when known
- Make prompts focused on read-only documentation
- Remind agents they are documentarians, not critics

### Cross-Component Understanding

- Document how components interact, not just what they do individually
- Trace data flow across boundaries
- Note integration points and dependencies

### Main Agent Role

- Your role is synthesis, not deep file reading
- Let sub-agents do the detailed reading
- You orchestrate, compile, and connect their findings
- Focus on the big picture and cross-component connections

### Documentation Style

- Sub-agents document examples and usage patterns as they exist
- Main agent synthesizes into coherent narrative
- Both levels: documentarian, not evaluator
- Never recommend changes or improvements unless explicitly asked

### File Reading Rules

- ALWAYS read mentioned files fully before spawning sub-tasks
- Use Read tool WITHOUT limit/offset for complete files
- This is critical for proper decomposition

### Follow the Steps

- These numbered steps are not suggestions - follow them exactly
- Don't skip steps or reorder them
- Each step builds on the previous ones

## Integration with Other Commands

This command integrates with the complete development workflow:

```
/research-codebase PROJ-123 → research document (+ Linear: Research)
                  ↓
           /create-plan → implementation plan (+ Linear: Planning)
                  ↓
          /implement-plan → code changes (+ Linear: In Progress)
                  ↓
              /describe-pr → PR created (+ Linear: In Review)
```

**How it connects:**

- **research_codebase → Linear**: Moves ticket to "Research" status and creates research document
- **research_codebase → create_plan**: Subsequent commands find research via `linear-document-locator`
- **Workflow context**: Current ticket is stored, subsequent commands use it automatically

## Example Workflow

```bash
# User starts research with ticket
/research-codebase PROJ-123

# You:
# 1. Set current ticket in workflow context
# 2. Update ticket status to "Research"
# 3. Ask for research question

# User asks: "How does authentication work in the API?"

# You execute:
# 1. Read any mentioned files fully
# 2. Add comment to ticket about starting research
# 3. Decompose into research areas (auth middleware, token validation, session management)
# 4. Spawn parallel agents:
#    - codebase-locator: Find auth-related files
#    - codebase-analyzer: Understand auth middleware implementation
#    - codebase-pattern-finder: Find auth usage patterns
#    - linear-document-locator: Find existing research on PROJ-123
# 5. Wait for all agents
# 6. Synthesize findings
# 7. Create Linear document "Research: Authentication Flow" attached to PROJ-123
# 8. Present summary to user

# User follows up: "How does it integrate with the database?"
# You update the same Linear document with new findings
```

## Error Handling

**If ticket not found:**

```
⚠️ Ticket {TICKET_ID} not found in Linear.

Please verify:
1. The ticket ID is correct (e.g., PROJ-123)
2. You have access to this Linear team
3. LINEAR_API_TOKEN is set correctly

Would you like me to create a new ticket for this research?
```

**If document creation fails:**

- Log error but continue with research
- Present findings to user directly
- Suggest manual document creation

## Status Update Convention

**EVERY workflow step MUST update status as the FIRST action**:

- Step 0 updates status to "Research in Progress" BEFORE any file reads
- Status stays "Research in Progress" after completion (next command advances it)
- On failure, roll back to previous state:

```bash
# Roll back to previous state on failure
linearis issues update "$TICKET_ID" --state "Backlog"
linearis comments create "$TICKET_ID" --body "Research failed: ${ERROR_REASON}"
```
