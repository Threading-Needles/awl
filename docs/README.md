# Documentation Index

Awl is a Claude Code workspace system built on a three-layer memory architecture. This index
helps you find the documentation you need.

## Core Concepts

**Stateless Commands**: Every workflow command takes the Linear ticket ID as a positional argument. No config files, no hidden state.

**Linear-Persisted Context**: Workflow documents (research, plans, handoffs, PRs) are stored as Linear documents attached to tickets. Discoverable by querying the ticket.

**Structured Development Workflow**:

```
research → plan → implement → validate → create-pr → merge-pr
```

See [CLAUDE.md](../CLAUDE.md) for complete architecture details.

---

## Quick Start

**New to Awl?**

1. [Installation & Configuration Guide](../QUICKSTART.md) - Complete setup and configuration
2. [USAGE.md](USAGE.md) - Workflow commands and patterns
3. [BEST_PRACTICES.md](BEST_PRACTICES.md) - Effective patterns

---

## Documentation by Category

### Setup & Configuration

#### [Installation & Configuration Guide](../QUICKSTART.md)

Complete guide covering installation, configuration, service integration (Linear), and project setup.

**Read this when**: Setting up a new project or configuring integrations.

---

### Workflow & Usage

#### [USAGE.md](USAGE.md)

Core workflow commands, installation, Linear integration, common workflows.

**Read this when**: Learning the system or looking up command usage.

---

#### [AGENTIC_WORKFLOW_GUIDE.md](AGENTIC_WORKFLOW_GUIDE.md)

Agent patterns, documentarian philosophy, spawning parallel agents, creating custom agents.

**Read this when**: Using agents effectively or creating new ones.

---

#### [BEST_PRACTICES.md](BEST_PRACTICES.md)

Research → Plan → Implement → Validate workflow, context management, handoffs, ticket management.

**Read this when**: Learning effective workflow patterns.

---

#### [PATTERNS.md](PATTERNS.md)

Parallel development, feature branches, documentation patterns, testing workflows.

**Read this when**: Looking for concrete usage examples.

---

#### [WORKFLOW_DISCOVERY_SYSTEM.md](WORKFLOW_DISCOVERY_SYSTEM.md)

Discovering and importing workflows from external repositories using `/awl-meta:discover-workflows`,
`/awl-meta:import-workflow`, `/awl-meta:create-workflow`.

**Read this when**: Extending Awl with new workflows.

---

### Integrations

#### [DEEPWIKI_INTEGRATION.md](DEEPWIKI_INTEGRATION.md)

External research using DeepWiki, researching external repositories, learning from open-source
patterns.

**Read this when**: Researching how external projects implement features.

---

### Technical

#### [CONTEXT_ENGINEERING.md](CONTEXT_ENGINEERING.md)

Context budgets, just-in-time loading, sub-agent architecture, handoff strategies.

**Read this when**: Optimizing context usage or understanding architectural decisions.

---

#### [FRONTMATTER_STANDARD.md](FRONTMATTER_STANDARD.md)

YAML frontmatter validation, required fields, valid categories/tools, validation rules.

**Read this when**: Creating new agents/commands or debugging frontmatter issues.

---

## By User Type

**First-Time Users**: [Installation & Configuration Guide](../QUICKSTART.md) → [USAGE.md](USAGE.md) →
[BEST_PRACTICES.md](BEST_PRACTICES.md)

**Plugin Developers**: [AGENTIC_WORKFLOW_GUIDE.md](AGENTIC_WORKFLOW_GUIDE.md) →
[FRONTMATTER_STANDARD.md](FRONTMATTER_STANDARD.md) →
[WORKFLOW_DISCOVERY_SYSTEM.md](WORKFLOW_DISCOVERY_SYSTEM.md)

**Integration Specialists**: [DEEPWIKI_INTEGRATION.md](DEEPWIKI_INTEGRATION.md)

---

## By Task

**Setting Up**: [Installation & Configuration Guide](../QUICKSTART.md)

**Daily Development**: [BEST_PRACTICES.md](BEST_PRACTICES.md) → [PATTERNS.md](PATTERNS.md)

**Creating Workflows**: [AGENTIC_WORKFLOW_GUIDE.md](AGENTIC_WORKFLOW_GUIDE.md) →
[WORKFLOW_DISCOVERY_SYSTEM.md](WORKFLOW_DISCOVERY_SYSTEM.md)

**Troubleshooting**: [Installation & Configuration Guide](../QUICKSTART.md#troubleshooting)

---

## Additional Resources

**Parent Directory**:

- [../README.md](../README.md) - Overview
- [../QUICKSTART.md](../QUICKSTART.md) - Installation guide
- [../CLAUDE.md](../CLAUDE.md) - Full architecture (read this!)

**Plugin Documentation**:

- [../plugins/dev/README.md](../plugins/dev/README.md) - Development plugin
- [../plugins/pm/README.md](../plugins/pm/README.md) - Project management plugin
- [../plugins/meta/README.md](../plugins/meta/README.md) - Meta plugin

**External**:

- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [Linear API](https://developers.linear.app/)

---

## Need Help?

**Can't find what you need?**

- Check [../README.md](../README.md) for overview
- Check [../CLAUDE.md](../CLAUDE.md) for architecture
- Review [USAGE.md](USAGE.md) troubleshooting section
- Search: `grep -r "search term" docs/`

**Found an issue?**

- Update the relevant document
- Run `/awl-meta:validate-frontmatter` for agent/command changes
- Create Linear ticket with `/awl-dev:linear` for larger tasks
