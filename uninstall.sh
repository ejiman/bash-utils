#!/usr/bin/env bash
set -euo pipefail

# ========= Configuration =========
INSTALL_PREFIX="${INSTALL_PREFIX:-${HOME}/.local}"
INSTALL_ROOT="${INSTALL_PREFIX}/share/bash-utils"
INSTALL_BIN_DIR="${INSTALL_PREFIX}/bin"

# ========= Colored logging =========
info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

# ========= OS detection =========
case "$(uname -s)" in
  Linux*) OS="linux" ;;
  Darwin*) OS="macos" ;;
  *)
    error "Unsupported OS: $(uname -s)"
    exit 1
    ;;
esac

info "Detected OS: $OS"

# ========= Check if bash-utils is installed =========
if [[ ! -d "$INSTALL_ROOT" ]]; then
  error "bash-utils is not installed at: $INSTALL_ROOT"
  exit 1
fi

# ========= Collect symlinks to remove =========
SYMLINKS_TO_REMOVE=()
if [[ -d "${INSTALL_ROOT}/bin" ]]; then
  for file in "$INSTALL_ROOT/bin"/*; do
    [[ -f "$file" ]] || continue

    name="$(basename "$file")"
    link="$INSTALL_BIN_DIR/$name"

    # Check if symlink exists and points to our installation
    if [[ -L "$link" ]]; then
      target="$(readlink "$link")"
      if [[ "$target" == "$file" ]]; then
        SYMLINKS_TO_REMOVE+=("$link")
      fi
    fi
  done
fi

# ========= Display what will be removed =========
echo
echo "The following items will be removed:"
echo
echo "  Directory: $INSTALL_ROOT"
if [[ ${#SYMLINKS_TO_REMOVE[@]} -gt 0 ]]; then
  echo "  Symlinks:"
  for link in "${SYMLINKS_TO_REMOVE[@]}"; do
    echo "    - $(basename "$link")"
  done
else
  echo "  Symlinks: (none found)"
fi
echo

# ========= Confirm uninstallation =========
read -rp "Proceed with uninstallation? [y/N] " ans
if [[ ! "$ans" =~ ^[Yy]$ ]]; then
  warn "Uninstallation cancelled"
  exit 0
fi

# ========= Remove symlinks =========
if [[ ${#SYMLINKS_TO_REMOVE[@]} -gt 0 ]]; then
  info "Removing symbolic links..."
  for link in "${SYMLINKS_TO_REMOVE[@]}"; do
    rm -f "$link"
    info "Removed: $(basename "$link")"
  done
else
  info "No symlinks to remove"
fi

# ========= Remove installation directory =========
info "Removing installation directory..."
rm -rf "$INSTALL_ROOT"
info "Removed: $INSTALL_ROOT"

# ========= Success message =========
echo
info "Uninstallation completed 🎉"
echo
echo "bash-utils has been removed from your system."
echo
