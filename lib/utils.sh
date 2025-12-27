#!/usr/bin/env bash

require_cmd() {
  command -v "$1" > /dev/null 2>&1 || die "Command not found: $1"
}

is_interactive() {
  [[ -t 1 ]]
}
