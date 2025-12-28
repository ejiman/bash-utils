#!/usr/bin/env bats

# ========= Load test helper =========
load test_helper

# ========= Setup/Teardown =========
setup() {
  setup_temp_dir

  # Create fake install prefix
  FAKE_INSTALL_PREFIX="${TEST_TEMP_DIR}/install"
  export INSTALL_PREFIX="${FAKE_INSTALL_PREFIX}"

  # Create fake project structure
  FAKE_PROJECT_DIR="${TEST_TEMP_DIR}/project"
  mkdir -p "${FAKE_PROJECT_DIR}/bin"
  mkdir -p "${FAKE_PROJECT_DIR}/lib"
  mkdir -p "${FAKE_PROJECT_DIR}/docs"

  # Create dummy files
  echo "#!/bin/bash" > "${FAKE_PROJECT_DIR}/bin/dummy-tool"
  chmod +x "${FAKE_PROJECT_DIR}/bin/dummy-tool"
  echo "# lib file" > "${FAKE_PROJECT_DIR}/lib/dummy.sh"
  echo "# Documentation" > "${FAKE_PROJECT_DIR}/docs/example.md"

  # Copy install.sh to fake project
  cp "${PROJECT_ROOT}/install.sh" "${FAKE_PROJECT_DIR}/"
}

teardown() {
  teardown_temp_dir
}

# ========= Helper functions =========

# Run install.sh from fake project directory
run_install() {
  cd "${FAKE_PROJECT_DIR}" || return 1
  run bash install.sh "$@"
}

# ========= Tests =========

@test "install.sh: completes successfully with valid project structure" {
  run_install
  assert_success
  assert_output_contains "Detected OS:"
  assert_output_contains "Installing to:"
  assert_output_contains "Installation completed"
}

@test "install.sh: creates installation directories" {
  run_install
  assert_success

  # Check that directories were created
  [[ -d "${FAKE_INSTALL_PREFIX}/share/bash-utils" ]]
  [[ -d "${FAKE_INSTALL_PREFIX}/bin" ]]
}

@test "install.sh: copies project files" {
  run_install
  assert_success

  # Check that files were copied
  [[ -d "${FAKE_INSTALL_PREFIX}/share/bash-utils/bin" ]]
  [[ -d "${FAKE_INSTALL_PREFIX}/share/bash-utils/lib" ]]
  [[ -d "${FAKE_INSTALL_PREFIX}/share/bash-utils/docs" ]]
  [[ -f "${FAKE_INSTALL_PREFIX}/share/bash-utils/bin/dummy-tool" ]]
  [[ -f "${FAKE_INSTALL_PREFIX}/share/bash-utils/lib/dummy.sh" ]]
  [[ -f "${FAKE_INSTALL_PREFIX}/share/bash-utils/docs/example.md" ]]
}

@test "install.sh: creates symbolic links" {
  run_install
  assert_success

  # Check that symlink was created
  [[ -L "${FAKE_INSTALL_PREFIX}/bin/dummy-tool" ]]

  # Check that symlink points to correct location
  local target
  target=$(readlink "${FAKE_INSTALL_PREFIX}/bin/dummy-tool")
  [[ "$target" == "${FAKE_INSTALL_PREFIX}/share/bash-utils/bin/dummy-tool" ]]
}

@test "install.sh: fails when bin directory is missing" {
  rm -rf "${FAKE_PROJECT_DIR}/bin"

  run_install
  assert_failure
  assert_output_contains "bin directory not found"
}

@test "install.sh: fails when lib directory is missing" {
  rm -rf "${FAKE_PROJECT_DIR}/lib"

  run_install
  assert_failure
  assert_output_contains "lib directory not found"
}

@test "install.sh: fails when docs directory is missing" {
  rm -rf "${FAKE_PROJECT_DIR}/docs"

  run_install
  assert_failure
  assert_output_contains "docs directory not found"
}

@test "install.sh: shows PATH warning when install dir not in PATH" {
  # Make sure FAKE_INSTALL_PREFIX/bin is not in PATH
  export PATH="/usr/bin:/bin"

  run_install
  assert_success
  assert_output_contains "is not in your PATH"
}

@test "install.sh: respects INSTALL_PREFIX environment variable" {
  local custom_prefix="${TEST_TEMP_DIR}/custom"
  export INSTALL_PREFIX="${custom_prefix}"

  run_install
  assert_success

  # Check that files were installed to custom location
  [[ -d "${custom_prefix}/share/bash-utils" ]]
  [[ -d "${custom_prefix}/bin" ]]
}

@test "install.sh: detects Linux OS" {
  # This test assumes we're running on Linux
  # Skip if not on Linux
  if [[ "$(uname -s)" != "Linux"* ]]; then
    skip "Not running on Linux"
  fi

  run_install
  assert_success
  assert_output_contains "Detected OS: linux"
}

@test "install.sh: detects macOS" {
  # This test assumes we're running on macOS
  # Skip if not on macOS
  if [[ "$(uname -s)" != "Darwin"* ]]; then
    skip "Not running on macOS"
  fi

  run_install
  assert_success
  assert_output_contains "Detected OS: macos"
}

@test "install.sh: shows installation summary" {
  run_install
  assert_success
  assert_output_contains "Installed to:"
  assert_output_contains "Root:"
  assert_output_contains "Binaries:"
}

@test "install.sh: handles multiple files in bin directory" {
  # Create additional dummy tools
  echo "#!/bin/bash" > "${FAKE_PROJECT_DIR}/bin/another-tool"
  chmod +x "${FAKE_PROJECT_DIR}/bin/another-tool"
  echo "#!/bin/bash" > "${FAKE_PROJECT_DIR}/bin/third-tool"
  chmod +x "${FAKE_PROJECT_DIR}/bin/third-tool"

  run_install
  assert_success

  # Check that all symlinks were created
  [[ -L "${FAKE_INSTALL_PREFIX}/bin/dummy-tool" ]]
  [[ -L "${FAKE_INSTALL_PREFIX}/bin/another-tool" ]]
  [[ -L "${FAKE_INSTALL_PREFIX}/bin/third-tool" ]]
}

@test "install.sh: preserves file permissions" {
  run_install
  assert_success

  # Check that executable permission was preserved
  [[ -x "${FAKE_INSTALL_PREFIX}/share/bash-utils/bin/dummy-tool" ]]
}
