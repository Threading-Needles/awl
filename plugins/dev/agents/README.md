# agents/ Directory: Specialized Research Agents

This directory contains markdown files that define specialized research agents for Claude Code.
Agents are invoked by commands using the `Task` tool to perform focused research tasks in parallel.

## How Agents Work

**Agents vs Commands:**

- **Commands** (`/command-name`) - User-facing workflows you invoke directly
- **Agents** (`@awl-dev:name`) - Specialized research tools spawned by commands

**Invocation:** Commands spawn agents using the Task tool:

```markdown
Task(subagent_type="awl-dev:codebase-locator", prompt="Find authentication files")
```

**Philosophy:** All agents follow a **documentarian, not critic** approach:

- Document what EXISTS, not what should exist
- NO suggestions for improvements unless explicitly asked
- NO root cause analysis unless explicitly asked
- Focus on answering "WHERE is X?" and "HOW does X work?"

## Available Agents

### Codebase Research Agents

#### codebase-locator

**Purpose**: Find WHERE code lives in a codebase

**Use when**: You need to locate files, directories, or components

- Finding all files related to a feature
- Discovering directory structure
- Locating test files, configs, or documentation

**Tools**: Grep, Glob, Bash(ls \*)

**Example invocation:**

```markdown
Task( subagent_type="awl-dev:codebase-locator", prompt="Find all authentication-related files" )
```

**Returns**: Organized list of file locations categorized by purpose

---

#### codebase-analyzer

**Purpose**: Understand HOW specific code works

**Use when**: You need to analyze implementation details

- Understanding how a component functions
- Documenting data flow
- Identifying integration points
- Tracing function calls

**Tools**: Read, Grep, Glob, Bash(ls \*)

**Example invocation:**

```markdown
Task( subagent_type="awl-dev:codebase-analyzer", prompt="Analyze the authentication middleware
implementation and document how it works" )
```

**Returns**: Detailed analysis of how code works, with file:line references

---

#### codebase-pattern-finder

**Purpose**: Find existing patterns and usage examples

**Use when**: You need concrete examples

- Finding similar implementations
- Discovering usage patterns
- Locating test examples
- Understanding conventions

**Tools**: Grep, Glob, Read, Bash(ls \*)

**Example invocation:**

```markdown
Task( subagent_type="awl-dev:codebase-pattern-finder", prompt="Find examples of how other components handle
error logging" )
```

**Returns**: Concrete code examples showing patterns in use

### Linear Integration Agents

#### linear-document-locator

**Purpose**: Find documents attached to a specific Linear ticket

**Use when**: You need to discover research, plans, handoffs, or PR descriptions

- Finding existing workflow documents for a ticket
- Checking what context already exists
- Listing document IDs for the analyzer agent

**Tools**: mcp__linear__get_issue, mcp__linear__list_documents, mcp__linear__get_document

**Example invocation:**

```markdown
Task( subagent_type="awl-dev:linear-document-locator", prompt="Find documents for PROJ-123" )
```

**Returns**: Table of documents with IDs, types, and creation dates

---

#### linear-document-analyzer

**Purpose**: Extract insights from a specific Linear document

**Use when**: You need to read and analyze document content

- Extracting decisions from research documents
- Understanding plan details
- Reading handoff context

**Tools**: mcp__linear__get_document, mcp__linear__get_issue

**Example invocation:**

```markdown
Task( subagent_type="awl-dev:linear-document-analyzer", prompt="Analyze document doc_abc123" )
```

**Returns**: Structured analysis with key decisions, findings, and actionable items

---

#### history-reader

**Purpose**: Find relevant context from completed work across the project

**Use when**: You need historical decisions, patterns, or lessons from past tickets

- Understanding how similar problems were solved before
- Finding architectural decisions from previous work
- Surfacing lessons learned from past implementations

**Tools**: mcp__linear__list_issues, mcp__linear__get_issue, mcp__linear__list_documents, mcp__linear__get_document

**Example invocation:**

```markdown
Task( subagent_type="awl-dev:history-reader", prompt="How was authentication implemented? Project: MyProject" )
```

**Returns**: Structured historical context with related tickets, decisions, patterns, and lessons

