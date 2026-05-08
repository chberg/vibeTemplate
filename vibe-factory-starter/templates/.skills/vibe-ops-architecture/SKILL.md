---
name: vibe-ops-architecture
category: architecture
description: Reference architecture for enterprise agentic platforms. Load this as context whenever planning, grilling, or implementing platform code. Defines the four planes (Decision/Permission/Execution/Trace), the native-not-LangChain principle, the Temporal+OPA+MCP stack, and the uncompressed-traces rule.
---

# Vibe-Ops Architecture Skill

## When to load

Load this skill at the start of any session that involves:
- Planning a new platform module (Grill Me sessions for product code)
- Writing or reviewing product code (Permission, Execution, Trace planes)
- Reviewing architecture decisions
- Onboarding a new contributor

Do NOT load this for factory work (scripts, prompts, tooling). It's only for product code.

## The core principle

The platform separates **what** from **how** via four planes. No code may bypass these boundaries.

```
        User / Caller
              |
              v
     ┌──────────────────┐
     │ Decision plane   │  interprets intent (NL-FSM, native Python LLM calls)
     └────────┬─────────┘
              | proposes action
              v
     ┌──────────────────┐
     │ Permission plane │  evaluates policy (OPA Rego)
     └────────┬─────────┘
              | grants or denies
              v
     ┌──────────────────┐
     │ Execution plane  │  runs the tool (Temporal workflow + activity, MCP dispatch)
     └────────┬─────────┘
              | emits evidence
              v
     ┌──────────────────┐
     │ Trace plane      │  records evidence (Postgres + pgvector, append-only)
     └──────────────────┘
```

## Plane-by-plane rules

### Decision plane

- Pattern: Natural Language FSM. LLM decides *transitions*, FSM enforces *states*.
- Tech: Native Python with model SDK directly. **No LangChain, no CrewAI, no thick frameworks.**
- The decision plane proposes actions. It never executes them.

### Permission plane

- Pattern: Decoupled policy. Every authorization decision is an OPA query.
- Tech: Open Policy Agent. Rego policies in `policy/`, unit-tested with `opa test`.
- **Forbidden**: `if user.role == "admin"` style checks in Python. Write Rego, query OPA.
- Policies live in Git. Version them like code. Compliance teams audit by reading Rego.

### Execution plane

- Pattern: Leader-Worker. Leader is a Temporal Workflow, Workers are Activities.
- Tech: Temporal for orchestration, MCP for the tool surface.
- Tool calls go through the **Execution Gateway** activity:
  ```
  Workflow → ExecutionGateway(tool_call)
                  ↓
              OPA pre-check (allow/deny)
                  ↓
              MCP dispatch
                  ↓
              Trace write
                  ↓
              Result
  ```
- **Forbidden**: bespoke connectors per tool. All tools are MCP.
- **Forbidden**: in-memory state for production paths. State is Temporal workflow state.
- Long-running tasks, HITL pauses, deterministic replay all come free from Temporal.

### Trace plane

- Pattern: Append-only, **uncompressed**.
- Tech: Postgres + pgvector.
- Store: full tool-call JSON, full LLM thought trace, full activity inputs/outputs, full timestamps.
- **Forbidden**: summarizing on write. Summaries happen at read time.
- Why uncompressed: future meta-harness optimizers need raw evidence to learn from.

## Cross-cutting rules

1. **No LangChain.** Native code-centric agents only. The model SDK plus Temporal plus OPA plus MCP is enough.
2. **No silent state.** All durable state is Temporal. Module-level globals are bugs.
3. **No bespoke tool connectors.** MCP only. If a tool doesn't have MCP, write an MCP server.
4. **No summarized traces on write.** Trace Spine is verbatim. Readers summarize.
5. **No hardcoded permission logic.** OPA Rego, queried via the Execution Gateway.
6. **No silent dependency additions.** Document every new top-level dep in the ADR.

## Module map

| Module | Plane | Status |
|---|---|---|
| Policy Catalog | Permission | OPA bundles + Postgres |
| ResolveBindings | Permission | OPA queries, deterministic ordering |
| Activation Token | Permission/Execution boundary | Short-lived JWT, OPA-gated issuance |
| Tool Registry | Execution | MCP server |
| Execution Gateway | Execution | Temporal activity (OPA pre-check + MCP dispatch + Trace write) |
| Trace Spine | Trace | Postgres + pgvector, append-only |
| Replay / Conformance harness | Trace | Temporal replay + golden traces |
| Scenario Pack Runner | Cross-cutting | Temporal child workflows |
| Admin / Governance UI | UI | Surfaces Trace Spine + OPA policies |

## Build order (do not skip)

1. Policy Catalog
2. ResolveBindings
3. Activation Token service
4. Tool Registry (MCP server)
5. Execution Gateway (the heart — Temporal activity that queries OPA, dispatches MCP, writes Trace)
6. Trace Spine
7. Replay / Conformance harness
8. Scenario Pack Runner
9. Admin / Governance UI
10. Demo workflows

Module 5 is the keystone. Everything before it is preparation; everything after extends it.

## Meta-Harness — DO NOT BUILD IN V1

A self-optimizing harness is appealing but premature. You need 100s of real production runs as training data first. Don't build the optimizer until you have a corpus.

What to do instead in v1: make the optimizer cheap to add later by enforcing:
- **Uncompressed traces from day one** (Trace plane rule above).
- **Versioned Rego policies in Git.**
- **Versioned system prompts and tool definitions in files** (not hardcoded strings).

With those properties, a meta-harness becomes a weekend project once you have data.

## What this skill is not

- It is not a substitute for ARCHITECTURE.md. ARCHITECTURE.md is the living, project-specific document. This skill is the reference template.
- It is not an implementation guide. The Pocock workflow (Grill Me → PRD → Kanban → AFK) is how you implement. This skill tells you what to implement.
- It is not for the factory itself. The factory is just shell scripts + Codex/Claude/Antigravity. It doesn't need Temporal or OPA.
