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

  # Create dummy files
  echo "#!/bin/bash" > "${FAKE_PROJECT_DIR}/bin/dummy-tool"
  chmod +x "${FAKE_PROJECT_DIR}/bin/dummy-tool"
  echo "# lib file" > "${FAKE_PROJECT_DIR}/lib/dummy.sh"

  # Copy install.sh and uninstall.sh to fake project
  cp "${PROJECT_ROOT}/install.sh" "${FAKE_PROJECT_DIR}/"
  cp "${PROJECT_ROOT}/uninstall.sh" "${FAKE_PROJECT_DIR}/"
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

# Run uninstall.sh with input
run_uninstall() {
  local answer="${1:-y}"
  cd "${FAKE_PROJECT_DIR}" || return 1
  run bash -c "echo '$answer' | bash uninstall.sh"
}

# ========= Tests =========

@test "uninstall.sh: fails when bash-utils is not installed" {
  # Don't run install first
  run_uninstall "y"
  assert_failure
  assert_output_contains "bash-utils is not installed"
}

@test "uninstall.sh: detects OS" {
  # Install first
  run_install
  assert_success

  # Run uninstall
  run_uninstall "y"
  assert_success
  assert_output_contains "Detected OS:"
}

@test "uninstall.sh: displays items to be removed" {
  # Install first
  run_install
  assert_success

  # Run uninstall
  run_uninstall "y"
  assert_success
  assert_output_contains "The following items will be removed:"
  assert_output_contains "Directory: ${FAKE_INSTALL_PREFIX}/share/bash-utils"
  assert_output_contains "Symlinks:"
}

@test "uninstall.sh: lists symlinks to be removed" {
  # Install first
  run_install
  assert_success

  # Run uninstall
  run_uninstall "y"
  assert_success
  assert_output_contains "dummy-tool"
}

@test "uninstall.sh: cancels when user answers no" {
  # Install first
  run_install
  assert_success

  # Check that installation exists before uninstall
  [[ -d "${FAKE_INSTALL_PREFIX}/share/bash-utils" ]]

  # Run uninstall with "n" answer
  run_uninstall "n"
  assert_success
  assert_output_contains "Uninstallation cancelled"

  # Check that installation still exists
  [[ -d "${FAKE_INSTALL_PREFIX}/share/bash-utils" ]]
  [[ -L "${FAKE_INSTALL_PREFIX}/bin/dummy-tool" ]]
}

@test "uninstall.sh: cancels when user answers capital N" {
  # Install first
  run_install
  assert_success

  # Run uninstall with "N" answer
  run_uninstall "N"
  assert_success
  assert_output_contains "Uninstallation cancelled"

  # Check that installation still exists
  [[ -d "${FAKE_INSTALL_PREFIX}/share/bash-utils" ]]
}

@test "uninstall.sh: removes symlinks when user answers yes" {
  # Install first
  run_install
  assert_success

  # Check that symlink exists before uninstall
  [[ -L "${FAKE_INSTALL_PREFIX}/bin/dummy-tool" ]]

  # Run uninstall with "y" answer
  run_uninstall "y"
  assert_success
  assert_output_contains "Removing symbolic links"
  assert_output_contains "Removed: dummy-tool"

  # Check that symlink was removed
  [[ ! -e "${FAKE_INSTALL_PREFIX}/bin/dummy-tool" ]]
}

@test "uninstall.sh: removes installation directory" {
  # Install first
  run_install
  assert_success

  # Check that directory exists before uninstall
  [[ -d "${FAKE_INSTALL_PREFIX}/share/bash-utils" ]]

  # Run uninstall
  run_uninstall "y"
  assert_success
  assert_output_contains "Removing installation directory"
  assert_output_contains "Removed: ${FAKE_INSTALL_PREFIX}/share/bash-utils"

  # Check that directory was removed
  [[ ! -d "${FAKE_INSTALL_PREFIX}/share/bash-utils" ]]
}

@test "uninstall.sh: shows success message" {
  # Install first
  run_install
  assert_success

  # Run uninstall
  run_uninstall "y"
  assert_success
  assert_output_contains "Uninstallation completed"
  assert_output_contains "bash-utils has been removed from your system"
}

