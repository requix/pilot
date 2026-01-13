# Verification Procedures

This document describes how to verify that the pack is correctly installed and functioning.

## Quick Verification

```bash
# Run automated verification
~/.pilot/packs/pilot-pack-template/tests/verify-pack.sh
```

## Manual Verification

### 1. File Structure Verification

**Check Pack Files:**
```bash
# Verify pack directory exists
test -d ~/.pilot/packs/pilot-pack-template && echo "✅ Pack directory exists" || echo "❌ Pack directory missing"

# Check required files
test -f ~/.pilot/packs/pilot-pack-template/pack.json && echo "✅ pack.json exists" || echo "❌ pack.json missing"
test -f ~/.pilot/packs/pilot-pack-template/README.md && echo "✅ README.md exists" || echo "❌ README.md missing"
```

**Check Source Files:**
```bash
# Verify source directory structure
test -d ~/.pilot/packs/pilot-pack-template/src/agents && echo "✅ agents/ exists" || echo "❌ agents/ missing"
test -d ~/.pilot/packs/pilot-pack-template/src/steering && echo "✅ steering/ exists" || echo "❌ steering/ missing"
test -d ~/.pilot/packs/pilot-pack-template/src/hooks && echo "✅ hooks/ exists" || echo "❌ hooks/ missing"
test -d ~/.pilot/packs/pilot-pack-template/src/tools && echo "✅ tools/ exists" || echo "❌ tools/ missing"
```

### 2. Kiro Integration Verification

**Steering Files:**
```bash
# Check steering files are installed
test -d ~/.kiro/steering/packs/pilot-pack-template && echo "✅ Steering directory exists" || echo "❌ Steering directory missing"

# List steering files
ls -la ~/.kiro/steering/packs/pilot-pack-template/

# Verify content
cat ~/.kiro/steering/packs/pilot-pack-template/template-knowledge.md
```

**Agent Configuration:**
```bash
# Check agent configuration
test -f ~/.kiro/settings/agents/template-agent.json && echo "✅ Agent config exists" || echo "❌ Agent config missing"

# Validate JSON
jq empty ~/.kiro/settings/agents/template-agent.json && echo "✅ Valid JSON" || echo "❌ Invalid JSON"

# Check agent name
jq -r '.name' ~/.kiro/settings/agents/template-agent.json
```

**Hook Scripts:**
```bash
# Check hooks are executable
test -x ~/.pilot/packs/pilot-pack-template/src/hooks/template-hook.sh && echo "✅ Hook executable" || echo "❌ Hook not executable"

# Test hook execution
~/.pilot/packs/pilot-pack-template/src/hooks/template-hook.sh "test" && echo "✅ Hook runs" || echo "❌ Hook fails"
```

### 3. Functional Verification

**Agent Activation:**
```bash
# Test agent can be activated
# This requires manual testing in Kiro CLI:
# kiro chat --agent template-agent
# Then type: "Hello, are you the template agent?"
```

**Hook Triggering:**
```bash
# Test hook is triggered
# In Kiro CLI with template-agent:
# Type a message that should trigger the hook
# Check hook logs:
tail -10 ~/.pilot/logs/hooks/hook-execution.log | grep template-hook
```

**Tool Execution:**
```bash
# Test CLI tool
~/.pilot/packs/pilot-pack-template/src/tools/template-tool.sh action1
```

### 4. Health Check Verification

**Run Health Checks:**
```bash
# Execute pack health checks
~/.pilot/system/installation/ai-installer.sh health-check pilot-pack-template

# Check health status
cat ~/.pilot/logs/pack-health.log | grep pilot-pack-template
```

**Verify Health Check Configuration:**
```bash
# Check health checks are defined
jq '.health_checks' ~/.pilot/packs/pilot-pack-template/pack.json
```

### 5. Security Verification

