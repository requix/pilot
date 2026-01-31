#!/usr/bin/env bash
# PILOT Verification Script
# Verifies PILOT installation at ~/.pilot/

set -uo pipefail

KIRO_HOME="${HOME}/.kiro"
PILOT_HOME="${HOME}/.pilot"

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

# Agent (only file in ~/.kiro/)
echo "Kiro Integration:"
check "Agent configuration (~/.kiro/agents/pilot.json)" test -f "${KIRO_HOME}/agents/pilot.json"
echo ""

# PILOT directories
echo "PILOT Directories:"
check "PILOT home (~/.pilot/)" test -d "${PILOT_HOME}"
check "Hooks directory" test -d "${PILOT_HOME}/hooks"
check "Steering directory" test -d "${PILOT_HOME}/steering"
check "System directory" test -d "${PILOT_HOME}/system"
check "Identity directory" test -d "${PILOT_HOME}/identity"
check "Learnings directory" test -d "${PILOT_HOME}/learnings"
check "Observations directory" test -d "${PILOT_HOME}/observations"
check "Memory (hot)" test -d "${PILOT_HOME}/memory/hot"
check "Memory (warm)" test -d "${PILOT_HOME}/memory/warm"
check "Memory (cold)" test -d "${PILOT_HOME}/memory/cold"
echo ""

# Hooks
echo "Hooks:"
check "agent-spawn.sh" test -f "${PILOT_HOME}/hooks/agent-spawn.sh"
check "user-prompt-submit.sh" test -f "${PILOT_HOME}/hooks/user-prompt-submit.sh"
check "pre-tool-use.sh" test -f "${PILOT_HOME}/hooks/pre-tool-use.sh"
check "post-tool-use.sh" test -f "${PILOT_HOME}/hooks/post-tool-use.sh"
check "stop.sh" test -f "${PILOT_HOME}/hooks/stop.sh"
check "Hooks executable" test -x "${PILOT_HOME}/hooks/agent-spawn.sh"
echo ""

# Steering
echo "Steering:"
check "methodology.md" test -f "${PILOT_HOME}/steering/methodology.md"
check "pilot-core-knowledge.md" test -f "${PILOT_HOME}/steering/pilot-core-knowledge.md"
echo ""

# System
echo "System:"
check "Resources (the-algorithm.md)" test -f "${PILOT_HOME}/system/resources/the-algorithm.md"
check "Resources (pilot-principles.md)" test -f "${PILOT_HOME}/system/resources/pilot-principles.md"
HELPER_COUNT=$(find "${PILOT_HOME}/system/helpers" -name "*.sh" -type f 2>/dev/null | wc -l | tr -d ' ')
check "Helpers (${HELPER_COUNT} files)" test "${HELPER_COUNT}" -ge 1
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

# Config
echo "Configuration:"
check "config.json" test -f "${PILOT_HOME}/config.json"
echo ""

# Functional tests
echo "Functional Tests:"

# Test agent-spawn hook
if [ -x "${PILOT_HOME}/hooks/agent-spawn.sh" ]; then
    OUTPUT=$(echo '{}' | "${PILOT_HOME}/hooks/agent-spawn.sh" 2>/dev/null || echo "")
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
if [ -x "${PILOT_HOME}/hooks/pre-tool-use.sh" ]; then
    if echo '{"tool":"shell","command":"ls -la"}' | "${PILOT_HOME}/hooks/pre-tool-use.sh" >/dev/null 2>&1; then
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