@test "uninstall.sh: handles capital Y for confirmation" {
  # Install first
  run_install
  assert_success

  # Run uninstall with "Y" answer
  run_uninstall "Y"
  assert_success
  assert_output_contains "Uninstallation completed"

  # Check that installation was removed
  [[ ! -d "${FAKE_INSTALL_PREFIX}/share/bash-utils" ]]
}

@test "uninstall.sh: handles multiple symlinks" {
  # Create additional dummy tools
  echo "#!/bin/bash" > "${FAKE_PROJECT_DIR}/bin/another-tool"
  chmod +x "${FAKE_PROJECT_DIR}/bin/another-tool"
  echo "#!/bin/bash" > "${FAKE_PROJECT_DIR}/bin/third-tool"
  chmod +x "${FAKE_PROJECT_DIR}/bin/third-tool"

  # Install
  run_install
  assert_success

  # Check that all symlinks exist
  [[ -L "${FAKE_INSTALL_PREFIX}/bin/dummy-tool" ]]
  [[ -L "${FAKE_INSTALL_PREFIX}/bin/another-tool" ]]
  [[ -L "${FAKE_INSTALL_PREFIX}/bin/third-tool" ]]

  # Run uninstall
  run_uninstall "y"
  assert_success
  assert_output_contains "dummy-tool"
  assert_output_contains "another-tool"
  assert_output_contains "third-tool"

  # Check that all symlinks were removed
  [[ ! -e "${FAKE_INSTALL_PREFIX}/bin/dummy-tool" ]]
  [[ ! -e "${FAKE_INSTALL_PREFIX}/bin/another-tool" ]]
  [[ ! -e "${FAKE_INSTALL_PREFIX}/bin/third-tool" ]]
}

@test "uninstall.sh: handles missing symlinks gracefully" {
  # Install first
  run_install
  assert_success

  # Manually remove symlink
  rm -f "${FAKE_INSTALL_PREFIX}/bin/dummy-tool"

  # Run uninstall (should still work)
  run_uninstall "y"
  assert_success
  assert_output_contains "Uninstallation completed"

  # Check that directory was still removed
  [[ ! -d "${FAKE_INSTALL_PREFIX}/share/bash-utils" ]]
}

@test "uninstall.sh: only removes symlinks that point to installation" {
  # Install first
  run_install
  assert_success

  # Create a symlink that points elsewhere
  ln -s "/usr/bin/true" "${FAKE_INSTALL_PREFIX}/bin/other-tool"

  # Run uninstall
  run_uninstall "y"
  assert_success

  # Check that our symlink was removed but the other one remains
  [[ ! -e "${FAKE_INSTALL_PREFIX}/bin/dummy-tool" ]]
  [[ -L "${FAKE_INSTALL_PREFIX}/bin/other-tool" ]]
}

@test "uninstall.sh: shows no symlinks message when none found" {
  # Manually create installation directory without going through install.sh
  mkdir -p "${FAKE_INSTALL_PREFIX}/share/bash-utils/bin"
  mkdir -p "${FAKE_INSTALL_PREFIX}/share/bash-utils/lib"
  echo "#!/bin/bash" > "${FAKE_INSTALL_PREFIX}/share/bash-utils/bin/tool"

  # Run uninstall (no symlinks exist)
  run_uninstall "y"
  assert_success
  assert_output_contains "Symlinks: (none found)"
  assert_output_contains "No symlinks to remove"
}

@test "uninstall.sh: respects INSTALL_PREFIX environment variable" {
  local custom_prefix="${TEST_TEMP_DIR}/custom"
  export INSTALL_PREFIX="${custom_prefix}"

  # Re-run setup with custom prefix
  mkdir -p "${FAKE_PROJECT_DIR}/bin"
  mkdir -p "${FAKE_PROJECT_DIR}/lib"
  echo "#!/bin/bash" > "${FAKE_PROJECT_DIR}/bin/custom-tool"
  chmod +x "${FAKE_PROJECT_DIR}/bin/custom-tool"

  # Install to custom prefix
  run_install
  assert_success

  # Verify installation at custom location
  [[ -d "${custom_prefix}/share/bash-utils" ]]

  # Uninstall from custom prefix
  run_uninstall "y"
  assert_success
  assert_output_contains "${custom_prefix}/share/bash-utils"

  # Check that custom installation was removed
  [[ ! -d "${custom_prefix}/share/bash-utils" ]]
}
