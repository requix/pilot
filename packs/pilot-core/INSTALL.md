# PILOT Core - Installation Guide

**This guide is designed for AI agents installing this pack into a user's Kiro setup.**

---

## AI Agent Instructions

**This is a wizard-style installation.** Guide the user through installation interactively:

1. **Explain** what PILOT is and why it matters
2. **Ask** questions to understand their needs
3. **Install** files to the correct locations
4. **Verify** everything works before declaring success

### Welcome Message

Before starting, greet the user:
```
"I'm installing PILOT Core - the foundation of your personal AI infrastructure.

PILOT (Platform for Intelligent Lifecycle Operations and Tools) provides:
- The Universal Algorithm for systematic problem-solving
- Identity system for personalized assistance
- Memory system for learning from past work
- Hook system for intelligent automation

All files will be installed to ~/.kiro/ - Kiro's home directory.

Let me analyze your system and guide you through installation."
```

---

## Phase 1: System Analysis

**Execute this analysis BEFORE any file operations.**

### 1.1 Run These Commands

```bash
# Check for Kiro directory
echo "Kiro directory: $HOME/.kiro"
ls -la "$HOME/.kiro" 2>/dev/null || echo "~/.kiro does not exist (will be created)"

# Check for existing PILOT installation
if [ -d "$HOME/.kiro/pilot" ]; then
  echo "⚠️ Existing PILOT installation found"
else
  echo "✓ No existing PILOT installation (clean install)"
fi

# Check for existing pilot agent
if [ -f "$HOME/.kiro/agents/pilot.json" ]; then
  echo "⚠️ Existing pilot agent found"
else
  echo "✓ No existing pilot agent"
fi
```

### 1.2 Present Findings

Tell the user what you found:
```
"Here's what I found on your system:
- Kiro directory: [exists / will be created]
- Existing PILOT: [Yes / No]
- Existing pilot agent: [Yes / No]"
```

---

## Phase 2: User Questions

### Question 1: Conflict Resolution (if existing PILOT found)

**Only ask if existing PILOT detected:**

```
"Existing PILOT installation detected. How should I proceed?
1. Backup and Replace (Recommended) - Creates timestamped backup, then installs new version
2. Abort Installation - Cancel, keep existing PILOT"
```

### Question 2: Final Confirmation

```
"Ready to install PILOT Core?

This will create:
- ~/.kiro/pilot/           (PILOT home directory)
- ~/.kiro/agents/pilot.json (Agent configuration)
- ~/.kiro/hooks/pilot/      (Hook scripts)
- ~/.kiro/steering/pilot/   (Steering files)

Proceed with installation?"
```

---

## Phase 3: Backup (If Needed)

**Only execute if user chose "Backup and Replace":**

```bash
BACKUP_DIR="$HOME/.kiro/backups/pilot-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup existing PILOT directory
[ -d "$HOME/.kiro/pilot" ] && cp -r "$HOME/.kiro/pilot" "$BACKUP_DIR/"

# Backup existing agent
[ -f "$HOME/.kiro/agents/pilot.json" ] && cp "$HOME/.kiro/agents/pilot.json" "$BACKUP_DIR/"

# Backup existing hooks
[ -d "$HOME/.kiro/hooks/pilot" ] && cp -r "$HOME/.kiro/hooks/pilot" "$BACKUP_DIR/"

# Backup existing steering
[ -d "$HOME/.kiro/steering/pilot" ] && cp -r "$HOME/.kiro/steering/pilot" "$BACKUP_DIR/"

echo "✓ Backed up to $BACKUP_DIR"
```

---

## Phase 4: Installation

### 4.1 Create Directory Structure

```bash
# PILOT home directory
mkdir -p "$HOME/.kiro/pilot/identity"
mkdir -p "$HOME/.kiro/pilot/resources"
mkdir -p "$HOME/.kiro/pilot/memory/hot"
mkdir -p "$HOME/.kiro/pilot/memory/warm"
mkdir -p "$HOME/.kiro/pilot/memory/cold"
mkdir -p "$HOME/.kiro/pilot/metrics"
mkdir -p "$HOME/.kiro/pilot/packs"
mkdir -p "$HOME/.kiro/pilot/.cache"

# Kiro integration directories
mkdir -p "$HOME/.kiro/agents"
mkdir -p "$HOME/.kiro/hooks/pilot"
mkdir -p "$HOME/.kiro/steering/pilot"
mkdir -p "$HOME/.kiro/backups"

echo "✓ Directory structure created"
```

