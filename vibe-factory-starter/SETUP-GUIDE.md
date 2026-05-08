# Step-by-Step Setup Guide

How to bootstrap the vibe coding factory and use it to build the Lockix / Skan platform. Follow these steps in order. Total time: about 4 hours of focused work to get to your first AFK loop, spread across 2 days.

---

## Day 0 — Prerequisites (30 min)

### What you need installed

```bash
# Required
git --version           # any recent
python3 --version       # 3.11+
node --version          # 20+
docker --version        # any recent

# Coding agents (install at least one)
npm install -g @openai/codex
# Optional: npm install -g @anthropic-ai/claude-code
# Optional: download Antigravity from antigravity.codes

# Python tooling for verify.sh
pip install ruff mypy pytest

# OPA (only needed once you start product code)
# macOS: brew install opa
# Linux: curl -L -o /usr/local/bin/opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static && chmod +x /usr/local/bin/opa

# Windows specific
# Git Bash or WSL2 is required to run the *.sh agentctl scripts in this toolkit.
```

### Accounts / API keys

- OpenAI (Codex): `OPENAI_API_KEY`
- Anthropic (optional second opinion): `ANTHROPIC_API_KEY`
- OpenRouter (for Hermes routing): `OPENROUTER_API_KEY`
- Your local Ollama / vLLM endpoints (you mentioned 3090 + DGX Spark)

### Codex login

```bash
codex login
```

Then create `~/.codex/config.toml` with your default model:

```toml
model = "gpt-5.4-codex"

[sandbox]
mode = "workspace-write"
network_access = false
```

---

## Day 1, Morning — Install the factory (1 hour)

### Step 1. Get the starter kit

You have two options.

**Option A (recommended): Use the bundle I produced.**

Download the `vibe-factory-starter.zip` I shared. Unzip it to a permanent location, e.g. `~/tools/vibe-factory-starter/`.

```bash
mkdir -p ~/tools
unzip vibe-factory-starter.zip -d ~/tools/
chmod +x ~/tools/vibe-factory-starter/vibe-init.sh
chmod +x ~/tools/vibe-factory-starter/templates/scripts/agentctl/*.sh
```

Optionally add the wizard to your PATH:

```bash
echo 'export PATH="$HOME/tools/vibe-factory-starter:$PATH"' >> ~/.zshrc   # or ~/.bashrc
source ~/.zshrc
```

Now `vibe-init.sh <project-name>` works from anywhere.

**Option B: Copy the templates into a Git repo of your own** so you can iterate on the factory itself with version history. Recommended once the factory works for you.

```bash
cd ~/projects
mkdir vibe-factory && cd vibe-factory
cp -a ~/tools/vibe-factory-starter/. .
git init && git add -A && git commit -m "chore: initial vibe factory"
```

### Step 2. Smoke test

Scaffold a throwaway project to confirm everything works:

```bash
cd /tmp
~/tools/vibe-factory-starter/vibe-init.sh smoke-test
cd smoke-test
./scripts/agentctl/verify.sh
./scripts/agentctl/status.sh
```

You should see `VERIFY OK` and the example ticket listed as OPEN.

### Step 3. Run the example ticket end-to-end (the most important step)

This is the supervised first run. Watch every step. The point is to learn what the agent actually does and tune from there.

```bash
cd /tmp/smoke-test
cp .env.example .env
# Edit .env, paste your OPENAI_API_KEY
./scripts/agentctl/once.sh
```

What should happen:

1. Codex reads `AGENTS.md`, the example ticket, and the AFK implementer prompt.
2. It creates `src/hello.py` with the `greet` function.
3. It creates `tests/test_hello.py`.
4. It runs `verify.sh` and iterates until `VERIFY OK`.
5. It writes `.agents/reports/000-EXAMPLE-ticket.md`.
6. It commits with `feat(hello): ...`.

Then run:

```bash
./scripts/agentctl/verify.sh         # confirms VERIFY OK
./scripts/agentctl/status.sh         # ticket should now be DONE
git log --oneline                     # commit visible
cat .agents/reports/000-EXAMPLE-ticket.md
```

### Step 4. Tune

Read what the agent did. Open the report. Open the diff. Things to look for and fix in your starter templates:

