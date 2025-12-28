#!/usr/bin/env bats

# ========= Load test helper =========
load test_helper

# ========= Setup/Teardown =========
setup() {
  setup_temp_dir

  # Create fake project structure
  FAKE_PROJECT_DIR="${TEST_TEMP_DIR}/project"
  mkdir -p "${FAKE_PROJECT_DIR}/bin"
  mkdir -p "${FAKE_PROJECT_DIR}/lib"
  mkdir -p "${FAKE_PROJECT_DIR}/docs"

  # Create dummy files
  echo "#!/bin/bash" > "${FAKE_PROJECT_DIR}/bin/dummy-tool"
  chmod +x "${FAKE_PROJECT_DIR}/bin/dummy-tool"
  echo "# lib file" > "${FAKE_PROJECT_DIR}/lib/utils.sh"
  echo "# Documentation" > "${FAKE_PROJECT_DIR}/docs/README.md"
  echo "# Install script" > "${FAKE_PROJECT_DIR}/install.sh"
  echo "# Uninstall script" > "${FAKE_PROJECT_DIR}/uninstall.sh"
  echo "# README" > "${FAKE_PROJECT_DIR}/README.md"
  echo "MIT License" > "${FAKE_PROJECT_DIR}/LICENSE"
  echo "# shellcheck config" > "${FAKE_PROJECT_DIR}/.shellcheckrc"
  echo "# Makefile" > "${FAKE_PROJECT_DIR}/Makefile"

  # Copy package.sh to fake project
  cp "${PROJECT_ROOT}/package.sh" "${FAKE_PROJECT_DIR}/"

  # Initialize git repo for version detection
  cd "${FAKE_PROJECT_DIR}" || return 1
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
  git add .
  git commit -q -m "Initial commit"
}

teardown() {
  teardown_temp_dir
}

# ========= Helper functions =========

# Run package.sh from fake project directory
# shellcheck disable=SC2120
run_package() {
  cd "${FAKE_PROJECT_DIR}" || return 1
  run bash package.sh "$@"
}

# Get the first matching tarball file
get_tarball() {
  # shellcheck disable=SC2231
  for file in "${FAKE_PROJECT_DIR}"/bash-utils-*.tar.gz; do
    if [[ -f "$file" ]]; then
      echo "$file"
      return 0
    fi
  done
  return 1
}

# Extract tarball
extract_tarball() {
  local tarball="$1"
  cd "${FAKE_PROJECT_DIR}" || return 1
  tar -xzf "$tarball"
}

# Get the first matching extracted directory
get_extracted_dir() {
  # shellcheck disable=SC2231
  for dir in "${FAKE_PROJECT_DIR}"/bash-utils-*; do
    if [[ -d "$dir" ]]; then
      echo "$dir"
      return 0
    fi
  done
  return 1
}

# ========= Tests =========

@test "package.sh: completes successfully" {
  run_package
  assert_success
  assert_output_contains "Packaging bash-utils version:"
  assert_output_contains "Package created successfully"
}

@test "package.sh: creates tarball with dev version" {
  run_package
  assert_success

  # Check that tarball exists with dev-{hash} format
  local tarball
  tarball=$(get_tarball)
  [[ -f "$tarball" ]]
  [[ "$tarball" == *"bash-utils-dev-"*.tar.gz ]]
}

@test "package.sh: creates tarball with git tag version" {
  # Create a git tag
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v1.0.0 -m "Version 1.0.0"

  run_package
  assert_success

  # Check that tarball exists with tagged version
  [[ -f "${FAKE_PROJECT_DIR}/bash-utils-v1.0.0.tar.gz" ]]
}

@test "package.sh: includes bin directory in tarball" {
  run_package
  assert_success

  local tarball
  tarball=$(get_tarball)
  extract_tarball "$tarball"

  local extracted_dir
  extracted_dir=$(get_extracted_dir)
  [[ -d "${extracted_dir}/bin" ]]
  [[ -f "${extracted_dir}/bin/dummy-tool" ]]
}

