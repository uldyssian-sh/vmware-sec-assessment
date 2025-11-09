# VMware Security Assessment Makefile
# Provides common development and deployment tasks

.PHONY: help install test lint clean build docker release docs

# Default target
help: ## Show this help message
	@echo "VMware Security Assessment - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Installation and setup
install: ## Install dependencies and setup development environment
	@echo "Installing PowerShell dependencies..."
	@pwsh -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted"
	@pwsh -Command "Install-Module -Name VMware.PowerCLI -Force -AllowClobber"
	@pwsh -Command "Install-Module -Name Pester -Force -AllowClobber"
	@pwsh -Command "Install-Module -Name PSScriptAnalyzer -Force -AllowClobber"
	@echo "Installing Python dependencies..."
	@pip install -r requirements.txt
	@echo "Setup completed successfully!"

# Testing
test: ## Run all tests
	@echo "Running PowerShell module tests..."
	@pwsh -Command "Invoke-Pester -Path tests/ -OutputFormat NUnitXml -OutputFile test-results.xml"

test-unit: ## Run unit tests only
	@echo "Running unit tests..."
	@pwsh -Command "Invoke-Pester -Path tests/unit/ -OutputFormat NUnitXml -OutputFile unit-test-results.xml"

test-integration: ## Run integration tests (requires TEST_VCENTER environment variable)
	@echo "Running integration tests..."
	@pwsh -Command "Invoke-Pester -Path tests/integration/ -OutputFormat NUnitXml -OutputFile integration-test-results.xml"

# Code quality
lint: ## Run code linting and analysis
	@echo "Running PSScriptAnalyzer..."
	@pwsh -Command "Invoke-ScriptAnalyzer -Path . -Recurse -ReportSummary"
	@echo "Running Python linting..."
	@flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics || true
	@flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics || true

format: ## Format PowerShell code
	@echo "Formatting PowerShell code..."
	@pwsh -Command "Get-ChildItem -Path . -Filter '*.ps1' -Recurse | ForEach-Object { Invoke-Formatter -ScriptDefinition (Get-Content $_.FullName -Raw) | Set-Content $_.FullName }"

# Build and packaging
build: ## Build the module for distribution
	@echo "Building VMware Security Assessment module..."
	@pwsh -Command "Test-ModuleManifest -Path VMwareSecAssessment.psd1"
	@mkdir -p build/
	@cp -r src/ build/
	@cp VMwareSecAssessment.psd1 build/
	@cp VMwareSecAssessment.psm1 build/
	@cp README.md build/
	@cp LICENSE build/
	@echo "Build completed in build/ directory"

archive: build ## Create distribution archive
	@echo "Creating distribution archive..."
	@mkdir -p dist/
	@tar -czf dist/vmware-security-assessment-$(shell date +%Y%m%d).tar.gz -C build/ .
	@echo "Archive created in dist/ directory"



# Documentation
docs: ## Generate documentation
	@echo "Generating documentation..."
	@mkdir -p docs/generated/
	@pwsh -Command "Get-Help Start-VMwareSecurityAssessment -Full | Out-File docs/generated/Start-VMwareSecurityAssessment.txt"
	@pwsh -Command "Get-Command -Module VMwareSecAssessment | Get-Help | Out-File docs/generated/all-functions.txt"
	@echo "Documentation generated in docs/generated/"

# Cleanup
clean: ## Clean build artifacts and temporary files
	@echo "Cleaning up..."
	@rm -rf build/
	@rm -rf dist/
	@rm -rf docs/generated/
	@rm -f test-results.xml
	@rm -f unit-test-results.xml
	@rm -f integration-test-results.xml
	@rm -f *.log

	@echo "Cleanup completed"

# Development helpers
dev-setup: install ## Setup development environment
	@echo "Setting up development environment..."
	@git config --local core.autocrlf false
	@git config --local core.eol lf
	@echo "Development environment ready!"

validate: lint test ## Run validation (lint + test)
	@echo "Validation completed successfully!"

# Release management
release-check: ## Check if ready for release
	@echo "Checking release readiness..."
	@pwsh -Command "Test-ModuleManifest -Path VMwareSecAssessment.psd1"
	@echo "Checking for required files..."
	@test -f README.md || (echo "README.md missing" && exit 1)
	@test -f LICENSE || (echo "LICENSE missing" && exit 1)
	@test -f CHANGELOG.md || (echo "CHANGELOG.md missing" && exit 1)
	@echo "Release check passed!"

# CI/CD helpers
ci-install: ## Install dependencies for CI environment
	@echo "Installing CI dependencies..."
	@pip install --upgrade pip
	@pip install -r requirements.txt
	@pwsh -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted"
	@pwsh -Command "Install-Module -Name VMware.PowerCLI -Force -AllowClobber -Scope CurrentUser"
	@pwsh -Command "Install-Module -Name Pester -Force -AllowClobber -Scope CurrentUser"
	@pwsh -Command "Install-Module -Name PSScriptAnalyzer -Force -AllowClobber -Scope CurrentUser"

ci-test: ## Run tests in CI environment
	@echo "Running CI tests..."
	@pwsh -Command "Invoke-Pester -Path tests/ -OutputFormat NUnitXml -OutputFile test-results.xml -CI"

# Security
security-scan: ## Run security scans
	@echo "Running security scans..."
	@docker run --rm -v $(PWD):/app aquasec/trivy fs /app || true
	@pwsh -Command "Invoke-ScriptAnalyzer -Path . -Recurse -Settings PSGallery" || true

# Version management
version: ## Show current version
	@pwsh -Command "(Test-ModuleManifest -Path VMwareSecAssessment.psd1).Version"

bump-version: ## Bump version (requires VERSION environment variable)
	@echo "Bumping version to $(VERSION)..."
	@pwsh -Command "$$manifest = Import-PowerShellDataFile -Path VMwareSecAssessment.psd1; $$manifest.ModuleVersion = '$(VERSION)'; $$manifest | Export-PowerShellDataFile -Path VMwareSecAssessment.psd1"

# All-in-one commands
all: clean install lint test build ## Run complete build pipeline
	@echo "Complete build pipeline finished successfully!"

validate-module: ## Validate PowerShell module
	@echo "Validating PowerShell module..."
	@pwsh -Command "Test-ModuleManifest -Path VMwareSecAssessment.psd1"
	@echo "Module validation completed!"

quick-test: lint test-unit ## Quick validation for development
	@echo "Quick test completed!"

# Environment info
info: ## Show environment information
	@echo "Environment Information:"
	@echo "======================="
	@echo "PowerShell Version: $$(pwsh -Command '$$PSVersionTable.PSVersion')"
	@echo "Python Version: $$(python --version 2>&1)"
	@echo "Git Version: $$(git --version)"
	@echo "Operating System: $$(uname -s 2>/dev/null || echo 'Windows')"
	@echo "Architecture: $$(uname -m 2>/dev/null || echo 'Unknown')"# Updated 20251109_123821
# Updated Sun Nov  9 12:52:29 CET 2025