---

### Linear and GitHub Research Agents

#### linear-research

**Purpose**: Research Linear tickets, cycles, projects, and milestones

**Use when**: You need data from Linear

- Finding tickets by status, label, cycle, or team
- Looking up project and milestone details
- Gathering ticket context for planning or analysis

**Tools**: Linear MCP tools (`mcp__linear__list_issues`, `mcp__linear__get_issue`, etc.), Read, Grep

**Example invocation:**

```markdown
Task( subagent_type="awl-dev:linear-research", prompt="List all In Progress tickets in team ENG with the backend label" )
```

**Returns**: Structured Linear data (tickets, cycles, projects) — pure data gathering, no synthesis

---

#### github-research

**Purpose**: Research GitHub PRs, issues, and workflows via the `gh` CLI

**Use when**: You need GitHub-specific metadata that git alone can't provide

- Looking up PR status, CI checks, reviews, comments
- Finding issues by label, author, or date
- Gathering workflow run history

**Tools**: `Bash(gh *)`, Read, Grep

**Example invocation:**

```markdown
Task( subagent_type="awl-dev:github-research", prompt="List all open PRs assigned to me with failing CI checks" )
```

**Returns**: Structured GitHub data from `gh` CLI — pure data gathering, no synthesis

---

### External Research Agents

#### external-research

**Purpose**: Research external frameworks and repositories

**Use when**: You need information from outside sources

- Understanding how popular repos implement features
- Learning framework patterns
- Researching best practices from open-source
- Discovering external documentation

**Tools**: `mcp__deepwiki__ask_question`, `mcp__deepwiki__read_wiki_structure`, `mcp__context7__get_library_docs`, `mcp__exa__search`

**Example invocation:**

```markdown
Task( subagent_type="awl-dev:external-research", prompt="Research how Next.js implements middleware
authentication patterns" )
```

**Returns**: Information from external repositories and documentation

## Agent File Structure

Every agent file has this structure:

```markdown
---
name: agent-name
description: What this agent does
tools: Tool1, Tool2, Tool3
model: inherit
---

# Agent Implementation

Instructions for the agent...

## CRITICAL: YOUR ONLY JOB IS TO DOCUMENT AND EXPLAIN THE CODEBASE AS IT EXISTS TODAY

- DO NOT suggest improvements...
- DO NOT perform root cause analysis...
- ONLY describe what exists...
```

### Frontmatter Fields

**Required** (Claude Code needs these to load the agent):

- `name` - Agent identifier (must match filename without `.md`)
- `description` - Tells Claude Code when to invoke this agent

**Recommended** (improves safety and cost):

- `tools` - Comma-separated tool list; omit to grant all tools
- `model` - `inherit` (default), `haiku`, `sonnet`, or `opus`

**Optional metadata**:

- `version`, `category`, `color`

See the [`awl-frontmatter` skill](../../meta/skills/awl-frontmatter/) for the full rules and
model-tier guidance (Claude auto-loads it when editing agent or command files).

### Naming Convention

- Filename: `agent-name.md` (hyphen-separated)
- Frontmatter name: `agent-name` (matches filename)
- Unlike commands, agents MUST have a `name` field

## How Commands Use Agents

### Parallel Research Pattern

Commands spawn multiple agents concurrently for efficiency:

```markdown
# Spawn three agents in parallel

Task(subagent_type="awl-dev:codebase-locator", ...)
Task(subagent_type="awl-dev:codebase-analyzer", ...)
Task(subagent_type="awl-dev:codebase-pattern-finder", ...)

# Wait for all to complete

# Synthesize findings
```

### Example from research_codebase.md

```markdown
Task 1 - Find WHERE components live: subagent: codebase-locator prompt: "Find all files related to
authentication"

Task 2 - Understand HOW it works: subagent: codebase-analyzer prompt: "Analyze auth middleware and
document how it works"

Task 3 - Find existing patterns: subagent: codebase-pattern-finder prompt: "Find similar
authentication implementations"
```

## Documentarian Philosophy

**What agents do:**

- ✅ Locate files and components
- ✅ Document how code works
- ✅ Provide concrete examples
- ✅ Explain data flow
- ✅ Show integration points

