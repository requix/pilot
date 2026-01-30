# Installing PILOT

> [!IMPORTANT]
> ## This File Is For Your AI Assistant
>
> **This is the future of software installation.**
>
> Software doesn't get installed by humans copying commands. It gets installed by your AI assistant, who reads the documentation, understands your system, and customizes the installation for your specific needs.
>
> **Give your AI this file and let it guide you through installation.**

---

## For AI Assistants: Installation Guide

You are about to help your user install PILOT (Platform for Intelligent Lifecycle Operations and Tools).

### What is PILOT?

PILOT transforms your AI assistant into a personalized engineering system with:
- **Universal Algorithm** — Structured approach: OBSERVE → THINK → PLAN → BUILD → EXECUTE → VERIFY → LEARN
- **Memory System** — Three-tier memory (hot/warm/cold) that learns from sessions
- **Security System** — Multi-tier command validation
- **Intelligence System** — Algorithm phase tracking and learning extraction
- **Monitoring System** — Session metrics and performance tracking

### Installation Location

PILOT files are installed to two locations:

```
~/.kiro/                    # Kiro integration
├── pilot/                  # PILOT system
│   ├── identity/           # Identity templates
│   ├── resources/          # Algorithm & principles
│   ├── memory/             # Three-tier memory
│   ├── lib/                # Shared libraries
│   ├── detectors/          # Identity detectors
│   └── metrics/            # Session metrics
├── agents/pilot.json       # Agent configuration
├── hooks/pilot/            # Hook scripts
└── steering/pilot/         # Steering files

~/.pilot/                   # User data
├── learnings/              # Auto-captured learnings
├── identity/               # Your personal context
├── observations/           # Adaptive identity capture
└── sessions/               # Session archives
```

---

## Installation Steps

### Step 1: Run the installer

```bash
cd src
./install.sh
```

### Step 2: Verify Installation

```bash
./verify.sh
```

Or manually:

```bash
[ -f "$HOME/.kiro/agents/pilot.json" ] && echo "✓ Agent" || echo "❌ Agent"
[ -d "$HOME/.kiro/hooks/pilot" ] && echo "✓ Hooks" || echo "❌ Hooks"
[ -d "$HOME/.kiro/pilot/identity" ] && echo "✓ Identity" || echo "❌ Identity"
[ -d "$HOME/.kiro/pilot/memory" ] && echo "✓ Memory" || echo "❌ Memory"
[ -d "$HOME/.pilot/learnings" ] && echo "✓ Learnings" || echo "❌ Learnings"
```

---

## After Installation

1. **Select the pilot agent** in Kiro
2. **Customize your identity** — Edit files in `~/.pilot/identity/`
3. **Start using PILOT** — The Universal Algorithm guides every task

### Identity Files to Customize

| File | Purpose |
|------|---------|
| `MISSION.md` | Your ultimate goal |
| `GOALS.md` | Specific objectives |
| `PROJECTS.md` | Current work |
| `BELIEFS.md` | Core convictions |
| `STRATEGIES.md` | Proven approaches |
| `LEARNED.md` | Past lessons |

---

## Troubleshooting

### Agent not appearing in Kiro

```bash
# Verify agent file
cat "$HOME/.kiro/agents/pilot.json" | head -5
```

### Hooks not executing

```bash
# Make hooks executable
chmod +x "$HOME/.kiro/hooks/pilot/"*.sh

# Test a hook
echo '{}' | "$HOME/.kiro/hooks/pilot/agent-spawn.sh"
```

### Memory not working

```bash
# Check directories exist
ls -la "$HOME/.kiro/pilot/memory/"
```

---

## Manual Installation

If you prefer to install without the script:

```bash
# From the src directory
mkdir -p "$HOME/.kiro/pilot/identity"
mkdir -p "$HOME/.kiro/pilot/resources"
mkdir -p "$HOME/.kiro/pilot/memory/hot"
mkdir -p "$HOME/.kiro/pilot/memory/warm"
mkdir -p "$HOME/.kiro/pilot/memory/cold"
mkdir -p "$HOME/.kiro/pilot/lib"
mkdir -p "$HOME/.kiro/pilot/detectors"
mkdir -p "$HOME/.kiro/agents"
mkdir -p "$HOME/.kiro/hooks/pilot"
mkdir -p "$HOME/.kiro/steering/pilot"
mkdir -p "$HOME/.pilot/learnings"
mkdir -p "$HOME/.pilot/identity"
mkdir -p "$HOME/.pilot/observations"

# Copy files
cp agents/pilot.json "$HOME/.kiro/agents/"
cp hooks/*.sh "$HOME/.kiro/hooks/pilot/"
cp lib/*.sh "$HOME/.kiro/pilot/lib/"
cp detectors/*.sh "$HOME/.kiro/pilot/detectors/"
cp resources/*.md "$HOME/.kiro/pilot/resources/"
cp identity/*.md "$HOME/.kiro/pilot/identity/"
cp steering/*.md "$HOME/.kiro/steering/pilot/"

# Make scripts executable
chmod +x "$HOME/.kiro/hooks/pilot/"*.sh
chmod +x "$HOME/.kiro/pilot/lib/"*.sh
chmod +x "$HOME/.kiro/pilot/detectors/"*.sh
```

---

## What's Different from PAI?

PILOT follows PAI's philosophy but with key differences:

| Aspect | PAI | PILOT |
|--------|-----|-------|
| Language | TypeScript hooks | Bash-only hooks |
| Location | `~/.claude/` or `$PAI_DIR` | `~/.kiro/` + `~/.pilot/` |
| Platform | Claude Code | Kiro |

Both share:
- AI-first installation
- Hook-based architecture
- Memory systems
- Security validation
