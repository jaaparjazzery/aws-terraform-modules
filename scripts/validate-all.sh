#!/bin/bash
# scripts/validate-all.sh
# Comprehensive validation script

set -e

echo "🔍 Running comprehensive validation..."
echo ""

# Track failures
failures=0

run_check() {
    local name=$1
    local command=$2
    
    echo "▶ Running: $name"
    if eval $command > /dev/null 2>&1; then
        echo "  ✓ $name passed"
    else
        echo "  ✗ $name failed"
        failures=$((failures + 1))
    fi
    echo ""
}

# Run all checks
run_check "Terraform Format" "make fmt-check"
run_check "Terraform Validate" "make validate"
run_check "TFLint" "make lint"
run_check "tfsec Security Scan" "make security-tfsec"
run_check "Checkov Security Scan" "make security-checkov"
run_check "Documentation Check" "make docs-check"
run_check "Example Validation" "make test-examples"

# Summary
echo "════════════════════════════════════"
if [ $failures -eq 0 ]; then
    echo "✓ All checks passed! 🎉"
    exit 0
else
    echo "✗ $failures check(s) failed"
    exit 1
fi
