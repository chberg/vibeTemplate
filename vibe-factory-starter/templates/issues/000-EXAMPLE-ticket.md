# 000 — EXAMPLE: Hello World vertical slice

**Type**: AFK
**Blocked by**: None

## Description

Add a tiny hello-world function that proves the factory works end-to-end. This is the first ticket the AFK loop should run against any new repo to verify the toolchain.

## Acceptance criteria

- A function `src/hello.py:greet(name: str) -> str` returns `"Hello, <name>!"`
- A test `tests/test_hello.py` covers happy path and one edge case (empty string).
- `./scripts/agentctl/verify.sh` prints `VERIFY OK`.
- Report at `.agents/reports/000-EXAMPLE-ticket.md` exists.

## Implementation notes

- Don't add any dependencies.
- Use Python type hints.
- Empty string should return `"Hello, stranger!"`.

## Out of scope

- Anything beyond the `greet` function.
- Performance optimization.
- Internationalization.

## Delete this ticket after first successful run.
