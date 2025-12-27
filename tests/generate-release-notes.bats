#!/usr/bin/env bats

# ========= Load test helper =========
load test_helper

# ========= Setup/Teardown =========
setup() {
  setup_temp_dir

  # Create a temporary git repository
  export TEST_REPO="$TEST_TEMP_DIR/test-repo"
  mkdir -p "$TEST_REPO"
  cd "$TEST_REPO"
  git init -q
  git config user.name "Test User"
  git config user.email "test@example.com"

  # Create initial commit
  echo "initial" > file.txt
  git add file.txt
  git commit -q -m "Initial commit"
  git tag v0.1.0

  # Create conventional commits
  echo "feat1" >> file.txt
  git add file.txt
  git commit -q -m "feat: add new feature"

  echo "fix1" >> file.txt
  git add file.txt
  git commit -q -m "fix: resolve bug"

  echo "feat2" >> file.txt
  git add file.txt
  git commit -q -m "feat(cli): add cli feature"
}

teardown() {
  teardown_temp_dir
}

# ========= Tests =========

@test "generate-release-notes: --help shows usage" {
  run "${BIN_DIR}/generate-release-notes" --help
  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "generate-release-notes"
}

@test "generate-release-notes: --version shows version" {
  run "${BIN_DIR}/generate-release-notes" --version
  assert_success
  assert_output_contains "version"
}

@test "generate-release-notes: generates release notes from latest tag" {
  cd "$TEST_REPO"
  run "${BIN_DIR}/generate-release-notes"
  assert_success
  assert_output_contains "Release Notes"
  assert_output_contains "Features"
  assert_output_contains "Bug Fixes"
  assert_output_contains "add new feature"
  assert_output_contains "resolve bug"
}

@test "generate-release-notes: --from and --to options work" {
  cd "$TEST_REPO"
  run "${BIN_DIR}/generate-release-notes" --from v0.1.0 --to HEAD
  assert_success
  assert_output_contains "Changes since v0.1.0"
}

@test "generate-release-notes: --output writes to file" {
  cd "$TEST_REPO"
  local output_file="${TEST_REPO}/notes.md"

  run "${BIN_DIR}/generate-release-notes" --output "$output_file"
  assert_success
  assert_output_contains "Release notes written to"

  [[ -f "$output_file" ]]
  grep -q "Release Notes" "$output_file"
}

@test "generate-release-notes: --no-group option works" {
  cd "$TEST_REPO"
  run "${BIN_DIR}/generate-release-notes" --no-group
  assert_success
  assert_output_contains "## Changes"
  # Verify it doesn't contain separate category headers
  if [[ "$output" == *"## Features"* ]]; then
    echo "Output should not contain '## Features' in --no-group mode"
    return 1
  fi
}

@test "generate-release-notes: fails without tags when --from not specified" {
  # Create new repo without tags
  local new_repo="${TEST_TEMP_DIR}/new_repo"
  mkdir -p "$new_repo"
  cd "$new_repo"
  git init -q
  git config user.name "Test User"
  git config user.email "test@example.com"
  echo "test" > file.txt
  git add file.txt
  git commit -q -m "Initial commit"

  run "${BIN_DIR}/generate-release-notes"
  assert_failure
  assert_output_contains "No tags found"
}

@test "generate-release-notes: parses commit with scope correctly" {
  cd "$TEST_REPO"
  run "${BIN_DIR}/generate-release-notes"
  assert_success
  assert_output_contains "**cli**: add cli feature"
}

@test "generate-release-notes: handles non-conventional commits" {
  cd "$TEST_REPO"
  echo "other" >> file.txt
  git add file.txt
  git commit -q -m "Some random commit message"

  run "${BIN_DIR}/generate-release-notes"
  assert_success
  assert_output_contains "Other Changes"
  assert_output_contains "Some random commit message"
}