- Did the agent actually follow AGENTS.md? If not, tighten the rules.
- Did `verify.sh` run after every change? If not, repeat the rule in `afk-implementer.md`.
- Was the report complete? If not, tighten the report template.
- Did it scope-creep? If yes, strengthen the stop conditions.

Edit the templates in `~/tools/vibe-factory-starter/templates/`. Run `vibe-init.sh` on a new throwaway project to confirm fixes. Repeat until one supervised iteration produces clean output.

---

## Day 1, Afternoon — Wire your auxiliary tools (1 hour)

### Step 5. Set up Hermes for persistent memory

Hermes is your continuity layer. It doesn't write code. It maintains `.agents/state/` files across sessions.

```bash
hermes model
# Pick OpenRouter, paste OPENROUTER_API_KEY, choose a model

# Or for local DGX Spark:
hermes model
# Pick "Custom endpoint", URL: http://192.168.x.x:8000/v1
```

The Hermes prompt to keep open in a tab:

```
You are the persistent coordinator for the vibe factory.

Read AGENTS.md, ARCHITECTURE.md, .agents/reports/, and issues/.

Maintain three files:
- .agents/state/project_summary.md  (what's done, what's in flight)
- .agents/state/open_risks.md       (security/architecture/scope concerns)
- .agents/state/next_tasks.md       (proposed next 3 unblocked tickets)

Refresh these every time I ask. Never modify source code. Never modify tests.
Never modify CI. Never edit policies.

Route summarization and log triage to the local model. Escalate
architectural questions to the frontier model.
```

### Step 6. Set up Antigravity

