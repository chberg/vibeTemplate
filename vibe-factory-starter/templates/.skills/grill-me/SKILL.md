---
name: grill-me
category: planning
description: Relentless one-question-at-a-time interviewing to build a shared design concept before any code is written. Uses sub-agents to explore the codebase, then grills the user through every branch of the decision tree. Based on Matt Pocock's workshop.
---

# Grill Me Skill

## Description

The Grill Me skill is the first step in Matt Pocock's AI coding workflow. Before writing a single line of code, you and an AI agent interview each other relentlessly — one question at a time — until you share a complete design concept.

**Origin**: Matt Pocock's workshop "The AI Coding Revolution" (conference talk, 2025)
**Duration**: 40-100+ questions, ~30-60 minutes
**Phase**: Human in the loop (HITL) — mandatory, cannot be automated

## When to Use This Skill

- You have a new feature or project idea and want to build it with AI
- You have a team discussion or domain expert meeting transcript you want to validate
- You're starting a PRD and want alignment first
- You want to surface edge cases and hidden assumptions before coding
- You're pairing with AI as if it's a third person in the room

Do NOT use this for:
- Trivial well-understood tasks (small fix, known pattern)
- Pure implementation tasks where the shape is already clear

## Trigger Condition

Any time the user says something like:
- "Let's plan out this feature"
- "I have an idea I want to build"
- "Help me think through [project/feature]"
- "Run the grill me process on this brief"
- `grill me` or `/grill` as a command

## How It Works

### Step 1: Clear context and start fresh

The user should start with a clean session so the system prompt stays tiny and the AI's attention is fresh.

```
/clear
```

### Step 2: Invoke the skill

Provide the client brief, meeting transcript, or even just a rough idea:

```
I want to build a gamification system for a course platform.
Users earn points for completing lessons. Points unlock badges and streaks.
Here's what I know so far: [paste notes or brief]
```

### Step 3: AI explores the codebase (sub-agent)

The first thing the AI should do is **explore** — not ask questions yet. Use a sub-agent to:

```markdown
Use a sub-agent to explore my codebase for context before asking questions.
Read:
- The project README and any docs/
- Current database schema if available
- Relevant existing services/modules
- Any existing tests that show patterns
```

This sub-agent can burn up to ~90K tokens on context-gathering. That's fine — the parent agent's context stays small.

### Step 4: One question at a time

The AI asks exactly **one question**. For each question, it provides a **recommended answer**.

```
Question 1: Points economy — what actions earn points and how much?
My recommendation: Start with 10 points per lesson completion.
No points for just viewing a lesson. This keeps it simple.
Do you agree?
```

The user responds. The AI can push back or agree, then proceed to the next question.

**Rules for the AI:**
- One question at a time — never batch questions
- Always provide your recommended answer alongside the question
- Push back if the user's answer has issues you can see
- Explore edge cases the user hasn't considered
- Only move to the next question once the current one is resolved

### Step 5: User answers naturally

The user answers in whatever form is natural:

```
Yes, 10 per lesson sounds right.
No retroactive. Let's not overcomplicate launch.
```

The AI agrees, pushes back, or asks a follow-up to clarify.

### Step 6: Wrap up

The conversation is the durable asset — not a plan document. By the end you have ~25K tokens of gold-standard aligned conversation that captures every decision and edge case.

## The Full Prompt (for direct use)

This is what Matt Pocock uses. Copy-paste it or invoke the skill:

```
/skill grill-me

Interview me relentlessly about every aspect of this plan until we reach
a shared understanding. Walk down each branch of the decision tree,
resolving dependencies one by one.

For each question, provide your recommended answer.

Ask the questions one at a time. After I answer, either agree with my
answer, push back if you think there is a better approach, or ask a
follow-up question to clarify. Only proceed to the next question once
we have alignment on the current one.

Use sub-agents to explore my codebase for context before asking
questions. Do NOT generate a plan or implementation until I explicitly
ask for it. The goal is shared understanding, not a plan.
```

## Categories of Questions You Can Expect

The AI will probe across these dimensions:

| Category | Example Questions |
|---|---|
| **Economics** | What actions earn points? How many? Are there caps? |
| **Edge Cases** | Should points be retroactive? What if a user re-watches a lesson? |
| **Progression** | What's the levels curve? How many points between levels? |
| **UI/UX** | Where does gamification UI live? What do we show first? |
| **Architecture** | New service or add to existing? What's the data model? |
| **Scope** | What's in v1 vs v2? What are we explicitly not building? |
| **Dependencies** | What features does this depend on? What depends on this? |
| **Testing** | What should we test? How do we test the gamification rules? |
| **Data** | What existing data can we use? What needs to be migrated? |

## What Comes Out

A rich conversation history that:

- Captures every decision and trade-off
- Surfaces edge cases neither you nor stakeholders considered
- Creates a shared "design concept" (Frederick Brooks' term)
- Is ~25K tokens of high-density, aligned context
- Is ready to feed into Step 2: PRD generation

## Tips from the Workshop

- **Use dictation** — answering 40-100 questions takes time. Dictate your answers rather than typing (Matt uses dictation software, mentions it at 19:05)
- **Don't fight good recommendations** — the AI's recommendations are often excellent (Matt at 19:07: "often what I'll find is the AI's recommendations are really good")
- **Lean into the AI's edge case probing** — it will ask things you and stakeholders never thought of (e.g., "Should points be retroactive?")
- **Feed in domain expert transcripts** — have a meeting with a domain expert, drop the transcript in as the brief, and let the AI grill the assumptions you didn't even know you had
- **Own your stack** — Matt recommends owning your planning process rather than using a third-party tool, so you have observability and can fix things when they break

## What Happens Next

After the grilling session, the user should:

1. **Generate a PRD** — still in the same session, just say "Write a PRD." The AI uses the entire aligned conversation as context.
2. **Generate a Kanban board** — "Break this PRD into independently grabbable issues using vertical slices. Write them as markdown files with blocking relationships."
3. **Run the AFK agent loop** — walk away while the AI implements the AFK-labeled tickets.

See [AFK Agent Loop](../afk-agent-loop/SKILL.md) and [PRD & Kanban Board](../prd-kanban-board/SKILL.md) for those steps.

## Pitfalls

- **Don't skip this step** — going straight from idea to code produces misaligned output that wastes more time than the grilling session
- **Don't batch questions** — the one-at-a-time rhythm is essential for maintaining depth and preventing skips
- **Don't accept the AI's first plan** — push back if the answer feels off. The grilling is a conversation, not a Q&A form
- **Don't treat the conversation as throwaway** — this is your design concept. Keep it. Reference it. Feed it into the next steps
- **Don't try to automate this** — alignment is inherently human-in-the-loop. AFK starts at step 4
