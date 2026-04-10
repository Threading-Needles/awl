---
description: Manage Linear tickets with workflow automation
category: project-task-management
tools:
  mcp__linear__get_issue, mcp__linear__list_issues,
  mcp__linear__save_issue, mcp__linear__save_comment,
  mcp__linear__get_document, mcp__linear__create_document,
  mcp__linear__update_document, mcp__linear__list_documents,
  mcp__linear__list_cycles, mcp__linear__list_issue_statuses,
  mcp__linear__research,
  Read, Write, Edit, Grep
model: inherit
version: 3.0.0
---

# Linear - Ticket Management

You are tasked with managing Linear tickets, updating ticket statuses, and following a structured
workflow using the official Linear MCP tools.

## Initial Response

If tools are available, respond based on the user's request:

### For general requests:

```
I can help you with Linear tickets. What would you like to do?
1. Create a new ticket
2. Add a comment to a ticket
3. Search for tickets
4. Update ticket status or details
5. Move ticket through workflow
6. View documents attached to a ticket
```

Then wait for the user's input.

---

## Workflow & Status Progression

This workflow ensures alignment through planning before implementation:

### Workflow Statuses

1. **Backlog** → New ideas and feature requests
2. **Triage** → Initial review and prioritization
3. **Research** → Requires investigation
4. **Planning** → Writing implementation plan
5. **Ready for Dev** → Plan approved, ready to implement
6. **In Progress** → Active development
7. **In Review** → PR submitted
8. **Done** → Completed

**Note**: These statuses must be configured in your Linear workspace settings. Use
`mcp__linear__list_issue_statuses` to see available states.

### Key Principle

**Review and alignment happen at the plan stage (not PR stage)** to move faster and avoid rework.

### Workflow Commands Integration

These commands automatically update ticket status:

- `/awl-dev:research-codebase PROJ-123` → Moves ticket to "Research"
- `/awl-dev:create-plan` → Moves ticket to "Planning"
- `/awl-dev:implement-plan` → Moves to "In Progress"
- `/awl-dev:create-pr` → Moves to "In Review"
- `/awl-dev:merge-pr` → Moves to "Done"

---

## Action-Specific Instructions

### 1. Creating Tickets

#### Steps to follow:

1. **Determine the team:**
   - If the user passed a team key as argument (e.g., `/awl-dev:linear create ENG "My ticket"`), use it.
   - Otherwise, use `mcp__linear__list_teams` to list available teams and ask which to create in.
   - Do not assume or hardcode a default team.

2. **Gather information:**
   - Title: Clear, action-oriented
   - Description: Problem/goal summary
   - Priority: 1=Urgent, 2=High, 3=Medium (default), 4=Low

3. **Create the ticket:**

   Use `mcp__linear__save_issue` with:
   - team (from step 1)
   - title
   - description (markdown)
   - priority (1-4)
   - state: "Backlog"

4. **Post-creation:**
   - Show the created ticket URL and ID
   - Tell the user they can now run workflow commands with that ticket ID, e.g., `/awl-dev:research-codebase NEW-123`

### 2. Adding Comments to Existing Tickets

When user wants to add a comment to a ticket:

1. **Determine which ticket:**
   - Use context from the current conversation
   - Or use `mcp__linear__get_issue` to confirm

2. **Format comments for clarity:**
   - Keep concise (~10 lines) unless more detail needed
   - Include relevant file references with backticks
   - Focus on key insights

3. **Add comment:**

   Use `mcp__linear__save_comment` with the issue ID and body text.

### 3. Moving Tickets Through Workflow

When moving tickets to a new status:

1. **Get current status:**

   Use `mcp__linear__get_issue` to read the current state.

2. **Suggest next status based on workflow:**
   ```
   Backlog → Research (needs investigation)
   Research → Planning (starting plan with /awl-dev:create-plan)
   Planning → Ready for Dev (plan approved)
   Ready for Dev → In Progress (starting work with /awl-dev:implement-plan)
   In Progress → In Review (PR created)
   In Review → Done (PR merged)
   ```

3. **Update status:**

   Use `mcp__linear__save_issue` with the new state.

