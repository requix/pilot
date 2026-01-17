# PILOT Core - Verification Checklist

**Run these checks after installation to confirm everything is working.**

---

## Quick Verification

```bash
# Run all checks at once
echo "=== PILOT Core Verification ===" && \
[ -d "$HOME/.kiro/pilot" ] && echo "✓ PILOT home" || echo "❌ PILOT home" && \
[ -f "$HOME/.kiro/agents/pilot.json" ] && echo "✓ Agent config" || echo "❌ Agent config" && \
[ -d "$HOME/.kiro/hooks/pilot" ] && echo "✓ Hooks directory" || echo "❌ Hooks directory" && \
[ -d "$HOME/.kiro/steering/pilot" ] && echo "✓ Steering directory" || echo "❌ Steering directory" && \
echo "=== Done ==="
```

---

## Detailed Verification

### 1. Directory Structure

```bash
# PILOT home directory
[ -d "$HOME/.kiro/pilot" ] && echo "✓" || echo "❌"
[ -d "$HOME/.kiro/pilot/identity" ] && echo "✓" || echo "❌"
[ -d "$HOME/.kiro/pilot/resources" ] && echo "✓" || echo "❌"
[ -d "$HOME/.kiro/pilot/memory/hot" ] && echo "✓" || echo "❌"
[ -d "$HOME/.kiro/pilot/memory/warm" ] && echo "✓" || echo "❌"
[ -d "$HOME/.kiro/pilot/memory/cold" ] && echo "✓" || echo "❌"
[ -d "$HOME/.kiro/pilot/metrics" ] && echo "✓" || echo "❌"
[ -d "$HOME/.kiro/pilot/packs" ] && echo "✓" || echo "❌"
```

### 2. Agent Configuration

```bash
# Agent file exists
[ -f "$HOME/.kiro/agents/pilot.json" ] && echo "✓ pilot.json exists"

# Valid JSON
jq . "$HOME/.kiro/agents/pilot.json" > /dev/null 2>&1 && echo "✓ Valid JSON" || echo "❌ Invalid JSON"

# Has required fields
jq -e '.name' "$HOME/.kiro/agents/pilot.json" > /dev/null && echo "✓ Has name"
jq -e '.prompt' "$HOME/.kiro/agents/pilot.json" > /dev/null && echo "✓ Has prompt"
jq -e '.hooks' "$HOME/.kiro/agents/pilot.json" > /dev/null && echo "✓ Has hooks"
```

### 3. Hook Scripts

```bash
# All hooks exist
[ -f "$HOME/.kiro/hooks/pilot/agent-spawn.sh" ] && echo "✓" || echo "❌"
[ -f "$HOME/.kiro/hooks/pilot/user-prompt-submit.sh" ] && echo "✓" || echo "❌"
[ -f "$HOME/.kiro/hooks/pilot/pre-tool-use.sh" ] && echo "✓" || echo "❌"
[ -f "$HOME/.kiro/hooks/pilot/post-tool-use.sh" ] && echo "✓" || echo "❌"
[ -f "$HOME/.kiro/hooks/pilot/stop.sh" ] && echo "✓" || echo "❌"

# All hooks are executable
[ -x "$HOME/.kiro/hooks/pilot/agent-spawn.sh" ] && echo "✓ executable" || echo "❌ not executable"
```

### 4. Resources

```bash
[ -f "$HOME/.kiro/pilot/resources/the-algorithm.md" ] && echo "✓" || echo "❌"
[ -f "$HOME/.kiro/pilot/resources/pilot-principles.md" ] && echo "✓" || echo "❌"
```

### 5. Identity Files (10 files expected)

```bash
IDENTITY_COUNT=$(ls "$HOME/.kiro/pilot/identity/"*.md 2>/dev/null | wc -l | tr -d ' ')
[ "$IDENTITY_COUNT" -eq 10 ] && echo "✓ 10 identity files" || echo "❌ Expected 10, found $IDENTITY_COUNT"
```

### 6. Steering Files

```bash
[ -f "$HOME/.kiro/steering/pilot/pilot-core-knowledge.md" ] && echo "✓" || echo "❌"
```

### 7. Config File

```bash
[ -f "$HOME/.kiro/pilot/config.json" ] && echo "✓ config.json exists"
jq . "$HOME/.kiro/pilot/config.json" > /dev/null 2>&1 && echo "✓ Valid JSON" || echo "❌ Invalid JSON"
```

### 8. Self-Learning Data Directory

```bash
# Self-learning data directory
[ -d "$HOME/.pilot" ] && echo "✓" || echo "❌"
[ -d "$HOME/.pilot/learnings" ] && echo "✓" || echo "❌"
[ -d "$HOME/.pilot/identity" ] && echo "✓" || echo "❌"
[ -d "$HOME/.pilot/observations" ] && echo "✓" || echo "❌"
[ -d "$HOME/.pilot/logs" ] && echo "✓" || echo "❌"
```

