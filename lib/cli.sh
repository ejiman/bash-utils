#!/usr/bin/env bash

# ========= Default values =========
: "${CLI_NAME:=$(basename "$0")}"
: "${CLI_VERSION:=0.1.0}"
: "${CLI_DESCRIPTION:=No description provided}"
: "${CLI_USAGE:=$CLI_NAME [options]}"

# ========= Show help =========
show_help() {
  cat << EOF
$CLI_NAME - $CLI_DESCRIPTION

Usage:
  $CLI_USAGE

Options:
  -h, --help       Show this help and exit
  -v, --version    Show version information and exit
EOF
}

# ========= Show version =========
show_version() {
  echo "$CLI_NAME version $CLI_VERSION"
}

# ========= Handle common options =========
handle_common_options() {
  for arg in "$@"; do
    case "$arg" in
      -h | --help)
        show_help
        exit 0
        ;;
      -v | --version)
        show_version
        exit 0
        ;;
    esac
  done
}
