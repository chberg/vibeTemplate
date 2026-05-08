#!/usr/bin/env bash
# vibe-init.sh — scaffold a new vibe-coded project from the starter templates.
#
# Usage:
#   ./vibe-init.sh <project-name> [target-parent-dir]
#
# Example:
#   ./vibe-init.sh lockix-platform ~/projects
#   # creates ~/projects/lockix-platform/ with the full factory scaffolding

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <project-name> [target-parent-dir]"
  exit 1
fi

PROJECT_NAME="$1"
TARGET_PARENT="${2:-$PWD}"
TARGET="$TARGET_PARENT/$PROJECT_NAME"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="$SCRIPT_DIR/templates"

if [ ! -d "$TEMPLATES" ]; then
  echo "Templates not found at $TEMPLATES"
  exit 1
fi

if [ -e "$TARGET" ]; then
  echo "Target already exists: $TARGET"
  exit 1
fi

echo "==> Creating $TARGET"
mkdir -p "$TARGET"

echo "==> Copying templates"
# -a preserves perms; we copy hidden files explicitly via dotglob
( cd "$TEMPLATES" && shopt -s dotglob && cp -a . "$TARGET"/ )

echo "==> Substituting placeholders"
# Replace PROJECT_NAME_PLACEHOLDER in pyproject.toml and README.md
if command -v sed >/dev/null 2>&1; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_NAME/g" "$TARGET/pyproject.toml" "$TARGET/README.md"
  else
    sed -i "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_NAME/g" "$TARGET/pyproject.toml" "$TARGET/README.md"
  fi
fi

echo "==> Making scripts executable"
chmod +x "$TARGET/scripts/agentctl/"*.sh

echo "==> Initializing git"
cd "$TARGET"
git init -q
git checkout -q -b main
git add -A
git -c user.email="vibe@local" -c user.name="vibe-init" commit -q -m "chore: vibe factory scaffold"

echo ""
echo "Done. Next steps:"
echo ""
echo "  cd $TARGET"
echo "  cp .env.example .env   # fill in your API keys"
echo "  ./scripts/agentctl/verify.sh   # confirm toolchain"
echo "  ./scripts/agentctl/once.sh     # run the example ticket"
echo ""
echo "When ready for real work:"
echo "  1. Open Antigravity (or Codex) on this directory."
echo "  2. /clear"
echo "  3. Load .skills/grill-me/SKILL.md and start your first session."
