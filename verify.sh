#!/usr/bin/env bash
# PILOT Verification Script
# Verifies PILOT installation at ~/.kiro/

set -uo pipefail

KIRO_HOME="${HOME}/.kiro"
PILOT_HOME="${KIRO_HOME}/pilot"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    local description="$1"
    shift
    
    if "$@" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $description"
        ((FAIL++))
    fi
}

echo ""
echo "PILOT Installation Verification"
echo "================================"
echo ""

# Directories
echo "Directories:"
check "PILOT home (~/.kiro/pilot/)" test -d "${PILOT_HOME}"
check "Identity directory" test -d "${PILOT_HOME}/identity"
check "Resources directory" test -d "${PILOT_HOME}/resources"
check "Hot memory" test -d "${PILOT_HOME}/memory/hot"
check "Warm memory" test -d "${PILOT_HOME}/memory/warm"
check "Cold memory" test -d "${PILOT_HOME}/memory/cold"
check "Metrics directory" test -d "${PILOT_HOME}/metrics"
echo ""

# Agent
echo "Agent:"
check "Agent configuration" test -f "${KIRO_HOME}/agents/pilot.json"
echo ""

# Hooks
echo "Hooks:"
check "agent-spawn.sh" test -f "${KIRO_HOME}/hooks/pilot/agent-spawn.sh"
check "user-prompt-submit.sh" test -f "${KIRO_HOME}/hooks/pilot/user-prompt-submit.sh"
check "pre-tool-use.sh" test -f "${KIRO_HOME}/hooks/pilot/pre-tool-use.sh"
check "post-tool-use.sh" test -f "${KIRO_HOME}/hooks/pilot/post-tool-use.sh"
check "stop.sh" test -f "${KIRO_HOME}/hooks/pilot/stop.sh"
check "Hooks executable" test -x "${KIRO_HOME}/hooks/pilot/agent-spawn.sh"
echo ""

# Resources
echo "Resources:"
check "the-algorithm.md" test -f "${PILOT_HOME}/resources/the-algorithm.md"
check "pilot-principles.md" test -f "${PILOT_HOME}/resources/pilot-principles.md"
echo ""

# Identity
echo "Identity:"
IDENTITY_COUNT=$(find "${PILOT_HOME}/identity" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "${IDENTITY_COUNT}" -ge 10 ]; then
    echo -e "${GREEN}✓${NC} Identity files (${IDENTITY_COUNT}/10)"
    ((PASS++))
else
    echo -e "${RED}✗${NC} Identity files (${IDENTITY_COUNT}/10)"
    ((FAIL++))
fi
echo ""

# Steering
echo "Steering:"
check "Steering files" test -f "${KIRO_HOME}/steering/pilot/pilot-core-knowledge.md"
echo ""

# Config
echo "Configuration:"
check "config.json" test -f "${PILOT_HOME}/config.json"
echo ""

# Functional tests
echo "Functional Tests:"

# Test agent-spawn hook
if [ -x "${KIRO_HOME}/hooks/pilot/agent-spawn.sh" ]; then
    OUTPUT=$(echo '{}' | "${KIRO_HOME}/hooks/pilot/agent-spawn.sh" 2>/dev/null || echo "")
    if [ -n "${OUTPUT}" ]; then
        echo -e "${GREEN}✓${NC} agent-spawn.sh produces output"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} agent-spawn.sh produces output"
        ((FAIL++))
    fi
else
    echo -e "${RED}✗${NC} agent-spawn.sh produces output"
    ((FAIL++))
fi

# Test pre-tool-use hook (should exit 0 for safe command)
if [ -x "${KIRO_HOME}/hooks/pilot/pre-tool-use.sh" ]; then
    if echo '{"tool":"shell","command":"ls -la"}' | "${KIRO_HOME}/hooks/pilot/pre-tool-use.sh" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} pre-tool-use.sh allows safe commands"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} pre-tool-use.sh allows safe commands"
        ((FAIL++))
    fi
else
    echo -e "${RED}✗${NC} pre-tool-use.sh allows safe commands"
    ((FAIL++))
fi

echo ""
echo "================================"
echo "Results: ${PASS} passed, ${FAIL} failed"
echo ""

if [ ${FAIL} -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "PILOT is ready to use. Select 'pilot' agent in Kiro."
    exit 0
else
    echo -e "${RED}✗ Some checks failed.${NC}"
    echo ""
    echo "Run ./install.sh to fix issues."
    exit 1
fi
