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

@test "github-get-project-field-id: --help shows usage" {
  run "${BIN_DIR}/github-get-project-field-id" --help
  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "github-get-project-field-id"
  assert_output_contains "Examples:"
  assert_output_contains "--project-id"
  assert_output_contains "--org"
  assert_output_contains "--number"
}

@test "github-get-project-field-id: --version shows version" {
  run "${BIN_DIR}/github-get-project-field-id" --version
  assert_success
  assert_output_contains "version"
}

@test "github-get-project-field-id: fails without required arguments" {
  run "${BIN_DIR}/github-get-project-field-id"
  assert_failure
  assert_output_contains "Must specify either --project-id or both --org and --number"
}

@test "github-get-project-field-id: fails when specifying only --org without --number" {
  run "${BIN_DIR}/github-get-project-field-id" --org "myorg"
  assert_failure
  assert_output_contains "Must specify either --project-id or both --org and --number"
}

@test "github-get-project-field-id: fails when specifying only --number without --org" {
  run "${BIN_DIR}/github-get-project-field-id" --number 1
  assert_failure
  assert_output_contains "Must specify either --project-id or both --org and --number"
}

@test "github-get-project-field-id: fails when specifying both --project-id and --org" {
  run "${BIN_DIR}/github-get-project-field-id" --project-id "PVT_test" --org "myorg" --number 1
  assert_failure
  assert_output_contains "Cannot specify both --project-id and --org/--number"
}

@test "github-get-project-field-id: fails when specifying both --project-id and --number" {
  run "${BIN_DIR}/github-get-project-field-id" --project-id "PVT_test" --number 1
  assert_failure
  assert_output_contains "Cannot specify both --project-id and --org/--number"
}

@test "github-get-project-field-id: fails with invalid format" {
  run "${BIN_DIR}/github-get-project-field-id" --project-id "PVT_test" --format invalid
  assert_failure
  assert_output_contains "Invalid format: invalid"
  assert_output_contains "Must be one of: table, json, id-only"
}

@test "github-get-project-field-id: short option -p works" {
  # gh command will fail, but we verify option parsing works
  run "${BIN_DIR}/github-get-project-field-id" -p "PVT_test"
  assert_failure
  # Should not show "Must specify either" error
  if [[ "$output" == *"Must specify either"* ]]; then
    echo "Option -p was not recognized"
    return 1
  fi
}

@test "github-get-project-field-id: short option -o works" {
  # gh command will fail, but we verify option parsing works
  run "${BIN_DIR}/github-get-project-field-id" -o "myorg" -n 1
  assert_failure
  # Should not show "Must specify either" error
  if [[ "$output" == *"Must specify either"* ]]; then
    echo "Option -o was not recognized"
    return 1
  fi
}

@test "github-get-project-field-id: short option -n works" {
  # gh command will fail, but we verify option parsing works
  run "${BIN_DIR}/github-get-project-field-id" -o "myorg" -n 1
  assert_failure
  # Should not show "Must specify either" error
  if [[ "$output" == *"Must specify either"* ]]; then
    echo "Option -n was not recognized"
    return 1
  fi
}

@test "github-get-project-field-id: short option -f works" {
  # gh command will fail, but we verify option parsing works
  run "${BIN_DIR}/github-get-project-field-id" -p "PVT_test" -f "status"
  assert_failure
  # Should not show "Must specify either" error
  if [[ "$output" == *"Must specify either"* ]]; then
    echo "Option -f was not recognized"
    return 1
  fi
}

@test "github-get-project-field-id: short option -V works" {
  # gh command will fail, but we verify option parsing works
  run "${BIN_DIR}/github-get-project-field-id" -p "PVT_test" -V
  assert_failure
  # Should not show "Must specify either" error
  if [[ "$output" == *"Must specify either"* ]]; then
    echo "Option -V was not recognized"
    return 1
  fi
}

@test "github-get-project-field-id: rejects unknown options" {
  run "${BIN_DIR}/github-get-project-field-id" --unknown-option
  assert_failure
  assert_output_contains "Unknown option"
}

@test "github-get-project-field-id: accepts table format" {
  # gh command will fail, but we verify format parsing works
  run "${BIN_DIR}/github-get-project-field-id" --project-id "PVT_test" --format table
  assert_failure
  # Should not show format error
  if [[ "$output" == *"Invalid format"* ]]; then
    echo "Format 'table' was not accepted"
    return 1
  fi
}

@test "github-get-project-field-id: accepts json format" {
  # gh command will fail, but we verify format parsing works
  run "${BIN_DIR}/github-get-project-field-id" --project-id "PVT_test" --format json
  assert_failure
  # Should not show format error
  if [[ "$output" == *"Invalid format"* ]]; then
    echo "Format 'json' was not accepted"
    return 1
  fi
}

@test "github-get-project-field-id: accepts id-only format" {
  # gh command will fail, but we verify format parsing works
  run "${BIN_DIR}/github-get-project-field-id" --project-id "PVT_test" --format id-only
  assert_failure
  # Should not show format error
  if [[ "$output" == *"Invalid format"* ]]; then
    echo "Format 'id-only' was not accepted"
    return 1
  fi
}
