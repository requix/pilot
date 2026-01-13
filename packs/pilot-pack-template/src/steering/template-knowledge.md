# Template Pack Knowledge

This steering file demonstrates how packs provide persistent knowledge through Kiro CLI's steering system.

## Overview

This template pack shows best practices for:
- Kiro CLI integration
- Steering file usage
- Hook system integration
- Agent configuration
- MCP server implementation

## Pack Integration Patterns

### 1. Steering Files

Steering files provide persistent knowledge that's automatically loaded by Kiro CLI:

**Benefits:**
- Always available in agent context
- Version controlled with pack
- Shared across team members
- No manual loading required

**Best Practices:**
- Use clear, structured markdown
- Include code examples
- Document integration points
- Explain Kiro-specific features

### 2. Agent Configuration

Agents leverage Kiro's native capabilities:

**Key Features:**
- Hook integration for automation
- Resource loading from steering files
- Tool permissions and restrictions
- Subagent coordination

**Configuration Tips:**
- Minimal required permissions
- Clear capability documentation
- Proper hook timeout settings
- Resource path specifications

### 3. Hook System

Hooks provide event-driven automation:

**Hook Events:**
- `agent-spawn`: Initialize pack context
- `user-prompt-submit`: Detect relevant tasks
- `pre-tool-use`: Validate operations
- `post-tool-use`: Capture learnings

**Hook Best Practices:**
- Always exit with code 0 (fail-safe)
- Keep execution under 100ms
- Log errors without failing
- Use timeout protection

### 4. MCP Servers

MCP servers provide specialized tools:

**When to Use:**
- Complex operations requiring state
- External API integrations
- Specialized data processing
- Performance-critical operations

**Implementation:**
- Simple bash or Node.js scripts
- Clear tool definitions
- Auto-approval for safe operations
- Comprehensive error handling

## Template Pack Capabilities

### Knowledge Management

This pack demonstrates:
- Structured knowledge organization
- Context-aware information delivery
- Integration with Kiro's search
- Cross-reference capabilities

### Automation Patterns

Example automation:
- Skill detection and activation
- Context loading and preparation
- Learning extraction and storage
- Performance monitoring

### Tool Integration

CLI tools provided:
- `template-tool.sh`: Example utility
- Integration with Kiro's shell tool
- Proper permission handling
- Error reporting

## Usage Examples

### Example 1: Basic Usage

```
User: "Show me how the template pack works"
Agent: Loads this steering file and explains integration patterns
```

### Example 2: Hook Triggering

```
User: "template keyword detected"
Hook: Activates and loads pack-specific context
Agent: Responds with enhanced capabilities
```

### Example 3: Tool Usage

```
User: "Run the template tool"
Agent: Executes ~/.pilot/packs/pilot-pack-template/src/tools/template-tool.sh
Result: Tool output with proper error handling
```

## Integration with PILOT Features

### Memory System

Pack integrates with PILOT's memory:
- Learnings stored in warm memory
- Context loaded from past sessions
- Cross-reference with other packs
- Performance tracking

### Security System

Security integration:
- Command validation before execution
- Permission checking
- Threat detection
- Audit logging

### Universal Algorithm

Algorithm integration:
- OBSERVE: Use context-gatherer
- THINK: Load steering knowledge
- PLAN: Leverage past learnings
- BUILD: Execute with tools
- EXECUTE: Monitor with hooks
- VERIFY: Run health checks
- LEARN: Capture insights

## Development Guidelines

### Creating New Packs

1. **Start with Template**: Copy this pack structure
2. **Update Metadata**: Modify pack.json
3. **Add Knowledge**: Create steering files
4. **Implement Features**: Add agents, hooks, tools
5. **Test Thoroughly**: Use verification scripts
6. **Document Well**: Update all markdown files

### Testing Packs

```bash
# Validate structure
./tests/verify-pack.sh

# Test installation
~/.pilot/system/installation/ai-installer.sh check-compatibility pack.json

# Verify integration
kiro chat --agent your-agent
```

### Publishing Packs

1. Complete all documentation
2. Pass security validation
3. Test on all platforms
4. Submit pull request
5. Pass CI/CD checks
6. Community review

## Troubleshooting

### Common Issues

**Steering Files Not Loading:**
- Check file location: `.kiro/steering/packs/pack-name/`
- Verify file permissions: `chmod 644 *.md`
- Restart Kiro CLI session

**Hooks Not Executing:**
- Verify executable: `chmod +x hook.sh`
- Check timeout settings
- Review hook logs

**Agent Not Available:**
- Check agent config: `.kiro/settings/agents/`
- Validate JSON syntax
- Verify agent name

### Debug Commands

```bash
# Check steering files
ls -la ~/.kiro/steering/packs/pilot-pack-template/

# Test hooks
~/.pilot/packs/pilot-pack-template/src/hooks/template-hook.sh "test"

# Verify agent
jq . ~/.kiro/settings/agents/template-agent.json

# Check logs
tail -f ~/.pilot/logs/hooks/hook-execution.log
```

## Best Practices Summary

1. **Minimal Permissions**: Request only what you need
2. **Clear Documentation**: Explain all features
3. **Fail-Safe Design**: Never crash the system
4. **Performance Focus**: Keep operations fast
5. **Security First**: Validate all inputs
6. **User Experience**: Provide clear feedback
7. **Integration**: Leverage Kiro's native features
8. **Testing**: Comprehensive verification

## Resources

- **Pack Documentation**: See README.md
- **Installation Guide**: See INSTALL.md
- **Verification**: See VERIFY.md
- **PILOT Docs**: `src/docs/KIRO-PACK-SYSTEM.md`

## Contributing

Improvements welcome:
- Better examples
- Additional patterns
- Performance optimizations
- Documentation enhancements

## License

MIT License - See pack LICENSE file
