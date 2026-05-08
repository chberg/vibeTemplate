#!/usr/bin/env bash
# spawn_worktree.sh — create an isolated git worktree for a ticket
# Usage: ./scripts/agentctl/spawn_worktree.sh <ticket-id>
# Example: ./scripts/agentctl/spawn_worktree.sh 001-policy-catalog

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <ticket-id>"
  exit 1
fi

TICKET_ID="$1"
REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_NAME="$(basename "$REPO_ROOT")"
WORKTREE_ROOT="$REPO_ROOT/../worktrees-$REPO_NAME"
BRANCH="agent/${TICKET_ID}"
WT="$WORKTREE_ROOT/${TICKET_ID}"

mkdir -p "$WORKTREE_ROOT"

if git worktree list | grep -q "$WT"; then
  echo "Worktree already exists at $WT"
  echo "cd $WT"
  exit 0
fi

git worktree add "$WT" -b "$BRANCH"

# Sanity: copy the ticket into the worktree's .agents/queue/ for in-context reading
TICKET_FILE="issues/${TICKET_ID}.md"
if [ -f "$REPO_ROOT/$TICKET_FILE" ]; then
  echo "Ticket: $TICKET_FILE"
fi

echo ""
echo "Worktree ready:"
echo "  cd $WT"
echo "  # then run codex / claude / antigravity scoped to this directory"
