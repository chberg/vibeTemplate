#!/usr/bin/env bash
# afk-loop.sh — automated AFK agent loop, bounded and sandboxed
# Loops once.sh until NO_MORE_TASKS, hard stop, or MAX_ITERATIONS.
#
# IMPORTANT: Only run this in a Docker sandbox or after extensive testing of once.sh.
# The agent has --permission accept-edits.

set -euo pipefail

MAX_ITERATIONS="${MAX_ITERATIONS:-20}"
SLEEP_BETWEEN="${SLEEP_BETWEEN:-5}"
ITERATION=0

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

mkdir -p .agents/logs

LOG_FILE=".agents/logs/afk-loop-$(date +%Y%m%d-%H%M%S).log"

echo "Starting AFK loop. Max iterations: $MAX_ITERATIONS. Log: $LOG_FILE"

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
  ITERATION=$((ITERATION + 1))
  echo ""
  echo "=== Iteration $ITERATION / $MAX_ITERATIONS ===" | tee -a "$LOG_FILE"

  # Capture iteration output
  set +e
  OUTPUT=$(./scripts/agentctl/once.sh 2>&1)
  EXIT_CODE=$?
  set -e
  echo "$OUTPUT" | tee -a "$LOG_FILE"

  # Termination signals
  if echo "$OUTPUT" | grep -q "NO_MORE_TASKS"; then
    echo "All AFK tasks complete." | tee -a "$LOG_FILE"
    exit 0
  fi

  if echo "$OUTPUT" | grep -q "BLOCKED:"; then
    echo "Hard stop signal received. Manual review needed." | tee -a "$LOG_FILE"
    exit 2
  fi

  if [ $EXIT_CODE -ne 0 ]; then
    echo "once.sh exited non-zero. Stopping." | tee -a "$LOG_FILE"
    exit 3
  fi

  # Sanity: was a commit made this iteration?
  if [ "$ITERATION" -gt 1 ]; then
    LAST_COMMIT_AGE=$(git log -1 --format=%ct)
    NOW=$(date +%s)
    AGE=$((NOW - LAST_COMMIT_AGE))
    if [ $AGE -gt 600 ]; then
      echo "No commit in last 10 min. Agent may be stuck. Stopping." | tee -a "$LOG_FILE"
      exit 4
    fi
  fi

  echo "Iteration $ITERATION complete. Sleeping $SLEEP_BETWEEN s..." | tee -a "$LOG_FILE"
  sleep "$SLEEP_BETWEEN"
done

echo "Reached max iterations ($MAX_ITERATIONS). Manual review needed." | tee -a "$LOG_FILE"
exit 1