### 9. Observation System Health

```bash
# Check observation files exist and are valid JSON
echo "=== Observation System Health ==="

for file in projects.json challenges.json patterns.json prompts.json time-allocation.json goals.json working-style.json evolution.json; do
  if [ -f "$HOME/.pilot/observations/$file" ]; then
    if jq . "$HOME/.pilot/observations/$file" > /dev/null 2>&1; then
      echo "✓ $file (valid)"
    else
      echo "⚠ $file (invalid JSON)"
    fi
  else
    echo "○ $file (not created yet)"
  fi
done
```

### 10. Lib Files (Detectors and Utilities)

```bash
# Check lib files
LIB_COUNT=$(ls "$HOME/.kiro/pilot/lib/"*.sh 2>/dev/null | wc -l | tr -d ' ')
echo "Lib files: $LIB_COUNT"
[ "$LIB_COUNT" -ge 10 ] && echo "✓ Sufficient lib files" || echo "⚠ Expected 10+, found $LIB_COUNT"

# Check detectors
DETECTOR_COUNT=$(ls "$HOME/.kiro/pilot/detectors/"*.sh 2>/dev/null | wc -l | tr -d ' ')
echo "Detectors: $DETECTOR_COUNT"
[ "$DETECTOR_COUNT" -ge 8 ] && echo "✓ All detectors present" || echo "⚠ Expected 8, found $DETECTOR_COUNT"
```

### 11. Performance Metrics

```bash
# Check performance tracking
if [ -f "$HOME/.pilot/observations/performance.json" ]; then
  TIER=$(jq -r '.currentTier // "unknown"' "$HOME/.pilot/observations/performance.json" 2>/dev/null)
  echo "Current tier: $TIER"
  
  DISABLED=$(jq -r '.disabledDetectors | length' "$HOME/.pilot/observations/performance.json" 2>/dev/null)
  echo "Disabled detectors: $DISABLED"
fi
```

---

## Installation Verification Checklist

After installation, confirm:

- [ ] `~/.kiro/pilot/` directory exists
- [ ] `~/.kiro/pilot/identity/` has 10 .md files
- [ ] `~/.kiro/pilot/resources/` has 2 .md files
- [ ] `~/.kiro/pilot/memory/` has hot/warm/cold subdirectories
- [ ] `~/.kiro/pilot/lib/` has 10+ .sh files
- [ ] `~/.kiro/pilot/detectors/` has 8 .sh files
- [ ] `~/.kiro/agents/pilot.json` exists and is valid JSON
- [ ] `~/.kiro/hooks/pilot/` has 5 executable .sh files
- [ ] `~/.kiro/steering/pilot/` has steering files
- [ ] `~/.kiro/pilot/config.json` exists
- [ ] `~/.pilot/` self-learning directory exists
- [ ] `~/.pilot/observations/` has observation JSON files
- [ ] `~/.pilot/identity/` has identity files or templates
- [ ] `~/.pilot/learnings/` directory exists

---

## Functional Tests

### Test 1: Agent Loads in Kiro

1. Open Kiro
2. Select "pilot" agent
3. Verify agent loads without errors

### Test 2: Hooks Execute

```bash
# Test agent-spawn hook
echo '{}' | "$HOME/.kiro/hooks/pilot/agent-spawn.sh"
echo "Exit code: $?"
```

### Test 3: Resources Readable

```bash
# Verify resources are readable
head -5 "$HOME/.kiro/pilot/resources/the-algorithm.md"
```

---

## Common Issues

### Shell Commands Blocked: "matches one or more rules on the denied list"

If you see an error like:
```
Command execute_bash is rejected because it matches one or more rules on the denied list:
- \A.*\z
```

PILOT has a restricted set of allowed shell commands (ls, cat, grep, find, git status, etc.) for safety.

**Resolution options:**

1. **Delegate to specialist** - If the task needs domain expertise (terraform, k8s, etc.), ask PILOT to delegate to a specialized agent

2. **Delegate to kiro_default** - For general execution, PILOT can delegate to the base Kiro agent:
   ```
   Please delegate this terraform validation to kiro_default
   ```

3. **Switch to hands-on mode** - If you want PILOT to execute directly, you may need to adjust the shell allowedCommands in `~/.kiro/agents/pilot.json`

**Note:** Delegation is the recommended approach - it follows PILOT's principle of specialized agents working together.

---

## Troubleshooting Failed Checks

### Directory missing

```bash
mkdir -p "$HOME/.kiro/pilot/identity"
mkdir -p "$HOME/.kiro/pilot/resources"
mkdir -p "$HOME/.kiro/pilot/memory/{hot,warm,cold}"
```

