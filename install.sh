#!/usr/bin/env bash
set -euo pipefail

# ========= Configuration =========
INSTALL_PREFIX="${INSTALL_PREFIX:-${HOME}/.local}"
INSTALL_ROOT="${INSTALL_PREFIX}/share/bash-utils"
INSTALL_BIN_DIR="${INSTALL_PREFIX}/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# ========= Check required directories =========
if [[ ! -d "${SCRIPT_DIR}/bin" ]]; then
  error "bin directory not found: ${SCRIPT_DIR}/bin"
  exit 1
fi

if [[ ! -d "${SCRIPT_DIR}/lib" ]]; then
  error "lib directory not found: ${SCRIPT_DIR}/lib"
  exit 1
fi

if [[ ! -d "${SCRIPT_DIR}/docs" ]]; then
  error "docs directory not found: ${SCRIPT_DIR}/docs"
  exit 1
fi

# ========= Create installation directories =========
info "Installing to: $INSTALL_ROOT"
mkdir -p "$INSTALL_ROOT"
mkdir -p "$INSTALL_BIN_DIR"

# ========= Copy project files =========
info "Copying project files..."
cp -r "${SCRIPT_DIR}/bin" "${SCRIPT_DIR}/lib" "${SCRIPT_DIR}/docs" "$INSTALL_ROOT/"
info "Project files copied"

# ========= Create symlinks in bin directory =========
info "Creating symbolic links..."
for file in "$INSTALL_ROOT/bin"/*; do
  [[ -f "$file" ]] || continue

  name="$(basename "$file")"
  target="$INSTALL_BIN_DIR/$name"

  if [[ -e "$target" ]] || [[ -L "$target" ]]; then
    read -rp "Overwrite existing $name? [y/N] " ans
    if [[ ! "$ans" =~ ^[Yy]$ ]]; then
      warn "Skipped: $name"
      continue
    fi
    rm -f "$target"
  fi

  ln -s "$file" "$target"
  info "Linked: $name -> $file"
done

# ========= Verify PATH =========
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_BIN_DIR"; then
  warn "$INSTALL_BIN_DIR is not in your PATH."
  echo
  echo "Add the following line to your shell config (~/.bashrc, ~/.zshrc, etc):"
  echo
  echo "  export PATH=\"\$PATH:$INSTALL_BIN_DIR\""
  echo
fi

info "Installation completed 🎉"
echo
echo "Installed to:"
echo "  Root: $INSTALL_ROOT"
echo "  Binaries: $INSTALL_BIN_DIR"
