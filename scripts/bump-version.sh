#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_DIR="${SCRIPT_DIR}/.."

show_usage() {
  echo "Usage: $0 <new_version> [--local]"
  echo ""
  echo "Examples:"
  echo "  $0 0.2.5          # Create tag and let CI handle version updates"
  echo "  $0 0.2.5 --local  # Update version locally (for testing)"
  echo ""
  echo "Release workflow:"
  echo "  1. Run: ./scripts/bump-version.sh 0.2.5"
  echo "  2. CI automatically updates pubspec.yaml"
  echo "  3. CI publishes to pub.dev and creates GitHub release"
  echo ""
  echo "The --local flag updates files locally without creating a tag."
  echo "Use this for local testing only."
}

if [[ $# -lt 1 ]]; then
  show_usage
  exit 1
fi

NEW_VERSION="$1"
LOCAL_MODE="${2:-}"

# Validate version format (semver)
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: Version must be in semver format (e.g., 0.2.5)"
  exit 1
fi

cd "$SDK_DIR"

if [[ "$LOCAL_MODE" == "--local" ]]; then
  echo "Updating version to $NEW_VERSION locally..."
  echo ""

  # Update pubspec.yaml
  echo "Updating pubspec.yaml..."
  sed -i '' "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml

  # Update CHANGELOG.md if version not present
  if ! grep -q "## $NEW_VERSION" CHANGELOG.md; then
    echo "Updating CHANGELOG.md..."
    sed -i '' "s/# Changelog/# Changelog\n\n## $NEW_VERSION\n- Release version $NEW_VERSION/" CHANGELOG.md
  fi

  echo ""
  echo "Version updated to $NEW_VERSION locally"
  echo ""
  echo "Note: This is for local testing only."
  echo "For releases, just create a tag and push it."
else
  echo "Creating release tag v$NEW_VERSION..."
  echo ""

  # Check if tag already exists
  if git rev-parse "v$NEW_VERSION" >/dev/null 2>&1; then
    echo "ERROR: Tag v$NEW_VERSION already exists!"
    echo "   Use a different version number."
    exit 1
  fi

  # Create and push tag
  git tag "v$NEW_VERSION"
  echo "Created tag v$NEW_VERSION"

  echo ""
  read -p "Push tag to trigger release? (y/N) " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push origin "v$NEW_VERSION"
    echo ""
    echo "Tag pushed! CI will now:"
    echo "   1. Update version in pubspec.yaml"
    echo "   2. Run tests"
    echo "   3. Publish to pub.dev"
    echo "   4. Create GitHub release"
    echo ""
    echo "Monitor progress at: https://github.com/mohn93/flutter_ulink_sdk/actions"
  else
    echo ""
    echo "Tag created locally. Push when ready:"
    echo "  git push origin v$NEW_VERSION"
  fi
fi
