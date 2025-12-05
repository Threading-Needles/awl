# AWL Meta Plugin (awl-meta)

Workflow discovery and creation tools.

## Installation

```bash
/plugin install awl-meta
```

## Prerequisites

### Required

- **Linearis CLI**: `npm install -g linearis`
- **LINEAR_API_TOKEN**: Environment variable

### Recommended Plugins

| Plugin | Purpose | Install |
|--------|---------|---------|
| plugin-dev | Plugin development tools | `/plugin install plugin-dev` |

## Commands

| Command | Purpose |
|---------|---------|
| `/awl-meta:discover-workflows` | Find workflow patterns in repos |
| `/awl-meta:import-workflow` | Import and adapt workflows |
| `/awl-meta:create-workflow` | Create new agents/commands |
| `/awl-meta:validate-frontmatter` | Check frontmatter consistency |

## Usage

### Discovering Workflows

Research Claude Code repositories for workflow patterns:

```
/awl-meta:discover-workflows
```

### Importing Workflows

Import and adapt a workflow from an external repository:

```
/awl-meta:import-workflow
```

### Creating New Workflows

Create new agents or commands based on discovered patterns:

```
/awl-meta:create-workflow
```

### Validating Frontmatter

Check frontmatter consistency across all plugin components:

```
/awl-meta:validate-frontmatter
```

## Related Plugins

From the same marketplace:

| Plugin | Purpose |
|--------|---------|
| awl-dev | Core development workflow |
| awl-pm | Project management |
| awl-analytics | PostHog integration |
| awl-debugging | Sentry integration |