**What agents do NOT do:**

- ❌ Suggest improvements
- ❌ Critique implementation
- ❌ Identify bugs (unless asked)
- ❌ Recommend refactoring
- ❌ Comment on code quality

**Why this matters:**

- Research should be objective
- Understanding comes before judgment
- Prevents bias in documentation
- Maintains focus on current state

## Plugin Distribution

Agents are distributed as part of the Awl plugin system:

### Installation

**Install Awl plugin**:

```bash
/plugin install awl-dev
```

This installs all agents automatically.

### Updates

**Update plugin**:

```bash
/plugin update awl-dev
```

Agents are pure research logic with no project-specific configuration, so updates are always safe.

### Per-Project Availability

Agents are available in any project where the awl-dev plugin is installed. No per-project setup
needed.

## Creating New Agents

### Step 1: Create Markdown File

```bash
# Create file with hyphen-separated name
touch agents/my-new-agent.md
```

### Step 2: Add Frontmatter

```yaml
---
name: my-new-agent
description: Clear, focused description of what this agent finds or analyzes
tools: Read, Grep, Glob
model: inherit
---
```

### Step 3: Write Agent Logic

```markdown
You are a specialist at [specific research task].

## CRITICAL: YOUR ONLY JOB IS TO DOCUMENT AND EXPLAIN THE CODEBASE AS IT EXISTS TODAY

[Standard documentarian guidelines]

## Core Responsibilities

1. **[Primary Task]**
   - [Specific action]
   - [What to look for]

2. **[Secondary Task]**
   - [Specific action]
   - [What to document]

## Output Format

[Specify how results should be structured]
```

### Step 4: Test

```bash
# In this workspace, agents are immediately available via symlinks
# Just restart Claude Code to reload

# Create a command that uses the agent
# Invoke the command to test the agent
```

### Step 5: Validate Frontmatter

```bash
# In Claude Code (workspace only)
/awl-meta:validate-frontmatter
```

## Common Patterns

### Pattern 1: Locator → Analyzer

```markdown
# First, find files

Task(subagent_type="awl-dev:codebase-locator", ...)

# Then analyze the most relevant ones

Task(subagent_type="awl-dev:codebase-analyzer", ...)
```

### Pattern 2: Pattern Discovery

```markdown
# Find patterns after understanding the code

Task(subagent_type="awl-dev:codebase-analyzer", ...) Task(subagent_type="awl-dev:codebase-pattern-finder", ...)
```

## Tool Access

Agents specify required tools in frontmatter:

**File Operations:**

- `Read` - Read file contents
- `Write` - Create files (rare for agents)

**Search:**

- `Grep` - Content search
- `Glob` - File pattern matching

**Execution:**

- `Bash(ls *)` - List directory contents

**External:**

- `mcp__deepwiki__ask_question` - Query external repos
- `mcp__deepwiki__read_wiki_structure` - Read external docs

## Troubleshooting

### Agent not found when spawned

**Check:**

1. Plugin installed? Run `/plugin list` to verify
2. Frontmatter `name` field matches filename?
3. Restarted Claude Code after adding/modifying agent?

**Solution:**

```bash
# Update plugin
/plugin update awl-dev

# Restart Claude Code
```

### Agent auto-updated by plugin

**This is by design** - agents are pure logic with no project-specific config.

**If you need customization:**

- Don't modify plugin agents - they'll be overwritten on update
- Create a custom agent in `.claude/plugins/custom/agents/`
- Use a different name to avoid conflicts

## See Also

- [`../commands/README.md`](../commands/README.md) — documentation for commands in this plugin
- [`../../../docs/AGENTIC_WORKFLOW_GUIDE.md`](../../../docs/AGENTIC_WORKFLOW_GUIDE.md) — agent
  patterns and best practices
- [`awl-frontmatter` skill](../../meta/skills/awl-frontmatter/) — frontmatter validation rules
- [`awl-linear-workflow` skill](../skills/awl-linear-workflow/) — Linear state machine and
  document conventions the research agents apply
- [`../../../README.md`](../../../README.md) — workspace overview
