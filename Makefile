.PHONY: help fmt fmt-check lint test all install clean

# Default target
help:
	@echo "bash-utils - Development Task Runner"
	@echo ""
	@echo "Available targets:"
	@echo "  make help       - Show this help message"
	@echo "  make fmt        - Format all shell scripts with shfmt"
	@echo "  make fmt-check  - Check formatting without modifying files"
	@echo "  make lint       - Run shellcheck on all scripts"
	@echo "  make test       - Run bats tests"
	@echo "  make all        - Run fmt-check, lint, and test (recommended for CI)"
	@echo "  make install    - Install scripts to ~/.local/bin"
	@echo "  make clean      - Clean test artifacts"
	@echo ""
	@echo "Requirements:"
	@echo "  - shfmt:      https://github.com/mvdan/sh"
	@echo "  - shellcheck: https://github.com/koalaman/shellcheck"
	@echo "  - bats:       https://github.com/bats-core/bats-core"

# Format all shell scripts
fmt:
	@echo "==> Formatting shell scripts with shfmt..."
	shfmt -i 2 -bn -ci -sr -w bin/ lib/ *.sh tests/*.bash

# Check formatting without modifying files
fmt-check:
	@echo "==> Checking shell script formatting..."
	shfmt -i 2 -bn -ci -sr -d bin/ lib/ *.sh tests/*.bash

# Run shellcheck on all scripts
lint:
	@echo "==> Running shellcheck..."
	shellcheck bin/* lib/* *.sh

# Run bats tests
test:
	@echo "==> Running bats tests..."
	bats tests/

# Run all checks (for CI/pre-commit)
all: fmt-check lint test
	@echo "==> All checks passed!"

# Install scripts
install:
	@echo "==> Installing scripts..."
	./install.sh

# Clean test artifacts
clean:
	@echo "==> Cleaning test artifacts..."
	rm -rf tests/temp_*
	rm -f tests/*.log
