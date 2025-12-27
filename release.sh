#!/usr/bin/env bash
set -euo pipefail

# ========= Configuration =========
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ========= Colored logging =========
info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }
die() {
  error "$*"
  exit 1
}

# ========= Check git status =========
if ! git diff-index --quiet HEAD --; then
  die "Working directory has uncommitted changes. Please commit or stash them first."
fi

# ========= Get current version =========
CURRENT_VERSION=$(git describe --tags --abbrev=0 2> /dev/null || echo "v0.0.0")
info "Current version: $CURRENT_VERSION"

# ========= Parse version =========
if [[ ! "$CURRENT_VERSION" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  die "Invalid version format: $CURRENT_VERSION (expected: vX.Y.Z)"
fi

MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"

# ========= Calculate next versions =========
NEXT_MAJOR="v$((MAJOR + 1)).0.0"
NEXT_MINOR="v${MAJOR}.$((MINOR + 1)).0"
NEXT_PATCH="v${MAJOR}.${MINOR}.$((PATCH + 1))"

# ========= Ask for version type =========
echo
echo "Select version bump type:"
echo "  1) Patch: $NEXT_PATCH (bug fixes)"
echo "  2) Minor: $NEXT_MINOR (new features, backward compatible)"
echo "  3) Major: $NEXT_MAJOR (breaking changes)"
echo "  4) Custom version"
echo
read -rp "Choice [1-4]: " choice

case "$choice" in
  1) NEW_VERSION="$NEXT_PATCH" ;;
  2) NEW_VERSION="$NEXT_MINOR" ;;
  3) NEW_VERSION="$NEXT_MAJOR" ;;
  4)
    read -rp "Enter version (e.g., v1.2.3): " NEW_VERSION
    if [[ ! "$NEW_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      die "Invalid version format: $NEW_VERSION (expected: vX.Y.Z)"
    fi
    ;;
  *)
    die "Invalid choice"
    ;;
esac

# ========= Confirm =========
echo
read -rp "Create release $NEW_VERSION? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  info "Release cancelled"
  exit 0
fi

# ========= Create tag =========
info "Creating tag: $NEW_VERSION"
git tag -a "$NEW_VERSION" -m "Release $NEW_VERSION"

# ========= Show instructions =========
echo
info "Tag created successfully!"
echo
echo "To push the tag and trigger the release workflow:"
echo "  git push origin $NEW_VERSION"
echo
echo "To delete the tag if you made a mistake:"
echo "  git tag -d $NEW_VERSION"
