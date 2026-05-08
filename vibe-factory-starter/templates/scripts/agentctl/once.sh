#!/usr/bin/env bash
# once.sh — run ONE iteration of the AFK agent loop
# Start here. Run manually, watch what happens, tune the prompt.
# Once you trust it, graduate to afk-loop.sh.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# 1. Gather all issue files
ISSUES=""
if compgen -G "issues/*.md" > /dev/null; then
  for file in issues/*.md; do
    CONTENT=$(cat "$file")
    ISSUES="${ISSUES}
---
File: $file
$CONTENT"
  done
else
  echo "No tickets in issues/. Generate them with the prd-and-kanban skill first."
  exit 1
fi

# 2. Gather git context
LAST_COMMITS=$(git log --oneline -10 || echo "no commits yet")
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# 3. Read the AFK implementer prompt
AFK_PROMPT=$(cat .agents/prompts/afk-implementer.md)

# 4. Build the full prompt
FULL_PROMPT="
${AFK_PROMPT}

## Current state

Branch: ${CURRENT_BRANCH}

Last 10 commits:
${LAST_COMMITS}

## Tickets in issues/

${ISSUES}

## Reports already written

$(ls .agents/reports/ 2>/dev/null || echo '(none yet)')
"

# 5. Choose your driver. Default: codex exec.
# Override with VIBE_DRIVER=claude or VIBE_DRIVER=antigravity
DRIVER="${VIBE_DRIVER:-codex}"

case "$DRIVER" in
  codex)
    if ! command -v codex >/dev/null 2>&1; then
      echo "codex CLI not found. Install: npm install -g @openai/codex"
      exit 1
    fi
    echo "$FULL_PROMPT" | codex exec --cd "$REPO_ROOT" -
    ;;
  claude)
    if ! command -v claude >/dev/null 2>&1; then
      echo "claude CLI not found."
      exit 1
    fi
    claude --permission accept-edits -p "$FULL_PROMPT"
    ;;
  *)
    echo "Unknown VIBE_DRIVER: $DRIVER"
    echo "Supported: codex, claude"
    exit 1
    ;;
esac

echo ""
echo "Iteration complete. Review:"
echo "  - git status / git log"
echo "  - .agents/reports/"
echo "  - run ./scripts/agentctl/verify.sh to confirm"
