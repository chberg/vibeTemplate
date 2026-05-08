# Architecture

> Fill this in during your first Grill Me session. Do not let agents implement product code until this document is populated.

## Product overview

[One paragraph: what does this platform do? Who uses it? What's the main value?]

## The four planes

This platform separates concerns into four planes. Implementation must not bypass these boundaries.

### Decision plane

[What interprets user/agent intent? What are the inputs and outputs? What state machine governs transitions?]

- Pattern: Natural Language FSM (NL-FSM). LLM decides transitions, FSM enforces states.
- Tech: Native Python, native tool-calling APIs (no LangChain).

### Permission plane

[What policies govern this platform? Who can do what, when, with what data?]

- Pattern: Decoupled policy. All authorization decisions go through OPA.
- Tech: Open Policy Agent (OPA), Rego policies versioned in `policy/`.
- Rule: Never inline `if user.role == ...` checks. Write Rego, query OPA.

### Execution plane

[What tools does the platform call? What workflows does it run? Which need durability/HITL/replay?]

- Pattern: Leader-Worker. Leader is a Temporal Workflow. Workers are Temporal Activities. Tool calls go through the Execution Gateway activity (OPA pre-check + MCP dispatch).
- Tech: Temporal for orchestration, MCP for tool surface.

### Trace plane

[What evidence does the platform record? What's the schema? What's the retention policy?]

- Pattern: Append-only, uncompressed traces. Summarize on read, never on write.
- Tech: Postgres + pgvector. Full tool-call JSON, full thought traces, full activity inputs/outputs stored verbatim.

## Module map

[List of modules and which plane each belongs to. Fill in as Grill Me sessions complete.]

| Module | Plane | Status | Notes |
|---|---|---|---|
| Policy Catalog | Permission | planned | OPA bundles + Postgres |
| ResolveBindings | Permission | planned | OPA queries |
| Activation Token | Permission/Execution | planned | Short-lived JWT, OPA-gated |
| Tool Registry | Execution | planned | MCP server |
| Execution Gateway | Execution | planned | Temporal activity |
| Trace Spine | Trace | planned | Postgres + pgvector |
| Replay Harness | Trace | planned | Temporal replay + golden traces |

## Cross-cutting decisions

- **No LangChain.** Native code-centric agents only.
- **No in-memory state for prod paths.** All state is Temporal workflow state.
- **No bespoke tool connectors.** MCP only.
- **No summarized traces on write.** Trace Spine stores everything; readers summarize.
- **No hardcoded permission logic.** OPA Rego, queried via gateway.

## ADRs

Architecture Decision Records live in `DECISIONS/`. Each new architectural choice gets a numbered ADR.
