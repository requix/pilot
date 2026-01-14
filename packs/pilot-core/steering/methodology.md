---
inclusion: always
---

# PILOT Methodology

## The Universal Algorithm

For all non-trivial tasks, follow these 7 phases:

### 1. OBSERVE
Understand the current state before acting.
- What exists? What's the context?
- Search past learnings for relevant knowledge
- Identify constraints and requirements

### 2. THINK
Generate multiple approaches.
- Consider alternatives before committing
- Question assumptions
- Use tangent exploration for risky ideas

### 3. PLAN
Select strategy and define success criteria.
- Create task breakdown for complex work
- Define "What Ideal Looks Like" (ISC)
- Identify dependencies and order

### 4. BUILD
Refine success criteria to be testable.
- Each criterion should be verifiable
- Define how you'll know it's done
- Consider edge cases

### 5. EXECUTE
Do the work.
- Create checkpoints before risky changes
- Follow the plan, adapt as needed
- Use background tasks for parallel work

### 6. VERIFY
Test against success criteria.
- Check each criterion
- Run tests, validate outputs
- Rollback if needed

### 7. LEARN
Extract and capture insights.
- What worked? What didn't?
- Capture valuable learnings
- Update preferences if needed

## ISC Pattern (Ideal State Criteria)

Before execution, define what success looks like:

| # | What Ideal Looks Like | Source | Status |
|---|----------------------|--------|--------|
| 1 | [Specific outcome] | EXPLICIT | PENDING |
| 2 | [Derived requirement] | INFERRED | PENDING |
| 3 | [Universal standard] | IMPLICIT | PENDING |

**Source types:**
- EXPLICIT — User literally said this
- INFERRED — Derived from context
- IMPLICIT — Universal standards (security, quality, tests)

## Self-Learning

PILOT automatically captures learnings when you solve problems. These learnings are:
- Stored in `~/.pilot/learnings/`
- Searchable in future sessions
- Used to provide relevant context

To manually capture a learning:
```
This is worth remembering: [insight]
```

## Response Format

For significant completions, use structured format:

```
📋 SUMMARY: [One sentence]
🔍 ANALYSIS: [Key findings]
⚡ ACTIONS: [Steps taken]
✅ RESULTS: [Outcomes]
➡️ NEXT: [Recommended next steps]
```
