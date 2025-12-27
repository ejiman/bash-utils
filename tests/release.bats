#!/usr/bin/env bats

# ========= Load test helper =========
load test_helper

# ========= Setup/Teardown =========
setup() {
  setup_temp_dir

  # Create fake project structure
  FAKE_PROJECT_DIR="${TEST_TEMP_DIR}/project"
  mkdir -p "${FAKE_PROJECT_DIR}"

  # Copy release.sh to fake project
  cp "${PROJECT_ROOT}/release.sh" "${FAKE_PROJECT_DIR}/"

  # Initialize git repo
  cd "${FAKE_PROJECT_DIR}" || return 1
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create initial commit
  echo "# Test project" > README.md
  git add .
  git commit -q -m "Initial commit"
}

teardown() {
  teardown_temp_dir
}

# ========= Helper functions =========

# Run release.sh with simulated input
# Each argument is a line of input
# shellcheck disable=SC2120
run_release() {
  cd "${FAKE_PROJECT_DIR}" || return 1

  # Create a temporary input file
  local input_file="${TEST_TEMP_DIR}/input.txt"

  # Write each argument as a line
  printf '%s\n' "$@" > "$input_file"

  # Run with input redirection
  run bash release.sh < "$input_file"
}

# Get the latest git tag
# Use git tag -l with sort to get the most recent tag
get_latest_tag() {
  cd "${FAKE_PROJECT_DIR}" || return 1
  # Sort tags by version number (assuming semver format)
  git tag -l 'v*' --sort=-version:refname | head -n1
}

# ========= Tests =========

@test "release.sh: fails with uncommitted changes" {
  # Create uncommitted change
  echo "uncommitted" >> "${FAKE_PROJECT_DIR}/README.md"

  run_release "1" "y"
  assert_failure
  assert_output_contains "uncommitted changes"
}

@test "release.sh: starts from v0.0.0 when no tags exist" {
  # No tags exist yet
  run_release "1" "y"
  assert_success
  assert_output_contains "Current version: v0.0.0"
  assert_output_contains "Patch: v0.0.1"

  # Check that tag was created
  local tag
  tag=$(get_latest_tag)
  [[ "$tag" == "v0.0.1" ]]
}

@test "release.sh: creates patch version bump (1)" {
  # Create initial tag
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v1.2.3 -m "Version 1.2.3"

  # Select option 1 (patch) and confirm
  run_release "1" "y"
  assert_success
  assert_output_contains "Current version: v1.2.3"
  assert_output_contains "Patch: v1.2.4"
  assert_output_contains "Tag created successfully"

  # Check that tag was created
  local tag
  tag=$(get_latest_tag)
  [[ "$tag" == "v1.2.4" ]]
}

@test "release.sh: creates minor version bump (2)" {
  # Create initial tag
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v1.2.3 -m "Version 1.2.3"

  # Select option 2 (minor) and confirm
  run_release "2" "y"
  assert_success
  assert_output_contains "Current version: v1.2.3"
  assert_output_contains "Minor: v1.3.0"
  assert_output_contains "Tag created successfully"

  # Check that tag was created
  local tag
  tag=$(get_latest_tag)
  [[ "$tag" == "v1.3.0" ]]
}

@test "release.sh: creates major version bump (3)" {
  # Create initial tag
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v1.2.3 -m "Version 1.2.3"

  # Select option 3 (major) and confirm
  run_release "3" "y"
  assert_success
  assert_output_contains "Current version: v1.2.3"
  assert_output_contains "Major: v2.0.0"
  assert_output_contains "Tag created successfully"

  # Check that tag was created
  local tag
  tag=$(get_latest_tag)
  [[ "$tag" == "v2.0.0" ]]
}

@test "release.sh: creates custom version (4)" {
  # Create initial tag
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v1.0.0 -m "Version 1.0.0"

  # Select option 4 (custom) with version v5.6.7 and confirm
  run_release "4" "v5.6.7" "y"
  assert_success
  assert_output_contains "Current version: v1.0.0"
  assert_output_contains "Tag created successfully"

  # Check that tag was created
  local tag
  tag=$(get_latest_tag)
  [[ "$tag" == "v5.6.7" ]]
}

@test "release.sh: rejects invalid custom version format" {
  # Create initial tag
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v1.0.0 -m "Version 1.0.0"

  # Select option 4 (custom) with invalid version
  run_release "4" "invalid-version" "y"
  assert_failure
  assert_output_contains "Invalid version format"
}

