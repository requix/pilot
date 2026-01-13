# PILOT - Platform for Intelligent Lifecycle Operations and Tools

**Transform Kiro into your personal engineering infrastructure.**

PILOT is an open-source framework that transforms Kiro into a personalized system with:
- **Universal Algorithm** — Structured approach to every task
- **Persistent memory** — Three-tier system that learns from your work
- **Identity awareness** — Knows your goals, beliefs, and strategies
- **Security validation** — Multi-tier command validation
- **Session monitoring** — Metrics and performance tracking

## Philosophy

PILOT follows the **Universal Algorithm**: Current State → Ideal State via verifiable iteration

Every task follows seven phases:
1. **OBSERVE** — Understand current reality (never assume)
2. **THINK** — Generate 3-5 approaches
3. **PLAN** — Select strategy and sequence
4. **BUILD** — Define success criteria BEFORE executing
5. **EXECUTE** — Do the work
6. **VERIFY** — Test against criteria objectively
7. **LEARN** — Extract insights for future

**Key insight:** "Verifiability is everything" — Define what success looks like BEFORE you execute.

## Quick Start

### Installation

```bash
cd src
./install.sh
```

The installer will:
- Create `~/.kiro/pilot/` directory structure
- Install the pilot agent to `~/.kiro/agents/`
- Set up 5 hook scripts for automation
- Copy identity templates and resources

### Verify Installation

```bash
./verify.sh
```

All 21 checks should pass.

### Start Using PILOT

1. Open Kiro
2. Select the `pilot` agent
3. Start working — PILOT follows the Algorithm automatically

## What's Installed

```
~/.kiro/
├── pilot/                  # PILOT home
│   ├── identity/           # Your personal context (10 files)
│   ├── resources/          # Algorithm & Principles
│   ├── memory/             # Hot/Warm/Cold storage
│   │   ├── hot/            # Current session
│   │   ├── warm/           # Recent learnings
│   │   └── cold/           # Archive
│   └── metrics/            # Session metrics
├── agents/pilot.json       # Agent configuration
├── hooks/pilot/            # 5 hook scripts
│   ├── agent-spawn.sh      # Initialize session
│   ├── user-prompt-submit.sh
│   ├── pre-tool-use.sh     # Security validation
│   ├── post-tool-use.sh    # Capture results
│   └── stop.sh             # Archive session
└── steering/pilot/         # Steering files
```

## Foundation Features

All implemented as bash hooks — no external dependencies.

| Feature | What It Does |
|---------|--------------|
| **Memory** | Three-tier storage (hot/warm/cold) with automatic archiving |
| **Intelligence** | Algorithm phase tracking and learning extraction |
| **Security** | Multi-tier command validation, sensitive file protection |
| **Monitoring** | Session metrics and tool usage tracking |

## Identity System (Optional)

PILOT works without identity files, but becomes more valuable when personalized.

Edit files in `~/.kiro/pilot/identity/`:

| File | Purpose |
|------|---------|
| `MISSION.md` | Your ultimate goal |
| `GOALS.md` | Specific objectives |
| `PROJECTS.md` | Current work |
| `BELIEFS.md` | Core convictions |
| `MODELS.md` | Mental frameworks |
| `STRATEGIES.md` | Proven approaches |
| `NARRATIVES.md` | Self-stories |
| `LEARNED.md` | Past lessons |
| `CHALLENGES.md` | Current obstacles |
| `IDEAS.md` | Future possibilities |

## Creating Packs

Want to extend PILOT? See:
- `src/packs/pilot-pack-template/` — Template for new packs
- `src/PACK-CREATION.md` — Pack development guide
- `src/docs/PACK-DEVELOPMENT.md` — Detailed documentation

## Design Principles

1. **Bash-only** — No TypeScript, no external runtimes
2. **Single directory** — Everything in `~/.kiro/`
3. **Hook-based** — All features via Kiro's native hooks
4. **Fail-safe** — Hooks always exit 0, never break Kiro
5. **Minimal** — Only what's needed for v1.0

## Credits

Inspired by [Personal AI Infrastructure (PAI)](https://github.com/danielmiessler/pai) by Daniel Miessler.

PILOT adapts PAI's modular architecture to Kiro, focusing on engineering workflows with a bash-only implementation.

## License

MIT License — Use freely, commercially or personally.
