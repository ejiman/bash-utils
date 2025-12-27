#!/usr/bin/env bats

# ========= Load test helper =========
load test_helper

# ========= Setup =========
setup() {
  load_lib "bootstrap.sh"
}

# ========= Tests for bootstrap.sh =========

@test "LIB_DIR variable is set" {
  [[ -n "$LIB_DIR" ]] || return 1
  [[ -d "$LIB_DIR" ]] || return 1
}

@test "bootstrap.sh loads all required library files" {
  # Check that all library files are sourced
  [[ -f "$LIB_DIR/log.sh" ]] || return 1
  [[ -f "$LIB_DIR/os.sh" ]] || return 1
  [[ -f "$LIB_DIR/utils.sh" ]] || return 1
  [[ -f "$LIB_DIR/cli.sh" ]] || return 1
  [[ -f "$LIB_DIR/argparse.sh" ]] || return 1
}

@test "bootstrap.sh makes log functions available" {
  # Check that log functions are defined
  declare -f log_info >/dev/null || return 1
  declare -f log_warn >/dev/null || return 1
  declare -f log_error >/dev/null || return 1
  declare -f die >/dev/null || return 1
}

@test "bootstrap.sh makes utils functions available" {
  # Check that utils functions are defined
  declare -f require_cmd >/dev/null || return 1
  declare -f is_interactive >/dev/null || return 1
}

@test "bootstrap.sh makes argparse functions available" {
  # Check that argparse functions are defined
  declare -f arg_flag >/dev/null || return 1
  declare -f arg_value >/dev/null || return 1
  declare -f arg_value_required >/dev/null || return 1
  declare -f parse_args >/dev/null || return 1
}

@test "bootstrap.sh makes cli functions available" {
  # Check that cli functions are defined
  declare -f show_help >/dev/null || return 1
}

# ========= Tests for utils.sh =========

@test "require_cmd: succeeds for existing command" {
  run require_cmd "bash"
  assert_success
}

@test "require_cmd: fails for non-existent command" {
  run require_cmd "nonexistent-command-12345"
  assert_failure
  assert_output_contains "Command not found: nonexistent-command-12345"
}

@test "is_interactive: detects non-interactive environment" {
  run is_interactive
  # In test environment, should be non-interactive
  assert_failure
}

# ========= Tests for log.sh =========

@test "log_info: outputs info message" {
  run log_info "Test message"
  assert_success
  assert_output_contains "[INFO]"
  assert_output_contains "Test message"
}

@test "log_warn: outputs warning message" {
  run log_warn "Warning message"
  assert_success
  assert_output_contains "[WARN]"
  assert_output_contains "Warning message"
}

@test "log_error: outputs error message to stderr" {
  run log_error "Error message"
  assert_success
  assert_output_contains "[ERROR]"
  assert_output_contains "Error message"
}

@test "die: outputs error and exits with status 1" {
  run die "Fatal error"
  [[ $status -eq 1 ]] || return 1
  assert_output_contains "[ERROR]"
  assert_output_contains "Fatal error"
}

# ========= Tests for os.sh =========

@test "OS variable is set" {
  [[ -n "$OS" ]] || return 1
  [[ "$OS" == "linux" || "$OS" == "macos" ]] || return 1
}

@test "SED variable is set correctly" {
  [[ -n "$SED" ]] || return 1
  if [[ "$OS" == "macos" ]]; then
    [[ "$SED" == "gsed" ]] || return 1
  else
    [[ "$SED" == "sed" ]] || return 1
  fi
}

@test "DATE variable is set correctly" {
  [[ -n "$DATE" ]] || return 1
  if [[ "$OS" == "macos" ]]; then
    [[ "$DATE" == "gdate" ]] || return 1
  else
    [[ "$DATE" == "date" ]] || return 1
  fi
}

# ========= Tests for argparse.sh =========

# Helper to reset argparse state
setup_argparse() {
  ARGS=()
  POSITIONAL=()
  CLI_NAME="test-tool"
  CLI_VERSION="1.0.0"
  CLI_DESCRIPTION="Test tool description"
  CLI_USAGE="test-tool [options]"

  # Define show_version function for argparse
  show_version() {
    echo "$CLI_NAME version $CLI_VERSION"
  }
}