**Permission Validation:**
```bash
# Check security configuration
jq '.security' ~/.pilot/packs/pilot-pack-template/pack.json

# Verify no dangerous patterns
grep -r "rm -rf\|curl.*bash\|eval" ~/.pilot/packs/pilot-pack-template/src/ && echo "⚠️  Warning: Dangerous patterns found" || echo "✅ No dangerous patterns"
```

**File Permissions:**
```bash
# Check file permissions are correct
find ~/.pilot/packs/pilot-pack-template -type f -name "*.sh" -exec test -x {} \; -print | wc -l
```

### 6. Dependency Verification

**Required Commands:**
```bash
# Check jq is available
which jq && echo "✅ jq available" || echo "❌ jq missing"

# Verify jq version
jq --version
```

**Platform Compatibility:**
```bash
# Check platform
uname -s

# Verify platform is supported
jq -r '.installation.requirements.platform[]' ~/.pilot/packs/pilot-pack-template/pack.json | grep -i "$(uname -s | tr '[:upper:]' '[:lower:]')" && echo "✅ Platform supported" || echo "❌ Platform not supported"
```

### 7. Integration Testing

**End-to-End Test:**
```bash
#!/bin/bash
# Complete integration test

echo "🧪 Running integration tests..."

# 1. Verify files
test -f ~/.pilot/packs/pilot-pack-template/pack.json || exit 1
echo "✅ Pack files verified"

# 2. Verify Kiro integration
test -d ~/.kiro/steering/packs/pilot-pack-template || exit 1
echo "✅ Steering files verified"

# 3. Test hook execution
~/.pilot/packs/pilot-pack-template/src/hooks/template-hook.sh "test" || exit 1
echo "✅ Hook execution verified"

# 4. Test tool execution
~/.pilot/packs/pilot-pack-template/src/tools/template-tool.sh action1 || exit 1
echo "✅ Tool execution verified"

# 5. Verify health checks
~/.pilot/system/installation/ai-installer.sh health-check pilot-pack-template || exit 1
echo "✅ Health checks verified"

echo "✅ All integration tests passed"
```

## Automated Verification Script

```bash
#!/bin/bash
# tests/verify-pack.sh
# Comprehensive pack verification

set -euo pipefail

PACK_NAME="pilot-pack-template"
PACK_PATH="$HOME/.pilot/packs/$PACK_NAME"
STEERING_PATH="$HOME/.kiro/steering/packs/$PACK_NAME"
AGENT_CONFIG="$HOME/.kiro/settings/agents/template-agent.json"

echo "🔍 Verifying $PACK_NAME installation..."

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function
test_check() {
    local description="$1"
    local command="$2"
    
    if eval "$command" >/dev/null 2>&1; then
        echo "✅ $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "❌ $description"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# File structure tests
echo ""
echo "📁 File Structure Tests:"
test_check "Pack directory exists" "test -d $PACK_PATH"
test_check "pack.json exists" "test -f $PACK_PATH/pack.json"
test_check "README.md exists" "test -f $PACK_PATH/README.md"
test_check "INSTALL.md exists" "test -f $PACK_PATH/INSTALL.md"
test_check "VERIFY.md exists" "test -f $PACK_PATH/VERIFY.md"
test_check "src/ directory exists" "test -d $PACK_PATH/src"

# Kiro integration tests
echo ""
echo "🔗 Kiro Integration Tests:"
test_check "Steering directory exists" "test -d $STEERING_PATH"
test_check "Agent config exists" "test -f $AGENT_CONFIG"
test_check "Agent config is valid JSON" "jq empty $AGENT_CONFIG"
test_check "Hook script exists" "test -f $PACK_PATH/src/hooks/template-hook.sh"
test_check "Hook script is executable" "test -x $PACK_PATH/src/hooks/template-hook.sh"

# Functional tests
echo ""
echo "⚙️  Functional Tests:"
test_check "Hook script runs" "$PACK_PATH/src/hooks/template-hook.sh test"
test_check "Tool script runs" "$PACK_PATH/src/tools/template-tool.sh action1"

# Metadata tests
echo ""
echo "📋 Metadata Tests:"
test_check "Pack name is correct" "jq -e '.name == \"$PACK_NAME\"' $PACK_PATH/pack.json"
test_check "Version is defined" "jq -e '.version' $PACK_PATH/pack.json"
test_check "Description is defined" "jq -e '.description' $PACK_PATH/pack.json"

# Security tests
echo ""
echo "🔒 Security Tests:"
test_check "No dangerous rm patterns" "! grep -r 'rm -rf /' $PACK_PATH/src"
test_check "No curl pipe bash" "! grep -r 'curl.*|.*bash' $PACK_PATH/src"
test_check "Security config exists" "jq -e '.security' $PACK_PATH/pack.json"

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Test Summary:"
echo "   Passed: $TESTS_PASSED"
echo "   Failed: $TESTS_FAILED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $TESTS_FAILED -eq 0 ]; then
    echo "✅ All tests passed! Pack is correctly installed."
    exit 0
else
    echo "❌ Some tests failed. Please review the output above."
    exit 1
fi
```

