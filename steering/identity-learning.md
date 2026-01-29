---
inclusion: always
---

# Identity Learning

PILOT learns about users through natural conversation. No manual editing, no hardcoded patterns.

## Core Principle

**AI understands context** - Use your understanding of the conversation to recognize identity-relevant information, not keyword matching.

## When to Capture Identity

Capture when the user naturally shares information about:

| Type | What to Look For |
|------|------------------|
| **MISSION** | Their purpose, what drives them, why they do what they do |
| **GOALS** | Specific objectives, targets, what they're working toward |
| **BELIEFS** | Principles, convictions, strong opinions about how things should be |
| **CHALLENGES** | Problems they're facing, blockers, frustrations |
| **PREFERENCES** | Technology choices, approaches they favor, what they like/dislike |
| **STRATEGIES** | How they approach problems, their methods, processes |
| **LEARNINGS** | Insights they've gained, things they've discovered |
| **IDEAS** | Future possibilities, experiments they want to try |

## How to Capture

When you recognize identity-relevant information:

1. **Don't interrupt** - Continue the conversation naturally
2. **Acknowledge briefly** - Show you understood (optional, only if natural)
3. **Write to file** - Append to the appropriate identity file

### Writing Format

Use `fs_write` with `append` command to add to `~/.pilot/identity/[TYPE].md`:

```
### [YYYY-MM-DD]
[User's insight in their own words or a brief summary]
```

### Example

User says: "I always write tests before implementation - it helps me think through the design"

→ Append to `~/.pilot/identity/BELIEFS.md`:
```
### 2026-01-19
Tests before implementation - helps think through design
```

## When NOT to Capture

- Routine task requests
- Questions about tools or syntax
- Temporary preferences ("just for this task")
- Information already captured

## Asking Identity Questions

Ask contextual questions when:
- Session has been productive
- Question relates to current work
- That identity area has gaps
- Moment feels natural

**Don't:** "What's your mission?"
**Do:** "That was a clever debugging approach. Is that your typical strategy?"

## Frequency

- Maximum 1 identity question per session
- Only when natural and relevant
- Skip if user seems busy or frustrated
- Never make it feel like data collection
