#!/usr/bin/env bash
# PILOT Installation Script
# Personal Intelligence Layer for Optimized Tasks
#
# Usage: ./install.sh [--update|-u] [--help|-h]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIRO_HOME="${HOME}/.kiro"
PILOT_HOME="${HOME}/.pilot"

# Colors
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m'
C='\033[0;36m' D='\033[0;90m' W='\033[1;37m' NC='\033[0m'

# Progress tracking
TOTAL_STEPS=8
CURRENT_STEP=0

progress() {
    ((CURRENT_STEP++)) || true
    local pct=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((pct / 5))
    local empty=$((20 - filled))
    local bar="${C}"
    for ((i=0; i<filled; i++)); do bar+="▓"; done
    for ((i=0; i<empty; i++)); do bar+="${D}░"; done
    printf "\r  ${D}[${bar}${D}]${NC} ${W}%3d%%${NC} ${D}│${NC} %s" "$pct" "$1" >&2
}

done_progress() {
    printf "\r  ${D}[${C}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${D}]${NC} ${G}100%%${NC} ${D}│${NC} ${G}✓${NC} Complete          \n" >&2
}

fail() { echo -e "\n${R}✗${NC} $1"; exit 1; }

show_help() {
    cat << 'EOF'
PILOT - Personal Intelligence Layer for Optimized Tasks

Usage: ./install.sh [OPTIONS]

  --update, -u    Update (preserves identity & learnings)
  --help, -h      Show this help

Installs to:
  ~/.kiro/agents/pilot.json  Agent config
  ~/.pilot/                  System files
EOF
    exit 0
}

# Parse args
UPDATE=false
for arg in "$@"; do
    case "$arg" in
        --update|-u) UPDATE=true ;;
        --help|-h) show_help ;;
    esac
done

# Banner - compact for small screens
clear 2>/dev/null || true
echo ""
echo -e "${C}   ██████╗ ██╗██╗      ██████╗ ████████╗${NC}"
echo -e "${C}   ██╔══██╗██║██║     ██╔═══██╗╚══██╔══╝${NC}"
echo -e "${C}   ██████╔╝██║██║     ██║   ██║   ██║${NC}"
echo -e "${C}   ██╔═══╝ ██║██║     ██║   ██║   ██║${NC}"
echo -e "${C}   ██║     ██║███████╗╚██████╔╝   ██║${NC}"
echo -e "${C}   ╚═╝     ╚═╝╚══════╝ ╚═════╝    ╚═╝${NC}"
echo ""
echo -e "   ${D}Self-Learning Assistant for Kiro${NC}"
echo -e "   ${D}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Pre-flight check
[[ -d "${SCRIPT_DIR}/agents" ]] || fail "Source files not found"
[[ -d "${SCRIPT_DIR}/hooks" ]] || fail "Source files not found"

echo -e "  ${Y}▲${NC} ${W}Pre-flight checks passed${NC}"
echo -e "  ${D}─────────────────────────────────────${NC}"
echo ""

# Step 1: Backup
progress "Preparing..."
sleep 0.2
if [[ "$UPDATE" == "true" ]] && [[ -d "$PILOT_HOME" ]]; then
    BACKUP="${PILOT_HOME}/backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP"
    [[ -d "${PILOT_HOME}/identity" ]] && cp -r "${PILOT_HOME}/identity" "$BACKUP/" 2>/dev/null || true
    [[ -d "${PILOT_HOME}/learnings" ]] && cp -r "${PILOT_HOME}/learnings" "$BACKUP/" 2>/dev/null || true
    [[ -d "${PILOT_HOME}/observations" ]] && cp -r "${PILOT_HOME}/observations" "$BACKUP/" 2>/dev/null || true
fi

# Step 2: Directories
progress "Creating directories..."
mkdir -p "${KIRO_HOME}/agents"
mkdir -p "${PILOT_HOME}"/{hooks,steering,identity/.history,learnings,observations}
mkdir -p "${PILOT_HOME}"/system/{helpers,scripts,resources,config}
mkdir -p "${PILOT_HOME}"/memory/{hot,warm,cold}
mkdir -p "${PILOT_HOME}"/{sessions,patterns,logs,backups,.cache}

