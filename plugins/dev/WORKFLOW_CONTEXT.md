# Workflow Context System

Complete guide to automatic document tracking and discovery in Awl.

## The Problem We Solved

**Before**: Users had to remember ticket IDs and find documents manually between commands.

**After**: System automatically tracks the current ticket and discovers documents from Linear:
```bash
# User researches the codebase
/research-codebase PROJ-123
# ✅ Sets current ticket, saves research to Linear

# Later, user wants to create a plan...
/create-plan
# ✅ Queries Linear for research attached to PROJ-123
```

---

## How It Works: Complete Flow

### 1. Setting the Current Ticket

When a workflow command is invoked with a ticket ID:

```
You → /research-codebase PROJ-123
      ↓
workflow-context.sh set-ticket PROJ-123
      ↓
.workflow-context.json updated:
{
  "lastUpdated": "2025-10-28T22:30:00Z",
  "currentTicket": "PROJ-123"
}
```

Research is saved as a Linear document "Research: ..." attached to PROJ-123.

**Key Components:**

1. **Workflow Context** (`.claude/.workflow-context.json`) - Tracks current ticket
2. **Workflow Script** (`scripts/workflow-context.sh`) - Set/get ticket
3. **Linear Documents** - All workflow artifacts stored in Linear

### 2. Discovering Documents (Auto-Discovery)

When user invokes a downstream workflow command:

```
You → /create-plan
      ↓
Command reads current ticket from workflow-context.json
      ↓
Queries Linear: mcp__linear__get_issue for PROJ-123
      ↓
Finds "Research: OAuth Implementation" document
      ↓
Claude reads research and creates plan
```

**Key Components:**

1. **Workflow Context** - Provides current ticket ID
2. **Linear MCP** - Query documents attached to ticket
3. **Command Instructions** - Auto-discover documents from Linear

---

## Complete Workflow Example

### Scenario: Research → Plan → Implement

```bash
# 1. Research the codebase
/research-codebase PROJ-123
# → Sets current ticket to PROJ-123
# → Creates Linear document "Research: Auth System" attached to PROJ-123 ✅

# 2. Create implementation plan
/create-plan
# → Reads current ticket (PROJ-123) from workflow context
# → Queries Linear for research document
# → Claude reads research and creates plan
# → Creates Linear document "Plan: OAuth Support" attached to PROJ-123 ✅

# 3. Implement the plan
/implement-plan
# → Reads current ticket (PROJ-123) from workflow context
# → Queries Linear for plan document
# → Claude reads plan and implements ✅
```

**Zero file paths needed after initial research!**

---

## Commands with Auto-Discovery

### ✅ Implemented

| Command | Auto-Discovers | Behavior |
|---------|---------------|----------|
| `/resume-handoff` | Recent handoff | Finds last handoff, asks to proceed |
| `/implement-plan` | Recent plan | Finds last plan, asks to proceed |
| `/create-plan` | Recent research | **Suggests** research as context |

### 🚧 Fallback if Not Found

All commands gracefully fall back to asking for input:

```bash
/resume-handoff
# No recent handoff found
→ "I'll help you resume work. Which handoff would you like to use?"
→ Lists available handoffs
→ Waits for user input
```

---

## Configuration Files

### Workflow Context (`.claude/.workflow-context.json`)

**Purpose**: Track current ticket for command chaining
**Location**: `.claude/.workflow-context.json` (per-worktree)
**Managed by**: Commands via `workflow-context.sh`

**Structure**:
```json
{
  "lastUpdated": "ISO timestamp",
  "currentTicket": "PROJ-123"
}
```

---

## Scripts

### `workflow-context.sh`

**Purpose**: Manage current ticket in workflow context
**Location**: `plugins/dev/scripts/workflow-context.sh`
**Used by**: Commands

**API**:
```bash
# Set current ticket
workflow-context.sh set-ticket PROJ-123

# Get current ticket
workflow-context.sh get-ticket
# → Returns: PROJ-123

# Initialize context file
workflow-context.sh init
```

---

## Command Pattern: Auto-Discovery

All workflow commands follow this pattern:

1. **Get current ticket** from `.claude/.workflow-context.json`
2. **Query Linear** for documents attached to that ticket
3. **Present findings** and proceed with the workflow

```markdown
## Initial Response

**STEP 1: Get current ticket (REQUIRED)**

Read the current ticket from workflow context:
```bash
TICKET=$("${CLAUDE_PLUGIN_ROOT}/scripts/workflow-context.sh" get-ticket)
```

**STEP 2: Query Linear for documents**

Use `mcp__linear__get_issue` with the ticket identifier to retrieve issue details and attached documents.

**STEP 3: Determine which document to use**

1. If user provided ticket/path → use it (override)
2. If documents found in Linear → proceed
3. If nothing found → ask for ticket ID
```

---

## Benefits

### 1. Zero Memory Required
Users don't need to remember ticket IDs between commands

### 2. Natural Workflow
Commands chain together seamlessly:
```bash
/research-codebase PROJ-123 → /create-plan → /implement-plan
```

### 3. Context Awareness
System knows what you're working on (ticket, documents in Linear)

### 4. Graceful Degradation
Falls back to asking for ticket ID if auto-discovery doesn't find anything

### 5. User Override
Can always provide explicit ticket ID to override auto-discovery

---

## Troubleshooting

### Auto-Discovery Not Working

**Symptom**: Commands can't find documents for the current ticket

**Solutions**:
1. Check current ticket is set: `workflow-context.sh get-ticket`
2. Verify Linear documents exist using `mcp__linear__get_issue` for the ticket
3. Ensure the Linear MCP server is configured and connected

### Workflow Context Empty

**Symptom**: `.workflow-context.json` exists but has no ticket

**Solutions**:
1. Set ticket manually: `workflow-context.sh set-ticket PROJ-123`
2. Re-run the initial command with a ticket ID: `/research-codebase PROJ-123`

### Wrong Ticket in Context

**Symptom**: Commands are querying the wrong ticket

**Solution**: Override by providing the ticket ID explicitly:
```bash
/research-codebase PROJ-456
```

---

## See Also

- [Linear Documents](./LINEAR_DOCUMENTS.md) - Linear documents conventions
- [Commands](./commands/) - Individual command documentation
- [Scripts](./scripts/) - Utility scripts