### 4.2 Install Agent Configuration

Copy `agents/pilot.json` to `~/.kiro/agents/pilot.json`

```bash
cp agents/pilot.json "$HOME/.kiro/agents/pilot.json"
echo "✓ Agent configuration installed"
```

### 4.3 Install Hook Scripts

Copy all files from `system/hooks/` to `~/.kiro/hooks/pilot/`:

| Source | Destination |
|--------|-------------|
| `system/hooks/agent-spawn.sh` | `~/.kiro/hooks/pilot/agent-spawn.sh` |
| `system/hooks/user-prompt-submit.sh` | `~/.kiro/hooks/pilot/user-prompt-submit.sh` |
| `system/hooks/pre-tool-use.sh` | `~/.kiro/hooks/pilot/pre-tool-use.sh` |
| `system/hooks/post-tool-use.sh` | `~/.kiro/hooks/pilot/post-tool-use.sh` |
| `system/hooks/stop.sh` | `~/.kiro/hooks/pilot/stop.sh` |

```bash
cp system/hooks/*.sh "$HOME/.kiro/hooks/pilot/"
chmod +x "$HOME/.kiro/hooks/pilot/"*.sh
echo "✓ Hook scripts installed"
```

### 4.4 Install Resources

Copy all files from `resources/` to `~/.kiro/pilot/resources/`:

| Source | Destination |
|--------|-------------|
| `resources/the-algorithm.md` | `~/.kiro/pilot/resources/the-algorithm.md` |
| `resources/pilot-principles.md` | `~/.kiro/pilot/resources/pilot-principles.md` |

```bash
cp resources/*.md "$HOME/.kiro/pilot/resources/"
echo "✓ Resources installed"
```

### 4.5 Install Identity Templates

Copy all files from `identity/` to `~/.kiro/pilot/identity/`:

| Source | Destination |
|--------|-------------|
| `identity/MISSION.md` | `~/.kiro/pilot/identity/MISSION.md` |
| `identity/GOALS.md` | `~/.kiro/pilot/identity/GOALS.md` |
| `identity/PROJECTS.md` | `~/.kiro/pilot/identity/PROJECTS.md` |
| `identity/BELIEFS.md` | `~/.kiro/pilot/identity/BELIEFS.md` |
| `identity/MODELS.md` | `~/.kiro/pilot/identity/MODELS.md` |
| `identity/STRATEGIES.md` | `~/.kiro/pilot/identity/STRATEGIES.md` |
| `identity/NARRATIVES.md` | `~/.kiro/pilot/identity/NARRATIVES.md` |
| `identity/LEARNED.md` | `~/.kiro/pilot/identity/LEARNED.md` |
| `identity/CHALLENGES.md` | `~/.kiro/pilot/identity/CHALLENGES.md` |
| `identity/IDEAS.md` | `~/.kiro/pilot/identity/IDEAS.md` |

```bash
cp identity/*.md "$HOME/.kiro/pilot/identity/"
echo "✓ Identity templates installed"
```

### 4.6 Install Steering Files

Copy all files from `steering/` to `~/.kiro/steering/pilot/`:

| Source | Destination |
|--------|-------------|
| `steering/pilot-core-knowledge.md` | `~/.kiro/steering/pilot/pilot-core-knowledge.md` |

```bash
cp steering/*.md "$HOME/.kiro/steering/pilot/"
echo "✓ Steering files installed"
```

### 4.7 Create Config File

```bash
cat > "$HOME/.kiro/pilot/config.json" << 'EOF'
{
  "version": "1.0.0",
  "installed_at": "$(date -Iseconds)",
  "pilot_home": "~/.kiro/pilot",
  "memory": {
    "hot_ttl_hours": 24,
    "warm_ttl_days": 30,
    "cold_ttl_days": 365
  }
}
EOF
echo "✓ Config file created"
```

---

## Phase 5: Verification

**Execute all checks from VERIFY.md:**

