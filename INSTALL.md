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

All PILOT files are installed to `~/.kiro/` — Kiro's home directory:

```
~/.kiro/
├── pilot/              # PILOT home
│   ├── identity/       # Your personal context (10 files)
│   ├── resources/      # Algorithm & principles
│   ├── memory/         # Three-tier memory
│   └── metrics/        # Session metrics
├── agents/pilot.json   # Agent configuration
├── hooks/pilot/        # Hook scripts (5 files)
└── steering/pilot/     # Steering files
```

---

## Installation Steps

### Step 1: Navigate to pilot-core pack

```bash
cd src/packs/pilot-core
```

### Step 2: Follow INSTALL.md

The pilot-core pack contains detailed installation instructions in `INSTALL.md`.

**Quick installation:**

```bash
# Create directories
mkdir -p "$HOME/.kiro/pilot/identity"
mkdir -p "$HOME/.kiro/pilot/resources"
mkdir -p "$HOME/.kiro/pilot/memory/hot"
mkdir -p "$HOME/.kiro/pilot/memory/warm"
mkdir -p "$HOME/.kiro/pilot/memory/cold"
mkdir -p "$HOME/.kiro/pilot/metrics"
mkdir -p "$HOME/.kiro/pilot/packs"
mkdir -p "$HOME/.kiro/pilot/.cache"
mkdir -p "$HOME/.kiro/agents"
mkdir -p "$HOME/.kiro/hooks/pilot"
mkdir -p "$HOME/.kiro/steering/pilot"

# Copy agent config
cp agents/pilot.json "$HOME/.kiro/agents/"

# Copy hooks
cp system/hooks/*.sh "$HOME/.kiro/hooks/pilot/"
chmod +x "$HOME/.kiro/hooks/pilot/"*.sh

# Copy resources
cp resources/*.md "$HOME/.kiro/pilot/resources/"

# Copy identity templates
cp identity/*.md "$HOME/.kiro/pilot/identity/"

# Copy steering files
cp steering/*.md "$HOME/.kiro/steering/pilot/"

# Create config
cat > "$HOME/.kiro/pilot/config.json" << 'EOF'
{
  "version": "1.0.0",
  "installed_at": "$(date -Iseconds)"
}
EOF
```

### Step 3: Verify Installation

```bash
# Quick verification
[ -f "$HOME/.kiro/agents/pilot.json" ] && echo "✓ Agent" || echo "❌ Agent"
[ -d "$HOME/.kiro/hooks/pilot" ] && echo "✓ Hooks" || echo "❌ Hooks"
[ -d "$HOME/.kiro/pilot/identity" ] && echo "✓ Identity" || echo "❌ Identity"
[ -d "$HOME/.kiro/pilot/memory" ] && echo "✓ Memory" || echo "❌ Memory"
```

---

## After Installation

1. **Select the pilot agent** in Kiro
2. **Customize your identity** — Edit files in `~/.kiro/pilot/identity/`
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

If you prefer to install without AI assistance:

```bash
# Clone the repository
git clone https://github.com/pilot-project/pilot.git
cd pilot/src/packs/pilot-core

# Follow INSTALL.md instructions
# Or run the quick installation commands above
```

---

## What's Different from PAI?

PILOT follows PAI's philosophy but with key differences:

| Aspect | PAI | PILOT |
|--------|-----|-------|
| Language | TypeScript hooks | Bash-only hooks |
| Location | `~/.claude/` or `$PAI_DIR` | `~/.kiro/` |
| Platform | Claude Code | Kiro |
| Complexity | Multiple packs | Single core pack |

Both share:
- AI-first installation
- Hook-based architecture
- Memory systems
- Security validation
