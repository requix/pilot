# STRATEGIES

**How do you approach problems? What's your playbook?**

Strategies are your go-to approaches - the patterns you've found that work. They're more concrete than beliefs, more actionable than models.

---

## My Strategies

### [Problem Type]

**Strategy:** [Your approach]  
**Steps:** [Concrete steps you follow]  
**When it works:** [Success conditions]  
**When it doesn't:** [Failure modes]

---

## Examples

### When Something is Down (Incident Response)

**Strategy:** OODA Loop (Observe, Orient, Decide, Act) + Clear Communication

**Steps:**
1. **Observe**: Check monitoring, logs, recent changes
2. **Orient**: Form hypothesis about cause
3. **Decide**: Choose fix approach (rollback vs hotfix vs scale)
4. **Act**: Execute fix
5. **Communicate**: Status updates every 15min to stakeholders
6. **Post-mortem**: After resolution, document learnings

**When it works:** Most production incidents (80%)  
**When it doesn't:** When root cause is truly novel or monitoring is insufficient

---

### Learning New Technology

**Strategy:** Build Something Real, Not Tutorials

**Steps:**
1. Read official "Getting Started" (30 min max)
2. Pick a real project (something you need)
3. Build it while reading docs as needed
4. Hit a wall, read more, push through
5. Iterate until functional
6. Read "Best Practices" docs
7. Refactor with new knowledge
8. Teach someone else

**When it works:** When technology has good docs  
**When it doesn't:** When docs are poor or tech is too complex (need guided course first)

---

### Debugging Production Issues

**Strategy:** Divide and Conquer with Data

**Steps:**
1. Reproduce the issue (or get clear repro steps)
2. Check recent changes (last 48 hours)
3. Examine logs/metrics for patterns
4. Form top 3 hypotheses
5. Test hypotheses with targeted experiments
6. Isolate root cause
7. Fix + prevent recurrence
8. Document

**When it works:** When you have good observability  
**When it doesn't:** Heisenbugs that disappear when you look at them

---

### Code Review

**Strategy:** Constructive, Educational, Fast

**Steps:**
1. Understand the "why" (read ticket/context)
2. Run the code locally if non-trivial
3. Check:
   - Does it solve the problem?
   - Is it readable?
   - Are there tests?
   - Security issues?
   - Performance concerns?
4. Comment with:
   - Questions (not accusations)
   - Suggestions (not demands)
   - Praise (for good patterns)
5. Distinguish: Must fix vs Nice to have
6. Approve or request changes with clear reasoning

**When it works:** When author is open to feedback  
**When it doesn't:** When relationship is poor or pressure is too high

---

### System Design

**Strategy:** Start Simple, Add Complexity Only When Needed

**Steps:**
1. Define requirements (functional + non-functional)
2. Design simplest solution that could work
3. Identify failure modes
4. Add complexity ONLY for real failure modes
5. Document tradeoffs
6. Build v1 (simple version)
7. Measure actual behavior
8. Iterate based on real data

**When it works:** Most projects (avoid over-engineering)  
**When it doesn't:** When scale/reliability requirements are known to be extreme from start

---

### Career Growth

**Strategy:** Make Yourself Obsolete

**Steps:**
1. Master current role
2. Document everything you do
3. Automate repetitive work
4. Teach others your skills
5. Take on next-level work
6. Repeat

**When it works:** When org has room for growth  
**When it doesn't:** In stagnant organizations (then strategy is: leave)

---

## Why This Matters

Your PILOT agent uses strategies to:
- Suggest proven approaches for problems
- Remind you of your own playbook
- Help you refine strategies over time
- Apply your strategies to new situations

---

## Tips

- **Name your strategies**: Makes them easier to remember and reference
- **Document failures too**: "I tried X, it failed because Y"
- **Update when you learn**: Strategies evolve
- **Share strategies**: Teaching reinforces them

---

## My Strategies

[Delete the template above and write your strategies here]
