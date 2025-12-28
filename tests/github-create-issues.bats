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

@test "github-create-issues: --help shows usage" {
  run "${BIN_DIR}/github-create-issues" --help
  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "github-create-issues"
  assert_output_contains "Input Format (JSON):"
}

@test "github-create-issues: --version shows version" {
  run "${BIN_DIR}/github-create-issues" --version
  assert_success
  assert_output_contains "version"
}

@test "github-create-issues: fails with invalid JSON" {
  run bash -c "echo 'not valid json' | '${BIN_DIR}/github-create-issues'"
  assert_failure
  assert_output_contains "Invalid JSON input"
}

@test "github-create-issues: fails when JSON has no issues" {
  run bash -c "echo '[]' | '${BIN_DIR}/github-create-issues'"
  assert_failure
  assert_output_contains "No issues found in JSON input"
}

@test "github-create-issues: fails when issue is missing title" {
  run bash -c "echo '[{\"body\":\"No title\"}]' | '${BIN_DIR}/github-create-issues' --dry-run"
  assert_failure
  assert_output_contains "missing required field: title"
}

@test "github-create-issues: accepts single issue object" {
  run bash -c "echo '{\"title\":\"Test issue\"}' | '${BIN_DIR}/github-create-issues' --dry-run"
  assert_success
  assert_output_contains "Found 1 issue(s) to create"
  assert_output_contains "Would create issue"
  assert_output_contains "Title: Test issue"
}

@test "github-create-issues: accepts array of issues" {
  run bash -c "echo '[{\"title\":\"Issue 1\"},{\"title\":\"Issue 2\"}]' | '${BIN_DIR}/github-create-issues' --dry-run"
  assert_success
  assert_output_contains "Found 2 issue(s) to create"
  assert_output_contains "Title: Issue 1"
  assert_output_contains "Title: Issue 2"
}

@test "github-create-issues: dry-run shows issue details" {
  run bash -c "echo '{\"title\":\"Test\",\"body\":\"Description\",\"labels\":[\"bug\",\"priority\"]}' | '${BIN_DIR}/github-create-issues' --dry-run"
  assert_success
  assert_output_contains "Title: Test"
  assert_output_contains "Body: Description"
  assert_output_contains "Labels: bug,priority"
  assert_output_contains "Dry run completed. No issues were created."
}

@test "github-create-issues: reads from file with -i option" {
  local test_file="${TEST_TEMP_DIR}/issues.json"
  echo '[{"title":"From file"}]' > "$test_file"

  run "${BIN_DIR}/github-create-issues" -i "$test_file" --dry-run
  assert_success
  assert_output_contains "Title: From file"
}

@test "github-create-issues: fails when input file does not exist" {
  run "${BIN_DIR}/github-create-issues" -i /nonexistent/file.json
  assert_failure
  assert_output_contains "Input file not found"
}

@test "github-create-issues: short option -i works" {
  local test_file="${TEST_TEMP_DIR}/test.json"
  echo '{"title":"Test"}' > "$test_file"

  run "${BIN_DIR}/github-create-issues" -i "$test_file" --dry-run
  assert_success
  assert_output_contains "Title: Test"
}

@test "github-create-issues: long option --input works" {
  local test_file="${TEST_TEMP_DIR}/test.json"
  echo '{"title":"Test"}' > "$test_file"

  run "${BIN_DIR}/github-create-issues" --input "$test_file" --dry-run
  assert_success
  assert_output_contains "Title: Test"
}

@test "github-create-issues: applies default labels" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' -l bug,enhancement --dry-run"
  assert_success
  assert_output_contains "Labels: bug,enhancement"
}

@test "github-create-issues: merges default and per-issue labels" {
  run bash -c "echo '{\"title\":\"Test\",\"labels\":[\"urgent\"]}' | '${BIN_DIR}/github-create-issues' -l bug --dry-run"
  assert_success
  assert_output_contains "Labels: bug,urgent"
}

@test "github-create-issues: applies default assignees" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' -a user1,user2 --dry-run"
  assert_success
  assert_output_contains "Assignees: user1,user2"
}

@test "github-create-issues: merges default and per-issue assignees" {
  run bash -c "echo '{\"title\":\"Test\",\"assignees\":[\"user3\"]}' | '${BIN_DIR}/github-create-issues' -a user1 --dry-run"
  assert_success
  assert_output_contains "Assignees: user1,user3"
}

