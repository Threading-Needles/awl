---
description: Manage Linear tickets with workflow automation
category: project-task-management
tools: Bash(linearis *), Read, Write, Edit, Grep
model: inherit
version: 2.0.0
---

# Linear - Ticket Management

You are tasked with managing Linear tickets, updating ticket statuses, and following a structured
workflow using the Linearis CLI.

## Prerequisites Check

First, verify that Linearis CLI is installed and configured:

```bash
if ! command -v linearis &> /dev/null; then
    echo "❌ Linearis CLI not found"
    echo ""
    echo "Install with:"
    echo "  npm install -g linearis"
    echo ""
    echo "Configure with:"
    echo "  export LINEAR_API_TOKEN=your_token"
    exit 1
fi

if [[ -z "$LINEAR_API_TOKEN" ]]; then
    echo "❌ LINEAR_API_TOKEN not set"
    echo ""
    echo "Get a token from: https://linear.app/settings/api"
    echo "Then: export LINEAR_API_TOKEN=your_token"
    exit 1
fi
```

## Configuration

Read team configuration from `.claude/config.json`:

```bash
CONFIG_FILE=".claude/config.json"

# Read team key (e.g., "ENG", "PROJ")
TEAM_KEY=$(jq -r '.catalyst.linear.teamKey // "PROJ"' "$CONFIG_FILE")

# Read default team name (optional)
DEFAULT_TEAM=$(jq -r '.catalyst.linear.defaultTeam // null' "$CONFIG_FILE")
```

**Configuration in `.claude/config.json`**:

```json
{
  "linear": {
    "teamKey": "ENG",
    "defaultTeam": "Backend"
  }
}
```

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

**Note**: These statuses must be configured in your Linear workspace settings. The Linearis CLI will
read and use whatever states exist in your workspace.

### Key Principle

**Review and alignment happen at the plan stage (not PR stage)** to move faster and avoid rework.

### Workflow Commands Integration

These commands automatically update ticket status:

- `/research-codebase PROJ-123` → Moves ticket to "Research"
- `/create-plan` → Moves ticket to "Planning"
- `/implement-plan` → Moves to "In Progress"
- `/create-pr` → Moves to "In Review"
- `/merge-pr` → Moves to "Done"

---

## Action-Specific Instructions

### 1. Creating Tickets

#### Steps to follow:

1. **Gather information:**
   - Title: Clear, action-oriented
   - Description: Problem/goal summary
   - Priority: 1=Urgent, 2=High, 3=Medium (default), 4=Low

2. **Create the ticket:**

   ```bash
   linearis issues create \
     --title "[title]" \
     --description "[description in markdown]" \
     --priority [1-4] \
     --state "Backlog"
   ```

3. **Post-creation:**
   - Show the created ticket URL
   - Set the ticket in workflow context for subsequent commands:
     ```bash
     "${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" set-ticket "$TICKET_ID"
     ```

### 2. Adding Comments to Existing Tickets

When user wants to add a comment to a ticket:

1. **Determine which ticket:**
   - Use context from the current conversation
   - Or use `linearis issues read TEAM-123` to confirm

2. **Format comments for clarity:**
   - Keep concise (~10 lines) unless more detail needed
   - Include relevant file references with backticks
   - Focus on key insights

3. **Add comment:**
   ```bash
   linearis comments create TEAM-123 --body "Your comment text here"
   ```

### 3. Moving Tickets Through Workflow

When moving tickets to a new status:

1. **Get current status:**
   ```bash
   linearis issues read TEAM-123 | jq -r '.state.name'
   ```

2. **Suggest next status based on workflow:**
   ```
   Backlog → Research (needs investigation)
   Research → Planning (starting plan with /create-plan)
   Planning → Ready for Dev (plan approved)
   Ready for Dev → In Progress (starting work with /implement-plan)
   In Progress → In Review (PR created)
   In Review → Done (PR merged)
   ```

3. **Update status:**
   ```bash
   linearis issues update TEAM-123 --state "In Progress"
   ```

4. **Add comment explaining the transition:**
   ```bash
   linearis comments create TEAM-123 --body "Moving to In Progress: Starting implementation"
   ```

### 4. Searching for Tickets

When user wants to find tickets:

