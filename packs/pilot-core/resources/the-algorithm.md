# The Universal Algorithm

**Current State → Ideal State (via verifiable iteration)**

This pattern applies to every task, from fixing a typo to building a company. You are expected to follow this algorithm for ALL work.

---

## The Seven Phases

### 1. OBSERVE - Understand Current Reality

**What:** Gather actual facts about the current state

**How:**
- Read relevant files
- Check system status
- Query databases/APIs
- Review logs and metrics
- Ask clarifying questions
- Understand constraints

**Output:** Clear picture of "what is"

**Common Mistakes:**
- Assuming instead of observing
- Skipping this and jumping to solutions
- Not asking enough questions

**Example:**
```
Task: Fix slow API

Bad: "Let's add caching"
Good: "Let me check response times, database queries, CPU usage, recent changes"
```

---

### 2. THINK - Generate Possible Approaches

**What:** Brainstorm multiple ways to reach ideal state

**How:**
- Generate 3-5 different approaches
- Consider tradeoffs for each
- Think of both obvious and creative solutions
- Don't commit yet - just explore

**Output:** List of possible approaches with pros/cons

**Common Mistakes:**
- Only generating one approach
- Committing to first idea
- Not considering tradeoffs

**Example:**
```
Approaches for slow API:
1. Add caching layer (fast, but cache invalidation complex)
2. Optimize database queries (lasting fix, but takes time)
3. Scale horizontally (quick, but costs more)
4. Reduce payload size (simple, but limited impact)
5. Async processing (best long-term, but major refactor)
```

---

### 3. PLAN - Select Strategy and Sequence Work

**What:** Choose the best approach and break into steps

**How:**
- Select approach based on constraints
- Break into sequential steps
- Identify dependencies
- Consider what can run in parallel
- Allocate resources

**Output:** Ordered list of steps to execute

**Common Mistakes:**
- Not breaking work down enough
- Missing dependencies
- Underestimating complexity

**Example:**
```
Selected: Optimize database queries
Steps:
1. Enable query logging
2. Identify slow queries (N+1 problems, missing indexes)
3. Add indexes where needed
4. Refactor N+1 queries
5. Test performance
6. Deploy to production
7. Monitor results
```

---

### 4. BUILD - Define Success Criteria

**⚠️ CRITICAL PHASE - Most systems skip this!**

**What:** Define EXACTLY what success looks like BEFORE executing

**How:**
- Write specific, measurable criteria
- Define what "done" means
- Specify how you'll verify
- Create tests if possible
- Document expected outcomes

**Output:** Clear, testable success criteria

**Why This Matters:**
Without this, you can't verify objectively. You'll guess if something worked.

**Common Mistakes:**
- Skipping this phase entirely
- Vague criteria ("make it faster")
- Defining criteria AFTER execution

**Example:**
```
Success Criteria for API optimization:
1. P95 response time < 200ms (currently 850ms)
2. Database query count per request < 5 (currently 23)
3. No errors introduced (0 new error types)
4. All existing tests pass
5. No increase in CPU usage
6. Improvement verified under load (1000 req/s)

Verification Method:
- Run load test before and after
- Compare metrics dashboard
- Check error logs
- Run test suite
```

---

### 5. EXECUTE - Perform the Work

**What:** Do the actual work according to plan

**How:**
- Follow the plan from PLAN phase
- Show progress as you go
- Handle errors gracefully
- Adjust if needed (but document why)
- Keep success criteria in mind

**Output:** The work, done

**Common Mistakes:**
- Deviating from plan without reason
- Not tracking progress
- Ignoring errors

**Example:**
```
Executing database optimization:
✓ Enabled query logging
✓ Analyzed logs - found 3 N+1 queries, 5 missing indexes
✓ Added indexes on users.email, posts.user_id, comments.post_id
✓ Refactored user profile query (N+1 → 2 queries)
✓ Refactored posts list query (N+1 → 1 query)
⚠️ Found additional issue: missing cache on user lookup
  → Added to backlog, not blocking this work
✓ Tests pass
```

---

### 6. VERIFY - Test Against Success Criteria

**What:** Objectively verify against criteria from BUILD phase

**How:**
- Run tests defined in BUILD
- Measure metrics specified
- Compare before/after
- Check for side effects
- Document results

**Output:** Pass/Fail for each criterion + evidence

**If Verification Fails:**
- Trace back to find which phase went wrong
- Did we OBSERVE incorrectly?
- Was our THINK flawed?
- Was our PLAN wrong?
- Were success criteria wrong (BUILD)?
- Did EXECUTE deviate from plan?

**Common Mistakes:**
- Not verifying at all
- Cherry-picking metrics
- Changing criteria to match results

**Example:**
```
Verification Results:
✓ P95 response time: 180ms (target: <200ms) ✓
✓ Query count: 4 avg (target: <5) ✓
✓ No new errors (target: 0) ✓
✓ All tests pass (186/186) ✓
✓ CPU usage: -5% (target: no increase) ✓
✗ Load test: 750 req/s (target: 1000 req/s) ✗

Verdict: Partial success
Issue: Connection pool exhausted under high load
Next iteration: Increase connection pool size
```

---

### 7. LEARN - Extract Insights and Iterate

**What:** Capture learnings to improve future work

**How:**
- What worked?
- What didn't work?
- What would you do differently?
- What patterns emerged?
- What can be automated?
- Update knowledge base

