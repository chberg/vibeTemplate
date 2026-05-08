#!/usr/bin/env bash
# status.sh — show what's running, what's done, what's next
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "=== Branch ==="
git rev-parse --abbrev-ref HEAD

echo ""
echo "=== Worktrees ==="
git worktree list

echo ""
echo "=== Tickets ==="
if compgen -G "issues/*.md" > /dev/null; then
  for f in issues/*.md; do
    TYPE=$(grep -m1 -E "^\*\*Type\*\*:" "$f" | sed 's/.*: *//' || echo "unknown")
    BLOCKED=$(grep -m1 -E "^\*\*Blocked by\*\*:" "$f" | sed 's/.*: *//' || echo "")
    REPORT=".agents/reports/$(basename "$f" .md).md"
    if [ -f "$REPORT" ]; then
      STATUS="DONE"
    else
      STATUS="OPEN"
    fi
    printf "  [%s] %-8s %s (blocked by: %s)\n" "$STATUS" "$TYPE" "$f" "$BLOCKED"
  done
else
  echo "  (no tickets in issues/)"
fi

echo ""
echo "=== Recent reports ==="
ls -lt .agents/reports/ 2>/dev/null | head -10 || echo "  (none)"

echo ""
echo "=== Last 5 commits ==="
git log --oneline -5
