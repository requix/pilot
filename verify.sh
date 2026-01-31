#!/usr/bin/env bash
# PILOT Verification Script
# Quick flight check for your PILOT installation

set -uo pipefail

KIRO_HOME="${HOME}/.kiro"
PILOT_HOME="${HOME}/.pilot"

# Colors
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
C='\033[0;36m' D='\033[0;90m' W='\033[1;37m' NC='\033[0m'

PASS=0 FAIL=0

chk() {
    if "$@" >/dev/null 2>&1; then
        echo -e "  ${G}✓${NC} $1"; ((PASS++))
    else
        echo -e "  ${R}✗${NC} $1"; ((FAIL++))
    fi
}

# Banner
echo ""
echo -e "${C}   ▄▀▀▀▀▄  PILOT${NC}"
echo -e "${C}  ▀▀▀▀▀▀▀▀▀${NC} ${D}Flight Check${NC}"
echo ""

# Core systems
echo -e "  ${D}─── Core Systems ───${NC}"
chk "Agent config" test -f "${KIRO_HOME}/agents/pilot.json"
chk "PILOT home" test -d "${PILOT_HOME}"
chk "Config" test -f "${PILOT_HOME}/config.json"
echo ""

# Subsystems
echo -e "  ${D}─── Subsystems ───${NC}"
chk "Hooks" test -d "${PILOT_HOME}/hooks"
chk "Steering" test -d "${PILOT_HOME}/steering"
chk "Identity" test -d "${PILOT_HOME}/identity"
chk "Memory" test -d "${PILOT_HOME}/memory"
chk "Observations" test -d "${PILOT_HOME}/observations"
echo ""

# Hooks check
echo -e "  ${D}─── Hook Status ───${NC}"
for hook in agent-spawn user-prompt-submit pre-tool-use post-tool-use stop; do
    chk "${hook}" test -x "${PILOT_HOME}/hooks/${hook}.sh"
done
echo ""

# Functional
echo -e "  ${D}─── Flight Test ───${NC}"
if [[ -x "${PILOT_HOME}/hooks/agent-spawn.sh" ]]; then
    if echo '{}' | "${PILOT_HOME}/hooks/agent-spawn.sh" >/dev/null 2>&1; then
        echo -e "  ${G}✓${NC} Hooks operational"; ((PASS++))
    else
        echo -e "  ${R}✗${NC} Hooks operational"; ((FAIL++))
    fi
else
    echo -e "  ${R}✗${NC} Hooks operational"; ((FAIL++))
fi

# Results
echo ""
echo -e "  ${D}━━━━━━━━━━━━━━━━━━━━━${NC}"
if [[ $FAIL -eq 0 ]]; then
    echo -e "  ${G}✈${NC}  ${W}All systems go!${NC} ${D}(${PASS}/${PASS})${NC}"
    echo ""
    echo -e "  ${D}Run:${NC} ${C}kiro-cli --agent pilot${NC}"
else
    echo -e "  ${Y}⚠${NC}  ${W}${PASS} passed, ${FAIL} failed${NC}"
    echo ""
    echo -e "  ${D}Fix:${NC} Run ${C}./install.sh${NC}"
fi
echo ""

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