@test "release.sh: cancels when user says no (n)" {
  # Create initial tag
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v1.0.0 -m "Version 1.0.0"

  # Select patch but cancel
  run_release "1" "n"
  assert_success
  assert_output_contains "Release cancelled"

  # Tag should not be created
  local tag
  tag=$(get_latest_tag)
  [[ "$tag" == "v1.0.0" ]]
}

@test "release.sh: cancels when user says no (N)" {
  # Create initial tag
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v1.0.0 -m "Version 1.0.0"

  # Select patch but cancel with capital N
  run_release "1" "N"
  assert_success
  assert_output_contains "Release cancelled"

  # Tag should not be created
  local tag
  tag=$(get_latest_tag)
  [[ "$tag" == "v1.0.0" ]]
}

@test "release.sh: fails with invalid choice" {
  # Create initial tag
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v1.0.0 -m "Version 1.0.0"

  # Select invalid option
  run_release "99" "y"
  assert_failure
  assert_output_contains "Invalid choice"
}

@test "release.sh: shows version options correctly" {
  # Create initial tag
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v2.5.8 -m "Version 2.5.8"

  # Run but cancel
  run_release "1" "n"
  assert_success
  assert_output_contains "Patch: v2.5.9"
  assert_output_contains "Minor: v2.6.0"
  assert_output_contains "Major: v3.0.0"
  assert_output_contains "Custom version"
}

@test "release.sh: shows push instructions" {
  run_release "1" "y"
  assert_success
  assert_output_contains "To push the tag and trigger the release workflow:"
  assert_output_contains "git push origin"
  assert_output_contains "To delete the tag if you made a mistake:"
  assert_output_contains "git tag -d"
}

@test "release.sh: handles version with leading zeros" {
  # Create tag with leading zeros
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v0.0.1 -m "Version 0.0.1"

  run_release "1" "y"
  assert_success
  assert_output_contains "Current version: v0.0.1"

  # Check that tag was created
  local tag
  tag=$(get_latest_tag)
  [[ "$tag" == "v0.0.2" ]]
}

@test "release.sh: increments from v0.9.9 to v0.10.0 correctly" {
  # Test version increment edge case
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v0.9.9 -m "Version 0.9.9"

  # Select minor version bump
  run_release "2" "y"
  assert_success

  # Check that tag was created
  local tag
  tag=$(get_latest_tag)
  [[ "$tag" == "v0.10.0" ]]
}

@test "release.sh: increments from v0.9.9 to v1.0.0 correctly" {
  # Test version increment edge case
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v0.9.9 -m "Version 0.9.9"

  # Select major version bump
  run_release "3" "y"
  assert_success

  # Check that tag was created
  local tag
  tag=$(get_latest_tag)
  [[ "$tag" == "v1.0.0" ]]
}

@test "release.sh: rejects custom version without 'v' prefix" {
  # Create initial tag
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v1.0.0 -m "Version 1.0.0"

  # Try custom version without 'v' prefix
  run_release "4" "2.0.0" "y"
  assert_failure
  assert_output_contains "Invalid version format"
}

@test "release.sh: rejects custom version with extra parts" {
  # Create initial tag
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v1.0.0 -m "Version 1.0.0"

  # Try custom version with extra version parts
  run_release "4" "v1.2.3.4" "y"
  assert_failure
  assert_output_contains "Invalid version format"
}

@test "release.sh: accepts yes with lowercase y" {
  run_release "1" "y"
  assert_success
  assert_output_contains "Tag created successfully"

  # Tag should be created
  local tag
  tag=$(get_latest_tag)
  [[ "$tag" == "v0.0.1" ]]
}

@test "release.sh: accepts yes with uppercase Y" {
  run_release "1" "Y"
  assert_success
  assert_output_contains "Tag created successfully"

  # Tag should be created
  local tag
  tag=$(get_latest_tag)
  [[ "$tag" == "v0.0.1" ]]
}

@test "release.sh: creates annotated tag with message" {
  run_release "1" "y"
  assert_success

  # Check that tag is annotated
  cd "${FAKE_PROJECT_DIR}" || return 1
  local tag_message
  tag_message=$(git tag -l -n9 v0.0.1)
  [[ "$tag_message" == *"Release v0.0.1"* ]]
}
