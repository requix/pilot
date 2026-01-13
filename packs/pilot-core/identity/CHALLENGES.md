# CHALLENGES

**What obstacles are you facing right now?**

This is your current struggle log - the problems you're actively working through. Documenting challenges helps you think through them and track progress.

---

## Current Challenges

### [Challenge Name]

**The Problem:** [Clear description]  
**Why It Matters:** [Impact if not solved]  
**What I've Tried:** [Approaches attempted]  
**What's Blocking Me:** [Root obstacles]  
**Potential Solutions:** [Ideas to try]  
**Help Needed:** [What would unblock this]

---

## Examples

### Technical Challenges

**Challenge: Database Performance Degradation**

**The Problem:** API latency has increased from 200ms to 1.2s over last month. Database CPU at 90%.

**Why It Matters:** Customers complaining, risking churn. Engineering velocity down because dev/test environments also slow.

**What I've Tried:**
- Added indexes on common queries (helped 10%)
- Increased instance size (helped 20%, but expensive)
- Analyzed slow query log (identified N+1 queries)

**What's Blocking Me:**
- Fixing N+1 queries requires refactoring 15 services
- Don't have time for major refactor right now
- Need to keep system running while fixing

**Potential Solutions:**
- Read replicas for read-heavy queries
- Implement caching layer (Redis)
- Refactor worst 3 services first (Pareto principle)
- Schedule refactor sprint next month

**Help Needed:** Architecture review from senior eng, budget approval for Redis cluster

---

**Challenge: Kubernetes Learning Curve**

**The Problem:** Team is struggling with K8s complexity. Deployments taking 3 hours that used to take 30 min.

**Why It Matters:** Velocity down, team morale down, questioning if K8s migration was right choice.

**What I've Tried:**
- Wrote documentation (not being read)
- Pair programming sessions (helps but doesn't scale)
- Simplified deployment scripts (helped somewhat)

**What's Blocking Me:**
- K8s has steep learning curve
- Team is under pressure, no time for training
- I'm the only one who understands it deeply

**Potential Solutions:**
- Dedicated training week (but stakeholders won't approve)
- Build abstraction layer (helm charts + CI/CD)
- Hire K8s consultant for week-long workshop
- Create video tutorials (more engaging than docs)

**Help Needed:** Buy-in from management for training time, budget for consultant

---

### Career Challenges

**Challenge: Technical Debt vs New Features**

**The Problem:** Product wants features, I want to pay down technical debt. Constant tension.

**Why It Matters:** Debt is slowing us down, but features are what users/investors see. Need balance.

**What I've Tried:**
- Explaining technical debt to product (they don't get it)
- Sneaking debt work into feature work (feels dishonest)
- Proposing dedicated debt sprints (rejected)

**What's Blocking Me:**
- Misaligned incentives: Product measured on features, Eng on reliability
- Hard to quantify debt cost
- Urgency of new features

**Potential Solutions:**
- Create "velocity metric" showing slowdown from debt
- Propose 20% time for debt work
- Frame debt work as "productivity features for engineering"
- Tie debt to concrete business impact (cost, reliability, speed)

**Help Needed:** Executive sponsor who understands technical debt, data showing debt cost

---

### Learning Challenges

**Challenge: Keeping Up With New Technologies**

**The Problem:** New tools/frameworks every week. Feeling behind. Imposter syndrome growing.

**Why It Matters:** Fear of becoming obsolete. Affects confidence in interviews/discussions.

**What I've Tried:**
- Following tech Twitter (overwhelming, FOMO)
- Reading Hacker News daily (also overwhelming)
- Trying to learn everything (burning out)

**What's Blocking Me:**
- Can't learn everything
- Don't know what's worth learning vs fads
- Limited time outside work

**Potential Solutions:**
- Focus on fundamentals (systems design, algorithms) not trendy frameworks
- Deep over broad (master one thing vs surface-level many things)
- Create learning criteria (only learn if immediately applicable)
- Accept that I can't know everything

**Help Needed:** Mentor to help prioritize what's worth learning

---

### Team Challenges

**Challenge: Remote Team Coordination**

**The Problem:** Team spread across 4 timezones. Async work is hard. Blockers sit for 12+ hours.

**Why It Matters:** Delays shipping, frustrating for team, meetings at bad times for someone.

**What I've Tried:**
- More detailed documentation (helps but not enough)
- Overlap hours (burns out people in bad timezones)
- Async standups (lose human connection)

**What's Blocking Me:**
- Physics (can't change timezones)
- Company policy (everyone must work from their location)
- Team size (too small to have coverage in all zones)

**Potential Solutions:**
- Find "golden hours" with maximum overlap
- Better async practices (video Loom messages)
- Clear ownership (minimize cross-timezone dependencies)
- Consider hiring to fill timezone gaps

**Help Needed:** Company support for async-first culture, budget for timezone-appropriate hires

---

## Resolved Challenges (Recent Wins)

### Database Migration Completed
**Resolved:** Jan 20, 2026  
**How:** Careful planning, incremental rollout, tested rollback  
**Lesson Learned:** Incremental > big bang. Always have rollback plan.

---

## Why This Matters

Your PILOT agent uses challenges to:
- Help brainstorm solutions
- Connect you to relevant resources
- Track progress on long-term challenges
- Celebrate when challenges are resolved
- Learn from how you solve problems

---

## Tips

- **Be specific**: "Work is hard" → "Database is slow due to N+1 queries"
- **Update regularly**: As you try solutions, document results
- **Move to LEARNED when solved**: Extract lessons
- **It's okay to have challenges**: Everyone does
- **Ask for help**: Documenting the challenge clarifies what help you need

---

## My Challenges

[Delete the template above and write your challenges here]
