# Claude Code Hooks for Awl Dev

Automatic workflow tracking via Claude Code hooks system.

## Overview

The Awl Dev plugin can include Claude Code hooks that run automatically during workflow operations. Hooks extend the plugin's capabilities by responding to tool usage events.

## How Hooks Work

### 1. Event Detection

Claude Code fires events when tools are used (e.g., Write, Edit, Bash).

### 2. Hook Triggers

Hooks defined in `hooks.toml` match against tool names and file path patterns.

### 3. Script Execution

When a hook matches, it runs the specified script.

## Hook Configuration

Hooks are defined in `plugins/dev/hooks.toml`:

```toml
[[hooks]]
name = "Example Hook"
event = "PostToolUse"

[hooks.matcher]
tool_name = "Write"
file_paths = ["*.md"]

[hooks.command]
command = "bash"
args = ["${CLAUDE_PLUGIN_ROOT}/hooks/example-hook.sh"]
run_in_background = false
```

## Activation

### During Plugin Installation

When you install the `awl-dev` plugin, Claude Code automatically:
1. Discovers the `hooks.toml` in the plugin
2. Registers all defined hooks
3. Activates them for your session

### Manual Activation

If hooks aren't working, restart Claude Code:
```bash
# Restart Claude Code to reload plugins and hooks
# Hooks will be active in the new session
```

## Commands That Use Workflow Context

These commands automatically read workflow context to find the current ticket and query Linear for documents:

- `/awl-dev:resume-handoff` - Finds handoff document for the current ticket
- `/awl-dev:create-plan` - Finds research document for the current ticket
- `/awl-dev:implement-plan` - Finds plan document for the current ticket
- `/awl-dev:validate-plan` - Verifies plan was followed

## Troubleshooting

### Hooks Not Firing

**Symptoms**: Expected hook behavior not occurring

**Solutions**:
1. Restart Claude Code (hooks load on startup)
2. Check plugin is installed: `/plugin list`
3. Verify hooks.toml exists in plugin
4. Check Claude Code hooks settings

### Script Path Not Found

**Symptom**: Hook runs but can't find the target script

**Solution**: Hook scripts should use `${CLAUDE_PLUGIN_ROOT}` to reference files relative to the plugin root.

## See Also

- [Scripts](./scripts/)
- [Claude Code Hooks Documentation](https://docs.claude.com/en/docs/claude-code/hooks)
