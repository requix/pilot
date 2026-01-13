# LEARNED

**What lessons have you extracted from experience?**

This is your wisdom database - the hard-won insights from successes and failures. These are more valuable than any tutorial because they're YOUR lessons.

---

## My Learnings

### [Topic/Domain]

**Lesson:** [What you learned]  
**Context:** [When/how you learned it]  
**Cost:** [What it cost you to learn this]  
**Application:** [When to apply this lesson]

---

## Examples

### Infrastructure & Operations

**Lesson: Never deploy on Friday**  
**Context:** Deployed major database migration on Friday afternoon. Issue discovered. Spent entire weekend rolling back.  
**Cost:** Weekend lost, team exhausted, customer trust damaged  
**Application:** Major changes only Monday-Thursday. Fridays for small fixes and documentation.

**Lesson: Monitoring before migration**  
**Context:** Migrated to new database without good metrics. Performance issues but couldn't measure them.  
**Cost:** 2 weeks blind troubleshooting  
**Application:** Set up observability BEFORE any major infrastructure change.

**Lesson: Document while building, not after**  
**Context:** Finished complex system, planned to document later. Never did. Left company. System was black box.  
**Cost:** Team struggled for months, eventually rewrote it  
**Application:** Write README, architecture doc, runbook AS you build.

---

### Technical Decisions

**Lesson: Boring technology is usually the right choice**  
**Context:** Chose hot new database for project. Hit bugs, poor docs, no Stack Overflow answers.  
**Cost:** 3 months rebuilding with PostgreSQL  
**Application:** Use proven tech unless new tech offers 10x improvement.

**Lesson: Premature optimization wastes time**  
**Context:** Spent weeks optimizing code before knowing if it was even the bottleneck.  
**Cost:** Time wasted, actual bottleneck (database) still slow  
**Application:** Profile first, optimize second. Measure, don't guess.

**Lesson: Microservices aren't free**  
**Context:** Split monolith into 20 microservices. Deployment complexity exploded. Debugging became nightmare.  
**Cost:** 6 months dealing with distributed systems problems  
**Application:** Monolith until you have specific reason to split. Complexity has a cost.

---

### Team & Communication

**Lesson: Over-communicate during incidents**  
**Context:** Worked quietly on incident. Team thought I was stuck. Manager panicked.  
**Cost:** Trust damaged, had to explain myself in post-mortem  
**Application:** Status update every 15-30 min during incidents, even if no progress.

**Lesson: Code review is teaching moment**  
**Context:** Initially gave terse review comments. Junior dev felt attacked, became defensive.  
**Cost:** Relationship damaged, quality of their future PRs dropped  
**Application:** Frame reviews as collaborative. Ask questions, don't just critique.

**Lesson: Say no early, not late**  
**Context:** Took on project knowing I was overcommitted. Failed to deliver. Let team down.  
**Cost:** Reputation hit, project delayed, stress through the roof  
**Application:** Say no when plate is full. It's better than promising and failing.

---

### Career & Growth

**Lesson: Job titles matter less than learning rate**  
**Context:** Took senior role at slow company vs mid-level at fast company. Chose title. Regretted it.  
**Cost:** 2 years of slow growth  
**Application:** Optimize for learning and impact, not titles.

**Lesson: Write about what you learn**  
**Context:** Wrote blog post about solving obscure bug. Got me invited to speak at conference. Led to new job.  
**Cost:** None - took 2 hours  
**Application:** Document solutions publicly. You never know what doors it opens.

**Lesson: Mentoring teaches you more than courses**  
**Context:** Explained concepts to junior dev. Realized gaps in my own understanding.  
**Cost:** Time spent mentoring (but positive cost)  
**Application:** Teaching forces clarity. Mentor others to deepen own knowledge.

---

### Failures & Mistakes

**Lesson: Test in production-like environment**  
**Context:** Tested in dev (2GB RAM). Deployed to prod (64GB RAM). Different behavior at scale.  
**Cost:** Production incident, 4-hour outage  
**Application:** Staging environment must match production. Test at production scale.

**Lesson: Backups are worthless until you test restore**  
**Context:** Had backups configured. Never tested restore. When needed, backups were corrupted.  
**Cost:** Lost 6 months of data  
**Application:** Regularly test backup restoration. Backup without restore is just theater.

**Lesson: Always have rollback plan**  
**Context:** Deployed one-way database migration. Had issues. Couldn't roll back.  
**Cost:** 12-hour incident fixing forward  
**Application:** Every deployment must be reversible. Plan rollback before deploying.

---

## Why This Matters

Your PILOT agent uses learnings to:
- Warn you before repeating mistakes
- Suggest relevant lessons for current situations
- Help others benefit from your experience
- Build your personal knowledge base

---

## Tips

- **Capture immediately**: Write lesson while memory is fresh
- **Include cost**: Knowing what it cost makes lesson stick
- **Be specific**: "Document code" is vague. "Write README with setup instructions" is actionable.
- **Update when you learn more**: Lessons can evolve
- **Share painful lessons**: Help others avoid your mistakes

---

## My Learnings

[Delete the template above and write your learnings here]
