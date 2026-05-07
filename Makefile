# Claude Code Security Kit — common tasks
# Usage: make <target>

.PHONY: help install update health audit lint test clean

help: ## Show this help
	@echo "Claude Code Security Kit — Make targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install the kit (Claude Code skill, commands, hooks)
	@bash install.sh

update: ## Pull latest from GitHub and re-install
	@bash update.sh

health: ## Run health check
	@bash scripts/health-check.sh

health-prod: ## Run health check including production sites
	@bash scripts/health-check.sh --check-prod

audit: ## Audit all projects in ecosystem
	@bash scripts/audit-projects.sh

audit-quick: ## Quick audit (skip gitleaks)
	@bash scripts/audit-projects.sh --quick

lint: ## Run shellcheck on all .sh files
	@find . -name '*.sh' -not -path './node_modules/*' -not -path './.git/*' -exec shellcheck {} \;

lint-md: ## Run markdownlint on all .md files
	@npx markdownlint-cli2 '**/*.md'

test: ## Run all tests (TBD)
	@echo "Tests TBD — see CONTRIBUTING.md to add"

clean: ## Remove generated files (reports, cache)
	@rm -rf reports/ .security-cache/ /tmp/leaks-*.json
	@echo "✅ Cleaned"
