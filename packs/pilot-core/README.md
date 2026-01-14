# PILOT Core Pack

> Personal Intelligence Layer for Optimized Tasks

PILOT is a self-learning engineering assistant that follows the Universal Algorithm for systematic problem-solving. It captures learnings from your work and applies them to future problems.

---

## What's Included

| Component | Description |
|-----------|-------------|
| **Universal Algorithm** | 7-phase methodology: Observe → Think → Plan → Build → Execute → Verify → Learn |
| **Self-Learning System** | Automatic capture and retrieval of learnings via semantic search |
| **Identity System** | Personal context files for personalized assistance |
| **Session Tracking** | Pattern detection, metrics, and session archiving |

---

## Self-Learning System

PILOT's core feature is its ability to learn from your work and apply that knowledge to future problems.

### The Complete Cycle

```
┌─────────────────────────────────────────────────────────────────┐
│                    SELF-LEARNING CYCLE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Problem ──► Search Knowledge ──► Apply Past Learning ──► Solve│
│      │                                                          │
│      ▼                                                          │
│   New Insight ──► Capture to File ──► Update Knowledge Base     │
│                                              │                  │
│                                              ▼                  │
│                                    Available for Future         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### How It Works

1. **Capture**: When you solve a problem or discover something valuable, PILOT writes the learning to `~/.pilot/learnings/`

2. **Index**: PILOT updates the knowledge base using Kiro's `/knowledge` tool for semantic search

3. **Search**: When facing a new problem, PILOT searches the knowledge base for relevant past learnings

4. **Apply**: PILOT uses your past learnings to inform solutions to current problems

### Example Flow

```
You: "I have a stuck Terraform state lock. What should I do?"

PILOT: [Searches knowledge base for "terraform state lock"]
       [Finds your previous learning about force-unlock]
       
       "Based on your past experience, use:
        terraform force-unlock LOCK_ID
        
        Key safety note from your learning: Only use when 
        certain no other operations are running."
```

### Capturing Learnings

PILOT captures learnings when you:
- Fix a bug and find the root cause
- Discover a useful pattern or technique
- Learn something about a codebase/project
- Find a solution after investigation

You can also explicitly ask:
```
"I just learned that [insight]. Save this as a learning."
```

### Storage Locations

| Location | Purpose |
|----------|---------|
| `~/.pilot/learnings/` | Learning files (daily markdown) |
| `~/.pilot/patterns/` | Question pattern detection |
| `~/.pilot/sessions/` | Session archives |
| `~/.kiro/knowledge_bases/pilot_*/` | Semantic search index |

---

## Directory Structure

```
~/.kiro/
├── agents/pilot.json         # Agent configuration
├── hooks/pilot/              # Hook scripts
│   ├── agent-spawn.sh        # Session init, context loading
│   ├── user-prompt-submit.sh # Pattern detection
│   ├── pre-tool-use.sh       # Security validation
│   ├── post-tool-use.sh      # Tool tracking
│   └── stop.sh               # Session archiving
├── steering/pilot/           # Methodology guidance
├── pilot/                    # PILOT integration
│   ├── identity/             # Identity templates
│   ├── resources/            # Algorithm & principles
│   ├── scripts/              # Helper scripts
│   ├── memory/               # Session memory
│   └── metrics/              # Session metrics

~/.pilot/                     # Self-learning data
├── learnings/                # Captured learnings (searchable)
├── patterns/                 # Question patterns
├── sessions/                 # Session archives
├── identity/                 # User context
└── logs/                     # System logs
```

---

## The Universal Algorithm

PILOT follows a 7-phase approach to every task:

1. **OBSERVE** - Understand current state (never assume)
2. **THINK** - Generate multiple approaches
3. **PLAN** - Select strategy and define success criteria
4. **BUILD** - Refine criteria to be testable
5. **EXECUTE** - Do the work
6. **VERIFY** - Test against success criteria
7. **LEARN** - Extract and capture insights

**Key principle:** "Verifiability is everything" - Always define what success looks like in BUILD phase before EXECUTE phase.

---

## Prerequisites

### Required: Kiro CLI

PILOT requires Kiro CLI to function.

### Optional but Recommended: Knowledge Feature (Experimental)

PILOT's semantic search uses Kiro CLI's experimental `/knowledge` feature. This enables intelligent retrieval of past learnings.

**To enable:**
```bash
kiro-cli settings chat.enableKnowledge true
```

**What happens without it:**
- ✅ Learning capture still works (files saved to `~/.pilot/learnings/`)
- ✅ Basic functionality works
- ❌ Semantic search disabled - agent can't search past learnings intelligently
- ❌ All learnings loaded at session start (inefficient as learnings grow)

**Note:** The `/knowledge` feature is experimental and may change in future Kiro CLI versions.

---

## Installation

### Using the Install Script (Recommended)

```bash
cd src
./install.sh
```

For updates (preserves identity and learnings):
```bash
./install.sh --update
```

### First-Time Setup

After installation, set up the knowledge base for learnings:

```
# In Kiro CLI with pilot agent:
Please add my learnings folder (~/.pilot/learnings) to the knowledge base
```

This enables semantic search across your captured learnings.

---

## Usage

After installation:

1. **Select the pilot agent** in Kiro CLI: `kiro-cli chat --agent pilot`
2. **Start working** - PILOT follows the Universal Algorithm
3. **Learnings are captured automatically** when you solve problems
4. **Past learnings inform future solutions** via semantic search

### Example: Learning Capture

```
You: "I just learned that git stash --include-untracked stashes 
      untracked files too. Save this."

PILOT: ✅ Learning captured and indexed!
       - Saved to ~/.pilot/learnings/20260114.md
       - Updated in knowledge base for future searches
```

### Example: Learning Retrieval

```
You: "How do I stash files including new ones I haven't added yet?"

PILOT: [Searches knowledge base]
       
       Based on your past learning: Use `git stash --include-untracked`
       to stash untracked files along with tracked changes.
```

---

## Customization

### Identity Context

Create your identity file for personalized assistance:

```bash
cp ~/.pilot/identity/context.md.template ~/.pilot/identity/context.md
# Edit with your details
```

### Knowledge Base

Add project documentation to the knowledge base:

```
# In Kiro CLI:
Please add [path/to/docs] to the knowledge base as "project-docs"
```

---

## Troubleshooting

### Agent not appearing

```bash
cat ~/.kiro/agents/pilot.json | head -5
```

### Hooks not executing

```bash
chmod +x ~/.kiro/hooks/pilot/*.sh
```

### Knowledge base not searching

Ensure the feature is enabled:
```bash
kiro-cli settings chat.enableKnowledge true
```

Then add learnings to knowledge base:
```
/knowledge add --name "pilot-learnings" --path ~/.pilot/learnings --index-type Best
```

---

## Version

**v1.1.0** - Self-Learning System with Knowledge Base Integration

---

## Related

- [INSTALL.md](INSTALL.md) - Installation guide
- [VERIFY.md](VERIFY.md) - Verification checklist
- [the-algorithm.md](resources/the-algorithm.md) - Universal Algorithm details
