#!/usr/bin/env bash
# Workflow context management - tracks current ticket for Linear document workflow
#
# Usage:
#   workflow-context.sh init              - Initialize context file
#   workflow-context.sh set-ticket ID     - Set current ticket
#   workflow-context.sh get-ticket        - Get current ticket
#   workflow-context.sh clear             - Clear current ticket
#   workflow-context.sh detect-mode       - Detect interactive vs headless mode (or use CLAUDE_MODE env var)
#   workflow-context.sh get-assignee [ID] - Get assignee name for ticket (returns empty on error)

set -euo pipefail

# Check for required dependency
if ! command -v jq &>/dev/null; then
	echo "Error: jq is required but not installed" >&2
	echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)" >&2
	exit 1
fi

CONTEXT_FILE=".claude/.workflow-context.json"

# Ensure .claude directory exists
ensure_dir() {
	mkdir -p "$(dirname "$CONTEXT_FILE")"
}

# Initialize context file if it doesn't exist
init_context() {
	ensure_dir
	if [[ ! -f $CONTEXT_FILE ]]; then
		if ! echo '{"currentTicket": null}' >"$CONTEXT_FILE"; then
			echo "Error: Could not create workflow context file: $CONTEXT_FILE" >&2
			echo "Check permissions and disk space." >&2
			exit 1
		fi
	fi
}

# Set current ticket
set_ticket() {
	local ticket="$1"
	init_context
	if ! jq --arg ticket "$ticket" '.currentTicket = $ticket' "$CONTEXT_FILE" >"${CONTEXT_FILE}.tmp" 2>/dev/null; then
		echo "Error: Failed to update workflow context. File may be corrupted: $CONTEXT_FILE" >&2
		echo "Try: rm $CONTEXT_FILE && $0 init" >&2
		exit 1
	fi
	if ! mv "${CONTEXT_FILE}.tmp" "$CONTEXT_FILE"; then
		echo "Error: Failed to save workflow context. Check disk space and permissions." >&2
		exit 1
	fi
	echo "Set current ticket: $ticket"
}

# Get current ticket
get_ticket() {
	init_context
	local ticket
	if ! ticket=$(jq -r '.currentTicket // empty' "$CONTEXT_FILE" 2>/dev/null); then
		echo "Error: Could not read workflow context. File may be corrupted: $CONTEXT_FILE" >&2
		exit 1
	fi
	echo "$ticket"
}

# Clear current ticket
clear_ticket() {
	init_context
	if ! jq '.currentTicket = null' "$CONTEXT_FILE" >"${CONTEXT_FILE}.tmp" 2>/dev/null; then
		echo "Error: Failed to update workflow context. File may be corrupted: $CONTEXT_FILE" >&2
		exit 1
	fi
	if ! mv "${CONTEXT_FILE}.tmp" "$CONTEXT_FILE"; then
		echo "Error: Failed to save workflow context. Check disk space and permissions." >&2
		exit 1
	fi
	echo "Cleared current ticket"
}

# Main dispatcher
case "${1:-}" in
init)
	init_context
	echo "Initialized workflow context"
	;;
set-ticket)
	if [[ -z "${2:-}" ]]; then
		echo "Usage: $0 set-ticket <ticket-id>" >&2
		exit 1
	fi
	set_ticket "$2"
	;;
get-ticket)
	get_ticket
	;;
clear)
	clear_ticket
	;;
detect-mode)
	# Detect if running in interactive or headless mode
	# Headless: claude -p "prompt" (no TTY)
	# Interactive: user typing in Claude Code terminal
	# Override: CLAUDE_MODE environment variable takes precedence
	if [[ -n "${CLAUDE_MODE:-}" ]]; then
		echo "$CLAUDE_MODE"
	elif [ -t 0 ] && [ -t 1 ]; then
		echo "interactive"
	else
		echo "headless"
	fi
	;;
get-assignee)
	# Get the assignee name for a ticket (for document mentions)
	# Returns: assignee name if found, empty string if no assignee or on error
	# Errors are logged to stderr for debugging
	_ga_ticket="${2:-}"
	if [[ -z "$_ga_ticket" ]]; then
		_ga_ticket=$(get_ticket)
	fi
	if [[ -z "$_ga_ticket" || "$_ga_ticket" == "null" ]]; then
		echo ""
		exit 0
	fi

	# Check if linearis is available
	if ! command -v linearis &>/dev/null; then
		echo "Warning: linearis CLI not found, cannot fetch assignee" >&2
		echo ""
		exit 0
	fi

	# Attempt to read ticket with error handling
	if ! _ga_response=$(linearis issues read "$_ga_ticket" 2>&1); then
		echo "Warning: Could not fetch ticket $_ga_ticket: $_ga_response" >&2
		echo ""
		exit 0
	fi

	# Validate JSON and extract assignee
	if ! _ga_assignee=$(echo "$_ga_response" | jq -r '.assignee.name // empty' 2>/dev/null); then
		echo "Warning: Invalid response from Linear for ticket $_ga_ticket" >&2
		echo ""
		exit 0
	fi

	echo "$_ga_assignee"
	;;
*)
	echo "Usage: $0 {init|set-ticket|get-ticket|clear|detect-mode|get-assignee}" >&2
	echo ""
	echo "Commands:"
	echo "  init              Initialize workflow context file"
	echo "  set-ticket <id>   Set current ticket (e.g., PROJ-123)"
	echo "  get-ticket        Get current ticket ID"
	echo "  clear             Clear current ticket"
	echo "  detect-mode       Detect interactive vs headless mode (CLAUDE_MODE overrides)"
	echo "  get-assignee [id] Get assignee name for ticket (empty on error)"
	exit 1
	;;
esac
