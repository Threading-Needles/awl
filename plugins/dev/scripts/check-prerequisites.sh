#!/usr/bin/env bash
# Awl Prerequisites Check
# Validates all required CLI tools are installed

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Required tools (command:name:install-instruction)
REQUIRED_TOOLS=(
	"gh:GitHub CLI:brew install gh"
)

# Optional MCP servers (name:purpose:install-command)
OPTIONAL_MCPS=(
	"exa:Web search:/plugin marketplace add exa-labs/exa-mcp-server"
	"posthog:Analytics:/plugin marketplace add posthog-mcp"
)

# Recommended plugins (name:purpose:install-command)
RECOMMENDED_PLUGINS=(
	"pr-review-toolkit:PR review automation:/plugin install pr-review-toolkit"
	"frontend-design:High-quality UI:/plugin install frontend-design"
	"feature-dev:Guided development:/plugin install feature-dev"
	"commit-commands:Commit shortcuts:/plugin install commit-commands"
	"code-review:Code review:/plugin install code-review"
	"hookify:Behavior prevention:/plugin install hookify"
)

echo "🔍 Checking Awl prerequisites..."
echo ""

missing_tools=()

# Check required tools
for tool_spec in "${REQUIRED_TOOLS[@]}"; do
	IFS=: read -r cmd name install <<<"$tool_spec"
	if ! command -v "$cmd" &>/dev/null; then
		missing_tools+=("$name ($install)")
	fi
done

# Report missing requirements
if [ ${#missing_tools[@]} -gt 0 ]; then
	echo -e "${RED}❌ Missing required tools:${NC}"
	for tool in "${missing_tools[@]}"; do
		echo -e "   ${RED}•${NC} $tool"
	done
	echo ""
	echo "Fix missing requirements and run again."
	exit 1
fi

echo -e "${GREEN}✅ All required CLI tools installed${NC}"
echo ""

# Optional: Check MCP servers
echo "ℹ️  Optional MCP servers:"
for mcp_spec in "${OPTIONAL_MCPS[@]}"; do
	IFS=: read -r name purpose install <<<"$mcp_spec"
	echo -e "   • ${YELLOW}$name${NC} ($purpose): $install"
done
echo ""

# Recommended plugins
echo "ℹ️  Recommended plugins (run /awl-dev:doctor for full check):"
for plugin_spec in "${RECOMMENDED_PLUGINS[@]}"; do
	IFS=: read -r name purpose install <<<"$plugin_spec"
	echo -e "   • ${YELLOW}$name${NC} ($purpose): $install"
done
echo ""

echo ""
echo -e "${GREEN}✅ Prerequisites check complete${NC}"
