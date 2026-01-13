# PILOT Pack System

## Overview

PILOT uses a modular pack system for extending functionality. Packs integrate with Kiro's native features: steering files, agents, and hooks.

All packs install to `~/.kiro/` — Kiro's home directory.

## Pack Types

| Type | Purpose | Example |
|------|---------|---------|
| **Feature** | Background capabilities | pilot-core |
| **Skill** | Specialized agents | (future) pilot-aws |
| **Bundle** | Collection of packs | (future) pilot-devops |

## Directory Structure

### Source (Development)

```
src/packs/my-pack/
├── pack.json           # Metadata
├── README.md           # Documentation
├── INSTALL.md          # Installation steps
├── VERIFY.md           # Verification
├── agents/             # Agent configs
├── steering/           # Knowledge files
├── system/hooks/       # Hook scripts
├── resources/          # Core resources
└── identity/           # Identity templates
```

### Installed (Runtime)

```
~/.kiro/
├── pilot/              # PILOT home
│   ├── identity/       # User context (10 files)
│   ├── resources/      # Algorithm & Principles
│   ├── memory/         # Hot/Warm/Cold
│   ├── metrics/        # Session metrics
│   └── packs/          # Pack metadata
├── agents/             # Agent configurations
│   └── pilot.json
├── hooks/              # Hook scripts
│   └── pilot/
│       ├── agent-spawn.sh
│       ├── user-prompt-submit.sh
│       ├── pre-tool-use.sh
│       ├── post-tool-use.sh
│       └── stop.sh
└── steering/           # Steering files
    └── pilot/
        └── pilot-core-knowledge.md
```

## Integration Points

### 1. Steering Files

Provide persistent knowledge to Kiro:

```markdown
# My Pack Knowledge

## Best Practices
- Practice 1
- Practice 2

## Integration
Automatically loaded by Kiro when relevant.
```

Location: `~/.kiro/steering/my-pack/`

### 2. Agent Configurations

Specialized agents with custom prompts and hooks:

```json
{
  "name": "my-agent",
  "model": "claude-sonnet-4",
  "prompt": "You are an expert in...",
  
  "hooks": {
    "agentSpawn": [{
      "command": "~/.kiro/hooks/my-pack/init.sh",
      "timeout_ms": 2000
    }]
  }
}
```

Location: `~/.kiro/agents/my-agent.json`

### 3. Hook Scripts

Event-driven automation:

| Hook | Event | Purpose |
|------|-------|---------|
| `agentSpawn` | Agent starts | Load context |
| `userPromptSubmit` | User sends message | Process input |
| `preToolUse` | Before tool runs | Validate security |
| `postToolUse` | After tool runs | Capture results |
| `stop` | Session ends | Archive session |

Location: `~/.kiro/hooks/my-pack/`

## pack.json Schema

```json
{
  "name": "pack-name",
  "version": "1.0.0",
  "type": "feature",
  "description": "What this pack does",
  
  "metadata": {
    "author": "Author Name",
    "license": "MIT",
    "tags": ["tag1", "tag2"]
  },
  
  "dependencies": {
    "kiro": ">=1.0.0"
  },
  
  "provides": {
    "agents": ["agent-name"],
    "hooks": ["hook1", "hook2"],
    "steering_files": ["knowledge.md"]
  },
  
  "creates": {
    "directories": [
      "~/.kiro/pilot/custom-dir"
    ],
    "files": [
      "~/.kiro/agents/my-agent.json"
    ]
  },
  
  "installation": {
    "ai_installable": true,
    "method": "wizard"
  }
}
```

## Installation

### Using install.sh

```bash
cd src
./install.sh
./verify.sh
```

### Manual Installation

1. Copy agent config to `~/.kiro/agents/`
2. Copy hooks to `~/.kiro/hooks/pack-name/`
3. Copy steering files to `~/.kiro/steering/pack-name/`
4. Copy resources to `~/.kiro/pilot/resources/`
5. Make hooks executable: `chmod +x ~/.kiro/hooks/pack-name/*.sh`

## Creating Packs

See [PACK-DEVELOPMENT.md](./PACK-DEVELOPMENT.md) for detailed guide.

### Quick Start

```bash
# Copy template
cp -r src/packs/pilot-pack-template src/packs/my-pack

# Edit pack.json
# Add your agents, hooks, steering files

# Test
./tests/verify-pack.sh
```

## Best Practices

### Hooks

- Always exit 0 (fail-safe)
- Keep execution <100ms
- Use `set -euo pipefail`
- Log errors, don't crash

### Steering Files

- Clear, structured markdown
- Include code examples
- Document integration points

### Agents

- Specific, focused prompts
- Minimal required permissions
- Reasonable timeouts

## pilot-core Pack

The foundation pack installed by default:

**Provides:**
- `pilot` agent with Universal Algorithm
- 5 hooks (memory, intelligence, security, monitoring)
- 10 identity templates
- Algorithm & Principles resources
- Core steering file

**Features:**
- Three-tier memory (hot/warm/cold)
- Algorithm phase tracking
- Multi-tier security validation
- Session metrics

See `src/packs/pilot-core/` for reference implementation.
