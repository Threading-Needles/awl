#!/usr/bin/env bash
# Workflow context management - tracks current ticket for Linear document workflow
#
# Usage:
#   workflow-context.sh init           - Initialize context file
#   workflow-context.sh set-ticket ID  - Set current ticket
#   workflow-context.sh get-ticket     - Get current ticket
#   workflow-context.sh clear          - Clear current ticket

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
	if [ -t 0 ] && [ -t 1 ]; then
		echo "interactive"
	else
		echo "headless"
	fi
	;;
*)
	echo "Usage: $0 {init|set-ticket|get-ticket|clear|detect-mode}" >&2
	echo ""
	echo "Commands:"
	echo "  init              Initialize workflow context file"
	echo "  set-ticket <id>   Set current ticket (e.g., PROJ-123)"
	echo "  get-ticket        Get current ticket ID"
	echo "  clear             Clear current ticket"
	echo "  detect-mode       Detect interactive vs headless mode"
	exit 1
	;;
esac