@test "github-create-issues: applies default milestone" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' -m 5 --dry-run"
  assert_success
  assert_output_contains "Milestone: 5"
}

@test "github-create-issues: per-issue milestone overrides default" {
  run bash -c "echo '{\"title\":\"Test\",\"milestone\":3}' | '${BIN_DIR}/github-create-issues' -m 5 --dry-run"
  assert_success
  assert_output_contains "Milestone: 3"
}

@test "github-create-issues: applies template" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' -t bug_report.md --dry-run"
  assert_success
  assert_output_contains "Template: bug_report.md"
}

@test "github-create-issues: per-issue template overrides default" {
  run bash -c "echo '{\"title\":\"Test\",\"template\":\"feature.md\"}' | '${BIN_DIR}/github-create-issues' -t bug.md --dry-run"
  assert_success
  assert_output_contains "Template: feature.md"
}

@test "github-create-issues: applies project" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' -p \"My Project\" --dry-run"
  assert_success
  assert_output_contains "Project: My Project"
}

@test "github-create-issues: applies repo" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' -r owner/repo --dry-run"
  assert_success
  assert_output_contains "Repo: owner/repo"
}

@test "github-create-issues: verbose mode shows additional info" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' -V --dry-run"
  assert_success
  assert_output_contains "Reading JSON from stdin"
  assert_output_contains "Command: gh issue create"
}

@test "github-create-issues: short option -n for dry-run works" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' -n"
  assert_success
  assert_output_contains "Would create issue"
  assert_output_contains "Dry run completed"
}

@test "github-create-issues: long option --dry-run works" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' --dry-run"
  assert_success
  assert_output_contains "Would create issue"
  assert_output_contains "Dry run completed"
}

@test "github-create-issues: rejects unknown options" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' --unknown-option"
  assert_failure
  assert_output_contains "Unknown option"
}

@test "github-create-issues: handles issue with all fields" {
  run bash -c "echo '{\"title\":\"Complex issue\",\"body\":\"Detailed description\",\"labels\":[\"bug\",\"urgent\"],\"assignees\":[\"user1\",\"user2\"],\"milestone\":5,\"template\":\"bug_report.md\"}' | '${BIN_DIR}/github-create-issues' --dry-run"
  assert_success
  assert_output_contains "Title: Complex issue"
  assert_output_contains "Body: Detailed description"
  assert_output_contains "Labels: bug,urgent"
  assert_output_contains "Assignees: user1,user2"
  assert_output_contains "Milestone: 5"
  assert_output_contains "Template: bug_report.md"
}

@test "github-create-issues: handles special characters in title" {
  run bash -c "echo '{\"title\":\"Issue with quotes and special\"}' | '${BIN_DIR}/github-create-issues' --dry-run"
  assert_success
  assert_output_contains "Title: Issue with"
}

@test "github-create-issues: truncates long body in dry-run output" {
  run bash -c "echo '{\"title\":\"Test\",\"body\":\"This is a very long body that should be truncated in the dry-run output because it exceeds 100 characters in total length\"}' | '${BIN_DIR}/github-create-issues' --dry-run"
  assert_success
  assert_output_contains "Body:"
  assert_output_contains "..."
}

# ========= Output Format Tests =========

@test "github-create-issues: --help shows --format option" {
  run "${BIN_DIR}/github-create-issues" --help
  assert_success
  assert_output_contains "--format"
  assert_output_contains "Output format"
}

@test "github-create-issues: rejects invalid format" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' --format invalid --dry-run"
  assert_failure
  assert_output_contains "Invalid format"
}

@test "github-create-issues: accepts --format simple" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' --format simple --dry-run"
  assert_success
  assert_output_contains "Would create issue"
}

@test "github-create-issues: accepts --format json" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' --format json --dry-run"
  assert_success
  assert_output_contains "Would create issue"
}

@test "github-create-issues: short option -f works with simple" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' -f simple --dry-run"
  assert_success
  assert_output_contains "Would create issue"
}

@test "github-create-issues: short option -f works with json" {
  run bash -c "echo '{\"title\":\"Test\"}' | '${BIN_DIR}/github-create-issues' -f json --dry-run"
  assert_success
  assert_output_contains "Would create issue"
}
