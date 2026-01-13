# PILOT Pack Development Guide

Complete guide to creating custom packs for PILOT.

## What is a Pack?

A pack is a modular extension for PILOT. Packs can provide:
- **Agents** — Custom agent configurations
- **Hooks** — Event-driven automation scripts
- **Steering** — Knowledge files for Kiro
- **Resources** — Documentation and templates
- **Identity** — User context templates

## Pack Types

| Type | Purpose | Example |
|------|---------|---------|
| **Feature** | Background capabilities | pilot-core |
| **Skill** | Specialized agents | pilot-aws (future) |
| **Bundle** | Collection of packs | pilot-devops (future) |

## Quick Start

```bash
# Copy the template
cp -r src/packs/pilot-pack-template src/packs/my-pack
cd src/packs/my-pack

# Edit pack.json with your metadata
# Add your agents, hooks, steering files
# Test with ./tests/verify-pack.sh
```

## Pack Structure

```
my-pack/
├── pack.json              # Metadata (REQUIRED)
├── README.md              # Documentation (REQUIRED)
├── INSTALL.md             # Installation guide (REQUIRED)
├── VERIFY.md              # Verification steps (REQUIRED)
├── agents/                # Agent configurations
│   └── my-agent.json
├── steering/              # Knowledge files
│   └── my-knowledge.md
├── system/
│   └── hooks/             # Hook scripts
│       └── my-hook.sh
├── resources/             # Core resources
│   └── my-resource.md
├── identity/              # Identity templates (optional)
└── tests/
    └── verify-pack.sh
```

## pack.json

### Minimal Configuration

```json
{
  "name": "my-pack",
  "version": "1.0.0",
  "type": "feature",
  "description": "My custom PILOT pack",
  
  "metadata": {
    "author": "Your Name",
    "license": "MIT",
    "tags": ["custom", "example"]
  },
  
  "dependencies": {
    "kiro": ">=1.0.0"
  },
  
  "provides": {
    "agents": ["my-agent"],
    "hooks": ["agent-spawn", "user-prompt-submit"],
    "steering_files": ["my-knowledge.md"]
  },
  
  "creates": {
    "directories": [
      "~/.kiro/pilot/packs/my-pack"
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

## Creating Components

### Agent Configuration

Create agents in `agents/`:

```json
{
  "name": "my-agent",
  "description": "My specialized agent",
  "model": "claude-sonnet-4",
  
  "prompt": "You are an expert in [domain].\n\nYou follow the Universal Algorithm:\n1. OBSERVE - Understand current state\n2. THINK - Generate approaches\n3. PLAN - Select strategy\n4. BUILD - Define success criteria\n5. EXECUTE - Do the work\n6. VERIFY - Test against criteria\n7. LEARN - Extract insights",
  
  "hooks": {
    "agentSpawn": [
      {
        "command": "~/.kiro/hooks/my-pack/agent-spawn.sh",
        "timeout_ms": 2000
      }
    ]
  },
  
  "resources": [
    "file://~/.kiro/pilot/resources/*.md",
    "file://~/.kiro/steering/my-pack/*.md"
  ],
  
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["my-command *"]
    }
  }
}
```

### Hook Scripts

Create hooks in `system/hooks/`:

```bash
#!/usr/bin/env bash
# my-hook.sh - Description
set -euo pipefail

# Parse input JSON (first argument)
input_json="${1:-{}}"

# Extract fields if needed
# message=$(echo "$input_json" | grep -o '"message"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"message"[[:space:]]*:[[:space:]]*"//;s/"$//')

# Your logic here
echo "<my-pack-context>"
echo "My pack is active"
echo "</my-pack-context>"

# CRITICAL: Always exit 0 (fail-safe)
exit 0
```

### Hook Events

| Event | When | Purpose |
|-------|------|---------|
| `agentSpawn` | Agent starts | Load context |
| `userPromptSubmit` | User sends message | Process input |
| `preToolUse` | Before tool runs | Validate security |
| `postToolUse` | After tool runs | Capture results |
| `stop` | Session ends | Archive session |

### Steering Files

Create knowledge in `steering/`:

```markdown
# My Pack Knowledge

## Overview
This pack provides...

## Best Practices
- Practice 1
- Practice 2

## Integration
This knowledge is automatically loaded by Kiro.
```

## Installation Location

Packs install to `~/.kiro/`:

```
~/.kiro/
├── pilot/packs/my-pack/    # Pack metadata
├── agents/my-agent.json    # Agent config
├── hooks/my-pack/          # Hook scripts
│   └── agent-spawn.sh
└── steering/my-pack/       # Steering files
    └── my-knowledge.md
