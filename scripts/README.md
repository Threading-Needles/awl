# scripts/ Directory: Setup Utilities

This directory contains **setup scripts** for integrating Linear and other services. These scripts
are **not bundled in the Catalyst plugin** - they're used during initial setup only.

**Note**: Runtime scripts (workflow-context.sh, check-prerequisites.sh, create-worktree.sh, etc.)
are bundled in the plugin at `plugins/dev/scripts/` and `plugins/meta/scripts/`.

## Directory Structure

```
scripts/
├── linear/              # Linear workflow setup
│   └── setup-linear-workflow
├── load-catalyst-config.sh
├── setup-catalyst-config.sh
└── README.md            # This file
```

---

## Prerequisites

Catalyst requires:

1. **Linearis CLI** - For Linear document operations
2. **LINEAR_API_TOKEN** - Environment variable with your API token

```bash
# Install Linearis CLI
npm install -g linearis

# Set Linear API token (get from https://linear.app/settings/api)
export LINEAR_API_TOKEN="lin_api_..."
```

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

### setup-catalyst-config.sh

**Initialize Catalyst configuration**

```bash
./scripts/setup-catalyst-config.sh
```

**What it does**:

- Creates `.claude/config.json` with project settings
- Configures Linear team key
- Sets up ticket prefix

### load-catalyst-config.sh

**Load Catalyst configuration in scripts**

```bash
source ./scripts/load-catalyst-config.sh
```

**What it does**:

- Loads project configuration
- Sets environment variables for scripts
- Used by other setup scripts

---

## Project Setup Workflow

### New Project Setup

1. **Install Catalyst plugin**:
   ```bash
   /plugin marketplace add coalesce-labs/catalyst
   /plugin install catalyst-dev
   ```

2. **Set Linear API token**:
   ```bash
   export LINEAR_API_TOKEN="lin_api_..."
   ```

3. **Configure project**:
   Edit `.claude/config.json`:
   ```json
   {
     "projectKey": "myproject",
     "project": {
       "ticketPrefix": "PROJ",
       "name": "My Project"
     },
     "catalyst": {
       "linear": {
         "teamKey": "PROJ"
       }
     }
   }
   ```

4. **Verify setup**:
   ```bash
   linearis issues list --limit 5
   ```

---

## Scripts in Plugin (Not Here)

These scripts are bundled in the Catalyst plugin:

- `plugins/dev/scripts/check-prerequisites.sh` - Validates Linear is configured
- `plugins/dev/scripts/create-worktree.sh` - Creates git worktrees
- `plugins/dev/scripts/workflow-context.sh` - Manages current ticket context

**Use commands instead**:

- `/create-worktree` - Creates worktrees
- `/validate-frontmatter` - Validates frontmatter

---

## Troubleshooting

### "linearis command not found"

```bash
npm install -g linearis
```

### "LINEAR_API_TOKEN not set"

```bash
# Get token from https://linear.app/settings/api
export LINEAR_API_TOKEN="lin_api_..."

# Or add to shell profile
echo 'export LINEAR_API_TOKEN="lin_api_..."' >> ~/.zshrc
```

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
