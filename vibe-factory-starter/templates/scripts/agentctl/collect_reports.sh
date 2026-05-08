#!/usr/bin/env bash
# collect_reports.sh — roll up all reports into one human-review doc
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

OUT=".agents/state/rollup-$(date +%Y%m%d-%H%M%S).md"
mkdir -p .agents/state

{
  echo "# Report rollup — $(date)"
  echo ""
  echo "## Branch"
  git rev-parse --abbrev-ref HEAD
  echo ""
  echo "## Recent commits"
  echo '```'
  git log --oneline -20
  echo '```'
  echo ""
  echo "## Reports"
  echo ""
  for f in .agents/reports/*.md; do
    [ -f "$f" ] || continue
    echo "---"
    echo ""
    echo "### $(basename "$f")"
    echo ""
    cat "$f"
    echo ""
  done
} > "$OUT"

echo "Wrote $OUT"
echo ""
echo "Open this file to review what the AFK loop has done."