4. **Add comment explaining the transition:**

   Use `mcp__linear__save_comment` with a message like:
   "Moving to In Progress: Starting implementation"

### 4. Searching for Tickets

When user wants to find tickets:

1. **Execute search:**

   - Use `mcp__linear__list_issues` with filters (team, status, assignee)
   - For complex queries, use `mcp__linear__research` with natural language

2. **Present results:**
   - Show ticket ID, title, status, assignee
   - Include direct links to Linear

### 5. Viewing Documents Attached to Tickets

To see documents (research, plans, handoffs, PR descriptions) attached to a ticket:

Use `mcp__linear__get_issue` with the ticket ID to see attached documents.

Documents are categorized by title pattern:
- `Research: ...` - Research documents
- `Plan: ...` - Implementation plans
- `Handoff: ...` - Session handoffs
- `PR: ...` - PR descriptions

To read a specific document, use `mcp__linear__get_document` with the document ID.

---

## Integration with Workflow Commands

### Automatic Ticket Updates

When workflow commands are run, they automatically update the associated ticket:

**During `/awl-dev:research-codebase PROJ-123`:**
1. Moves to "Research" status
2. Creates "Research: ..." document attached to ticket

**During `/awl-dev:create-plan PROJ-123`:**
1. Moves to "Planning" status
2. Creates "Plan: ..." document attached to ticket

**During `/awl-dev:implement-plan PROJ-123`:**
1. Moves to "In Progress" status
2. Adds progress comments as phases complete

**During `/awl-dev:create-pr`:**
1. Moves to "In Review" status (ticket extracted from branch name)
2. Creates "PR: ..." document attached to ticket

**During `/awl-dev:merge-pr`:**
1. Moves to "Done" status
2. Adds merge completion comment

---

## Example Workflows

### Workflow 1: Research → Plan → Implement

```bash
# 1. Start research with ticket
/awl-dev:research-codebase PROJ-123
# Creates "Research: ..." document in Linear
# Ticket moves to "Research"

# 2. Create plan
/awl-dev:create-plan
# Reads research from Linear
# Creates "Plan: ..." document in Linear
# Ticket moves to "Planning"

# 3. Implement
/awl-dev:implement-plan
# Reads plan from Linear
# Ticket moves to "In Progress"

# 4. Create PR
/awl-dev:create-pr
# Creates "PR: ..." document in Linear
# Ticket moves to "In Review"

# 5. Merge PR
/awl-dev:merge-pr
# Ticket moves to "Done"
```

### Workflow 2: Quick Ticket Updates

Use the Linear MCP tools directly:

- Add a comment: `mcp__linear__save_comment` with issue ID and body
- Move ticket forward: `mcp__linear__save_issue` with new state
- Search tickets: `mcp__linear__list_issues` with filters or `mcp__linear__research` with natural language
- View documents: `mcp__linear__get_issue` to find attachments

---

## Linear MCP Tool Reference

### Common Operations

- **Read issue**: `mcp__linear__get_issue` - Get full ticket details
- **List issues**: `mcp__linear__list_issues` - Filter by team, status, etc.
- **Create/update issue**: `mcp__linear__save_issue` - Create new or update existing
- **Add comment**: `mcp__linear__save_comment` - Add comment to issue
- **List documents**: `mcp__linear__list_documents` - Find documents
- **Read document**: `mcp__linear__get_document` - Read document content
- **Create document**: `mcp__linear__create_document` - Create new document
- **Update document**: `mcp__linear__update_document` - Update document content
- **List cycles**: `mcp__linear__list_cycles` - Get cycle information
- **Research**: `mcp__linear__research` - Natural language queries

---

## Notes

- **Team selection**: Pass team as positional arg when creating tickets, or prompt interactively
- **Status mapping**: Use status names that exist in your Linear workspace
- **Automation**: Workflow commands auto-update tickets when ticket IDs are passed as arguments
- **Documents**: All workflow documents (research, plans, handoffs, PRs) are stored as Linear documents attached to tickets

This command integrates seamlessly with the research → plan → implement → validate workflow while
keeping Linear tickets in sync!
