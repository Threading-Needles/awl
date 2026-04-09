# scripts/ Directory: Setup Utilities

This directory contains **setup scripts** for integrating Linear and other services. These scripts
are **not bundled in the Awl plugin** - they're used during initial setup only.

**Note**: Runtime scripts (workflow-context.sh, check-prerequisites.sh, etc.)
are bundled in the plugin at `plugins/dev/scripts/` and `plugins/meta/scripts/`.

## Directory Structure

```
scripts/
├── linear/              # Linear workflow setup
│   └── setup-linear-workflow
├── load-awl-config.sh
├── setup-awl-config.sh
└── README.md            # This file
```

---

## Prerequisites

Awl requires:

1. **Linear MCP** - The official Linear MCP server for Linear document operations (handles authentication automatically)

---

## Linear Workflow Scripts

### setup-linear-workflow

**Generate Linear workflow status setup**

```bash
./scripts/linear/setup-linear-workflow TEAM-KEY
```

**What it does**:

- Creates GraphQL mutation file at `/tmp/linear-workflow-setup.graphql`
- Defines workflow statuses:
  - Backlog → Triage → Research → Planning → In Progress → In Review → Done
- Provides setup instructions

**When to use**: Initial Linear integration setup (optional, can manage statuses manually)

---

## Configuration Scripts

### setup-awl-config.sh

**Initialize Awl configuration**

```bash
./scripts/setup-awl-config.sh
```

**What it does**:

- Creates `.claude/config.json` with project settings
- Configures Linear team key
- Sets up ticket prefix

### load-awl-config.sh

**Load Awl configuration in scripts**

```bash
source ./scripts/load-awl-config.sh
```

**What it does**:

- Loads project configuration
- Sets environment variables for scripts
- Used by other setup scripts

---

## Project Setup Workflow

### New Project Setup

1. **Install Awl plugin**:
   ```bash
   /plugin marketplace add Threading-Needles/awl
   /plugin install awl-dev
   ```

2. **Ensure Linear MCP is configured** in your Claude Code settings (handles authentication automatically).

3. **Configure project**:
   Edit `.claude/config.json`:
   ```json
   {
     "projectKey": "myproject",
     "project": {
       "ticketPrefix": "PROJ",
       "name": "My Project"
     },
     "awl": {
       "linear": {
         "teamKey": "PROJ"
       }
     }
   }
   ```

4. **Verify setup**:
   Use `mcp__linear__list_issues` to confirm connectivity to Linear.

---

## Scripts in Plugin (Not Here)

These scripts are bundled in the Awl plugin:

- `plugins/dev/scripts/check-prerequisites.sh` - Validates Linear is configured
- `plugins/dev/scripts/workflow-context.sh` - Manages current ticket context

**Use commands instead**:

- `/awl-meta:validate-frontmatter` - Validates frontmatter

---

## Troubleshooting

### "Linear MCP not available"

Ensure the official Linear MCP server is configured in your Claude Code settings. The MCP server handles authentication automatically via OAuth.

### "jq not found" warning

```bash
brew install jq  # macOS
apt-get install jq  # Linux
```

---

## See Also

- [QUICKSTART.md](../QUICKSTART.md) - Getting started guide
- [docs/CONFIGURATION.md](../docs/CONFIGURATION.md) - Configuration reference
- [docs/LINEAR_DOCUMENTS.md](../docs/LINEAR_DOCUMENTS.md) - Linear documents architecture
