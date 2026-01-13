# The 15 PILOT Principles

**Decision-making guidelines that inform how PILOT works**

These aren't features to build - they're principles that guide architectural decisions and daily work. When in doubt, refer to these.

---

## 1. The Algorithm Always

**Use OBSERVE → THINK → PLAN → BUILD → EXECUTE → VERIFY → LEARN for everything**

- From fixing typos to designing systems
- At all scales and timescales
- No exceptions

**Why:** Universal pattern that works. Skipping phases causes failures.

**In Practice:**
```
❌ "Let me fix that bug" → immediately coding
✅ OBSERVE bug → THINK of causes → PLAN fix → BUILD test → EXECUTE → VERIFY → LEARN
```

---

## 2. Clear Thinking Precedes Good Prompts

**Understand the problem before asking AI**

- Don't use AI as a substitute for thinking
- Think first, prompt second
- Clear questions get clear answers

**Why:** Garbage in, garbage out. AI amplifies your thinking quality.

**In Practice:**
```
❌ "Help me with this code"
✅ "I need to optimize this database query that's taking 850ms. I think it's an N+1 problem. Help me verify and fix."
```

---

## 3. System Architecture > Model Choice

**How you build matters more than which LLM you use**

- Focus on architecture (memory, hooks, structure)
- Don't chase the latest model
- Good architecture works with any model

**Why:** Models change monthly. Architecture lasts years.

**In Practice:**
- PILOT works with Claude, could work with others
- Memory system matters more than which model
- Hooks matter more than prompt engineering

---

## 4. Deterministic Infrastructure Over Probabilistic AI

**Use code/config for infrastructure, AI for creativity**

- Infrastructure as code (deterministic)
- Not "AI-generated infrastructure" (probabilistic)
- AI helps write code, but code defines truth

**Why:** Infrastructure must be reliable, reproducible, version-controlled.

**In Practice:**
```
❌ "AI, deploy to production" (probabilistic, no audit trail)
✅ AI writes Terraform → You review → Terraform apply (deterministic, auditable)
```

---

## 5. Code Before Prompts When Possible

**Automate with code first, use prompts when code isn't suitable**

Decision hierarchy:
1. **Code** - If you can script it, script it
2. **CLI** - If code is overkill, use CLI tools
3. **Prompts** - If above don't work, prompt AI
4. **Agents** - If prompts are repetitive, make agents

**Why:** Code is precise, reusable, testable, fast.

**In Practice:**
```
Task: Check AWS resources across 50 accounts

❌ Prompt AI 50 times
✅ Script with AWS CLI → AI helps write script if needed
```

---

## 6. Specifications and Tests First

**Define what success looks like before building**

- Write specs before code
- Write tests before implementation
- This is BUILD phase of the Algorithm

**Why:** You can't verify what you didn't define.

**In Practice:**
```
Task: Add caching layer

❌ Build cache → "Does it work?" → Try it
✅ Write: "Cache hit rate >80%, P95 latency <50ms" → Build → Measure
```

---

## 7. UNIX Philosophy

**Do one thing well, compose tools**

- Each agent does one thing
- Each pack solves one problem
- Combine them for complex tasks

**Why:** Simple tools compose better than complex ones.

**In Practice:**
```
❌ One agent that does: AWS + K8s + Terraform + Security
✅ aws-architect agent + k8s-operator agent + terraform-expert agent + security-auditor agent
```

---

## 8. Engineering/SRE Principles for AI Systems

**Treat AI systems like production software**

- Version control
- Rollback capability
- Monitoring and logging
- Incident response
- Post-mortems

**Why:** AI systems ARE production systems.

**In Practice:**
- PILOT is in git
- Changes are commits
- Can rollback to previous version
- Memory system logs everything
- Learn from failures

---

## 9. CLI as Primary Interface

**Terminal first, GUI second (or never)**

- Everything should work in terminal
- Scripts should be pipeable
- Automation-friendly

**Why:** GUIs don't compose. CLIs do.

**In Practice:**
```
✅ pilot install pack aws-foundation
✅ kiro-cli --agent aws-architect
✅ pilot list packs | grep aws

❌ Click "Install" button
```

---

## 10. Decision Hierarchy

**Goal → Code → CLI → Prompts → Agents (in that order)**

When solving a problem:
1. **Goal** - What are you trying to achieve? (OBSERVE)
2. **Code** - Can you write code to solve it?
3. **CLI** - Can you use existing CLI tools?
4. **Prompts** - Do you need AI assistance?
5. **Agents** - Is this repetitive enough to warrant an agent?

**Why:** Use the simplest solution that works.

**In Practice:**
```
Task: Deploy to 10 servers

Goal: Zero-downtime deployment
Code: Write deployment script
CLI: Use script with parallel execution
Prompts: Ask AI to help write script
Agents: If you deploy daily, make deployment-agent
```

---

## 11. Self-Updating Systems

**Systems that learn from failures and improve**

- Capture errors
- Learn patterns
- Update procedures
- Prevent recurrence

**Why:** Manual improvement is slow. Automated improvement scales.

**In Practice:**
- VERIFY failure → Trace to phase → Update that phase's process
- Store learning in `memory/warm/[phase]/`
- Future work references past learnings

---

## 12. Modular Skill Management

**Install only what you need, compose for complex tasks**

- Start with pilot-core (foundation)
- Add packs as needed
- No bloat, no unused features

