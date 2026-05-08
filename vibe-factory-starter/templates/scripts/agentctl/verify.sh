#!/usr/bin/env bash
# verify.sh — the single source of truth for "done"
# Every agent role, /goal, AFK iteration, and CI job calls this exact script.
# If it doesn't print VERIFY OK, the work is not done.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "== format =="
if command -v ruff >/dev/null 2>&1; then
  ruff format --check .
else
  echo "(ruff not installed, skipping format check)"
fi

echo "== lint =="
if command -v ruff >/dev/null 2>&1; then
  ruff check .
else
  echo "(ruff not installed, skipping lint)"
fi

echo "== types =="
if command -v mypy >/dev/null 2>&1 && [ -f pyproject.toml ]; then
  mypy . || { echo "mypy failed"; exit 1; }
else
  echo "(mypy not configured, skipping)"
fi

echo "== tests =="
if command -v pytest >/dev/null 2>&1 && [ -d tests ] && find tests -name 'test_*.py' -o -name '*_test.py' | grep -q .; then
  pytest -q --maxfail=1
else
  echo "(no pytest tests found, skipping)"
fi

echo "== policies =="
if command -v opa >/dev/null 2>&1 && [ -d policy ] && ls policy/*.rego >/dev/null 2>&1; then
  opa test policy/
else
  echo "(no OPA policies to test, skipping)"
fi

echo "== e2e =="
if [ -d "tests/e2e" ] && command -v npx >/dev/null 2>&1; then
  npx playwright test
else
  echo "(no e2e tests, skipping)"
fi

echo ""
echo "VERIFY OK"
