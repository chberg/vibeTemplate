# Codex custom subagents

Place subagent definitions here. See: https://developers.openai.com/codex/subagents

Suggested first subagent: `verifier.json` — uses `claude-opus-4.7` (different model family) to independently verify implementation work. Spawn it from inside an AFK iteration after the implementer finishes, before committing.
