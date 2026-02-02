# MODELS

**What mental frameworks do you use to understand the world?**

Models are the lenses through which you see problems. They're the frameworks, analogies, and mental tools you reach for when tackling challenges.

---

## My Mental Models

### [Model Name]
**What it is:** [Brief explanation]  
**When I use it:** [Situations where this applies]  
**Example:** [Concrete example]

---

## Examples

### The Universal Algorithm (OBSERVE→THINK→PLAN→BUILD→EXECUTE→VERIFY→LEARN)
**What it is:** Seven-phase approach to any problem  
**When I use it:** Every task, from debugging to designing systems  
**Example:** When API is slow, I OBSERVE metrics first (not guess), THINK of approaches, PLAN the fix, BUILD success criteria, EXECUTE, VERIFY, and LEARN

### Systems Thinking
**What it is:** Everything is part of interconnected systems with feedback loops  
**When I use it:** Designing architecture, debugging complex issues  
**Example:** Slow database isn't just a database problem - could be network, connection pooling, query patterns, caching, or load balancer config. Check the system.

### Second-Order Thinking
**What it is:** Consider consequences of consequences  
**When I use it:** Making architectural decisions  
**Example:** "Adding caching" solves latency (first-order). But creates cache invalidation complexity, memory pressure, and debugging difficulty (second-order). Worth it?

### Pareto Principle (80/20 Rule)
**What it is:** 80% of results come from 20% of effort  
**When I use it:** Prioritization, optimization  
**Example:** 3 API endpoints account for 80% of traffic. Optimize those first, not all 50 endpoints.

### Technical Debt as Financial Debt
**What it is:** Shortcuts have interest payments  
**When I use it:** Deciding whether to refactor or move fast  
**Example:** Skipping tests is like taking a loan - you move faster now but pay interest (bugs, slow development) until you pay it back (write tests).

### Conway's Law
**What it is:** System design mirrors communication structure  
**When I use it:** Org design, microservices boundaries  
**Example:** If backend and frontend teams don't talk, the API will be poorly designed. Fix communication before fixing API.

### Premature Optimization
**What it is:** Optimizing before knowing where bottleneck is wastes time  
**When I use it:** When team wants to "make it fast"  
**Example:** Don't add caching/CDN/sharding until you measure and find actual bottleneck. Profile first, optimize second.

### Fail Fast Principle
**What it is:** Detect and report errors immediately, don't mask them  
**When I use it:** Error handling, input validation  
**Example:** Validate API input immediately and return 400, don't process bad data and fail mysteriously later.

### Unix Philosophy
**What it is:** Do one thing well, compose tools  
**When I use it:** Building tools, designing APIs  
**Example:** Don't build "deployment-monitoring-testing-tool". Build separate tools that pipe together.

### Occam's Razor
**What it is:** Simplest explanation is usually correct  
**When I use it:** Debugging, architecture decisions  
**Example:** Service is slow. Could be advanced cache coherency issue OR someone increased timeout. Check timeout first.

---

## Why This Matters

Your PILOT agent uses models to:
- Frame problems using your preferred frameworks
- Suggest relevant models for situations
- Remind you of models you've forgotten
- Learn which models you apply successfully

---

## Tips

- **Name your models**: Even if you invented it, give it a name
- **Collect actively**: When you have an "aha" moment, capture the pattern
- **Note when you use them**: Strengthen neural pathways
- **Combine models**: Best solutions use multiple frameworks

---

## My Models

[Delete the template above and write your models here]
