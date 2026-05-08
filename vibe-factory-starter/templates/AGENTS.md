# Agent Instructions

## Prime Directive

You are working in a governed agentic engineering factory. Optimize for small, reviewable, tested changes.

The factory builds enterprise agentic platforms. It is itself governed the same way the products it builds are governed.

## Non-negotiables

- Do not modify `main` directly. Always work in a git worktree on a branch.
- Do not remove tests to make a task pass.
- Do not weaken security, policy, auth, or audit behavior.
- Do not introduce silent memory writes or silent permission escalation.
- Do not add new top-level dependencies without documenting why in the report.
- Do not touch secrets, credentials, `.env`, private keys, or production configs.
- Do not edit CI workflows except via an explicit task that says you may.
- Fail closed on ambiguity. Stop and write a `*-blocked.md` report.

## Pocock workflow (this repo uses it)

- Tickets live in `issues/` (single source of truth).
- Each ticket has `Type: AFK` or `Type: HITL`. Agents only run AFK.
- Each ticket is a vertical slice across at least 2 layers (e.g., schema + service, or service + UI).
- Workflow: agent reads tickets → picks next unblocked AFK → implements → runs `verify.sh` → commits → loops.

## Required workflow per ticket

Before implementation:
1. Read `ARCHITECTURE.md`.
2. Read the ticket file from `issues/`.
3. Read `.skills/vibe-ops-architecture/SKILL.md` if implementing product code.
4. Identify target files and tests.
5. State a minimal implementation plan in your first message.

During implementation:
1. Make the smallest coherent diff.
2. Add or update tests in the same commit as code changes.
3. Run `./scripts/agentctl/verify.sh` after every meaningful change.

Before finishing:
1. `./scripts/agentctl/verify.sh` must print `VERIFY OK`.
2. Write a report to `.agents/reports/<ticket-id>.md` with:
   - Summary
   - Files changed
   - Tests added/updated
   - `verify.sh` output (last 20 lines)
   - Risks
   - Follow-ups
   - Merge recommendation
3. Commit with conventional commit format: `feat(module): summary` or `fix(module): summary`.

## Stop conditions (hard)

Stop and write a `<ticket-id>-blocked.md` report if any of these is true:
- Same test fails 3 times in a row.
- Diff exceeds 400 lines without a passing test.
- You would touch: secrets, `.env`, CI config, auth/policy code outside scope, migrations.
- You would add a new top-level dependency.
- The ticket's blocking deps are not actually complete (verify by reading prior reports).
- Architectural ambiguity (the answer is not in `ARCHITECTURE.md` or the ticket).
- You would need to modify a file outside the ticket's declared scope.

## Architecture boundaries (factory)

The factory itself has no product planes. It just runs Codex/Claude/Hermes against tickets. Don't over-engineer it.

## Architecture boundaries (product code, when implementing platform modules)

The product runs on four planes. No implementation may bypass policy gates.

- **Decision plane** — interprets intent (LLM reasoning, NL-FSM transitions). Native Python, no LangChain.
- **Permission plane** — evaluates policy. **OPA Rego only.** Never inline `if` checks for authorization.
- **Execution plane** — runs tools. **Temporal workflows + activities.** Tool calls go through the Execution Gateway activity.
- **Trace plane** — records evidence. **Postgres + pgvector, append-only.** Uncompressed traces.

Tool surface: **MCP only.** No bespoke connectors.

When implementing product modules:
- State MUST be Temporal workflow state, not module-level globals.
- Traces MUST be uncompressed (full tool-call JSON, full thought trace). Summarize on read, never on write.
- Policies MUST live in `policy/*.rego` and be unit-tested with `opa test`.
- Tool calls MUST go through the Execution Gateway activity (OPA pre-check + MCP dispatch).

## Standard checks

The single source of truth for "done" is `./scripts/agentctl/verify.sh`. It runs:

```bash
ruff format --check .
ruff check .
mypy .
pytest -q --maxfail=1
opa test policy/   # if policy/ has files
```

If `verify.sh` exits non-zero, the work is not done.