## Troubleshooting Failed Verifications

### Pack Files Missing

```bash
# Reinstall pack
~/.pilot/system/installation/ai-installer.sh install ~/.pilot/packs/pilot-pack-template
```

### Steering Files Not Found

```bash
# Manually copy steering files
mkdir -p ~/.kiro/steering/packs/pilot-pack-template
cp ~/.pilot/packs/pilot-pack-template/src/steering/*.md \
   ~/.kiro/steering/packs/pilot-pack-template/
```

### Agent Config Invalid

```bash
# Validate and fix JSON
jq . ~/.kiro/settings/agents/template-agent.json

# Reinstall if needed
cp ~/.pilot/packs/pilot-pack-template/src/agents/template-agent.json \
   ~/.kiro/settings/agents/
```

### Hooks Not Executable

```bash
# Make hooks executable
chmod +x ~/.pilot/packs/pilot-pack-template/src/hooks/*.sh
chmod +x ~/.pilot/packs/pilot-pack-template/src/tools/*.sh
```

### Health Checks Failing

```bash
# Run health checks manually
~/.pilot/system/installation/ai-installer.sh health-check pilot-pack-template

# Check logs
tail -50 ~/.pilot/logs/pack-health.log
```

## Continuous Verification

### Periodic Checks

Set up periodic verification:

```bash
# Add to crontab for daily verification
0 2 * * * ~/.pilot/packs/pilot-pack-template/tests/verify-pack.sh >> ~/.pilot/logs/pack-verification.log 2>&1
```

### Monitoring

Monitor pack health:

```bash
# Watch health logs
tail -f ~/.pilot/logs/pack-health.log | grep pilot-pack-template

# Check for errors
grep ERROR ~/.pilot/logs/pack-health.log | grep pilot-pack-template
```

## Verification Checklist

Use this checklist for manual verification:

- [ ] Pack directory exists at `~/.pilot/packs/pilot-pack-template`
- [ ] All required files present (pack.json, README.md, INSTALL.md, VERIFY.md)
- [ ] Source directory structure complete
- [ ] Steering files installed to `.kiro/steering/packs/pilot-pack-template/`
- [ ] Agent configuration installed to `.kiro/settings/agents/`
- [ ] Agent configuration is valid JSON
- [ ] Hook scripts are executable
- [ ] Hook scripts run without errors
- [ ] CLI tools are executable
- [ ] CLI tools run without errors
- [ ] Health checks pass
- [ ] No security issues detected
- [ ] Agent can be activated in Kiro CLI
- [ ] Hooks trigger correctly
- [ ] Steering files load in Kiro sessions

## Support

If verification fails:

1. Review error messages carefully
2. Check installation logs
3. Consult troubleshooting section
4. Reinstall pack if necessary
5. Report persistent issues on GitHub

## Next Steps

After successful verification:

1. Explore pack features
2. Test with real workflows
3. Provide feedback
4. Contribute improvements
