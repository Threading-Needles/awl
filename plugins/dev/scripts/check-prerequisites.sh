#!/usr/bin/env bash
# Catalyst Prerequisites Check
# Validates all required CLI tools are installed

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Required tools (command:name:install-instruction)
REQUIRED_TOOLS=(
	"jq:JSON processor:brew install jq"
	"gh:GitHub CLI:brew install gh"
	"linearis:Linear CLI:npm install -g linearis"
)

# Optional tools (command:name:install-instruction)
OPTIONAL_TOOLS=(
	"railway:Railway CLI:npm install -g @railway/cli"
	"sentry-cli:Sentry CLI:curl -sL https://sentry.io/get-cli/ | sh"
)

# Required environment variables
REQUIRED_ENV_VARS=(
	"LINEAR_API_TOKEN:Linear API token:https://linear.app/settings/api"
)

# Optional MCP servers (name:purpose:install-command)
OPTIONAL_MCPS=(
	"exa:Web search:/plugin marketplace add exa-labs/exa-mcp-server"
	"posthog:Analytics:/plugin marketplace add posthog-mcp"
)

echo "🔍 Checking Catalyst prerequisites..."
echo ""

missing_tools=()
missing_env=()

# Check required tools
for tool_spec in "${REQUIRED_TOOLS[@]}"; do
	IFS=: read -r cmd name install <<<"$tool_spec"
	if ! command -v "$cmd" &>/dev/null; then
		missing_tools+=("$name ($install)")
	fi
done

# Check required environment variables
for env_spec in "${REQUIRED_ENV_VARS[@]}"; do
	IFS=: read -r var name url <<<"$env_spec"
	if [[ -z "${!var:-}" ]]; then
		missing_env+=("$var - $name (Get from: $url)")
	fi
done

# Report missing requirements
if [ ${#missing_tools[@]} -gt 0 ] || [ ${#missing_env[@]} -gt 0 ]; then
	if [ ${#missing_tools[@]} -gt 0 ]; then
		echo -e "${RED}❌ Missing required tools:${NC}"
		for tool in "${missing_tools[@]}"; do
			echo -e "   ${RED}•${NC} $tool"
		done
		echo ""
	fi

	if [ ${#missing_env[@]} -gt 0 ]; then
		echo -e "${RED}❌ Missing required environment variables:${NC}"
		for env in "${missing_env[@]}"; do
			echo -e "   ${RED}•${NC} $env"
		done
		echo ""
	fi

	echo "Fix missing requirements and run again."
	exit 1
fi

echo -e "${GREEN}✅ All required CLI tools installed${NC}"
echo -e "${GREEN}✅ All required environment variables set${NC}"
echo ""

# Check optional tools
echo "ℹ️  Optional tools:"
for tool_spec in "${OPTIONAL_TOOLS[@]}"; do
	IFS=: read -r cmd name install <<<"$tool_spec"
	if command -v "$cmd" &>/dev/null; then
		echo -e "   ${GREEN}✓${NC} $name"
	else
		echo -e "   ${YELLOW}○${NC} $name (not installed): $install"
	fi
done
echo ""

# Optional: Check MCP servers
echo "ℹ️  Optional MCP servers:"
for mcp_spec in "${OPTIONAL_MCPS[@]}"; do
	IFS=: read -r name purpose install <<<"$mcp_spec"
	echo -e "   • ${YELLOW}$name${NC} ($purpose): $install"
done

echo ""
echo -e "${GREEN}✅ Prerequisites check complete${NC}"
