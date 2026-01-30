---
inclusion: manual
---

# PILOT Core Knowledge

This steering file provides essential knowledge about PILOT capabilities and integration patterns for Kiro CLI agents.

## PILOT System Overview

PILOT is an intelligent personal AI infrastructure that provides:

- **Intelligent Memory System**: Automatic learning extraction and categorization
- **Advanced Hook Architecture**: Fail-safe automation with 8+ event types
- **Sophisticated Security**: 10-tier threat detection with context awareness
- **AI-First Installation**: Simple installer with automatic configuration
- **Universal Algorithm**: OBSERVE→THINK→PLAN→BUILD→EXECUTE→VERIFY→LEARN workflow

## Memory System Integration

### Memory Categories
- **Hot Memory**: Active session data (`~/.pilot/memory/hot/`)
- **Warm Memory**: Categorized knowledge (`~/.pilot/memory/warm/`)
  - `learnings/` - Problem-solving insights
  - `research/` - Investigation and analysis
  - `decisions/` - Architectural decisions
  - `execution/` - Implementation work
  - `sessions/` - Session summaries
- **Cold Memory**: Long-term archive (`~/.pilot/memory/cold/`)

### Memory Operations
```bash
# Load relevant memory context
~/.pilot/system/intelligence/memory-intelligence.sh context "current task description"

# Extract learnings from session
~/.pilot/system/intelligence/learning-extractor.sh analyze session-file.md
```

## Security System Integration

### Security Tiers (1-10)
- **Tier 10**: Catastrophic (always block) - `rm -rf /*`, `dd if=/dev/zero`
- **Tier 9**: Destructive (block + alert) - `DROP DATABASE`, `sudo rm -rf`
- **Tier 8**: Dangerous (block + warning) - `curl | bash`, `chmod 777`
- **Tier 7**: Risky (confirm required) - `sudo`, `rm -rf`, `git --force`
- **Tier 6**: Suspicious (warn + log) - `base64 -d`, `eval $()`
- **Tier 5**: Questionable (log only) - `ps aux | grep`, `netstat -an`

### Security Operations
```bash
# Analyze command security
~/.pilot/system/security/security-intelligence.sh analyze "command to check"

# Check threat patterns
~/.pilot/system/security/threat-detection.sh check "suspicious command"
```

## Hook System Integration

### Available Hook Events
- `user-prompt-submit` - Skill detection and memory loading
- `pre-tool-use` - Security validation and resource monitoring
- `post-tool-use` - Learning extraction and memory updates
- `agent-spawn` - Context initialization
- `session-start` - Session setup
- `session-end` - Session synthesis
- `memory-synthesis` - Memory processing
- `security-alert` - Security incident response

## Performance Targets

- **Memory Queries**: <50ms for 90% of requests
- **Hook Execution**: <100ms for 95% of hooks
- **Security Analysis**: <10ms for 95% of commands
- **System Startup**: <2s including Kiro CLI integration

## Configuration Management

### Main Configuration
```bash
# Check system status
~/.pilot/system/config-manager.sh status

# Validate configuration
~/.pilot/system/config-manager.sh validate

# Get configuration value
~/.pilot/system/config-manager.sh get ~/.pilot/system/config/pilot.json ".system.memory.enabled"
```

### Logging and Monitoring
```bash
# System health check
~/.pilot/system/logging-system.sh health

# Performance statistics
~/.pilot/system/logging-system.sh stats

# View recent alerts
tail -f ~/.pilot/logs/system/alerts.log
```

## Universal Algorithm Integration

The Universal Algorithm phases can be tracked and optimized:

1. **OBSERVE** - Gather context and requirements
2. **THINK** - Analyze and understand the problem
3. **PLAN** - Design solution approach
4. **BUILD** - Implement the solution
5. **EXECUTE** - Deploy and run the solution
6. **VERIFY** - Test and validate results
7. **LEARN** - Extract insights and update knowledge

## Integration Patterns

### Context-Aware Loading
When working on projects, PILOT can automatically load relevant past work and learnings based on:
- Technology stack keywords
- Problem patterns
- Project type
- Team collaboration history

### Intelligent Skill Routing
PILOT can detect required skills and suggest appropriate tools or approaches based on:
- Command patterns
- File types being worked on
- Error messages encountered
- Historical success patterns

### Security-First Approach
All operations are validated through the security system with:
- Context-aware threat assessment
- Environment-specific rules (dev/test/prod)
- Learning from security incidents
- Recovery suggestions for blocked commands

## Best Practices

1. **Memory Management**: Let PILOT automatically categorize learnings rather than manual organization
2. **Security Awareness**: Trust the security system's recommendations and learn from blocked commands
3. **Hook Integration**: Use hooks for automation but ensure fail-safe design
4. **Performance Monitoring**: Monitor system performance and optimize based on metrics
5. **Configuration Validation**: Regularly validate configurations to prevent issues

## Troubleshooting

### Common Issues
- **Slow Memory Queries**: Check indices and consider rebuilding
- **Hook Failures**: Review hook logs and ensure timeout settings
- **Security False Positives**: Adjust context-specific rules
- **Configuration Errors**: Use validation tools and reset to defaults if needed

### Diagnostic Commands
```bash
# System health overview
~/.pilot/system/logging-system.sh health

# Memory system status
find ~/.pilot/memory -name "*.json" -exec wc -l {} \;

# Hook system status
grep -c "SUCCESS\|ERROR\|TIMEOUT" ~/.pilot/logs/hooks/hook-execution.log

# Security system status
tail -20 ~/.pilot/logs/security/security-threats.log
```