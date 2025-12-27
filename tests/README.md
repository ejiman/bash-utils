# Tests

This directory contains automated tests for bash-utils using [Bats (Bash Automated Testing System)](https://github.com/bats-core/bats-core).

---

## Installation

### Linux

```bash
# Install bats-core
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

Or using package managers:

```bash
# Debian/Ubuntu
sudo apt-get install bats

# Arch Linux
sudo pacman -S bats
```

### macOS

```bash
brew install bats-core
```

---

## Running Tests

### Run all tests

```bash
bats tests/
```

### Run a specific test file

```bash
bats tests/example-tool.bats
```

### Run with verbose output

```bash
bats --tap tests/
```

### Run a specific test

```bash
bats -f "example-tool: --help shows usage" tests/example-tool.bats
```

---

## Test Structure

```
tests/
├── README.md           # This file
├── test_helper.bash    # Common test utilities and assertions
├── example-tool.bats   # Tests for bin/example-tool
└── lib_utils.bats      # Tests for lib/ functions
```

---

## Writing Tests

### Basic Test Template

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

@test "your-tool: description of test" {
  run "${BIN_DIR}/your-tool" --arg value
  assert_success
  assert_output_contains "expected output"
}
```

### Available Assertions

The `test_helper.bash` provides the following assertion helpers:

- `assert_success` - Assert command succeeded (exit status 0)
- `assert_failure` - Assert command failed (non-zero exit status)
- `assert_output_contains "text"` - Assert output contains the text
- `assert_output_equals "text"` - Assert output exactly matches the text

### Available Helper Functions

- `setup_temp_dir` - Create a temporary directory for the test (`$TEST_TEMP_DIR`)
- `teardown_temp_dir` - Clean up the temporary directory
- `create_temp_file "name" "content"` - Create a temporary file with content
- `load_lib "library.sh"` - Load a library from `lib/` for testing

### Environment Variables

- `$PROJECT_ROOT` - Path to the project root
- `$BIN_DIR` - Path to the bin/ directory
- `$LIB_DIR` - Path to the lib/ directory
- `$TEST_TEMP_DIR` - Temporary directory for the current test (created by `setup_temp_dir`)

---

## Testing Guidelines

### Test Organization

- One test file per CLI tool (e.g., `your-tool.bats` for `bin/your-tool`)
- Library function tests go in `lib_*.bats` files
- Group related tests using descriptive prefixes

### Test Naming Convention

Use the format: `"tool-name: description of what is being tested"`

Examples:
- `"example-tool: --help shows usage"`
- `"example-tool: fails without required config"`
- `"log_info: outputs info message"`

### What to Test

For CLI tools:
- `--help` and `--version` options work correctly
- Required arguments are validated
- Optional arguments are handled properly
- Error messages are appropriate
- Both long (`--option`) and short (`-o`) flags work
- Unknown options are rejected
- Positional arguments are processed correctly

For library functions:
- Functions succeed with valid input
- Functions fail appropriately with invalid input
- Error messages are clear
- Edge cases are handled

### Test Isolation

- Always use `setup_temp_dir` for file operations
- Clean up in `teardown` to avoid side effects
- Don't depend on test execution order
- Don't modify global state unless necessary

---

## Continuous Integration

Tests should be run as part of CI/CD pipeline. Example GitHub Actions workflow:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install bats
        run: |
          git clone https://github.com/bats-core/bats-core.git
          cd bats-core
          sudo ./install.sh /usr/local
      - name: Run tests
        run: bats tests/
      - name: Run shellcheck
        run: shellcheck bin/* lib/* install.sh
```

---

## Troubleshooting

### Tests fail with "command not found"

Make sure scripts in `bin/` have execute permissions:

```bash
chmod +x bin/*
```

### Tests fail on macOS

Some tests may require GNU tools. Install them via Homebrew:

```bash
brew install coreutils gnu-sed
```

### Temporary files not cleaned up

Make sure you're calling `teardown_temp_dir` in the `teardown()` function.

---

## Additional Resources

- [Bats documentation](https://bats-core.readthedocs.io/)
- [Bats tutorial](https://github.com/bats-core/bats-core#tutorial)
- [Writing robust Bash tests](https://github.com/bats-core/bats-core/wiki/Writing-Bats-Tests)