@test "argparse: arg_flag defines a flag argument" {
  setup_argparse
  arg_flag VERBOSE -V --verbose "Enable verbose mode"
  [[ ${#ARGS[@]} -eq 1 ]] || return 1
  [[ "${ARGS[0]}" =~ ^flag\| ]] || return 1
}

@test "argparse: arg_value defines an optional value argument" {
  setup_argparse
  arg_value OUTPUT -o --output "Output file" "FILE"
  [[ ${#ARGS[@]} -eq 1 ]] || return 1
  [[ "${ARGS[0]}" =~ ^value\|.*\|optional$ ]] || return 1
}

@test "argparse: arg_value_required defines a required value argument" {
  setup_argparse
  arg_value_required INPUT -i --input "Input file" "FILE"
  [[ ${#ARGS[@]} -eq 1 ]] || return 1
  [[ "${ARGS[0]}" =~ ^value\|.*\|required$ ]] || return 1
}

@test "argparse: parse_args handles long flag option" {
  setup_argparse
  arg_flag VERBOSE -V --verbose "Enable verbose mode"
  parse_args --verbose
  [[ "$VERBOSE" == "true" ]] || return 1
}

@test "argparse: parse_args handles short flag option" {
  setup_argparse
  arg_flag VERBOSE -V --verbose "Enable verbose mode"
  parse_args -V
  [[ "$VERBOSE" == "true" ]] || return 1
}

@test "argparse: parse_args handles long value option" {
  setup_argparse
  arg_value OUTPUT -o --output "Output file" "FILE"
  parse_args --output test.txt
  [[ "$OUTPUT" == "test.txt" ]] || return 1
}

@test "argparse: parse_args handles short value option" {
  setup_argparse
  arg_value OUTPUT -o --output "Output file" "FILE"
  parse_args -o test.txt
  [[ "$OUTPUT" == "test.txt" ]] || return 1
}

@test "argparse: parse_args collects positional arguments" {
  setup_argparse
  arg_flag VERBOSE -V --verbose "Enable verbose mode"
  parse_args -V arg1 arg2 arg3
  [[ ${#POSITIONAL[@]} -eq 3 ]] || return 1
  [[ "${POSITIONAL[0]}" == "arg1" ]] || return 1
  [[ "${POSITIONAL[1]}" == "arg2" ]] || return 1
  [[ "${POSITIONAL[2]}" == "arg3" ]] || return 1
}

@test "argparse: parse_args fails on missing required argument" {
  setup_argparse
  arg_value_required INPUT -i --input "Input file" "FILE"
  run parse_args
  assert_failure
  assert_output_contains "Required option missing"
}

@test "argparse: parse_args fails on missing value for option" {
  setup_argparse
  arg_value OUTPUT -o --output "Output file" "FILE"
  run parse_args -o
  assert_failure
  assert_output_contains "requires"
}

@test "argparse: parse_args fails on unknown long option" {
  setup_argparse
  arg_flag VERBOSE -V --verbose "Enable verbose mode"
  run parse_args --unknown
  assert_failure
  assert_output_contains "Unknown option"
}

@test "argparse: parse_args fails on unknown short option" {
  setup_argparse
  arg_flag VERBOSE -V --verbose "Enable verbose mode"
  run parse_args -x
  assert_failure
  assert_output_contains "Unknown option"
}

@test "argparse: parse_args handles mixed options and positional args" {
  setup_argparse
  arg_flag VERBOSE -V --verbose "Enable verbose mode"
  arg_value OUTPUT -o --output "Output file" "FILE"
  parse_args -V --output result.txt file1 file2
  [[ "$VERBOSE" == "true" ]] || return 1
  [[ "$OUTPUT" == "result.txt" ]] || return 1
  [[ ${#POSITIONAL[@]} -eq 2 ]] || return 1
  [[ "${POSITIONAL[0]}" == "file1" ]] || return 1
  [[ "${POSITIONAL[1]}" == "file2" ]] || return 1
}

# ========= Tests for cli.sh =========

# Helper to setup CLI variables
setup_cli() {
  CLI_NAME="test-tool"
  CLI_VERSION="1.0.0"
  CLI_DESCRIPTION="Test tool description"
  CLI_USAGE="test-tool [options] <args>"
}

@test "cli: show_help outputs help message" {
  setup_cli
  run show_help
  assert_success
  assert_output_contains "$CLI_NAME"
  assert_output_contains "$CLI_DESCRIPTION"
  assert_output_contains "Usage:"
  assert_output_contains "$CLI_USAGE"
  assert_output_contains "Options:"
  assert_output_contains "--help"
  assert_output_contains "--version"
}

@test "cli: show_version outputs version information" {
  setup_cli
  run show_version
  assert_success
  assert_output_contains "$CLI_NAME"
  assert_output_contains "version"
  assert_output_contains "$CLI_VERSION"
}

@test "cli: handle_common_options exits on -h" {
  setup_cli
  run handle_common_options -h
  assert_success
  assert_output_contains "Usage:"
}

@test "cli: handle_common_options exits on --help" {
  setup_cli
  run handle_common_options --help
  assert_success
  assert_output_contains "Usage:"
}

@test "cli: handle_common_options exits on -v" {
  setup_cli
  run handle_common_options -v
  assert_success
  assert_output_contains "version"
}

@test "cli: handle_common_options exits on --version" {
  setup_cli
  run handle_common_options --version
  assert_success
  assert_output_contains "version"
}

@test "cli: handle_common_options does not exit on other arguments" {
  setup_cli
  # This should return without output
  run handle_common_options -x --other
  assert_success
  [[ -z "$output" ]] || return 1
}
