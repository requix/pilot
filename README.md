# PILOT - Platform for Intelligent Lifecycle Operations and Tools

**Self-learning engineering assistant for Kiro CLI. Structured methodology, persistent memory, continuous improvement.**

PILOT extends Kiro CLI with:
- **Universal Algorithm** — Structured approach to every engineering task
- **Self-learning** — Captures verified solutions and applies them to future work
- **Persistent memory** — Three-tier system (hot/warm/cold) that grows with you
- **Identity awareness** — Knows your goals, projects, and strategies
- **Working modes** — Hands-on execution or advisory discussion
- **Delegation** — Routes specialized tasks to expert agents

## Philosophy

PILOT follows the **Universal Algorithm**: Current State → Ideal State via verifiable iteration

Every task follows seven phases:
1. **OBSERVE** — Understand current reality (never assume)
2. **THINK** — Generate multiple approaches
3. **PLAN** — Select strategy and sequence
4. **BUILD** — Define success criteria BEFORE executing
5. **EXECUTE** — Do the work (or delegate to specialists)
6. **VERIFY** — Test against criteria objectively
7. **LEARN** — Extract insights only after verification confirms success

**Key principle:** "Verifiability is everything" — Define what success looks like BEFORE you execute.

## Quick Start

### Installation

```bash
./install.sh
```

The installer will:
- Install agent config to `~/.kiro/agents/pilot.json` (only file in .kiro)
- Create `~/.pilot/` directory with everything else
- Set up hooks, steering, system files, and identity templates

### Verify Installation

```bash
./verify.sh
```

### Dashboard (Optional)

PILOT has a companion TUI dashboard for real-time monitoring, available as a separate project:

**[pilot-dashboard](https://github.com/pilot-framework/pilot-dashboard)** — Terminal dashboard for PILOT sessions

```bash
# Clone and install
git clone https://github.com/pilot-framework/pilot-dashboard.git
cd pilot-dashboard
bun install
bun run start
```

Features:
- Real-time session monitoring
- Learning capture visualization
- Universal Algorithm phase tracking
- Statistics and metrics

### Start Using PILOT

1. Open Kiro CLI
2. Select the `pilot` agent
3. Start working — PILOT follows the Algorithm automatically

## Directory Structure

PILOT uses a simple structure:

```
~/.kiro/agents/pilot.json   # Agent config (only file in .kiro)

~/.pilot/                   # Everything else
├── hooks/                  # Hook scripts (6 files)
├── steering/               # Methodology files
├── system/                 # System files
│   ├── helpers/            # Consolidated libraries & detectors (6 files)
│   └── resources/          # Algorithm & Principles
├── identity/               # Your personal context
├── learnings/              # Captured solutions
├── observations/           # Adaptive identity capture
├── memory/                 # Hot/Warm/Cold storage
│   ├── hot/                # Current session
│   ├── warm/               # Recent context
│   └── cold/               # Archive
├── sessions/               # Session archives
├── patterns/               # Pattern detection
└── logs/                   # System logs
```

**Simple:** One file in `~/.kiro/`, everything else in `~/.pilot/`. Total: 12 shell scripts (6 hooks + 6 helpers).

## Working Modes

PILOT can operate in two modes:

| Mode | Description | Use When |
|------|-------------|----------|
| **Hands-on** | Directly edit files, run commands, implement | You want PILOT to do the work |
| **Advisory** | Discuss, plan, delegate execution | You want to discuss before acting |

Switch modes by telling PILOT: "Let's just discuss this" or "Go ahead and implement".

## Delegation

PILOT delegates to specialized agents when appropriate:

- **Specialized expertise** — Terraform, Kubernetes, specific frameworks
- **Parallel work** — Run multiple tasks simultaneously  
- **User preference** — Keep PILOT in advisory mode
- **Long-running operations** — Don't block conversation

Delegation strategy:
1. Find specialist agent matching the task domain
2. Fall back to `kiro_default` if no specialist found
3. Report results back to user

## Self-Learning

PILOT captures learnings from verified solutions:

### When PILOT Learns
- Fixed a bug and verified the fix works
- Discovered a pattern and tested it
- Found a solution and confirmed it solves the problem

### When PILOT Doesn't Learn
- Proposed solution not yet verified
- Routine tasks without insights
- Simple lookups

Learnings are stored in `~/.pilot/learnings/` and searchable via the knowledge tool.

## Identity System (Optional)

PILOT works without identity files, but becomes more personalized when configured.

Edit files in `~/.pilot/identity/`:

| File | Purpose |
|------|---------|
| `MISSION.md` | Your ultimate goal |
| `GOALS.md` | Specific objectives |
| `PROJECTS.md` | Current work |
| `BELIEFS.md` | Core convictions |
| `STRATEGIES.md` | Proven approaches |
| `LEARNED.md` | Past lessons |
| `CHALLENGES.md` | Current obstacles |

## Foundation Features

All implemented as bash hooks — no external dependencies.

| Feature | What It Does |
|---------|--------------|
| **Memory** | Three-tier storage with automatic archiving |
| **Self-Learning** | Captures verified solutions for future reference |
| **Security** | Multi-tier command validation |
| **Monitoring** | Session metrics and tracking |

## Source Structure

```
src/
├── agents/             # Agent configuration
│   └── pilot.json
├── hooks/              # Hook scripts (6 files)
├── helpers/            # Consolidated libraries & detectors (6 files)
│   ├── json.sh         # JSON utilities
│   ├── dashboard.sh    # Dashboard emission
│   ├── identity.sh     # Identity & observation init
│   ├── capture.sh      # Capture controller & silent capture
│   ├── analysis.sh     # Cross-file intelligence & performance
│   └── detectors.sh    # All 8 detectors consolidated
├── identity/           # Identity templates
├── resources/          # Algorithm & Principles
└── steering/           # Steering files
```

## Design Principles

1. **Bash-only** — No TypeScript, no external runtimes
2. **Single directory** — Everything in `~/.pilot/` (except agent config)
3. **Hook-based** — All features via Kiro's native hooks
4. **Fail-safe** — Hooks always exit 0, never break Kiro
5. **Verified learning** — Only capture learnings after verification

## Credits

Inspired by [Personal AI Infrastructure (PAI)](https://github.com/danielmiessler/pai) by Daniel Miessler.

PILOT adapts PAI's modular architecture to Kiro CLI, focusing on engineering workflows with a bash-only implementation.

## License

MIT License — Use freely, commercially or personally.
