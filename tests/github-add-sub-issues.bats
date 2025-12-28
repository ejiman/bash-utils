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

@test "github-add-sub-issues: --help shows usage" {
  run "${BIN_DIR}/github-add-sub-issues" --help
  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "github-add-sub-issues"
  assert_output_contains "parent-issue"
  assert_output_contains "sub-issue"
}

@test "github-add-sub-issues: --version shows version" {
  run "${BIN_DIR}/github-add-sub-issues" --version
  assert_success
  assert_output_contains "version"
}

@test "github-add-sub-issues: fails without arguments" {
  run "${BIN_DIR}/github-add-sub-issues"
  assert_failure
  assert_output_contains "At least two arguments required"
}

@test "github-add-sub-issues: fails with only one argument" {
  run "${BIN_DIR}/github-add-sub-issues" 1
  assert_failure
  assert_output_contains "At least two arguments required"
}

@test "github-add-sub-issues: short option -V works" {
  run "${BIN_DIR}/github-add-sub-issues" -V
  assert_failure
  assert_output_contains "At least two arguments required"
}

@test "github-add-sub-issues: long option --verbose works" {
  run "${BIN_DIR}/github-add-sub-issues" --verbose
  assert_failure
  assert_output_contains "At least two arguments required"
}

@test "github-add-sub-issues: short option -f works" {
  run "${BIN_DIR}/github-add-sub-issues" -f
  assert_failure
  assert_output_contains "At least two arguments required"
}

@test "github-add-sub-issues: long option --force works" {
  run "${BIN_DIR}/github-add-sub-issues" --force
  assert_failure
  assert_output_contains "At least two arguments required"
}

@test "github-add-sub-issues: -R option requires value" {
  run "${BIN_DIR}/github-add-sub-issues" -R
  assert_failure
  assert_output_contains "Option -R requires OWNER/REPO"
}

@test "github-add-sub-issues: --repo option requires value" {
  run "${BIN_DIR}/github-add-sub-issues" --repo
  assert_failure
  assert_output_contains "Option --repo requires OWNER/REPO"
}

@test "github-add-sub-issues: unknown option is rejected" {
  run "${BIN_DIR}/github-add-sub-issues" --unknown-option
  assert_failure
  assert_output_contains "Unknown option"
}