@test "package.sh: includes lib directory in tarball" {
  run_package
  assert_success

  local tarball
  tarball=$(get_tarball)
  extract_tarball "$tarball"

  local extracted_dir
  extracted_dir=$(get_extracted_dir)
  [[ -d "${extracted_dir}/lib" ]]
  [[ -f "${extracted_dir}/lib/utils.sh" ]]
}

@test "package.sh: includes docs directory in tarball" {
  run_package
  assert_success

  local tarball
  tarball=$(get_tarball)
  extract_tarball "$tarball"

  local extracted_dir
  extracted_dir=$(get_extracted_dir)
  [[ -d "${extracted_dir}/docs" ]]
  [[ -f "${extracted_dir}/docs/README.md" ]]
}

@test "package.sh: includes install.sh in tarball" {
  run_package
  assert_success

  local tarball
  tarball=$(get_tarball)
  extract_tarball "$tarball"

  local extracted_dir
  extracted_dir=$(get_extracted_dir)
  [[ -f "${extracted_dir}/install.sh" ]]
}

@test "package.sh: includes uninstall.sh in tarball" {
  run_package
  assert_success

  local tarball
  tarball=$(get_tarball)
  extract_tarball "$tarball"

  local extracted_dir
  extracted_dir=$(get_extracted_dir)
  [[ -f "${extracted_dir}/uninstall.sh" ]]
}

@test "package.sh: includes README.md in tarball" {
  run_package
  assert_success

  local tarball
  tarball=$(get_tarball)
  extract_tarball "$tarball"

  local extracted_dir
  extracted_dir=$(get_extracted_dir)
  [[ -f "${extracted_dir}/README.md" ]]
}

@test "package.sh: includes LICENSE in tarball" {
  run_package
  assert_success

  local tarball
  tarball=$(get_tarball)
  extract_tarball "$tarball"

  local extracted_dir
  extracted_dir=$(get_extracted_dir)
  [[ -f "${extracted_dir}/LICENSE" ]]
}

@test "package.sh: handles missing LICENSE file gracefully" {
  rm "${FAKE_PROJECT_DIR}/LICENSE"

  run_package
  assert_success
  assert_output_contains "LICENSE file not found, skipping"

  local tarball
  tarball=$(get_tarball)
  extract_tarball "$tarball"

  local extracted_dir
  extracted_dir=$(get_extracted_dir)
  [[ ! -f "${extracted_dir}/LICENSE" ]]
}

@test "package.sh: includes optional .shellcheckrc in tarball" {
  run_package
  assert_success

  local tarball
  tarball=$(get_tarball)
  extract_tarball "$tarball"

  local extracted_dir
  extracted_dir=$(get_extracted_dir)
  [[ -f "${extracted_dir}/.shellcheckrc" ]]
}

@test "package.sh: includes optional Makefile in tarball" {
  run_package
  assert_success

  local tarball
  tarball=$(get_tarball)
  extract_tarball "$tarball"

  local extracted_dir
  extracted_dir=$(get_extracted_dir)
  [[ -f "${extracted_dir}/Makefile" ]]
}

@test "package.sh: handles missing optional files gracefully" {
  rm "${FAKE_PROJECT_DIR}/.shellcheckrc"
  rm "${FAKE_PROJECT_DIR}/Makefile"

  run_package
  assert_success

  local tarball
  tarball=$(get_tarball)
  extract_tarball "$tarball"

  local extracted_dir
  extracted_dir=$(get_extracted_dir)
  [[ ! -f "${extracted_dir}/.shellcheckrc" ]]
  [[ ! -f "${extracted_dir}/Makefile" ]]
}