### Hook not executable

```bash
chmod +x "$HOME/.kiro/hooks/pilot/"*.sh
```

### Invalid JSON

```bash
# Check syntax
jq . "$HOME/.kiro/agents/pilot.json"

# If invalid, reinstall from pack
cp /path/to/pilot-core/agents/pilot.json "$HOME/.kiro/agents/"
```

---

## Complete Verification Script

Save and run this script for full verification:

```bash
#!/bin/bash
# verify-pilot.sh

echo "=== PILOT Core Verification ==="
echo ""

PASS=0
FAIL=0
WARN=0

check() {
  if [ "$1" = "true" ]; then
    echo "✓ $2"
    ((PASS++))
  else
    echo "❌ $2"
    ((FAIL++))
  fi
}

warn() {
  echo "⚠ $1"
  ((WARN++))
}

# Kiro Integration Directories
echo "--- Kiro Integration ---"
check "$([ -d "$HOME/.kiro/pilot" ] && echo true)" "PILOT home directory"
check "$([ -d "$HOME/.kiro/pilot/identity" ] && echo true)" "Identity templates"
check "$([ -d "$HOME/.kiro/pilot/resources" ] && echo true)" "Resources directory"
check "$([ -d "$HOME/.kiro/pilot/memory" ] && echo true)" "Memory directory"
check "$([ -d "$HOME/.kiro/pilot/lib" ] && echo true)" "Lib directory"
check "$([ -d "$HOME/.kiro/pilot/detectors" ] && echo true)" "Detectors directory"

# Agent
echo ""
echo "--- Agent Configuration ---"
check "$([ -f "$HOME/.kiro/agents/pilot.json" ] && echo true)" "Agent configuration"

# Hooks
echo ""
echo "--- Hooks ---"
check "$([ -f "$HOME/.kiro/hooks/pilot/agent-spawn.sh" ] && echo true)" "agent-spawn.sh"
check "$([ -f "$HOME/.kiro/hooks/pilot/user-prompt-submit.sh" ] && echo true)" "user-prompt-submit.sh"
check "$([ -f "$HOME/.kiro/hooks/pilot/pre-tool-use.sh" ] && echo true)" "pre-tool-use.sh"
check "$([ -f "$HOME/.kiro/hooks/pilot/post-tool-use.sh" ] && echo true)" "post-tool-use.sh"
check "$([ -f "$HOME/.kiro/hooks/pilot/stop.sh" ] && echo true)" "stop.sh"

# Resources
echo ""
echo "--- Resources ---"
check "$([ -f "$HOME/.kiro/pilot/resources/the-algorithm.md" ] && echo true)" "the-algorithm.md"
check "$([ -f "$HOME/.kiro/pilot/resources/pilot-principles.md" ] && echo true)" "pilot-principles.md"

# Steering
echo ""
echo "--- Steering ---"
check "$([ -f "$HOME/.kiro/steering/pilot/pilot-core-knowledge.md" ] && echo true)" "Steering files"

# Self-Learning Data
echo ""
echo "--- Self-Learning Data (~/.pilot/) ---"
check "$([ -d "$HOME/.pilot" ] && echo true)" "Self-learning home"
check "$([ -d "$HOME/.pilot/learnings" ] && echo true)" "Learnings directory"
check "$([ -d "$HOME/.pilot/identity" ] && echo true)" "Identity directory"
check "$([ -d "$HOME/.pilot/observations" ] && echo true)" "Observations directory"

# Observation Files
echo ""
echo "--- Observation System ---"
for file in projects.json challenges.json prompts.json; do
  if [ -f "$HOME/.pilot/observations/$file" ]; then
    if jq . "$HOME/.pilot/observations/$file" > /dev/null 2>&1; then
      check "true" "$file"
    else
      warn "$file exists but invalid JSON"
    fi
  else
    warn "$file not yet created"
  fi
done

# Lib and Detector counts
echo ""
echo "--- Components ---"
LIB_COUNT=$(ls "$HOME/.kiro/pilot/lib/"*.sh 2>/dev/null | wc -l | tr -d ' ')
DETECTOR_COUNT=$(ls "$HOME/.kiro/pilot/detectors/"*.sh 2>/dev/null | wc -l | tr -d ' ')
check "$([ "$LIB_COUNT" -ge 10 ] && echo true)" "Lib files ($LIB_COUNT)"
check "$([ "$DETECTOR_COUNT" -ge 8 ] && echo true)" "Detectors ($DETECTOR_COUNT)"

echo ""
echo "========================================="
echo "Results: $PASS passed, $FAIL failed, $WARN warnings"
echo "========================================="

[ $FAIL -eq 0 ] && echo "✓ All critical checks passed!" || echo "❌ Some checks failed"
```
