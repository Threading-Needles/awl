#!/usr/bin/env bash
# migrate-catalyst-to-awl.sh - Migrate user config from Catalyst to Awl
#
# This script helps users migrate their local configuration from the
# old "Catalyst" structure to the new "Awl" structure.
#
# What it does:
# 1. Renames ~/.config/catalyst/ to ~/.config/awl/
# 2. Updates JSON keys from "catalyst" to "awl" in config files
# 3. Preserves all existing configuration values
#
# Usage:
#   ./scripts/migrate-catalyst-to-awl.sh
#   ./scripts/migrate-catalyst-to-awl.sh --dry-run  # Preview changes without making them

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}🔍 DRY RUN MODE - No changes will be made${NC}\n"
fi

OLD_CONFIG_DIR="$HOME/.config/catalyst"
NEW_CONFIG_DIR="$HOME/.config/awl"

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Catalyst → Awl Migration Script        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

# Check if old config directory exists
if [[ ! -d "$OLD_CONFIG_DIR" ]]; then
    echo -e "${GREEN}✓ No Catalyst config found at $OLD_CONFIG_DIR${NC}"
    echo -e "  Nothing to migrate - you're all set!"
    exit 0
fi

# Check if new config directory already exists
if [[ -d "$NEW_CONFIG_DIR" ]]; then
    echo -e "${YELLOW}⚠ Warning: $NEW_CONFIG_DIR already exists${NC}"
    echo -e "  This might indicate a previous migration attempt."
    echo ""
    read -p "  Do you want to overwrite it? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}✗ Migration cancelled${NC}"
        exit 1
    fi
    if [[ "$DRY_RUN" == "false" ]]; then
        rm -rf "$NEW_CONFIG_DIR"
    fi
fi

echo -e "${BLUE}📁 Found Catalyst config at: $OLD_CONFIG_DIR${NC}"
echo ""

# List files to migrate
echo -e "${BLUE}Files to migrate:${NC}"
for file in "$OLD_CONFIG_DIR"/*; do
    if [[ -f "$file" ]]; then
        echo -e "  • $(basename "$file")"
    fi
done
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}Would perform the following actions:${NC}"
    echo -e "  1. Create directory: $NEW_CONFIG_DIR"
    echo -e "  2. Copy config files"
    echo -e "  3. Update JSON keys: \"catalyst\" → \"awl\""
    echo -e "  4. Remove old directory: $OLD_CONFIG_DIR"
    echo ""
    echo -e "${YELLOW}Run without --dry-run to perform migration${NC}"
    exit 0
fi

# Create new config directory
echo -e "${BLUE}📁 Creating new config directory...${NC}"
mkdir -p "$NEW_CONFIG_DIR"

# Process each config file
for old_file in "$OLD_CONFIG_DIR"/*; do
    if [[ -f "$old_file" ]]; then
        filename=$(basename "$old_file")
        new_file="$NEW_CONFIG_DIR/$filename"

        echo -e "  Processing: $filename"

        # Copy and transform the file
        if [[ "$filename" == *.json ]]; then
            # For JSON files, update the "catalyst" key to "awl"
            if command -v jq &> /dev/null; then
                # Use jq if available for proper JSON transformation
                jq 'if has("catalyst") then {awl: .catalyst} + (del(.catalyst)) else . end' "$old_file" > "$new_file"
            else
                # Fallback to sed if jq is not available
                sed 's/"catalyst":/"awl":/g' "$old_file" > "$new_file"
            fi
        else
            # For non-JSON files, just copy
            cp "$old_file" "$new_file"
        fi

        echo -e "    ${GREEN}✓ Migrated to $new_file${NC}"
    fi
done

echo ""
echo -e "${BLUE}🗑️  Removing old config directory...${NC}"
rm -rf "$OLD_CONFIG_DIR"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Migration Complete! 🎉                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Your config has been migrated from:"
echo -e "  ${RED}$OLD_CONFIG_DIR${NC} → ${GREEN}$NEW_CONFIG_DIR${NC}"
echo ""
echo -e "Config files now use the ${GREEN}\"awl\"${NC} namespace instead of ${RED}\"catalyst\"${NC}"
echo ""
echo -e "${YELLOW}Note: Restart Claude Code for changes to take effect${NC}"
