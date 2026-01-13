# PILOT Core Pack

> The foundation of your personal AI infrastructure

PILOT (Platform for Intelligent Lifecycle Operations and Tools) is an engineering assistant that follows the Universal Algorithm for systematic problem-solving.

---

## What's Included

| Component | Description |
|-----------|-------------|
| **Universal Algorithm** | 7-phase methodology: Observe → Think → Plan → Build → Execute → Verify → Learn |
| **Identity System** | 10 personal context files for personalized assistance |
| **4 Foundation Features** | Memory, Intelligence, Security, Monitoring - all as bash hooks |

---

## Foundation Features

All foundation features are implemented as pure bash scripts triggered by Kiro hooks.

### 1. Memory System

Three-tier memory with automatic archiving:

| Tier | Purpose | Retention |
|------|---------|-----------|
| **Hot** | Current session data | Until session ends |
| **Warm** | Recent learnings, patterns | 30 days |
| **Cold** | Archived sessions | 1 year (compressed) |

**Files:**
- `memory/hot/current-session.jsonl` - Session interactions
- `memory/hot/tool-usage.jsonl` - Tool call history
- `memory/warm/index.md` - Memory index
- `memory/cold/sessions/` - Archived sessions

### 2. Intelligence System

Algorithm phase tracking and learning extraction:

- **Phase Detection** - Automatically detects which algorithm phase from prompts
- **Pattern Tracking** - Records tool usage patterns for learning
- **Learning Extraction** - Captures failures and successes for future reference

**Files:**
- `memory/hot/algorithm-phases.jsonl` - Phase transitions
- `memory/hot/tool-patterns.jsonl` - Usage patterns
- `memory/warm/learnings-*.md` - Extracted learnings

### 3. Security System

Multi-tier command validation:

| Tier | Protection | Action |
|------|------------|--------|
| **1** | Catastrophic commands (rm -rf /) | Block |
| **2** | Remote code execution (curl \| bash) | Block |
| **3** | System directory writes | Block |
| **4** | Sensitive file access | Alert |

**Files:**
- `memory/hot/security.log` - Security audit trail

### 4. Monitoring System

Session metrics and health tracking:

- **Session Metrics** - Prompts, tool calls, success/failure rates
- **Performance Tracking** - Tool execution durations
- **Security Events** - Blocked commands count

**Files:**
- `metrics/session-*.json` - Per-session metrics
- `metrics/events.jsonl` - Event stream

---

## Directory Structure (After Installation)

```
~/.kiro/
├── pilot/                    # PILOT home directory
│   ├── identity/             # Your personal context (10 files)
│   ├── resources/            # Algorithm & principles
│   ├── memory/               # Three-tier memory
│   │   ├── hot/              # Current session
│   │   ├── warm/             # Recent (30 days)
│   │   └── cold/             # Archive (1 year)
│   ├── metrics/              # Session metrics
│   ├── packs/                # Installed packs
│   └── config.json           # Configuration
├── agents/
│   └── pilot.json            # Agent configuration
├── hooks/pilot/              # Hook scripts (5 files)
│   ├── agent-spawn.sh        # Memory + Intelligence + Monitoring init
│   ├── user-prompt-submit.sh # Memory + Intelligence (phase detection)
│   ├── pre-tool-use.sh       # Security validation
│   ├── post-tool-use.sh      # Memory + Intelligence + Monitoring
│   └── stop.sh               # Memory archive + Learning extraction
└── steering/pilot/           # Steering files
    └── pilot-core-knowledge.md
```

---

## The Universal Algorithm

PILOT follows a 7-phase approach to every task:

1. **OBSERVE** - Understand current state (never assume)
2. **THINK** - Generate 3-5 possible approaches
3. **PLAN** - Select strategy and break into steps
4. **BUILD** - Define success criteria BEFORE executing
5. **EXECUTE** - Perform the work
6. **VERIFY** - Test against success criteria objectively
7. **LEARN** - Extract insights for future work

**Key principle:** "Verifiability is everything" - Always define what success looks like in BUILD phase before EXECUTE phase.

---

## Installation

### AI-Assisted (Recommended)

Give this pack directory to your AI agent:

```
Install the pilot-core pack from this directory.
```

Your AI will:
1. Read this README for context
2. Follow INSTALL.md step by step
3. Copy files to ~/.kiro/
4. Complete VERIFY.md checklist

### Manual Installation

See [INSTALL.md](INSTALL.md) for step-by-step instructions.

---

## Usage

After installation:

1. **Select the pilot agent** in Kiro
2. **Customize your identity** - Edit files in `~/.kiro/pilot/identity/`
3. **Start working** - PILOT will follow the Universal Algorithm

### Example Interaction

```
User: Help me design a new API endpoint

PILOT: I'll follow the Universal Algorithm for this task.

**OBSERVE**: Let me understand your current API structure...
[analyzes codebase]

**THINK**: Here are 3 approaches we could take:
1. RESTful endpoint following existing patterns
2. GraphQL mutation for flexibility
3. gRPC for performance

**PLAN**: Based on your existing REST API, I recommend approach #1...

**BUILD**: Success criteria:
- [ ] Endpoint accepts POST requests
- [ ] Validates input schema
- [ ] Returns proper status codes
- [ ] Has test coverage

**EXECUTE**: Creating the endpoint...

**VERIFY**: Running tests...

**LEARN**: This pattern worked well for [reason]. Adding to memory.
```

---

## Customization

### Identity Files

Edit these files to personalize PILOT's assistance:

| File | Purpose | Example |
|------|---------|---------|
| `MISSION.md` | Your ultimate goal | "Build tools that empower developers" |
| `GOALS.md` | Specific objectives | "Launch v1.0 by Q2" |
| `PROJECTS.md` | Current work | "API redesign, Mobile app" |
| `BELIEFS.md` | Core convictions | "Simplicity over complexity" |
| `STRATEGIES.md` | Proven approaches | "Test-first development" |
| `LEARNED.md` | Past lessons | "Always validate inputs" |

### Memory System

PILOT automatically stores learnings:

- **Hot memory** (24h) - Recent context, active work
- **Warm memory** (30 days) - Relevant learnings, decisions
- **Cold memory** (1 year) - Archive for reference

---

## Files in This Pack

```
pilot-core/
├── README.md           # This file
├── INSTALL.md          # Installation instructions
├── VERIFY.md           # Verification checklist
├── pack.json           # Pack metadata
├── agents/
│   └── pilot.json      # Agent configuration
├── identity/           # Identity templates (10 files)
├── resources/          # Core knowledge (2 files)
├── steering/           # Steering files
└── system/hooks/       # Hook scripts (5 files)
```

---

## Requirements

- Kiro IDE
- macOS, Linux, or Windows (WSL)

---

## Troubleshooting

### Agent not appearing

```bash
# Verify agent file
cat ~/.kiro/agents/pilot.json | head -5
```

### Hooks not executing

```bash
# Make hooks executable
chmod +x ~/.kiro/hooks/pilot/*.sh
```

### Identity not loading

```bash
# Check identity files exist
ls ~/.kiro/pilot/identity/
```

---

## Related

- [INSTALL.md](INSTALL.md) - Installation guide
- [VERIFY.md](VERIFY.md) - Verification checklist
- [the-algorithm.md](resources/the-algorithm.md) - Universal Algorithm details
- [pilot-principles.md](resources/pilot-principles.md) - PILOT principles