@test "package.sh: displays package summary" {
  run_package
  assert_success
  assert_output_contains "File:"
  assert_output_contains "Size:"
  assert_output_contains "SHA256:"
  assert_output_contains "To test the package:"
}

@test "package.sh: shows tarball size" {
  run_package
  assert_success
  assert_output_contains "Size:"
}

@test "package.sh: shows SHA256 hash" {
  run_package
  assert_success

  # Extract the SHA256 from output
  local sha256_line
  sha256_line=$(echo "$output" | grep "SHA256:")
  [[ -n "$sha256_line" ]]

  # SHA256 hash should be 64 hex characters
  local hash
  hash=$(echo "$sha256_line" | awk '{print $2}')
  [[ ${#hash} -eq 64 ]]
}

@test "package.sh: cleans up temporary package directory" {
  run_package
  assert_success

  # Package directory should not exist after script completes
  # Only tarball should exist, not the directory
  local tarball
  tarball=$(get_tarball)
  [[ -f "$tarball" ]]

  # Try to get extracted dir - should fail
  if get_extracted_dir >/dev/null 2>&1; then
    # If directory exists, it's a failure
    return 1
  fi
}

@test "package.sh: creates valid tarball that can be extracted" {
  run_package
  assert_success

  local tarball
  tarball=$(get_tarball)

  # Extract and verify
  cd "${FAKE_PROJECT_DIR}" || return 1
  run tar -tzf "$tarball"
  assert_success
  assert_output_contains "bin/dummy-tool"
  assert_output_contains "lib/utils.sh"
  assert_output_contains "docs/README.md"
  assert_output_contains "install.sh"
  assert_output_contains "uninstall.sh"
}

@test "package.sh: preserves file permissions in tarball" {
  run_package
  assert_success

  local tarball
  tarball=$(get_tarball)
  extract_tarball "$tarball"

  local extracted_dir
  extracted_dir=$(get_extracted_dir)
  # Check that executable permission is preserved
  [[ -x "${extracted_dir}/bin/dummy-tool" ]]
}

@test "package.sh: removes old tarball with same version before creating new one" {
  # Create first tarball
  run_package
  assert_success

  local first_tarball
  first_tarball=$(get_tarball)
  [[ -f "$first_tarball" ]]

  # Get the original modification time
  local first_mtime
  first_mtime=$(stat -c %Y "$first_tarball" 2>/dev/null || stat -f %m "$first_tarball")

  # Wait to ensure different timestamp
  sleep 1

  # Run package script again WITHOUT changing git state
  # This should remove the old tarball and create a new one with same name
  run_package
  assert_success

  # Tarball should still exist
  local second_tarball
  second_tarball=$(get_tarball)
  [[ -f "$second_tarball" ]]

  # Should have same name (since git state didn't change)
  [[ "$first_tarball" == "$second_tarball" ]]

  # But should have different modification time (was recreated)
  local second_mtime
  second_mtime=$(stat -c %Y "$second_tarball" 2>/dev/null || stat -f %m "$second_tarball")
  [[ "$first_mtime" != "$second_mtime" ]]
}

@test "package.sh: shows installation instructions" {
  run_package
  assert_success
  assert_output_contains "To test the package:"
  assert_output_contains "tar -xzf"
  assert_output_contains "./install.sh"
}

@test "package.sh: uses correct project name" {
  run_package
  assert_success
  assert_output_contains "Packaging bash-utils"
}

@test "package.sh: creates tarball with consistent naming" {
  # With tag
  cd "${FAKE_PROJECT_DIR}" || return 1
  git tag -a v2.0.0 -m "Version 2.0.0"

  run_package
  assert_success

  local tarball="${FAKE_PROJECT_DIR}/bash-utils-v2.0.0.tar.gz"
  [[ -f "$tarball" ]]

  # Extracted directory should have same name
  extract_tarball "$tarball"
  [[ -d "${FAKE_PROJECT_DIR}/bash-utils-v2.0.0" ]]
}