**Why:** Complexity kills systems. Start simple, grow deliberately.

**In Practice:**
```
Week 1: pilot-core (foundation)
Week 2: + aws-foundation (need AWS work)
Week 3: + kubernetes-ops (started K8s project)
Week 4: + terraform-expert (IaC standardization)
```

---

## 13. Historical Capture Feeds Future Context

**Memory makes AI useful**

- Capture everything to memory
- Hot → Warm → Cold flow
- Future decisions informed by past

**Why:** Without memory, you repeat mistakes and repeat yourself.

**In Practice:**
```
Month 1: Work on Database optimization
        → Captured to memory

Month 3: New database performance issue
        → Agent loads past learnings
        → "I see we solved similar issue before..."
        → Faster resolution
```

---

## 14. Agent Personalities for Specialized Work

**Different agents for different roles**

- aws-architect for infrastructure design
- security-auditor for compliance
- sre-oncall for incidents
- Each has specialized knowledge and permissions

**Why:** Context switching is expensive. Specialized agents maintain context.

**In Practice:**
```
Infrastructure design:
kiro-cli --agent aws-architect
→ Loads: Well-Architected Framework, cost optimization, security best practices

Incident response:
kiro-cli --agent sre-oncall
→ Loads: Runbooks, troubleshooting guides, recent incidents
```

---

## 15. Science as Meta-Loop

**Hypothesis → Experiment → Measure → Iterate**

- Treat improvements as experiments
- Measure results
- Keep what works
- Discard what doesn't

**Why:** Data beats opinions. Measurement enables improvement.

**In Practice:**
```
Hypothesis: "Adding caching will reduce latency by 50%"

Experiment:
1. Measure baseline (OBSERVE)
2. Add caching (EXECUTE)
3. Measure results (VERIFY)
4. Compare to hypothesis

Result: Latency reduced by 60%

Learning: Cache effectiveness exceeded expectations
Next: Apply caching pattern to other services
```

---

## How Principles Work Together

### Example: Optimizing API Performance

**Principles in action:**

1. **Algorithm** - Follow 7 phases
2. **Clear thinking** - Understand problem first
3. **Architecture** - Memory captures learnings
4. **Deterministic** - Changes via code, not ad-hoc
5. **Code first** - Script performance tests
6. **Specs first** - Define target metrics
7. **UNIX** - Compose monitoring tools
8. **Engineering** - Version control changes
9. **CLI** - Automate testing
10. **Hierarchy** - Goal → Code → Prompts
11. **Self-updating** - Capture optimization patterns
12. **Modular** - Use observability pack
13. **Historical** - Reference past optimizations
14. **Specialized** - Use sre-agent
15. **Scientific** - Measure everything

Result: Systematic, reproducible, learning-driven improvement.

---

## When Principles Conflict

Sometimes principles seem to conflict. Resolution:

### "Code before prompts" vs "Use specialized agents"

**Resolution:** Both are true at different scales
- One-off task? Code or CLI
- Repetitive task? Make specialized agent

### "UNIX philosophy" vs "Complex workflows"

**Resolution:** Compose simple tools for complex workflows
- Don't make one complex tool
- Make simple tools that work together

### "Deterministic infrastructure" vs "AI assistance"

**Resolution:** AI helps write deterministic code
- AI generates Terraform (deterministic)
- Not: AI provisions infrastructure (probabilistic)

---

## Applying Principles Daily

### Morning
```
Start with pilot-base agent
Agent loads your MISSION, GOALS, PROJECTS (Principle 13: Historical context)
Review memory from yesterday
```

### During Work
```
New task arrives
↓
OBSERVE → THINK → PLAN → BUILD → EXECUTE → VERIFY → LEARN (Principle 1)
↓
Can I code this? (Principle 5)
If yes: Code → test → commit
If no: Prompt AI → review → commit
```

### End of Day
```
Agent captures session to memory (Principle 11: Self-updating)
Learnings flow to warm memory
Tomorrow benefits from today's work (Principle 13)
```

---

## Anti-Patterns (Violations of Principles)

### ❌ "AI, fix everything"
**Violates:** Clear thinking (#2), Code before prompts (#5), Decision hierarchy (#10)

**Better:** Understand problem → Code fix if possible → Use AI to help write code

### ❌ "Let's add every feature"
**Violates:** Modular (#12), UNIX philosophy (#7)

**Better:** Start minimal, add only what's needed

### ❌ "This worked once, ship it"
**Violates:** Specs and tests first (#6), Scientific method (#15)

**Better:** Define success criteria, measure, verify

### ❌ "I'll remember how I did this"
**Violates:** Historical capture (#13), Self-updating (#11)

**Better:** Document in memory system, reference later

---

## Remember

These principles aren't rules to follow blindly. They're **guidelines for making good decisions** when the path isn't obvious.

When facing a choice, ask:
- "Which approach follows these principles?"
- "Which principles apply here?"
- "Am I violating principles for a good reason?"

Good reasons exist to violate principles. But know you're doing it and why.

---

## Principle of Principles

**Use principles as guidelines, not rules. Think, don't just follow.**

The meta-principle: These principles help you think better. They don't replace thinking.

When principles help: Use them.
When principles hinder: Question them.
But understand them first before dismissing them.

---

**These 15 principles make PILOT different from "just another AI tool."**

They encode wisdom from decades of software engineering, applied to AI systems.

Follow them, and you'll build systems that last.
