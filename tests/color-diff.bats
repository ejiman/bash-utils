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

@test "color-diff: --help shows usage" {
  run "${BIN_DIR}/color-diff" --help
  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "color-diff"
}

@test "color-diff: --version shows version" {
  run "${BIN_DIR}/color-diff" --version
  assert_success
  assert_output_contains "version"
}

@test "color-diff: fails without arguments" {
  run "${BIN_DIR}/color-diff"
  assert_failure
  assert_output_contains "Expected exactly 2 files"
}

@test "color-diff: fails with only one argument" {
  echo "test" > "$TEST_TEMP_DIR/file1.txt"
  run "${BIN_DIR}/color-diff" "$TEST_TEMP_DIR/file1.txt"
  assert_failure
  assert_output_contains "Expected exactly 2 files"
}

@test "color-diff: fails when first file does not exist" {
  echo "test" > "$TEST_TEMP_DIR/file2.txt"
  run "${BIN_DIR}/color-diff" "$TEST_TEMP_DIR/nonexistent.txt" "$TEST_TEMP_DIR/file2.txt"
  assert_failure
  assert_output_contains "File not found"
}

@test "color-diff: fails when second file does not exist" {
  echo "test" > "$TEST_TEMP_DIR/file1.txt"
  run "${BIN_DIR}/color-diff" "$TEST_TEMP_DIR/file1.txt" "$TEST_TEMP_DIR/nonexistent.txt"
  assert_failure
  assert_output_contains "File not found"
}

@test "color-diff: shows no differences for identical files" {
  echo "line 1" > "$TEST_TEMP_DIR/file1.txt"
  echo "line 1" > "$TEST_TEMP_DIR/file2.txt"

  run "${BIN_DIR}/color-diff" "$TEST_TEMP_DIR/file1.txt" "$TEST_TEMP_DIR/file2.txt"
  assert_success
  assert_output_contains "Files are identical"
}

@test "color-diff: shows differences between different files" {
  cat > "$TEST_TEMP_DIR/file1.txt" <<EOF
line 1
line 2
line 3
EOF

  cat > "$TEST_TEMP_DIR/file2.txt" <<EOF
line 1
line 2 modified
line 3
EOF

  run "${BIN_DIR}/color-diff" "$TEST_TEMP_DIR/file1.txt" "$TEST_TEMP_DIR/file2.txt"
  assert_failure  # diff returns 1 when files differ
  assert_output_contains "line 2"
}

@test "color-diff: --json sorts JSON keys before comparing" {
  # Skip if jq is not installed
  if ! command -v jq &>/dev/null; then
    skip "jq is not installed"
  fi

  cat > "$TEST_TEMP_DIR/json1.json" <<EOF
{
  "name": "Alice",
  "age": 30,
  "city": "Tokyo"
}
EOF

  cat > "$TEST_TEMP_DIR/json2.json" <<EOF
{
  "city": "Tokyo",
  "name": "Alice",
  "age": 31
}
EOF

  run "${BIN_DIR}/color-diff" --json "$TEST_TEMP_DIR/json1.json" "$TEST_TEMP_DIR/json2.json"
  assert_failure  # Files differ (age is different)
  assert_output_contains "age"
  assert_output_contains "30"
  assert_output_contains "31"
}

@test "color-diff: --json fails with invalid JSON" {
  # Skip if jq is not installed
  if ! command -v jq &>/dev/null; then
    skip "jq is not installed"
  fi

  echo "invalid json" > "$TEST_TEMP_DIR/invalid.json"
  echo "{}" > "$TEST_TEMP_DIR/valid.json"

  run "${BIN_DIR}/color-diff" --json "$TEST_TEMP_DIR/invalid.json" "$TEST_TEMP_DIR/valid.json"
  assert_failure
  assert_output_contains "Failed to parse"
}

@test "color-diff: --json recognizes identical JSON with different key order" {
  # Skip if jq is not installed
  if ! command -v jq &>/dev/null; then
    skip "jq is not installed"
  fi

  cat > "$TEST_TEMP_DIR/json1.json" <<EOF
{
  "name": "Alice",
  "age": 30,
  "city": "Tokyo"
}
EOF

  cat > "$TEST_TEMP_DIR/json2.json" <<EOF
{
  "city": "Tokyo",
  "name": "Alice",
  "age": 30
}
EOF

  run "${BIN_DIR}/color-diff" --json "$TEST_TEMP_DIR/json1.json" "$TEST_TEMP_DIR/json2.json"
  assert_success
  assert_output_contains "Files are identical"
}

@test "color-diff: -j is alias for --json" {
  # Skip if jq is not installed
  if ! command -v jq &>/dev/null; then
    skip "jq is not installed"
  fi

  cat > "$TEST_TEMP_DIR/json1.json" <<EOF
{"b": 2, "a": 1}
EOF

  cat > "$TEST_TEMP_DIR/json2.json" <<EOF
{"a": 1, "b": 2}
EOF

  run "${BIN_DIR}/color-diff" -j "$TEST_TEMP_DIR/json1.json" "$TEST_TEMP_DIR/json2.json"
  assert_success
  assert_output_contains "Files are identical"
}

@test "color-diff: --context changes number of context lines" {
  cat > "$TEST_TEMP_DIR/file1.txt" <<EOF
line 1
line 2
line 3
line 4
line 5
line 6
line 7
EOF

  cat > "$TEST_TEMP_DIR/file2.txt" <<EOF
line 1
line 2
line 3 modified
line 4
line 5
line 6
line 7
EOF

  run "${BIN_DIR}/color-diff" --context 1 "$TEST_TEMP_DIR/file1.txt" "$TEST_TEMP_DIR/file2.txt"
  assert_failure  # Files differ
  # With context=1, should show 1 line before and after the change
  assert_output_contains "line 3"
}

@test "color-diff: unknown option is rejected" {
  echo "test" > "$TEST_TEMP_DIR/file1.txt"
  echo "test" > "$TEST_TEMP_DIR/file2.txt"

  run "${BIN_DIR}/color-diff" --unknown "$TEST_TEMP_DIR/file1.txt" "$TEST_TEMP_DIR/file2.txt"
  assert_failure
  assert_output_contains "Unknown option"
}