# Step 3: Agent
progress "Installing agent..."
cp "${SCRIPT_DIR}/agents/pilot.json" "${KIRO_HOME}/agents/"

# Step 4: Hooks
progress "Installing hooks..."
cp "${SCRIPT_DIR}/hooks/"*.sh "${PILOT_HOME}/hooks/"
chmod +x "${PILOT_HOME}/hooks/"*.sh

# Step 5: Steering
progress "Installing steering..."
cp "${SCRIPT_DIR}/steering/"*.md "${PILOT_HOME}/steering/"

# Step 6: System
progress "Installing system..."
[[ -d "${SCRIPT_DIR}/helpers" ]] && { cp "${SCRIPT_DIR}/helpers/"*.sh "${PILOT_HOME}/system/helpers/" 2>/dev/null || true; chmod +x "${PILOT_HOME}/system/helpers/"*.sh 2>/dev/null || true; }
[[ -d "${SCRIPT_DIR}/scripts" ]] && { cp "${SCRIPT_DIR}/scripts/"*.sh "${PILOT_HOME}/system/scripts/" 2>/dev/null || true; chmod +x "${PILOT_HOME}/system/scripts/"*.sh 2>/dev/null || true; }
cp "${SCRIPT_DIR}/resources/"*.md "${PILOT_HOME}/system/resources/"
[[ -d "${SCRIPT_DIR}/config" ]] && cp "${SCRIPT_DIR}/config/"*.json "${PILOT_HOME}/system/config/" 2>/dev/null || true

# Step 7: Identity
progress "Setting up identity..."
if [[ "$UPDATE" != "true" ]] || [[ ! -f "${PILOT_HOME}/identity/MISSION.md" ]]; then
    cp "${SCRIPT_DIR}/identity/"*.md "${PILOT_HOME}/identity/"
fi

# Config
cat > "${PILOT_HOME}/config.json" << EOF
{"installed":"$(date -Iseconds)","features":{"learning":true,"memory":true,"patterns":true}}
EOF

# Step 8: Observations
progress "Initializing systems..."
OBS="${PILOT_HOME}/observations"
for f in projects sessions patterns challenges prompts time-allocation goals working-style evolution cross-file performance strategies ideas beliefs models narratives; do
    [[ -f "${OBS}/${f}.json" ]] || echo '{}' > "${OBS}/${f}.json"
done

done_progress

# Verify
echo ""
ERRORS=0
for check in "${KIRO_HOME}/agents/pilot.json" "${PILOT_HOME}/hooks" "${PILOT_HOME}/steering" "${PILOT_HOME}/identity" "${PILOT_HOME}/memory" "${PILOT_HOME}/observations"; do
    [[ -e "$check" ]] || ((ERRORS++))
done

if [[ $ERRORS -eq 0 ]]; then
    echo -e "  ${G}✓${NC} ${W}Installation verified${NC}"
else
    fail "Installation incomplete ($ERRORS errors)"
fi

# Summary
echo ""
echo -e "  ${D}─────────────────────────────────────${NC}"
echo -e "  ${G}✈${NC}  ${W}PILOT ready for takeoff!${NC}"
echo -e "  ${D}─────────────────────────────────────${NC}"
echo ""
echo -e "  ${D}Locations:${NC}"
echo -e "    ${C}~/.kiro/agents/pilot.json${NC}  agent"
echo -e "    ${C}~/.pilot/${NC}                  system"
echo ""
echo -e "  ${D}Next:${NC} Select ${W}'pilot'${NC} in Kiro, or run:"
echo -e "        ${C}kiro-cli --agent pilot${NC}"
echo ""
echo -e "  ${D}Tip:${NC}  Enable semantic search for better memory:"
echo -e "        ${C}kiro-cli settings chat.enableKnowledge true${NC}"
echo ""
