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

When you solve a non-trivial problem, debug an issue, or discover something valuable, **capture the learning**.

### When to Capture
- Fixed a bug and found the root cause
- Discovered a useful pattern or technique
- Learned something about the codebase/project
- Found a solution after investigation

### How to Capture
1. Write the learning to the learnings file:
```bash
echo -e "\n## [Title]\n**Context:** [situation]\n**Learning:** [insight]\n" >> "$HOME/.pilot/learnings/$(date +%Y%m%d).md"
```

2. Update the knowledge base so it's searchable:
   - Use the `knowledge` tool to update the "pilot-learnings" entry
   - If "pilot-learnings" doesn't exist, add it first pointing to `~/.pilot/learnings`

### Searching Past Learnings
Before solving a problem, search the knowledge base for relevant past learnings:
- Use the `knowledge` tool to search for related topics
- Apply relevant learnings to the current problem

### Don't Capture
- Routine tasks without insights
- Simple lookups or reads

## Response Format

For significant completions, use structured format:

```
📋 SUMMARY: [One sentence]
🔍 ANALYSIS: [Key findings]
⚡ ACTIONS: [Steps taken]
✅ RESULTS: [Outcomes]
➡️ NEXT: [Recommended next steps]
```
