# Makefile for AWS Terraform Modules
# Provides convenient commands for common tasks

.PHONY: help init validate fmt lint test security docs clean install-tools

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
NC := \033[0m # No Color

##@ General

help: ## Display this help message
	@echo "$(BLUE)AWS Terraform Modules - Makefile Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(GREEN)<target>$(NC)\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup

install-tools: ## Install required development tools
	@echo "$(BLUE)Installing development tools...$(NC)"
	@command -v terraform >/dev/null 2>&1 || (echo "$(RED)Terraform not found! Install from https://www.terraform.io/downloads$(NC)" && exit 1)
	@echo "$(GREEN)✓ Terraform installed$(NC)"
	@command -v tflint >/dev/null 2>&1 || (echo "$(YELLOW)Installing TFLint...$(NC)" && curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash)
	@echo "$(GREEN)✓ TFLint installed$(NC)"
	@command -v tfsec >/dev/null 2>&1 || (echo "$(YELLOW)Installing tfsec...$(NC)" && brew install tfsec || curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash)
	@echo "$(GREEN)✓ tfsec installed$(NC)"
	@command -v terraform-docs >/dev/null 2>&1 || (echo "$(YELLOW)Installing terraform-docs...$(NC)" && brew install terraform-docs || go install github.com/terraform-docs/terraform-docs@latest)
	@echo "$(GREEN)✓ terraform-docs installed$(NC)"
	@command -v pre-commit >/dev/null 2>&1 || (echo "$(YELLOW)Installing pre-commit...$(NC)" && pip3 install pre-commit)
	@echo "$(GREEN)✓ pre-commit installed$(NC)"
	@pre-commit install
	@echo "$(GREEN)✓ Pre-commit hooks installed$(NC)"
	@echo "$(GREEN)All tools installed successfully!$(NC)"

init: ## Initialize all Terraform modules
	@echo "$(BLUE)Initializing Terraform modules...$(NC)"
	@for dir in modules/*; do \
		if [ -d "$$dir" ]; then \
			echo "$(YELLOW)Initializing $$dir...$(NC)"; \
			(cd $$dir && terraform init -backend=false) || exit 1; \
			echo "$(GREEN)✓ $$dir initialized$(NC)"; \
		fi \
	done
	@echo "$(GREEN)All modules initialized!$(NC)"

##@ Code Quality

validate: ## Validate all Terraform configurations
	@echo "$(BLUE)Validating Terraform configurations...$(NC)"
	@for dir in modules/*; do \
		if [ -d "$$dir" ]; then \
			echo "$(YELLOW)Validating $$dir...$(NC)"; \
			(cd $$dir && terraform init -backend=false >/dev/null 2>&1 && terraform validate) || exit 1; \
			echo "$(GREEN)✓ $$dir validated$(NC)"; \
		fi \
	done
	@echo "$(GREEN)All configurations valid!$(NC)"

fmt: ## Format all Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	@terraform fmt -recursive .
	@echo "$(GREEN)Formatting complete!$(NC)"

fmt-check: ## Check if Terraform files are formatted
	@echo "$(BLUE)Checking Terraform formatting...$(NC)"
	@terraform fmt -check -recursive . || (echo "$(RED)Files need formatting! Run 'make fmt'$(NC)" && exit 1)
	@echo "$(GREEN)All files properly formatted!$(NC)"

lint: ## Lint all Terraform files with TFLint
	@echo "$(BLUE)Linting Terraform files...$(NC)"
	@for dir in modules/*; do \
		if [ -d "$$dir" ]; then \
			echo "$(YELLOW)Linting $$dir...$(NC)"; \
			(cd $$dir && tflint --init && tflint) || exit 1; \
			echo "$(GREEN)✓ $$dir linted$(NC)"; \
		fi \
	done
	@echo "$(GREEN)Linting complete!$(NC)"

##@ Security

security: ## Run security scans with tfsec and checkov
	@echo "$(BLUE)Running security scans...$(NC)"
	@echo "$(YELLOW)Running tfsec...$(NC)"
	@tfsec . --minimum-severity MEDIUM || echo "$(YELLOW)⚠ Security issues found$(NC)"
	@echo "$(YELLOW)Running checkov...$(NC)"
	@checkov -d . --framework terraform --quiet || echo "$(YELLOW)⚠ Security issues found$(NC)"
	@echo "$(GREEN)Security scans complete!$(NC)"

security-tfsec: ## Run tfsec security scan
	@echo "$(BLUE)Running tfsec security scan...$(NC)"
	@tfsec . --minimum-severity MEDIUM

security-checkov: ## Run checkov security scan
	@echo "$(BLUE)Running checkov security scan...$(NC)"
	@checkov -d . --framework terraform

security-trivy: ## Run trivy IaC scan
	@echo "$(BLUE)Running trivy IaC scan...$(NC)"
	@trivy config . || echo "$(YELLOW)⚠ Install trivy: https://github.com/aquasecurity/trivy$(NC)"

##@ Documentation

docs: ## Generate documentation for all modules
	@echo "$(BLUE)Generating documentation...$(NC)"
	@for dir in modules/*; do \
		if [ -d "$$dir" ]; then \
			echo "$(YELLOW)Generating docs for $$dir...$(NC)"; \
			terraform-docs markdown table --output-file README.md --output-mode inject $$dir || exit 1; \
			echo "$(GREEN)✓ $$dir documented$(NC)"; \
		fi \
	done
	@echo "$(GREEN)Documentation generated!$(NC)"

docs-check: ## Check if documentation is up to date
	@echo "$(BLUE)Checking documentation...$(NC)"
	@for dir in modules/*; do \
		if [ -d "$$dir" ]; then \
			terraform-docs markdown table --output-file README.md --output-mode inject --output-check $$dir || \
			(echo "$(RED)$$dir documentation out of date! Run 'make docs'$(NC)" && exit 1); \
		fi \
	done
	@echo "$(GREEN)All documentation up to date!$(NC)"

##@ Testing

test: ## Run all tests
	@echo "$(BLUE)Running tests...$(NC)"
	@$(MAKE) validate
	@$(MAKE) fmt-check
	@$(MAKE) lint
	@$(MAKE) security
	@echo "$(GREEN)All tests passed!$(NC)"

test-go: ## Run Go integration tests
	@echo "$(BLUE)Running Go integration tests...$(NC)"
	@cd test && go test -v -timeout 45m -parallel 1 ./...

test-examples: ## Test all example configurations
	@echo "$(BLUE)Testing example configurations...$(NC)"
	@for dir in examples/*; do \
		if [ -d "$$dir" ]; then \
			echo "$(YELLOW)Testing $$dir...$(NC)"; \
			(cd $$dir && terraform init -backend=false && terraform validate) || exit 1; \
			echo "$(GREEN)✓ $$dir validated$(NC)"; \
		fi \
	done
	@echo "$(GREEN)All examples valid!$(NC)"

##@ Pre-commit

pre-commit-run: ## Run pre-commit hooks on all files
	@echo "$(BLUE)Running pre-commit hooks...$(NC)"
	@pre-commit run --all-files

pre-commit-update: ## Update pre-commit hooks
	@echo "$(BLUE)Updating pre-commit hooks...$(NC)"
	@pre-commit autoupdate

##@ CI/CD

ci: ## Run CI checks (what runs in GitHub Actions)
	@echo "$(BLUE)Running CI checks...$(NC)"
	@$(MAKE) fmt-check
	@$(MAKE) validate
	@$(MAKE) lint
	@$(MAKE) security
	@$(MAKE) docs-check
	@echo "$(GREEN)CI checks passed!$(NC)"

##@ Examples

example-vpc: ## Plan VPC example
	@echo "$(BLUE)Planning VPC example...$(NC)"
	@cd examples/simple-web-app && terraform init && terraform plan

example-eks: ## Plan EKS example
	@echo "$(BLUE)Planning EKS example...$(NC)"
	@cd examples/microservices-platform && terraform init && terraform plan

example-data: ## Plan data pipeline example
	@echo "$(BLUE)Planning data pipeline example...$(NC)"
	@cd examples/data-processing-pipeline && terraform init && terraform plan

##@ Cleanup

clean: ## Clean Terraform files and cache
	@echo "$(BLUE)Cleaning Terraform files...$(NC)"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@find . -type f -name "terraform.tfstate*" -delete 2>/dev/null || true
	@find . -type f -name "*.backup" -delete 2>/dev/null || true
	@echo "$(GREEN)Cleanup complete!$(NC)"

clean-logs: ## Clean log files
	@echo "$(BLUE)Cleaning log files...$(NC)"
	@find . -type f -name "*.log" -delete 2>/dev/null || true
	@echo "$(GREEN)Log files cleaned!$(NC)"

##@ Release

version: ## Display current version
	@echo "$(BLUE)Current version:$(NC)"
	@git describe --tags --abbrev=0 2>/dev/null || echo "No version tags found"

changelog: ## Generate changelog
	@echo "$(BLUE)Generating changelog...$(NC)"
	@git log --pretty=format:"- %s (%h)" $(shell git describe --tags --abbrev=0)..HEAD

release-patch: ## Create patch release (v1.0.X)
	@echo "$(BLUE)Creating patch release...$(NC)"
	@./scripts/release.sh patch

release-minor: ## Create minor release (v1.X.0)
	@echo "$(BLUE)Creating minor release...$(NC)"
	@./scripts/release.sh minor

release-major: ## Create major release (vX.0.0)
	@echo "$(BLUE)Creating major release...$(NC)"
	@./scripts/release.sh major

##@ Utilities

cost-estimate: ## Estimate infrastructure costs
	@echo "$(BLUE)Estimating costs...$(NC)"
	@echo "$(YELLOW)Install infracost: https://www.infracost.io/docs/$(NC)"
	@infracost breakdown --path examples/ 2>/dev/null || echo "$(YELLOW)Infracost not installed$(NC)"

graph: ## Generate dependency graph
	@echo "$(BLUE)Generating dependency graph...$(NC)"
	@cd examples/simple-web-app && terraform init && terraform graph | dot -Tpng > ../../graph.png
	@echo "$(GREEN)Graph saved to graph.png$(NC)"

list-resources: ## List all Terraform resources
	@echo "$(BLUE)Listing all resources...$(NC)"
	@find modules -name "*.tf" -exec grep -h "^resource " {} \; | sort -u

count-resources: ## Count Terraform resources
	@echo "$(BLUE)Counting resources...$(NC)"
	@find modules -name "*.tf" -exec grep -h "^resource " {} \; | wc -l | xargs echo "Total resources:"

##@ Quick Commands

quick-check: ## Quick validation (fmt, validate)
	@$(MAKE) fmt
	@$(MAKE) validate
	@echo "$(GREEN)Quick check passed!$(NC)"

full-check: ## Full check (fmt, validate, lint, security)
	@$(MAKE) test
	@echo "$(GREEN)Full check passed!$(NC)"

---
