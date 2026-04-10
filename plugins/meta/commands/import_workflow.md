---
description: Import and adapt a workflow from external repositories
category: workflow-discovery
tools: Read, Write, Edit, mcp__deepwiki__ask_question
model: inherit
version: 1.0.0
workspace_only: true
---

# Import Workflow

You are tasked with importing and adapting workflows from external Claude Code repositories into
this workspace.

## Purpose

This command helps you import discovered workflows, adapt them to your workspace standards, validate
frontmatter consistency, and integrate with your configuration.

## Initial Response

When invoked:

```
I'll help you import a workflow from an external repository.

Please provide:
1. Repository name (e.g., wshobson/commands)
2. Workflow name (e.g., code-review)

Or, if you've already run /awl-meta:discover-workflows:
- Pick from previously discovered workflows
```

## Process

### Step 1: Identify Workflow

Get the repository and workflow name from user or parameters.

### Step 2: Parallel Research & Validation

**IMPORTANT**: Spawn 3 parallel tasks for comprehensive analysis.

Use TodoWrite to track parallel research.

**Task 1 - External Research**:

```
Use external-research agent:
"Research {repo}/{workflow}. Explain what this workflow does, how it works, what tools it uses, and provide the complete implementation including frontmatter."

Tools: mcp__deepwiki__ask_question
Return: Full workflow understanding and implementation
```

**Task 2 - Local Pattern Check**:

```
Use codebase-pattern-finder agent:
"Find similar workflows in our workspace (agents/ and commands/ directories). Look for workflows that serve similar purposes or use similar patterns."

Tools: Grep, Glob, Read
Path: /Users/ryan/code-repos/ryan-claude-workspace
Return: Similar local workflows for comparison
```

**WAIT for both tasks to complete.**

### Step 3: Aggregate and Analyze

Combine results from the parallel tasks:

- External workflow details (Task 1)
- Similar local patterns (Task 2)

Mark all tasks complete in TodoWrite.

Analyze:

1. **Purpose alignment**: Does this fit our needs?
2. **Duplication check**: Do we already have something similar?
3. **Adaptation needs**: What needs to change?

### Step 4: Present Analysis to User

Show comprehensive analysis:

````markdown
# Import Analysis: {workflow-name}

## What It Does

[Summary from external research]

## External Implementation

- **Repository**: {repo}
- **Tools used**: [list]
- **Frontmatter**:
  ```yaml
  [original frontmatter]
  ```
````

## Comparison with Our Workspace

### Similar Local Workflows

[From Task 2 - what we already have]

### Differences

- [Key differences from our patterns]

## Required Adaptations

1. **Frontmatter**: [what needs to change]
2. **Configuration**: [ticket prefix, Linear IDs, etc.]
3. **Tool references**: [any tool updates needed]
4. **Naming**: [follow our conventions]

## Recommendation

[Import as-is / Import with modifications / Skip (we have similar)]

Proceed with import? (Y/n)

````

### Step 5: Adapt to Workspace Standards

If user approves, adapt the workflow:

#### 5a. Standardize Frontmatter

Apply consistent frontmatter based on type:

**For Agents**:
```yaml
---
name: {workflow-name}
description: |
  {Clear description from research}
  {When to invoke}
tools: {validated tool list}
model: inherit
category: {appropriate category}
version: 1.0.0
source: {repo-url}  # Track origin
---
````

**For Commands**:

```yaml
---
description: { One-line summary }
category: { appropriate category }
argument-hint: { if applicable }
tools: { tool list }
model: inherit
version: 1.0.0
source: { repo-url } # Track origin
---
```

#### 5b. Replace Repository-Specific Values

Check for and replace:

- Hardcoded ticket prefixes (ENG-XXX → placeholder `TICKET-123` or parameterize via command argument)
- Repository paths (their paths → local paths)
- Team/project IDs (their IDs → command arguments or interactive prompts)
- User names (their names → generic placeholders)
- Tool names (check compatibility)

#### 5c. Add Attribution

Add source attribution in frontmatter and as comment:

```markdown
---
source: https://github.com/{repo}
adapted: { date }
original-author: { if known }
---

<!--
Adapted from: {repo}/{workflow-name}
Original: {URL}
Modifications:
- {change 1}
- {change 2}
-->
```

### Step 6: Validate Frontmatter

Before saving, validate against standard:

- Required fields present?
- Tools list valid?
- Category appropriate?
- Description clear?
- Name follows kebab-case?

If validation fails, show issues and fix.

### Step 7: Save Workflow

Determine type and save location:

**If Agent**:

- Save to: `agents/{workflow-name}.md`

**If Command**:

- Save to: `commands/{workflow-name}.md`

### Step 8: Confirmation

Present success summary:

```markdown
✅ Workflow imported successfully!

**Saved to**: {file-path}

**Adaptations made**:

- Standardized frontmatter
- Updated ticket prefix: ENG → PROJ
- Added source attribution
- Validated tools list

**Next steps**:

1. Review: `{file-path}`
2. Test: Try using the workflow
3. Customize: Adjust for your specific needs
4. Commit: `git add {file-path} && git commit -m "Import {workflow-name} from {repo}"`
```

## Advanced Usage

### Import with Custom Adaptations

```
/awl-meta:import-workflow wshobson/commands code-review --adapt "Use our custom linting rules"
```

### Import Multiple Workflows

```
/awl-meta:import-workflow wshobson/commands code-review refactor test-gen
```

Imports all 3 in sequence (with parallel validation for each).

### Dry Run Mode

```
/awl-meta:import-workflow wshobson/commands code-review --dry-run
```

Shows what would be imported without actually saving files.

## Important Notes

- **Always validate**: Never blindly import without checking compatibility
- **Track provenance**: Always attribute source
- **Respect licenses**: Check repo license before importing
- **Test imported workflows**: Verify they work in your environment
- **Track imports**: Keep a record of what you've imported

## Integration with Other Commands

- **Discover first**: `/awl-meta:discover-workflows` → catalog workflows
- **Then import**: `/awl-meta:import-workflow` (this command)
- **Validate**: `/awl-meta:validate-frontmatter` ensures consistency
- **Create custom**: `/awl-meta:create-workflow` for new workflows

## Error Handling

### Workflow Not Found

- Suggest running `/awl-meta:discover-workflows {repo}` first
- Check catalog for available workflows

### Incompatible Tools

- List tools that don't exist in your environment
- Suggest alternatives
- Ask if should proceed with modifications

### Duplicate Workflow

- Show existing similar workflow
- Ask: Replace / Rename / Skip?

### Validation Failures

- Show specific issues
- Offer to auto-fix
- Request manual review if complex

This command bridges external workflows into your workspace with proper adaptation and validation!
