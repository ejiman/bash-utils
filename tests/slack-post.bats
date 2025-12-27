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

@test "slack-post: --help shows usage" {
  run "${BIN_DIR}/slack-post" --help
  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "slack-post"
  assert_output_contains "Environment Variables:"
  assert_output_contains "SLACK_WEBHOOK_URL"
}

@test "slack-post: --version shows version" {
  run "${BIN_DIR}/slack-post" --version
  assert_success
  assert_output_contains "version"
}

@test "slack-post: fails without message argument" {
  run "${BIN_DIR}/slack-post"
  assert_failure
  assert_output_contains "Message is required"
}

@test "slack-post: fails without webhook or token" {
  run "${BIN_DIR}/slack-post" "Test message"
  assert_failure
  assert_output_contains "Either --webhook URL or --token TOKEN must be specified"
}

@test "slack-post: fails when using token without channel" {
  run "${BIN_DIR}/slack-post" --token "xoxb-test-token" "Test message"
  assert_failure
  assert_output_contains "The --channel option is required when using --token"
}

@test "slack-post: short option -w works" {
  # This will fail at curl stage, but we can verify option parsing works
  run "${BIN_DIR}/slack-post" -w "https://example.com/webhook" "Test"
  # Should fail at curl, but not at argument parsing
  assert_failure
  # If it shows "Either --webhook" error, option parsing failed
  if [[ "$output" == *"Either --webhook"* ]]; then
    echo "Option -w was not recognized"
    return 1
  fi
}

@test "slack-post: short option -t works" {
  # This will fail because no channel is specified
  run "${BIN_DIR}/slack-post" -t "xoxb-test" "Test"
  assert_failure
  assert_output_contains "The --channel option is required"
}

@test "slack-post: short option -c works" {
  run "${BIN_DIR}/slack-post" -t "xoxb-test" -c "C12345" "Test"
  # Should fail at curl, but not at argument parsing
  assert_failure
  # If it shows channel error, option parsing failed
  if [[ "$output" == *"channel option is required"* ]]; then
    echo "Option -c was not recognized"
    return 1
  fi
}

@test "slack-post: accepts SLACK_WEBHOOK_URL environment variable" {
  SLACK_WEBHOOK_URL="https://example.com/webhook" run "${BIN_DIR}/slack-post" "Test"
  # Should fail at curl, but not at argument parsing
  assert_failure
  # Should not show "Either --webhook" error
  if [[ "$output" == *"Either --webhook"* ]]; then
    echo "SLACK_WEBHOOK_URL environment variable was not recognized"
    return 1
  fi
}

@test "slack-post: accepts SLACK_BOT_TOKEN and SLACK_CHANNEL environment variables" {
  SLACK_BOT_TOKEN="xoxb-test" SLACK_CHANNEL="C12345" run "${BIN_DIR}/slack-post" "Test"
  # Should fail at curl, but not at argument parsing
  assert_failure
  # Should not show channel or webhook requirement errors
  if [[ "$output" == *"Either --webhook"* ]] || [[ "$output" == *"channel option is required"* ]]; then
    echo "Environment variables were not recognized"
    return 1
  fi
}

@test "slack-post: command-line options override environment variables" {
  # Set env var to webhook, but use token in command line
  SLACK_WEBHOOK_URL="https://example.com/webhook" run "${BIN_DIR}/slack-post" --token "xoxb-test" "Test"
  # Should fail asking for channel (meaning it's using token, not webhook)
  assert_failure
  assert_output_contains "The --channel option is required"
}

@test "slack-post: rejects unknown options" {
  run "${BIN_DIR}/slack-post" --unknown-option "Test"
  assert_failure
  assert_output_contains "Unknown option"
}

@test "slack-post: handles messages with spaces" {
  SLACK_WEBHOOK_URL="https://example.com/webhook" run "${BIN_DIR}/slack-post" "Hello World with spaces"
  # Should fail at curl, but message should be accepted
  assert_failure
  # Should not show "Message is required" error
  if [[ "$output" == *"Message is required"* ]]; then
    echo "Message with spaces was not parsed correctly"
    return 1
  fi
}

@test "slack-post: handles messages with special characters" {
  SLACK_WEBHOOK_URL="https://example.com/webhook" run "${BIN_DIR}/slack-post" 'Message with "quotes" and $variables'
  # Should fail at curl, but message should be accepted
  assert_failure
  # Should not show "Message is required" error
  if [[ "$output" == *"Message is required"* ]]; then
    echo "Message with special characters was not parsed correctly"
    return 1
  fi
}
