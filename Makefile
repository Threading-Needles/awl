.PHONY: help lint format check clean

# Default target - show help
help:
	@echo "Awl - Development Commands"
	@echo ""
	@echo "Quality Checks:"
	@echo "  make lint    - Run all Trunk linters (shellcheck, markdownlint, etc.)"
	@echo "  make format  - Auto-fix formatting issues with Trunk"
	@echo "  make check   - Run all quality checks"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean   - Clean temporary files and caches"
	@echo ""
	@echo "Frontmatter validation:"
	@echo "  Use the /awl-meta:validate-frontmatter command from inside Claude Code."

# Run Trunk linters
lint:
	@echo "Running Trunk linters..."
	trunk check

# Auto-fix formatting issues
format:
	@echo "Auto-fixing formatting issues..."
	trunk fmt

# Run all quality checks
check: lint
	@echo ""
	@echo "✅ All quality checks passed!"

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -name "*.tmp" -delete
	@find . -name ".DS_Store" -delete
	@echo "✅ Cleaned!"
