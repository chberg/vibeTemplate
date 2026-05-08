---
name: afk-agent-loop
category: planning
description: AFK (Away From Keyboard) agent loop that reads vertical-slice Kanban tickets from a local issues/ directory, picks the next unblocked AFK task, implements it, runs tests, and commits. Includes both a manual once.sh and an automated Docker-based loop. Based on Matt Pocock's workshop.
---

# AFK Agent Loop Skill

## Description

The implementation phase of Matt Pocock's AI coding workflow. After the Grill Me alignment (Step 1), PRD generation (Step 2), and Kanban board creation (Step 3), the AFK agent loop executes the implementation **without you at the keyboard**.

The agent reads the Kanban issues/, picks the next unblocked AFK task, implements it end-to-end, runs tests, commits, and loops.

**Phase**: AFK (Away From Keyboard) — you can walk away
**Prerequisites**: Completed issues/ directory with AFK-labeled, vertical-slice tickets with blocking relationships

## When to Use

- After Grill Me + PRD + Kanban board, you're ready to implement
- You have a set of vertical-slice tickets with clear blocking relationships
- You want to walk away and let the AI do the implementation work

Do NOT use this:
- Before the planning phases are complete
- With undefined, vague, or horizontal-layer tickets
- Without a Docker sandbox for the automated loop

## How It Works

### Phase 1: The Manual Loop (once.sh — Start Here)

Run once, observe, tune, then automate.

Create a file called `once.sh` at the root of your project:

```bash
#!/bin/bash
# once.sh — Run one iteration of the AFK agent loop
# Start here. Run this manually, watch what happens, then tune the prompt.

set -euo pipefail

# 1. Gather all issue files from the Kanban board
ISSUES=""
for file in issues/*.md; do
    CONTENT=$(cat "$file")
    ISSUES="$ISSUES\n---\n$CONTENT"
done

# 2. Gather git context
LAST_COMMITS=$(git log --oneline -5)

# 3. Build the prompt
PROMPT="
## Context
Local issue files from issues/ directory:

$ISSUES

## Git State
I am at the root of the repository.
Last 5 commits:
$LAST_COMMITS

## Instructions
You are working on AFK issues only. Each issue has a Type field
that is either AFK or HITL.

### Task Selection
- Only work on tasks marked as Type: AFK
- Check the 'Blocked by' field of each issue
- Only pick tasks whose blocking dependencies are complete
- Prioritize unblocked tasks that have the fewest dependents
- If all AFK tasks are complete, output exactly: NO_MORE_TASKS

### Implementation
- Make small, incremental changes (one task at a time)
- Each change should be a vertical slice crossing at least 2 layers
- Run tests after each change
- Commit after completing each task with a clear message
- If you encounter an unexpected blocker, stop and report it
"

claude --permission accept-edits -p "$PROMPT"
```

**Before automating, do this:**
1. `chmod +x once.sh`
2. Run it: `./once.sh`
3. Watch what the agent does — does it pick the right task?
4. Check the quality of the output
5. Tune the prompt — add guardrails for things it got wrong
6. Only then, wire up the automated loop

---

### Phase 2: The Automated Loop (afk-loop.sh)

Once once.sh runs correctly, graduate to the full automated loop.

```bash
#!/bin/bash
# afk-loop.sh — Automated AFK agent loop (Docker sandbox)
# Loops until all AFK tasks are done.

set -euo pipefail

MAX_ITERATIONS=20
ITERATION=0

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    echo "=== Iteration $ITERATION ==="

    # Build context from issues + git
    ISSUES=$(cat issues/*.md)
    COMMITS=$(git log --oneline -5)

    # Run Claude Code in Docker sandbox
    OUTPUT=$(docker run \
        -v $(pwd):/workspace \
        -e CLAUDE_API_KEY=${CLAUDE_API_KEY:?} \
        sandbox-image \
        claude --permission accept-edits \
            -p "Issues: $ISSUES\nLast commits: $COMMITS\n
                You are working on AFK issues only.
                If all AFK tasks are complete, output NO_MORE_TASKS.
                Otherwise pick the next unblocked task and implement it."
    )

    # Check if done
    if echo "$OUTPUT" | grep -q "NO_MORE_TASKS"; then
        echo "All AFK tasks complete!"
        exit 0
    fi

    echo "Iteration $ITERATION complete. Looping..."
    sleep 5
done

echo "Reached max iterations ($MAX_ITERATIONS). Manual review needed."
exit 1
```