1. **Execute search:**
   ```bash
   # List issues
   linearis issues list --limit 100

   # Filter by status using jq
   linearis issues list --limit 100 | jq '.[] | select(.state.name == "In Progress")'

   # Search by text
   linearis issues list --limit 100 | jq '.[] | select(.title | contains("search term"))'
   ```

2. **Present results:**
   - Show ticket ID, title, status, assignee
   - Include direct links to Linear

### 5. Viewing Documents Attached to Tickets

To see documents (research, plans, handoffs, PR descriptions) attached to a ticket:

```bash
linearis attachments list --issue TEAM-123
```

This returns all document attachments on the issue. Documents are categorized by title pattern:
- `Research: ...` - Research documents
- `Plan: ...` - Implementation plans
- `Handoff: ...` - Session handoffs
- `PR: ...` - PR descriptions

To read a specific document:
```bash
linearis documents read <document-id>
```

---

## Integration with Workflow Commands

### Automatic Ticket Updates

When workflow commands are run, they automatically update the associated ticket:

**During `/research-codebase PROJ-123`:**
1. Sets ticket in workflow context
2. Moves to "Research" status
3. Creates "Research: ..." document attached to ticket

**During `/create-plan`:**
1. Moves to "Planning" status
2. Creates "Plan: ..." document attached to ticket

**During `/implement-plan`:**
1. Moves to "In Progress" status
2. Adds progress comments as phases complete

**During `/create-pr`:**
1. Moves to "In Review" status
2. Creates "PR: ..." document attached to ticket

**During `/merge-pr`:**
1. Moves to "Done" status
2. Adds merge completion comment

---

## Example Workflows

### Workflow 1: Research → Plan → Implement

```bash
# 1. Start research with ticket
/research-codebase PROJ-123
# Creates "Research: ..." document in Linear
# Ticket moves to "Research"

# 2. Create plan
/create-plan
# Reads research from Linear
# Creates "Plan: ..." document in Linear
# Ticket moves to "Planning"

# 3. Implement
/implement-plan
# Reads plan from Linear
# Ticket moves to "In Progress"

# 4. Create PR
/create-pr
# Creates "PR: ..." document in Linear
# Ticket moves to "In Review"

# 5. Merge PR
/merge-pr
# Ticket moves to "Done"
```

### Workflow 2: Quick Ticket Updates

```bash
# Add progress comment
linearis comments create PROJ-123 --body "Completed phase 1, moving to phase 2"

# Move ticket forward
linearis issues update PROJ-123 --state "In Progress"

# Search for related tickets
linearis issues list --limit 100 | jq '.[] | select(.title | contains("authentication"))'

# View documents attached to ticket
linearis attachments list --issue PROJ-123
```

---

## Linearis CLI Reference

### Common Commands

```bash
# List issues
linearis issues list --limit 50

# Filter by status using jq
linearis issues list --limit 100 | jq '.[] | select(.state.name == "In Progress")'

# Read specific issue
linearis issues read TICKET-123

# Create issue
linearis issues create --title "Title" --description "Description" --state "Backlog"

# Update issue state
linearis issues update TICKET-123 --state "In Progress"

# Update assignee
linearis issues update TICKET-123 --assignee "@me"

# Add comment
linearis comments create TICKET-123 --body "Comment text"

# List documents attached to issue
linearis attachments list --issue TICKET-123

# Read document
linearis documents read <document-id>

# Create document
linearis documents create --title "Title" --content "Content" --attach-to TICKET-123

# List cycles
linearis cycles list --team TEAM [--active]
```

### JSON Output Parsing

Linearis returns JSON, parse with jq:

```bash
# Get ticket status
linearis issues read TEAM-123 | jq -r '.state.name'

# Get ticket title
linearis issues read TEAM-123 | jq -r '.title'

# Get assignee
linearis issues read TEAM-123 | jq -r '.assignee.name'

# Filter list by keyword
linearis issues list --limit 100 | jq '.[] | select(.title | contains("bug"))'
```

---

## Notes

- **Configuration**: Use `.claude/config.json` for team settings
- **Status mapping**: Use status names that exist in your Linear workspace
- **Automation**: Workflow commands auto-update tickets when ticket IDs are used
- **CLI required**: Linearis CLI must be installed and LINEAR_API_TOKEN set
- **Documents**: All workflow documents (research, plans, handoffs, PRs) are stored as Linear documents attached to tickets

This command integrates seamlessly with the research → plan → implement → validate workflow while
keeping Linear tickets in sync!