```bash
echo "=== PILOT Core Verification ==="

# Check directories
echo "Checking directories..."
[ -d "$HOME/.kiro/pilot" ] && echo "✓ ~/.kiro/pilot" || echo "❌ ~/.kiro/pilot missing"
[ -d "$HOME/.kiro/pilot/identity" ] && echo "✓ ~/.kiro/pilot/identity" || echo "❌ identity missing"
[ -d "$HOME/.kiro/pilot/resources" ] && echo "✓ ~/.kiro/pilot/resources" || echo "❌ resources missing"
[ -d "$HOME/.kiro/pilot/memory" ] && echo "✓ ~/.kiro/pilot/memory" || echo "❌ memory missing"

# Check agent
echo ""
echo "Checking agent..."
[ -f "$HOME/.kiro/agents/pilot.json" ] && echo "✓ pilot.json" || echo "❌ pilot.json missing"

# Check hooks
echo ""
echo "Checking hooks..."
[ -f "$HOME/.kiro/hooks/pilot/agent-spawn.sh" ] && echo "✓ agent-spawn.sh" || echo "❌ agent-spawn.sh missing"
[ -f "$HOME/.kiro/hooks/pilot/user-prompt-submit.sh" ] && echo "✓ user-prompt-submit.sh" || echo "❌ user-prompt-submit.sh missing"
[ -f "$HOME/.kiro/hooks/pilot/pre-tool-use.sh" ] && echo "✓ pre-tool-use.sh" || echo "❌ pre-tool-use.sh missing"
[ -f "$HOME/.kiro/hooks/pilot/post-tool-use.sh" ] && echo "✓ post-tool-use.sh" || echo "❌ post-tool-use.sh missing"
[ -f "$HOME/.kiro/hooks/pilot/stop.sh" ] && echo "✓ stop.sh" || echo "❌ stop.sh missing"

# Check resources
echo ""
echo "Checking resources..."
[ -f "$HOME/.kiro/pilot/resources/the-algorithm.md" ] && echo "✓ the-algorithm.md" || echo "❌ the-algorithm.md missing"
[ -f "$HOME/.kiro/pilot/resources/pilot-principles.md" ] && echo "✓ pilot-principles.md" || echo "❌ pilot-principles.md missing"

# Check identity (count files)
echo ""
echo "Checking identity..."
IDENTITY_COUNT=$(ls "$HOME/.kiro/pilot/identity/"*.md 2>/dev/null | wc -l)
echo "Identity files: $IDENTITY_COUNT (expected: 10)"

# Check steering
echo ""
echo "Checking steering..."
[ -f "$HOME/.kiro/steering/pilot/pilot-core-knowledge.md" ] && echo "✓ pilot-core-knowledge.md" || echo "❌ pilot-core-knowledge.md missing"

echo ""
echo "=== Verification Complete ==="
```

---

## Success/Failure Messages

### On Success

```
"PILOT Core v1.0.0 installed successfully!

Directory structure:
~/.kiro/
├── pilot/              # PILOT home
│   ├── identity/       # Your personal context (10 files)
│   ├── resources/      # Algorithm & principles
│   ├── memory/         # Learning storage
│   └── config.json     # Configuration
├── agents/pilot.json   # Agent configuration
├── hooks/pilot/        # Hook scripts (5 files)
└── steering/pilot/     # Steering files

Next steps:
1. Select 'pilot' agent in Kiro
2. Customize your identity files in ~/.kiro/pilot/identity/
3. Start using PILOT with the Universal Algorithm!"
```

### On Failure

```
"Installation encountered issues. Here's what to check:

1. Verify ~/.kiro/ directory exists and is writable
2. Check file permissions
3. Run the verification commands above
4. See VERIFY.md for detailed checks

Need help? Check the Troubleshooting section below."
```

---

## Customization Guide

### After Installation: Customize Your PILOT

**Step 1: Define Your Mission**

Edit `~/.kiro/pilot/identity/MISSION.md`:
- What is your ultimate goal?
- What drives you?

**Step 2: Set Your Goals**

Edit `~/.kiro/pilot/identity/GOALS.md`:
- Short-term objectives
- Long-term aspirations

**Step 3: Add Your Projects**

Edit `~/.kiro/pilot/identity/PROJECTS.md`:
- Current work
- Upcoming initiatives

**Step 4: Document Your Learnings**

Edit `~/.kiro/pilot/identity/LEARNED.md`:
- Past lessons
- Key insights

---

## Troubleshooting

### Agent not appearing in Kiro

```bash
# Verify agent file exists
cat "$HOME/.kiro/agents/pilot.json"

# Check JSON syntax
jq . "$HOME/.kiro/agents/pilot.json"
```

### Hooks not executing

```bash
# Check hook files are executable
ls -la "$HOME/.kiro/hooks/pilot/"

# Make executable if needed
chmod +x "$HOME/.kiro/hooks/pilot/"*.sh
```

### Identity files not loading

```bash
# Verify files exist
ls -la "$HOME/.kiro/pilot/identity/"

# Check file permissions
chmod 644 "$HOME/.kiro/pilot/identity/"*.md
```