```

## Testing

### Verification Script

```bash
#!/usr/bin/env bash
# tests/verify-pack.sh
set -euo pipefail

echo "Validating pack structure..."

# Check required files
test -f pack.json || { echo "❌ pack.json missing"; exit 1; }
test -f README.md || { echo "❌ README.md missing"; exit 1; }
test -f INSTALL.md || { echo "❌ INSTALL.md missing"; exit 1; }
test -f VERIFY.md || { echo "❌ VERIFY.md missing"; exit 1; }

# Validate JSON
jq empty pack.json || { echo "❌ Invalid pack.json"; exit 1; }

# Check required fields
jq -e '.name' pack.json >/dev/null || { echo "❌ Missing name"; exit 1; }
jq -e '.version' pack.json >/dev/null || { echo "❌ Missing version"; exit 1; }

# Check hooks are executable (if they exist)
if [ -d "system/hooks" ]; then
    for hook in system/hooks/*.sh; do
        [ -x "$hook" ] || { echo "❌ $hook not executable"; exit 1; }
    done
fi

echo "✅ Pack structure valid"
```

### Manual Testing

```bash
# Test hook execution
echo '{}' | ./system/hooks/my-hook.sh

# Validate agent JSON
jq . agents/my-agent.json
```

## Best Practices

### Code Quality

```bash
#!/usr/bin/env bash
set -euo pipefail          # Catch errors

my_function() {
    local param="$1"       # Use local variables
}

echo "$variable"           # Quote variables

command -v jq &>/dev/null  # Check commands exist
```

### Hook Rules

1. **Always exit 0** — Never break Kiro
2. **Keep it fast** — Target <100ms
3. **Log errors** — Don't fail silently
4. **Use timeouts** — Prevent hanging

### Security

- Validate all inputs
- Use minimal permissions
- Never store secrets in pack files
- Declare required permissions in pack.json

### Documentation

- Clear README with examples
- Step-by-step INSTALL.md
- Comprehensive VERIFY.md
- Code comments for complex logic

## Example: AWS Pack

### pack.json

```json
{
  "name": "pilot-aws",
  "version": "1.0.0",
  "type": "skill",
  "description": "AWS management for PILOT",
  
  "metadata": {
    "author": "PILOT Team",
    "license": "MIT",
    "tags": ["aws", "cloud", "infrastructure"]
  },
  
  "provides": {
    "agents": ["aws-expert"],
    "hooks": ["aws-context-loader"],
    "steering_files": ["aws-best-practices.md"]
  },
  
  "installation": {
    "requirements": {
      "commands": ["aws", "jq"],
      "environment": {
        "AWS_PROFILE": "AWS profile must be configured"
      }
    }
  }
}
```

### Agent (aws-expert.json)

```json
{
  "name": "aws-expert",
  "description": "PILOT agent specialized for AWS",
  "model": "claude-sonnet-4",
  
  "prompt": "You are PILOT specialized for AWS infrastructure.\n\nFollow the Universal Algorithm with AWS expertise:\n- OBSERVE: Check CloudWatch, CloudTrail, Config\n- THINK: Consider AWS-specific solutions\n- PLAN: Follow Well-Architected Framework\n- BUILD: Define AWS metrics as success criteria\n- EXECUTE: Use IaC, least privilege, encryption\n- VERIFY: Use Config Rules, Security Hub\n- LEARN: Document as runbooks",
  
  "hooks": {
    "agentSpawn": [{
      "command": "~/.kiro/hooks/pilot-aws/load-context.sh",
      "timeout_ms": 3000
    }]
  }
}
```

### Hook (load-context.sh)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Get AWS identity
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")
AWS_REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")

echo "<aws-context>"
echo "Account: ${AWS_ACCOUNT}"
echo "Region: ${AWS_REGION}"
echo "Profile: ${AWS_PROFILE:-default}"
echo "</aws-context>"

exit 0
```

## Publishing

### Checklist

- [ ] pack.json complete and valid
- [ ] README.md with usage examples
- [ ] INSTALL.md with clear steps
- [ ] VERIFY.md with test procedures
- [ ] All hooks exit 0
- [ ] Tests pass: `./tests/verify-pack.sh`

### Submit to PILOT

1. Fork PILOT repository
2. Add pack to `src/packs/`
3. Submit pull request
4. Pass review

## Reference

- **Template**: `src/packs/pilot-pack-template/`
- **Example**: `src/packs/pilot-core/`
- **Pack System**: `src/PILOT-PACK-SYSTEM.md`
