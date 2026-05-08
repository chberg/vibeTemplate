# PROJECT_NAME_PLACEHOLDER

A vibe-coded agentic platform built with the governed factory pattern.

## What this is

This repo is governed by the **vibe-factory** workflow: Grill Me → PRD → Kanban → AFK loop, with a single `verify.sh` truth gate.

- See `AGENTS.md` for the contract every agent must follow.
- See `ARCHITECTURE.md` for the four-plane product architecture.
- See `.skills/` for the three workflow skills (grill-me, prd-and-kanban, afk-agent-loop) plus `vibe-ops-architecture`.
- See `issues/` for the Kanban board.
- See `.agents/reports/` for what AFK loops have produced.

## Quick start

### macOS / Linux
```bash
# 1. Verify the toolchain works
./scripts/agentctl/verify.sh

# 2. Run the example ticket end-to-end
./scripts/agentctl/once.sh

# 3. See where you stand
./scripts/agentctl/status.sh

# 4. Review reports after an AFK loop
./scripts/agentctl/collect_reports.sh
```

### Windows (PowerShell via Git Bash)
```powershell
# 1. Verify the toolchain works
bash ./scripts/agentctl/verify.sh

# 2. Run the example ticket end-to-end
bash ./scripts/agentctl/once.sh

# 3. See where you stand
bash ./scripts/agentctl/status.sh

# 4. Review reports after an AFK loop
bash ./scripts/agentctl/collect_reports.sh
```

## Workflow

1. **Grill Me** — open Antigravity (or Codex CLI), `/clear`, invoke `.skills/grill-me/SKILL.md`, paste your brief.
2. **PRD + Kanban** — invoke `.skills/prd-and-kanban/SKILL.md` to write tickets into `issues/`.
3. **Review the Kanban** — read each ticket, check vertical slicing, fix labels.
4. **AFK loop** — `./scripts/agentctl/once.sh` to start. Once trusted, `./scripts/agentctl/afk-loop.sh`.
5. **Review** — read `.agents/reports/*`. Merge passing PRs.

## The four-plane architecture (product code only)

| Plane | Tech | Rule |
|---|---|---|
| Decision | Native Python LLM SDK | NL-FSM. No LangChain. |
| Permission | OPA Rego | No inline auth. |
| Execution | Temporal + MCP | Tool calls go through Execution Gateway. |
| Trace | Postgres + pgvector | Append-only, uncompressed. |

Full reference: `.skills/vibe-ops-architecture/SKILL.md`
