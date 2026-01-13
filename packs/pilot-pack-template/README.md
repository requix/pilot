# PILOT Pack Template

This is a template for creating new PILOT packs with full Kiro CLI integration.

## Features

- Kiro CLI native integration
- Steering file support for persistent knowledge
- Agent configuration template
- Hook system integration
- Health monitoring
- Security validation

## Structure

```
pilot-pack-template/
├── pack.json                      # Pack metadata and configuration
├── README.md                      # This file
├── INSTALL.md                     # Installation instructions
├── VERIFY.md                      # Verification procedures
├── src/                           # Pack source code
│   ├── agents/                    # Kiro agent configurations
│   │   └── template-agent.json
│   ├── steering/                  # Steering files for knowledge
│   │   └── template-knowledge.md
│   ├── hooks/                     # Kiro hook scripts
│   │   └── template-hook.sh
│   └── tools/                     # CLI utilities
│       └── template-tool.sh
└── tests/                         # Pack tests
    └── verify-pack.sh
```

## Quick Start

### 1. Copy Template

```bash
cp -r src/packs/pilot-pack-template src/packs/my-new-pack
cd src/packs/my-new-pack
```

### 2. Update Metadata

Edit `pack.json`:
- Change `name` to your pack name (use `pilot-` prefix)
- Update `description`, `author`, `license`
- Modify `provides` section with your capabilities
- Update `kiro_integration` paths

### 3. Implement Features

- **Agents**: Edit `src/agents/template-agent.json`
- **Steering**: Edit `src/steering/template-knowledge.md`
- **Hooks**: Edit `src/hooks/template-hook.sh`
- **Tools**: Edit `src/tools/template-tool.sh`

### 4. Test Pack

```bash
# Validate pack structure
./tests/verify-pack.sh

# Test installation
~/.pilot/system/installation/ai-installer.sh check-compatibility pack.json
```

### 5. Install Pack

```bash
~/.pilot/system/installation/ai-installer.sh install .
```

## Customization Guide

### Agent Configuration

Edit `src/agents/template-agent.json` to create a specialized agent:

```json
{
  "name": "my-expert",
  "description": "Expert in my domain",
  "model": "claude-sonnet-4",
  "prompt": "You are an expert in...",
  
  "resources": [
    "file://.kiro/steering/packs/my-pack/**/*.md"
  ],
  
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["my-command *"]
    }
  }
}
```

### Steering Files

Edit `src/steering/template-knowledge.md` to provide domain knowledge:

```markdown
# My Pack Knowledge

## Best Practices
- Practice 1
- Practice 2

## Common Patterns
- Pattern 1
- Pattern 2

## Kiro Integration
This knowledge is automatically loaded when working with my domain.
```

### Hook Scripts

Edit `src/hooks/template-hook.sh` to add automation:

```bash
#!/bin/bash
# Detect when to activate your pack's capabilities

set -euo pipefail

USER_INPUT="$1"

if echo "$USER_INPUT" | grep -qi "my-keyword"; then
    echo "🔍 My pack activated"
    # Load context, activate features, etc.
fi

exit 0
```

### CLI Tools

Edit `src/tools/template-tool.sh` to provide utilities:

```bash
#!/bin/bash
# My pack CLI tool

set -euo pipefail

case "${1:-}" in
    "action1")
        echo "Performing action 1..."
        ;;
    "action2")
        echo "Performing action 2..."
        ;;
    *)
        echo "Usage: $0 {action1|action2}"
        exit 1
        ;;
esac
```

## Integration Points

### 1. Steering Files
- Installed to: `.kiro/steering/packs/my-pack/`
- Automatically loaded by Kiro CLI
- Provides persistent knowledge

### 2. Agent Configurations
- Installed to: `.kiro/settings/agents/`
- Activated with: `kiro chat --agent my-expert`
- Leverages Kiro's native features

### 3. Hooks
- Registered in agent configuration
- Triggered by Kiro CLI events
- Fail-safe execution

### 4. MCP Servers (Optional)
- Configured in `.kiro/settings/mcp.json`
- Provides specialized tools
- Auto-approval for safe operations

## Testing

### Validation Script

```bash
#!/bin/bash
# tests/verify-pack.sh

set -euo pipefail

echo "Validating pack structure..."

# Check required files
test -f pack.json || { echo "❌ pack.json missing"; exit 1; }
test -f README.md || { echo "❌ README.md missing"; exit 1; }
test -f INSTALL.md || { echo "❌ INSTALL.md missing"; exit 1; }
test -f VERIFY.md || { echo "❌ VERIFY.md missing"; exit 1; }

# Validate pack.json
jq empty pack.json || { echo "❌ Invalid pack.json"; exit 1; }

# Check required fields
jq -e '.name' pack.json >/dev/null || { echo "❌ Missing name"; exit 1; }
jq -e '.version' pack.json >/dev/null || { echo "❌ Missing version"; exit 1; }

echo "✅ Pack structure valid"
```

## Security

### Permissions

Declare all required permissions in `pack.json`:

```json
{
  "security": {
    "permissions": {
      "filesystem": {
        "read": [".kiro/steering/**"],
        "write": ["~/.pilot/packs/my-pack/cache/**"]
      },
      "network": {
        "allowed_domains": ["api.example.com"]
      },
      "commands": {
        "allowed": ["jq", "curl"]
      }
    }
  }
}
```

### Best Practices

1. **Minimal Permissions**: Request only what you need
2. **Input Validation**: Validate all user inputs
3. **Secure Defaults**: Use safe default configurations
4. **Audit Logging**: Log security-relevant operations

## Publishing

### Checklist

- [ ] Update version in pack.json
- [ ] Update CHANGELOG.md
- [ ] Test on all supported platforms
- [ ] Run security validation
- [ ] Update documentation
- [ ] Create git tag

### Submission

1. Fork PILOT repository
2. Add pack to `src/packs/`
3. Submit pull request
4. Pass CI/CD checks
5. Security review
6. Merge and publish

## Support

- **Documentation**: See `src/docs/KIRO-PACK-SYSTEM.md`
- **Core Pack**: Check `src/packs/pilot-core/` for reference
- **Issues**: GitHub Issues

## License

MIT License - See LICENSE file for details