---

## The Agent Prompt Structure

The prompt given to the implementation agent has three sections:

### 1. Context Injection
```
Local issue files from issues/ directory are provided at the start.
Each file is a markdown ticket with: title, description, blocking deps,
type (AFK vs HITL), and acceptance criteria.

The git state is provided: last 5 commits, current branch.
```

### 2. Task Selection Rules
```
- Only work on AFK tasks (ignore HITL tasks)
- Check blocking relationships — only pick tasks whose deps are done
- Prioritize tasks with fewest dependents (unblock downstream work)
- If all AFK tasks complete, output: NO_MORE_TASKS
```

### 3. Implementation Rules
```
- Make small, incremental changes (one task at a time)
- Each change should be a vertical slice crossing at least 2 layers
- Run tests after each change
- Commit after completing each task with a clear message
- If you hit an unexpected blocker, stop and report it
```

---

## Parallel Execution

With a proper DAG of tickets, you can run multiple agents in parallel:

```
         Ticket A
        /        \
    Ticket B    Ticket C  (can run in parallel after A)
        \        /
         Ticket D  (blocked on B and C)
```

Run `afk-loop.sh` on three separate machines/containers for three independent branches of the DAG. Each agent will only pick unblocked tasks from its branch.

**Caveat**: The tickets must be truly independent (no shared state conflicts). If tickets B and C both modify the same files, they'll conflict. Design your DAG with this in mind.

---

## What a Completed Iteration Looks Like

Each iteration of the loop should produce:

1. A working commit with changes that satisfy one ticket's acceptance criteria
2. Passing tests
3. The ticket file marked as completed (or moved to a `done/` directory)
4. The agent moves to the next unblocked task

If an iteration doesn't produce a commit, it means either:
- The agent got stuck (need a better prompt)
- The task was actually HITL-level ambiguous (reclassify it)
- There's a codebase issue the grilling didn't surface (go back to planning)

---

## Safety

### Sandbox Requirements
- **Always run the automated loop in Docker** — prevents the agent from damaging your actual system
- The Docker image should have: git, Claude Code (or equivalent), your language runtime, and your test runner
- Mount your project as a volume (`-v $(pwd):/workspace`)
- Do NOT give the container access to production secrets

### Prompt Safety Cues
The AFK prompt explicitly tells the agent to stop if it encounters unexpected blocks. This prevents the agent from going down a wrong path for 20 iterations before you check in.

### Manual Override
Keep the `MAX_ITERATIONS` guard in production code. If something goes wrong, the loop terminates with a manual-review signal instead of running forever.

### Exit Condition Monitoring
The loop always outputs `NO_MORE_TASKS` before exiting. If you don't see this in the output, the loop was interrupted or hit max iterations — investigate before assuming all work is done.

---

## The Matt Technique: Ralph Loop

The AFK loop is inspired by the "Ralph loop" (community pattern from Nathan B.). The core insight:

> The agent doesn't need a complete multi-phase plan. It just needs the destination (PRD) and permission to make small changes that move toward it.

Each iteration is a Ralph loop: read the destination, pick the next move, make it, test, commit, repeat.

---

## Pitfalls

- **Don't skip the manual once.sh phase** — one manual run surfaces prompt issues that would loop silently in automation
- **Don't use with horizontal-layer tickets** — if a ticket only touches one layer, the agent can't test it and you lose feedback
- **Don't set MAX_ITERATIONS too high** — 20 is a safe ceiling. If a project needs more, split your tickets into phases
- **Don't skip Docker sandbox** — the AFK agent has `--permission accept-edits`. Without sandbox, it can damage your system
- **Don't run without tests** — the loop relies on test feedback. If your project has no tests, the agent works blind
- **Don't expect perfect on first iteration** — tune the prompt after each manual run. The first version of once.sh always has gaps
