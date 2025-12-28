#!/usr/bin/env bash
set -euo pipefail

# ========= Configuration =========
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="bash-utils"

# ========= Colored logging =========
info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }
die() {
  error "$*"
  exit 1
}

# ========= Version detection =========
# Try to get version from git tag, fallback to "dev"
if git describe --tags --exact-match 2> /dev/null; then
  VERSION="$(git describe --tags --exact-match)"
else
  VERSION="dev-$(git rev-parse --short HEAD 2> /dev/null || echo 'unknown')"
fi

info "Packaging $PROJECT_NAME version: $VERSION"

# ========= Prepare package directory =========
PACKAGE_DIR="${PROJECT_NAME}-${VERSION}"
TARBALL="${PACKAGE_DIR}.tar.gz"

info "Creating package directory: $PACKAGE_DIR"
rm -rf "$PACKAGE_DIR" "$TARBALL"
mkdir -p "$PACKAGE_DIR"

# ========= Copy files =========
info "Copying project files..."

# Essential directories
cp -r bin lib docs "$PACKAGE_DIR/"

# Essential files
cp install.sh uninstall.sh README.md LICENSE "$PACKAGE_DIR/" 2> /dev/null || {
  warn "LICENSE file not found, skipping"
  cp install.sh uninstall.sh README.md "$PACKAGE_DIR/"
}

# Optional files
[[ -f .shellcheckrc ]] && cp .shellcheckrc "$PACKAGE_DIR/"
[[ -f Makefile ]] && cp Makefile "$PACKAGE_DIR/"

# ========= Create tarball =========
info "Creating tarball: $TARBALL"
tar -czf "$TARBALL" "$PACKAGE_DIR"

# ========= Cleanup =========
rm -rf "$PACKAGE_DIR"

# ========= Summary =========
TARBALL_SIZE=$(du -h "$TARBALL" | cut -f1)
info "Package created successfully!"
echo
echo "  File: $TARBALL"
echo "  Size: $TARBALL_SIZE"
echo "  SHA256: $(sha256sum "$TARBALL" | cut -d' ' -f1)"
echo
echo "To test the package:"
echo "  tar -xzf $TARBALL"
echo "  cd $PACKAGE_DIR"
echo "  ./install.sh"
