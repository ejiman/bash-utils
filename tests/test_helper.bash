#!/usr/bin/env bash

# ========= Test helper functions =========

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJECT_ROOT

# Paths
BIN_DIR="${PROJECT_ROOT}/bin"
LIB_DIR="${PROJECT_ROOT}/lib"

export BIN_DIR
export LIB_DIR

# ========= Helper functions =========

# Load a library for testing
load_lib() {
  local lib_name="$1"
  # shellcheck source=/dev/null
  source "${LIB_DIR}/${lib_name}"
}

# Create a temporary directory for the test
setup_temp_dir() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_TEMP_DIR
}

# Clean up temporary directory
teardown_temp_dir() {
  if [[ -n "${TEST_TEMP_DIR:-}" && -d "${TEST_TEMP_DIR}" ]]; then
    rm -rf "${TEST_TEMP_DIR}"
  fi
}

# Create a temporary file with content
create_temp_file() {
  local filename="$1"
  local content="${2:-}"
  local filepath="${TEST_TEMP_DIR}/${filename}"

  echo "${content}" > "${filepath}"
  echo "${filepath}"
}

# Assert command succeeds
assert_success() {
  if [[ "$status" -ne 0 ]]; then
    echo "Command failed with status: $status"
    echo "Output: $output"
    return 1
  fi
}

# Assert command fails
assert_failure() {
  if [[ "$status" -eq 0 ]]; then
    echo "Command succeeded but was expected to fail"
    echo "Output: $output"
    return 1
  fi
}

# Assert output contains string
assert_output_contains() {
  local expected="$1"
  if [[ "$output" != *"$expected"* ]]; then
    echo "Expected output to contain: $expected"
    echo "Actual output: $output"
    return 1
  fi
}

# Assert output equals string
assert_output_equals() {
  local expected="$1"
  if [[ "$output" != "$expected" ]]; then
    echo "Expected output: $expected"
    echo "Actual output: $output"
    return 1
  fi
}
