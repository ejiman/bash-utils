# bash-utils

[![CI](https://github.com/ejiman/bash-utils/actions/workflows/ci-main.yml/badge.svg)](https://github.com/ejiman/bash-utils/actions/workflows/ci-main.yml)
[![Release](https://img.shields.io/github/v/release/ejiman/bash-utils)](https://github.com/ejiman/bash-utils/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash Version](https://img.shields.io/badge/bash-%3E%3D4.0-blue.svg)](https://www.gnu.org/software/bash/)

A collection of practical Bash utilities and a framework for building production-quality CLI tools.
Designed primarily for Linux, with macOS compatibility in mind.

## Features

- **Production-ready CLI framework**: Not just snippets, but actual usable CLI tools
- **Unified interface**: All tools support `--help` and `--version`
- **Shared libraries**: Reusable logging, OS detection, argument parsing, and more
- **Linux-first, macOS-compatible**: Works on both platforms with OS-specific handling
- **Zero external dependencies**: Uses standard Bash features (with optional GNU tools on macOS)
- **Comprehensive testing**: Automated testing with Bats (Bash Automated Testing System)

## Requirements

- **Bash 4.0 or higher** (some scripts use associative arrays)
  - Linux: Usually pre-installed
  - macOS: Install via Homebrew: `brew install bash` (default is 3.2)

### Optional Dependencies (macOS only)

Some tools may require GNU versions of common utilities:

```bash
# macOS only
brew install gnu-sed    # for gsed
brew install coreutils  # for gdate and other GNU utilities
```

## Project Structure

```
bash-utils/
├── bin/                # User-facing CLI tools (executable scripts)
│   ├── color-diff
│   ├── generate-release-notes
│   ├── github-create-issues
│   └── slack-post
├── lib/                # Shared libraries
│   ├── bootstrap.sh    # Load all libraries + OS detection
│   ├── cli.sh          # Basic help/version display
│   ├── argparse.sh     # Argument parsing framework
│   ├── log.sh          # Logging functions (log_info, log_warn, log_error, die)
│   ├── os.sh           # OS-dependent command aliases (sed/date/etc)
│   └── utils.sh        # Utility functions
├── docs/               # Tool documentation
│   ├── color-diff.md
│   ├── generate-release-notes.md
│   ├── github-create-issues.md
│   └── slack-post.md
├── tests/              # Bats tests
│   ├── test_helper.bash
│   ├── color-diff.bats
│   ├── generate-release-notes.bats
│   ├── github-create-issues.bats
│   ├── install.bats
│   ├── lib_utils.bats
│   ├── package.bats
│   ├── release.bats
│   ├── slack-post.bats
│   └── README.md       # Testing guide
├── .github/
│   └── workflows/      # GitHub Actions
│       ├── ci-main.yml   # CI for main branch (tests & linting)
│       ├── ci-others.yml # CI for other branches (tests & linting)
│       └── release.yml   # Release automation
├── install.sh          # Installation script
├── package.sh          # Packaging script (creates tarball)
├── release.sh          # Release automation script (version management & tagging)
├── Makefile            # Development task runner
├── .shellcheckrc       # shellcheck configuration
└── README.md           # This file
```

## Installation

Clone the repository and run the installation script:

```bash
git clone https://github.com/yourusername/bash-utils.git
cd bash-utils
./install.sh
```

This will copy all scripts from `bin/` to `~/.local/bin/`. Make sure `~/.local/bin` is in your `PATH`:

```bash
# Add to your ~/.bashrc or ~/.zshrc if not already present
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

All tools support standard `--help` and `--version` options:

```bash
# Show help for any tool
color-diff --help
generate-release-notes --help
github-create-issues --help
slack-post --help

# Show version
color-diff --version
generate-release-notes --version
github-create-issues --version
slack-post --version
```

### Available Tools

For detailed documentation, examples, and advanced usage, see the individual tool documentation:

#### [color-diff](docs/color-diff.md)

Show colorized diff between two files with optional JSON key sorting.

```bash
# Compare two files
color-diff file1.txt file2.txt

# Compare JSON files with key sorting (requires jq)
color-diff --json config1.json config2.json
```

**[→ Full documentation](docs/color-diff.md)**

#### [generate-release-notes](docs/generate-release-notes.md)

Generate release notes from git commits using conventional commit format.

```bash
# Generate release notes from latest tag
generate-release-notes

# Specify version range
generate-release-notes --from v1.0.0 --to v2.0.0
```

**[→ Full documentation](docs/generate-release-notes.md)**

#### [slack-post](docs/slack-post.md)

Post messages to Slack via Incoming Webhook or Web API.

```bash
# Using Incoming Webhook
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00/B00/XXX"
slack-post "Hello from bash script!"

# Using Bot Token
slack-post --token "xoxb-your-token" --channel "C12345678" "Hello via API!"
```

**[→ Full documentation](docs/slack-post.md)**

#### [github-create-issues](docs/github-create-issues.md)

Create multiple GitHub issues from JSON input with support for labels, assignees, milestones, and templates.

```bash
# Create issues from JSON file
github-create-issues -i issues.json

# With default labels and dry-run
github-create-issues -i issues.json -l bug,priority-high --dry-run

# From stdin
echo '[{"title":"Bug fix","body":"Description"}]' | github-create-issues
```

**[→ Full documentation](docs/github-create-issues.md)**

## Development

### Creating a New Tool

1. **Create a new script in `bin/`**:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/bootstrap.sh"

CLI_NAME="your-tool"
CLI_VERSION="1.0.0"
CLI_DESCRIPTION="Brief description of what this tool does"
CLI_USAGE="your-tool [options] <args>"

# ========= Argument definitions =========
arg_flag           VERBOSE -V --verbose "Enable verbose output"
arg_value_required INPUT   -i --input   "Input file" "FILE"
arg_value          OUTPUT  -o --output  "Output file (default: stdout)" "FILE"

# ========= Parse arguments =========
parse_args "$@"

# ========= Main function =========
main() {
  [[ "${VERBOSE:-}" == true ]] && log_info "Verbose mode enabled"
  log_info "Processing: $INPUT"

  # Add your actual processing logic here
}

main
```

2. **Make it executable**:

```bash
chmod +x bin/your-tool
```

3. **Test locally**:

```bash
./bin/your-tool --help
./bin/your-tool --version
```

4. **Install and test**:

```bash
./install.sh
your-tool --help
```

### Shared Libraries

All tools automatically have access to these libraries via `bootstrap.sh`:

- **Logging**: `log_info`, `log_warn`, `log_error`, `die`
- **Utilities**: `require_cmd`, `is_interactive`
- **OS Detection**: `$OS` variable (`linux` or `macos`)
- **OS-specific commands**: `$SED`, `$DATE` (automatically use GNU versions on macOS)
- **Argument parsing**: `arg_flag`, `arg_value`, `arg_value_required`, `parse_args`

### Development Tasks (Makefile)

The project includes a `Makefile` for common development tasks:

```bash
# Show all available tasks
make help

# Format code with shfmt
make fmt

# Check formatting (without modifying files)
make fmt-check

# Run shellcheck linting
make lint

# Run Bats tests
make test

# Run all checks (formatting, linting, tests) - recommended for CI
make all

# Install scripts
make install

# Clean test artifacts
make clean
```

**Recommended workflow:**

1. Write code
2. `make fmt` to format
3. `make all` to run all checks and tests
4. `make install` to install locally

### Code Quality

Run shellcheck on all scripts:

```bash
# Using Makefile (recommended)
make lint

# Direct execution
shellcheck bin/*
shellcheck lib/*
shellcheck install.sh
```

The project includes a `.shellcheckrc` configuration for consistent linting.

## Testing

This project uses **Bats (Bash Automated Testing System)** for automated testing.

### Install Bats

**Linux:**

```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

**macOS:**

```bash
brew install bats-core
```

### Run Tests

```bash
# Run all tests
bats tests/

# Run specific test file
bats tests/slack-post.bats
bats tests/generate-release-notes.bats

# Run with TAP output
bats --tap tests/
```

### Writing Tests

Create a new test file `tests/your-tool.bats`:

```bash
#!/usr/bin/env bats

# ========= Load test helper =========
load test_helper

# ========= Setup/Teardown =========
setup() {
  setup_temp_dir
}

teardown() {
  teardown_temp_dir
}

# ========= Tests =========

@test "your-tool: --help shows usage" {
  run "${BIN_DIR}/your-tool" --help
  assert_success
  assert_output_contains "Usage:"
}

@test "your-tool: --version shows version" {
  run "${BIN_DIR}/your-tool" --version
  assert_success
  assert_output_contains "version"
}
```

See `tests/README.md` for detailed testing guidelines.

## Coding Standards

- **Error handling**: Use `set -euo pipefail` at the top of every script
- **Logging**: Use `log_info`, `log_warn`, `log_error`, and `die` for all output
- **OS compatibility**: Use `$OS`, `$SED`, `$DATE` for OS-specific behavior
- **Argument parsing**: Use the `argparse.sh` framework for consistent CLI interface
- **Language**: All comments, log messages, and error messages should be in English
- **Naming conventions**:
  - Scripts: kebab-case (`my-tool`, `check-status`)
  - Functions: snake_case (`process_file`, `validate_input`)
  - Variables: UPPER_SNAKE_CASE (`INPUT_FILE`, `VERBOSE`)
  - Local variables: lower_snake_case with `local` declaration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run shellcheck and tests
5. Submit a pull request

## License

MIT License - feel free to use and modify as needed.

## Release and Packaging

### Creating a Release

Use the automated release script:

```bash
./release.sh        # Interactive menu to choose version type
./release.sh major  # Major version bump (1.0.0 → 2.0.0)
./release.sh minor  # Minor version bump (1.0.0 → 1.1.0)
./release.sh patch  # Patch version bump (1.0.0 → 1.0.1)
```

The script will:

- Detect current version
- Calculate next version
- Generate release notes automatically
- Create and push Git tag

### Creating a Package

Create a tarball distribution:

```bash
./package.sh
```

This creates a `bash-utils-{version}.tar.gz` file with all necessary files.

## CI/CD

The project includes GitHub Actions workflows:

- **CI Workflow for main** (`.github/workflows/ci-main.yml`): Runs on pull requests and pushes to main branch

  - Tests on Linux and macOS
  - Runs shellcheck and Bats tests
  - Checks code formatting

- **CI Workflow for others** (`.github/workflows/ci-others.yml`): Runs on pull requests and pushes to branches other than main

  - Tests on Linux and macOS
  - Runs shellcheck and Bats tests
  - Checks code formatting

- **Release Workflow** (`.github/workflows/release.yml`): Runs on Git tags
  - Generates release notes
  - Creates tarball
  - Attaches artifacts to GitHub release

## Future Enhancements

- ✅ ~~CI/CD pipeline with GitHub Actions~~ → Completed
- More utility functions (file operations, JSON processing, etc.)
- Subcommand support framework
- Performance testing
