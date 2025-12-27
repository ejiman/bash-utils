#!/usr/bin/env bash

# ========= OS detection =========
case "$(uname -s)" in
  Linux*) OS="linux" ;;
  Darwin*) OS="macos" ;;
  *)
    echo "[ERROR] Unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac

export OS

# ========= Load libraries =========
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=log.sh
source "$LIB_DIR/log.sh"
# shellcheck source=os.sh
source "$LIB_DIR/os.sh"
# shellcheck source=utils.sh
source "$LIB_DIR/utils.sh"
# shellcheck source=cli.sh
source "$LIB_DIR/cli.sh"
# shellcheck source=argparse.sh
source "$LIB_DIR/argparse.sh"