Open Antigravity, "Open Folder", point it at your factory repo (or whatever project you're scaffolding). Antigravity will read `AGENTS.md` automatically.

The `/goal` you'll use most often:

```
/goal Implement the next unblocked AFK ticket from issues/.
Read AGENTS.md, the ticket, and .skills/vibe-ops-architecture/SKILL.md
if implementing product code.

Work in a git worktree. Make a vertical slice. Run verify.sh until it
prints VERIFY OK. Write the report. Commit with conventional commit format.

Stop on any condition listed in AGENTS.md and write a *-blocked.md report.
```

Antigravity's strength is the **Browser sub-agent** + **Manager**. Use Browser for visual verification of UI tickets. Use Manager to spawn a verifier agent in parallel.

### Step 7. Build the Docker sandbox

```bash
cd /tmp/smoke-test
docker build -t vibe-sandbox -f docker/sandbox.Dockerfile .

# Test it
docker run --rm -v "$(pwd)":/workspace -w /workspace vibe-sandbox \
  ./scripts/agentctl/verify.sh
```

This is the box you'll use for the automated `afk-loop.sh` once you trust the prompt.

---

## Day 2, Morning — First real project: the Lockix platform (2 hours)

### Step 8. Scaffold

```bash
cd ~/projects
~/tools/vibe-factory-starter/vibe-init.sh lockix-platform
cd lockix-platform
cp .env.example .env   # paste keys
```

Delete the example ticket — you don't need it anymore:

```bash
rm issues/000-EXAMPLE-ticket.md
git add -A && git commit -m "chore: remove example ticket"
```

### Step 9. Open Antigravity (or Codex CLI), `/clear`, run Grill Me

This is the most important hour of the whole project. **Dictate, don't type.**

Open Antigravity on `lockix-platform/`. In the chat:

```
Load .skills/grill-me/SKILL.md and .skills/vibe-ops-architecture/SKILL.md.

I am rebuilding our enterprise agentic automation platform. Architecture
constraints from .skills/vibe-ops-architecture/SKILL.md apply: four planes,
Temporal+OPA+MCP, no LangChain, uncompressed traces.

The first module to design is the **Policy Catalog**. It is part of the
Permission plane. It must support:
- register a policy (immutable versions)
- list policies for tenant/env
- resolve a policy by tenant/env/policy_id/version with deterministic ordering
- fail-closed for missing or ambiguous policy

Use a sub-agent to read ARCHITECTURE.md and the vibe-ops-architecture
skill. Then start grilling me one question at a time. For each question,
provide your recommended answer. Do NOT generate a plan or implementation
until I explicitly ask. The goal is shared understanding.
```

Spend ~45-60 minutes answering questions. Dictate. Push back when the AI's recommendation feels off. Let it surface edge cases.

### Step 10. Generate the PRD

Same session, when grilling feels complete:

```
Load .skills/prd-and-kanban/SKILL.md.

Write a PRD for the Policy Catalog into issues/policy-catalog/PRD.md
using the template in the skill. Use the entire grilling conversation
as context.
```

Don't read the PRD. Trust the alignment from grilling.

### Step 11. Generate the Kanban board

Same session, immediately after PRD:

```
Break the Policy Catalog PRD into vertical-slice tickets, one markdown
file each, in issues/policy-catalog/. Each ticket must:

- Touch at least 2 layers (schema + service, or service + test, etc.)
- Have Type: AFK or HITL
- Have Blocked by: <ticket-id> or None
- Have explicit acceptance criteria
- Honor the four-plane architecture

The first slice should be the thinnest possible end-to-end: register
one policy, resolve it, write a trace. Use the example issue format
from issues/000-EXAMPLE-ticket.md.
```

If the AI proposes horizontal layers (DB-only ticket, then API-only ticket, then UI-only ticket), push back hard:

```
The first slice is too horizontal. I want to see schema changes, service
code, AND a test that proves the end-to-end flow. Vertical slices, not
horizontal.
```

### Step 12. Review the Kanban (the cheap, important review)

Read every ticket. For each one, check:

- Is it actually a vertical slice?
- Are blocking deps real?
- Is the AFK/HITL label correct?
- Could this fit in one Codex session (~100k tokens)?
- Are acceptance criteria testable?

Edit tickets directly. Commit:

```bash
git add issues/
git commit -m "docs: kanban for policy-catalog"
```

### Step 13. First supervised AFK iteration

```bash
./scripts/agentctl/once.sh
```

Watch what happens. If it goes off the rails, kill it (`Ctrl+C`), tune the prompts in `.agents/prompts/`, and try again.

When you trust it:

```bash
docker run --rm -v "$(pwd)":/workspace -w /workspace \
  -e OPENAI_API_KEY="$OPENAI_API_KEY" \
  --env-file .env \
  vibe-sandbox \
  ./scripts/agentctl/afk-loop.sh
```

Walk away. Come back in an hour. Read `.agents/reports/`. Run `./scripts/agentctl/collect_reports.sh` for a rollup.

### Step 14. Merge what passes verify

Each agent branch is `agent/<ticket-id>`. For each one:

```bash
git checkout main
git merge --no-ff agent/<ticket-id>
git push
```

GitHub Actions runs `verify.sh` on the PR. The CI also blocks merging if `.agents/reports/<ticket-id>.md` is missing.

---

## Recurring weekly cadence

Once the first module is in, your week looks like:

| Day | Activity |
|---|---|
| Mon AM | Grill Me on next module (~1 hour) |
| Mon PM | PRD + Kanban + review |
| Tue–Thu | AFK loops, monitor, merge |
| Thu PM | Hermes generates `.agents/state/*` rollups |
| Fri AM | Retro: what guardrail was missing? Update AGENTS.md or prompts |
| Fri PM | Lessons get pushed back to `~/tools/vibe-factory-starter/templates/` so the next module benefits |

---

## The exact prompt cheatsheet

### `/goal` for Antigravity, mission level

```
/goal Implement the next unblocked AFK ticket from issues/.
Honor AGENTS.md and stop conditions. Vertical slice only.
Run verify.sh until VERIFY OK. Write the report. Commit.
```

```
/goal Verify ticket <id> independently. Do not trust the implementer's report.
Run verify.sh, check scope, check acceptance criteria against actual code.
Write .agents/reports/<id>-verification.md.
```

```
/goal Security review the diff between main and HEAD.
Use .agents/prompts/security-reviewer.md.
Write .agents/reports/<id>-security.md.
```

### Hermes prompt to keep persistent

(See Step 5 above.)

### Codex one-shot (when you don't want the AFK loop)

```bash
cd ~/projects/lockix-platform
codex exec "$(cat <<'EOF'
Read AGENTS.md and pick the next unblocked AFK ticket from issues/.
Implement it as a vertical slice. Run ./scripts/agentctl/verify.sh
until VERIFY OK. Write the report. Commit.
Stop on any condition listed in AGENTS.md.
EOF
)"
```

### Grill Me invocation

```
Load .skills/grill-me/SKILL.md and .skills/vibe-ops-architecture/SKILL.md.

[Paste your brief, meeting transcript, or rough idea here.]

Use a sub-agent to explore the codebase and read ARCHITECTURE.md.
Then grill me one question at a time, with your recommendation.
Do not produce a plan until I explicitly ask.
```

### PRD generation

```
Load .skills/prd-and-kanban/SKILL.md.
Write a PRD into issues/<module>/PRD.md using the entire grilling
conversation as context.
```

### Kanban generation

```
Break the PRD into vertical-slice tickets in issues/<module>/.
Each ticket: Type, Blocked by, acceptance criteria. First slice is
the thinnest end-to-end. Use the format from issues/000-EXAMPLE-ticket.md.
```

### Pushing back on horizontal slices

```
That's too horizontal. I want each ticket to touch schema + service +
a test that proves the end-to-end flow. Vertical slices. Regenerate.
```

---

## File reference (where everything lives)

```
<project>/
├── AGENTS.md                          # the contract every agent reads
├── ARCHITECTURE.md                    # filled during Grill Me
├── README.md
├── pyproject.toml                     # ruff/mypy/pytest config
├── .env.example                       # copy to .env, fill keys
├── .gitignore
├── .skills/
│   ├── grill-me/SKILL.md              # alignment workflow
│   ├── prd-and-kanban/SKILL.md        # planning workflow
│   ├── afk-agent-loop/SKILL.md        # implementation workflow
│   └── vibe-ops-architecture/SKILL.md # 4-plane reference
├── .agents/
│   ├── prompts/
│   │   ├── afk-implementer.md         # used by once.sh / afk-loop.sh
│   │   ├── verifier.md                # for independent verification
│   │   └── security-reviewer.md       # for /goal security review
│   ├── reports/                       # AFK writes here
│   ├── logs/                          # afk-loop.sh writes here
│   └── state/                         # Hermes writes here
├── .codex/agents/                     # Codex custom subagents
├── .github/workflows/verify.yml       # CI runs verify.sh
├── docker/
│   ├── sandbox.Dockerfile             # for afk-loop.sh
│   └── docker-compose.product.yml     # Temporal+OPA+Postgres for product
├── scripts/agentctl/
│   ├── verify.sh                      # truth gate
│   ├── once.sh                        # one AFK iteration
│   ├── afk-loop.sh                    # bounded automated loop
│   ├── spawn_worktree.sh              # worktree per ticket
│   ├── status.sh                      # what's done, what's open
│   └── collect_reports.sh             # rollup for human review
├── issues/                            # Kanban board (source of truth)
├── policy/                            # OPA Rego policies (product)
├── tests/                             # pytest tests
└── DECISIONS/                         # ADRs
```

---

## Common failure modes and fixes

**Agent ignores AGENTS.md.**
Tighten the language. Replace passive voice ("should") with imperative ("MUST"). Move the most-violated rule to the top.

**Agent removes a test to make verify.sh pass.**
Add this to AGENTS.md stop conditions: "If you would delete or modify a test to fix a failure, stop and write a `*-blocked.md` report instead."

**Agent makes 800-line diffs.**
Add a `git diff --stat | awk '{added+=$1} END {print added}'` check to `once.sh` and abort if > 400. Or just enforce it via the prompt ("Diff exceeds 400 lines is an automatic stop condition").

**Agent works on wrong ticket order.**
Make `Blocked by` parsing strict. Tell the agent to verify deps by checking `.agents/reports/<dep-id>.md` exists, not by reading the ticket file.

**Antigravity Browser sub-agent runs out of context.**
Spawn it as a separate `/goal` so its context is its own. Don't let your main mission control thread accumulate browser-session noise.

**Hermes recommends merging.**
Hermes shouldn't merge anything. Re-read its prompt. Hermes only writes to `.agents/state/`.

---

## When to graduate to product runtime

Don't start Temporal/OPA/Postgres on Day 2. Start them when you reach module 4 (Tool Registry / MCP server) — that's the first module where the runtime stack actually adds value over plain Python.

```bash
# When you're ready:
docker compose -f docker/docker-compose.product.yml up -d
# Temporal UI: http://localhost:8080
# OPA: http://localhost:8181
# Postgres: localhost:5432 (user: vibe, pw: vibe)
```

Modules 1-3 (Policy Catalog, ResolveBindings, Activation Token) can be built with plain Python + Postgres + tests. Don't over-build.
