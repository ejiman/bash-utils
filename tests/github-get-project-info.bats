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

@test "github-get-project-info: --help shows usage" {
  run "${BIN_DIR}/github-get-project-info" --help
  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "github-get-project-info"
  assert_output_contains "issue-number"
}

@test "github-get-project-info: --version shows version" {
  run "${BIN_DIR}/github-get-project-info" --version
  assert_success
  assert_output_contains "version"
}

@test "github-get-project-info: fails without issue number argument" {
  run "${BIN_DIR}/github-get-project-info"
  assert_failure
  assert_output_contains "Expected exactly 1 argument"
}

@test "github-get-project-info: fails with non-numeric issue number" {
  run "${BIN_DIR}/github-get-project-info" "abc"
  assert_failure
  assert_output_contains "must be a positive integer"
}

@test "github-get-project-info: fails with negative issue number" {
  run "${BIN_DIR}/github-get-project-info" "-1"
  assert_failure
  assert_output_contains "Unknown option"
}

@test "github-get-project-info: fails with zero issue number" {
  run "${BIN_DIR}/github-get-project-info" "0"
  # Will fail at API call or repo detection, but should accept the number
  assert_failure
  # Should not show "must be a positive integer" for 0
  # (0 is technically valid as it matches the regex, though GitHub uses 1+)
}

@test "github-get-project-info: accepts valid issue number" {
  run "${BIN_DIR}/github-get-project-info" "123"
  # Will fail at repo detection or API call, but number should be accepted
  assert_failure
  # Should not show "must be a positive integer" error
  if [[ "$output" == *"must be a positive integer"* ]]; then
    echo "Valid issue number was rejected"
    return 1
  fi
}

@test "github-get-project-info: short option -o works" {
  run "${BIN_DIR}/github-get-project-info" -o "test-owner" "123"
  # Will fail at repo name or API call
  assert_failure
  # If it accepted -o, it won't show "Unknown option"
  if [[ "$output" == *"Unknown option"* ]]; then
    echo "Option -o was not recognized"
    return 1
  fi
}

@test "github-get-project-info: short option -r works" {
  run "${BIN_DIR}/github-get-project-info" -r "test-repo" "123"
  # Will fail at owner or API call
  assert_failure
  # If it accepted -r, it won't show "Unknown option"
  if [[ "$output" == *"Unknown option"* ]]; then
    echo "Option -r was not recognized"
    return 1
  fi
}

@test "github-get-project-info: short option -f works" {
  run "${BIN_DIR}/github-get-project-info" -o "owner" -r "repo" -f "json" "123"
  # Will fail at API call, but should accept the format option
  assert_failure
  # Should not show format validation error
  if [[ "$output" == *"Invalid format"* ]]; then
    echo "Option -f was not recognized or value was rejected"
    return 1
  fi
}

@test "github-get-project-info: short option -V works" {
  run "${BIN_DIR}/github-get-project-info" -o "owner" -r "repo" -V "123"
  # Will fail at API call, but should accept verbose option
  assert_failure
  # If it accepted -V, it won't show "Unknown option"
  if [[ "$output" == *"Unknown option"* ]]; then
    echo "Option -V was not recognized"
    return 1
  fi
}

@test "github-get-project-info: validates format option" {
  run "${BIN_DIR}/github-get-project-info" -o "owner" -r "repo" -f "invalid" "123"
  assert_failure
  assert_output_contains "Invalid format"
}

@test "github-get-project-info: accepts text format" {
  run "${BIN_DIR}/github-get-project-info" -o "owner" -r "repo" -f "text" "123"
  # Will fail at API call, but format should be accepted
  assert_failure
  # Should not show format validation error
  if [[ "$output" == *"Invalid format"* ]]; then
    echo "Format 'text' was rejected"
    return 1
  fi
}

@test "github-get-project-info: accepts json format" {
  run "${BIN_DIR}/github-get-project-info" -o "owner" -r "repo" -f "json" "123"
  # Will fail at API call, but format should be accepted
  assert_failure
  # Should not show format validation error
  if [[ "$output" == *"Invalid format"* ]]; then
    echo "Format 'json' was rejected"
    return 1
  fi
}

@test "github-get-project-info: rejects unknown options" {
  run "${BIN_DIR}/github-get-project-info" --unknown-option "123"
  assert_failure
  assert_output_contains "Unknown option"
}

@test "github-get-project-info: requires both owner and repo when not in git repo" {
  # Create a temp directory that is not a git repo
  local non_git_dir="${TEST_TEMP_DIR}/non-git"
  mkdir -p "$non_git_dir"
  cd "$non_git_dir"

  run "${BIN_DIR}/github-get-project-info" -o "owner" "123"
  assert_failure
  assert_output_contains "Failed to auto-detect repository"
}

@test "github-get-project-info: long options work" {
  run "${BIN_DIR}/github-get-project-info" --owner "test" --repo "test" --format "json" --verbose "123"
  # Will fail at API call, but all options should be accepted
  assert_failure
  # Should not show any option parsing errors
  if [[ "$output" == *"Unknown option"* ]] || [[ "$output" == *"Invalid format"* ]]; then
    echo "Long options were not recognized correctly"
    return 1
  fi
}

@test "github-get-project-info: fails with too many positional arguments" {
  run "${BIN_DIR}/github-get-project-info" "123" "456"
  assert_failure
  assert_output_contains "Expected exactly 1 argument"
}