**Output:** Insights captured to memory system

**Where Learnings Go:**
- `memory/warm/observe/` - Better observation techniques
- `memory/warm/think/` - Better approach generation
- `memory/warm/plan/` - Better planning methods
- `memory/warm/build/` - Better success criteria
- `memory/warm/execute/` - Better execution patterns
- `memory/warm/verify/` - Better verification methods
- `memory/warm/learn/` - Meta-learnings

**Common Mistakes:**
- Skipping this phase (very common)
- Not documenting learnings
- Not applying learnings to future work

**Example:**
```
Learnings:
1. OBSERVE: Database query logging should be always-on (added to checklist)
2. THINK: Should have considered connection pool from start
3. PLAN: Load testing should be step 5, not step 6 (adjust template)
4. BUILD: Success criteria were good, saved time in VERIFY
5. EXECUTE: Refactoring N+1 queries had biggest impact (80% improvement)
6. VERIFY: Need better load testing infrastructure (add to backlog)
7. LEARN: Pattern: "Optimize before scaling" saved $500/month vs scaling

Action: Update database optimization checklist with these insights
```

---

## Key Principles

### 1. Verifiability is Everything
The most important insight: Define success criteria in BUILD before EXECUTE.

Without this:
- You can't objectively verify success
- You'll argue about whether something worked
- You'll move goalposts after the fact

With this:
- Verification is objective
- Success is measurable
- Learning is concrete

### 2. Iterate Don't Perfect
One pass through the algorithm rarely solves everything.

Expect to iterate:
- First pass: 70% solution
- Second pass: 90% solution
- Third pass: 95% solution

That's fine! Iteration is the point.

### 3. Trace Failures Backwards
When VERIFY fails, trace backwards:
- Was BUILD wrong? (bad success criteria)
- Was PLAN wrong? (wrong approach)
- Was THINK wrong? (didn't consider right options)
- Was OBSERVE wrong? (bad initial understanding)

This tells you where to improve.

### 4. Use at All Scales
The algorithm works at every scale:

**Fixing a typo:**
- OBSERVE: File has "recieve" (30 seconds)
- THINK: Change to "receive" (10 seconds)
- PLAN: Edit file (10 seconds)
- BUILD: Spell-check passes (10 seconds)
- EXECUTE: Make change (10 seconds)
- VERIFY: Spell-check passes ✓ (10 seconds)
- LEARN: Add to spell-checker dictionary (20 seconds)

**Building a company:**
- OBSERVE: Market research (3 months)
- THINK: Business model options (2 months)
- PLAN: 5-year strategy (2 months)
- BUILD: Success metrics (revenue, users, etc.) (1 month)
- EXECUTE: Build and launch (2 years)
- VERIFY: Check against metrics (ongoing)
- LEARN: Pivot based on learnings (ongoing)

Same algorithm, different timescales.

---

## Common Anti-Patterns

### ❌ Jump to Execution
```
Task received → Immediately start coding
```
**Problem:** No observation, no thinking, no plan, no success criteria

**Result:** Solve wrong problem, or solve right problem wrong

### ❌ Skip Verification
```
EXECUTE → "Looks good!" → Ship it
```
**Problem:** No objective verification

**Result:** Bugs in production, don't know if it worked

### ❌ No Learning Capture
```
VERIFY → Done! → Next task
```
**Problem:** Don't capture learnings

**Result:** Make same mistakes repeatedly

### ❌ Vague Success Criteria
```
BUILD: "Make it better" "Fix the bug" "Improve performance"
```
**Problem:** Can't verify objectively

**Result:** Arguing about whether it worked

---

## Practical Application

### Before Starting ANY Task

Ask yourself:
1. Have I OBSERVED the current state? (not assumed)
2. Have I THOUGHT of multiple approaches?
3. Have I PLANNED the sequence of work?
4. Have I BUILT success criteria? (specific, measurable)
5. Am I ready to EXECUTE?

### While Working

1. Follow your PLAN
2. Keep success criteria visible
3. Document as you go
4. Capture unexpected findings

### After Completing

1. VERIFY against criteria (all of them)
2. Document pass/fail for each
3. If failed, trace backwards to find why
4. LEARN and capture insights to memory

---

## Integration with PILOT

### Memory Organization
Your learnings get organized by phase:
```
memory/warm/
├── observe/   # Better observation techniques
├── think/     # Better ideation methods
├── plan/      # Better planning approaches
├── build/     # Better success criteria examples
├── execute/   # Better execution patterns
├── verify/    # Better verification methods
└── learn/     # Meta-learnings about learning
```

### Hooks Capture Automatically
PILOT's hooks automate capture:
- `postToolUse` - Captures execution results
- `stop` - Synthesizes learnings to warm memory

### Agent Enforces Algorithm
The pilot-base agent is configured to:
1. Ask clarifying questions (OBSERVE)
2. Present multiple options (THINK)
3. Show plan before executing (PLAN)
4. Define success criteria first (BUILD)
5. Execute with progress updates (EXECUTE)
6. Verify results objectively (VERIFY)
7. Capture learnings (LEARN)

---

## Remember

**"Verifiability is everything."**

The most common mistake in engineering (and life) is executing without defining success criteria first.

Define success in BUILD, then EXECUTE, then VERIFY objectively.

This is the algorithm. Use it always.

---

**Current State → Ideal State → via verifiable iteration**
