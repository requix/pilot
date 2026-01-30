---
inclusion: always
---

# Identity Learning

PILOT learns about users through natural conversation and silent observation. No manual editing required.

## Core Principle

**Silent capture first, questions rarely** - The system observes patterns in your prompts and silently captures identity information. Only occasionally (max 1/session, 3/week) will it ask clarifying questions.

## How It Works

### Keyword Indicator Approach

PILOT uses simple keyword matching (not complex regex) to detect identity signals. Each category has a list of indicators, and capture occurs when enough indicators match.

### Capture Flow

| Source | Hook | Categories Captured |
|--------|------|---------------------|
| **User prompts** | `user-prompt-submit.sh` | beliefs, challenges, projects, ideas, goals, strategies |
| **AI responses** | `stop.sh` | learnings |

### Capture Thresholds

| Category | Threshold | Rationale |
|----------|-----------|-----------|
| **Ideas** | 1 indicator | Fleeting thoughts - capture immediately |
| **Projects** | 1 indicator | Explicit mentions - capture immediately |
| **Learnings** | 2+ indicators | Need evidence of problem-solving |
| **Beliefs** | 2+ indicators | Need consistent statements |
| **Challenges** | 2+ indicators | Need clear struggle signals |
| **Goals** | 2+ indicators | Need clear intent signals |
| **Strategies** | 2+ indicators | Need clear approach description |

### Keyword Indicators by Category

**Learning indicators:**
`problem`, `solved`, `discovered`, `fixed`, `learned`, `realized`, `figured out`, `root cause`, `issue was`, `turned out`, `bug`, `solution`, `mistake`, `error`, `debugging`

**Belief indicators:**
`i always`, `i never`, `i believe`, `i prefer`, `i think`, `should always`, `must always`, `principle`, `value`, `important to me`

**Challenge indicators:**
`struggling`, `stuck`, `frustrated`, `difficult`, `hard time`, `problem with`, `issue with`, `error`, `failing`, `broken`, `cant`, `cannot`, `can't figure`

**Project indicators:**
`working on`, `my project`, `the project`, `building`, `developing`, `shipping`, `launching`, `maintaining`

**Idea indicators:**
`would be cool`, `could try`, `might try`, `someday`, `idea`, `interesting to`, `explore`, `wonder if`, `what if`

**Goal indicators:**
`my goal`, `trying to`, `want to`, `need to`, `aiming to`, `deadline`, `ship by`, `finish by`, `complete by`

**Strategy indicators:**
`my approach`, `i usually`, `i typically`, `my method`, `my process`, `when i`, `first i`, `before i`

## Examples

### Prompt → Belief Capture (2+ indicators)
```
"I always write tests first, I believe in TDD"
→ Matches: "i always", "i believe" (2 indicators)
→ Captured to BELIEFS.md
```

### Prompt → Idea Capture (1 indicator)
```
"Would be cool to add dark mode"
→ Matches: "would be cool" (1 indicator)
→ Captured to IDEAS.md (threshold is 1)
```

### Response → Learning Capture (2+ indicators)
```
"The problem was a race condition. I fixed it by adding a mutex."
→ Matches: "problem", "fixed" (2 indicators)
→ Captured to learnings
```

## What Gets Captured

| Type | What to Look For |
|------|------------------|
| **BELIEFS** | Principles, convictions, preferences |
| **CHALLENGES** | Problems, blockers, frustrations |
| **PROJECTS** | Active work, codebases |
| **IDEAS** | Future possibilities, explorations |
| **GOALS** | Specific objectives, deadlines |
| **STRATEGIES** | Approaches, methods, processes |
| **LEARNINGS** | Insights from problem-solving |

## Viewing Captured Data

Check what's been captured:
```bash
ls -la ~/.pilot/identity/
cat ~/.pilot/logs/identity-capture.log
```

## Disabling Auto-Capture

To disable silent capture:
```bash
# In ~/.pilot/config/pilot.json
{
  "identity_automation_enabled": false
}
```
