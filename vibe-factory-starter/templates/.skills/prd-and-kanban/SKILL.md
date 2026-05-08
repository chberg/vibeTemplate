---
name: prd-and-kanban
category: planning
description: After a Grill Me session, distills the aligned conversation into a PRD (destination doc), then breaks it into vertical-slice Kanban tickets with a DAG of blocking relationships. Based on Matt Pocock's workshop.
---

# PRD & Kanban Board Skill

## Description

Takes the output of a Grill Me session (~25K tokens of aligned conversation) and produces two artifacts:

1. **PRD** — A product requirements document (the "destination")
2. **Kanban board** — Independently grabbable vertical-slice tickets (the "journey")

**Phase**: Human in the loop (HITL) but lightweight — you only need to review the Kanban board
**Prerequisite**: Completed Grill Me session in the same conversation

## When to Use

- After a Grill Me session, to formalize the design concept
- You have a new feature and want to generate implementation tickets
- You want to organize work into a DAG for parallel AFK execution
- You need to communicate the feature plan to other developers

## How It Works

### Step 1: Generate the PRD

In the same session where the Grill Me conversation happened, simply say:

```
Write a PRD.
```

The AI uses the entire aligned Grill Me conversation (~25K tokens of gold context) to produce a PRD without needing to re-interview you.

**The complete PRD skill prompt** (if starting fresh without a grilling):

```
/skill write-prd

1. Ask the user for a long detailed description of the problem.
   (Optional — skip if Grill Me session already happened.)

2. Explore the codebase to understand current architecture.

3. Interview the user relentlessly about requirements.
   (This is a second grilling pass focused on documentation.)

4. Output a PRD using this template:
   - Problem Statement
   - Solution
   - User Stories (Given/When/Then format, 18-20 stories)
   - Implementation Decisions
   - Testing Decisions

5. Create the PRD as a local markdown file in the issues/ directory.
```

**PRD template** (the format Matt uses):

```
## Problem Statement
[What problem is the user facing?]

## Solution
[High-level approach to solving it]

## User Stories
- GIVEN a user is logged in WHEN they complete a lesson THEN they earn
  10 points
- GIVEN a user has 100 points WHEN they visit the dashboard THEN they
  see they are at Level 2
- [18-20 stories total — happy path, edge cases, error states]

## Implementation Decisions
[Architecture choices, module boundaries, data model]

## Testing Decisions
[What to test and how, test pyramid placement]
```

### Should You Read the PRD?

**No.** Matt explicitly says he doesn't read it (line 35:26):

> "I don't look at these. What am I testing when I read it? I know that LLMs are great at summarization because they are. I have reached the same wavelength as the LLM using the grill me skill. All I'm doing is checking the LLM's ability to summarize."

The PRD is an artifact **for the AI**, not for you. Your alignment happened during the grilling.

---

### Step 2: Generate the Kanban Board

Still in the same session, after the PRD is written:

```
Break this PRD into independently grabbable issues using
vertical slices / traceable bullets. Write them as local
markdown files with blocking relationships.
```

### What Comes Out

A directory like this:

```
issues/
  001-award-points-lesson-completion.md
  002-streak-tracking.md
  003-points-wire-into-quiz.md
  004-dashboard-gamification-ui.md
  005-retroactive-backfill.md
```

Each file looks like:

```markdown
# 001 - Award Points for Lesson Completion

**Type**: AFK
**Blocked by**: None

## Description
When a student completes a lesson, award them points
visible on their dashboard.

## Acceptance Criteria
- Points are recorded in gamification DB table
- API endpoint returns points for current user
- Dashboard shows point total
- Points increase after lesson completion

## Implementation Notes
- New gamification service module
- Add gamification schema to database
- Wire into lesson completion event
```

---

### Step 3: The DAG Pattern

Tickets form a Directed Acyclic Graph:

```
Ticket A (schema + base service) — AFK, blocked by nothing
    |
    ├── Ticket B (streak tracking) — AFK, blocked by A
    ├── Ticket C (wire points into quiz) — AFK, blocked by A
    |       |
    ├── Ticket D (retroactive backfill) — AFK, blocked by A
    |
    └── Ticket E (dashboard UI for gamification) — AFK, blocked by B & C
```

This enables parallelism: Tickets B, C, and D can run simultaneously once A completes.

---

### Step 4: Human Review of the Kanban Board

Unlike the PRD, **do review the Kanban board** (Matt at ~38:00):

> "This is really cheap to do, very quick to do once I've done the PRD, and I can immediately see some issues here."

What to check:
- Are tickets truly vertical slices (crossing at least 2 layers)?
- Do blocking relationships make sense?
- Are ticket sizes appropriate (~100K token fits for the AI)?
- AFK vs HITL labels correct?
- Is the first slice the thinnest possible end-to-end slice?

### Correcting Horizontal Slices

If the AI generates horizontal layers instead of vertical slices:

```
The first slice is too horizontal. I want to see schema changes,
some new service being created, AND a minimal representation
on the frontend. Go through vertical slices, not horizontal.
```

The AI will course-correct and regenerate the board with proper vertical slices.

---

## Why Vertical Slices Matter

| Approach | What it looks like | Problem |
|---|---|---|
| **Horizontal layers** | Phase 1: all DB, Phase 2: all API, Phase 3: all UI | Can't test anything until Phase 3. If Phase 1 was wrong, you don't know until everything is built. |
| **Vertical slices** | Each ticket: DB + API + UI for one feature | Each ticket produces a testable, shippable increment. Feedback on every iteration. |

Vertical slices = **traceable bullets** (from The Pragmatic Programmer):
> "Every sixth bullet glows as it flies — you see where you're aiming."

**Rules for the AI when slicing:**
```
- Each issue must cross at least 2 layers (DB + API, or API + UI)
- No issue should be purely one layer
- The first slice should be the thinnest end-to-end slice
- Each subsequent slice adds more functionality to the existing wireframe
```

## Pitfalls

- **Don't skip the Grill Me** — generating a PRD without grilling produces thin specs that miss edge cases
- **Do review the Kanban board** — this is cheap, quick, and catches slice mistakes early
- **Don't let the AI do horizontal layers** — push back aggressively. Vertical slices are non-negotiable for the AFK loop to work
- **Size tickets appropriately** — each ticket should fit in a single AI session (~100K tokens). If a ticket is too big, split it further
- **Keep the PRD file** — it's a reference artifact for the AI, even if you don't read it yourself
