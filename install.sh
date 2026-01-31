#!/usr/bin/env bash
# PILOT Installation Script
# Personal Intelligence Layer for Optimized Tasks
#
# Installs PILOT to ~/.pilot/ (with only agent config in ~/.kiro/)
#
# Usage: ./install.sh [OPTIONS]
#   --update    Update existing installation
#   --help      Show help

set -euo pipefail

VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIRO_HOME="${HOME}/.kiro"
PILOT_HOME="${HOME}/.pilot"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local level="$1"
    local message="$2"
    case $level in
        "INFO")    echo -e "${BLUE}ℹ${NC}  $message" ;;
        "SUCCESS") echo -e "${GREEN}✓${NC} $message" ;;
        "WARN")    echo -e "${YELLOW}⚠${NC}  $message" ;;
        "ERROR")   echo -e "${RED}✗${NC} $message" ;;
    esac
}

show_help() {
    cat << 'EOF'
PILOT Installation Script

Usage: ./install.sh [OPTIONS]

OPTIONS:
    --update, -u     Update existing installation (preserves identity and learnings)
    --help, -h       Show this help message

DESCRIPTION:
    Installs PILOT with self-learning capabilities:
    
    ~/.kiro/agents/pilot.json  - Agent configuration (only file in .kiro)
    
    ~/.pilot/                  - Everything else
    ├── hooks/                 - Hook scripts
    ├── steering/              - Methodology guidance
    ├── system/                - Libraries, detectors, resources
    ├── identity/              - User context
    ├── learnings/             - Auto-captured learnings
    ├── observations/          - Adaptive identity capture
    ├── memory/                - Session memory
    └── logs/                  - System logs

EOF
}

# Parse arguments
UPDATE_MODE=false
for arg in "$@"; do
    case "$arg" in
        --update|-u) UPDATE_MODE=true ;;
        --help|-h) show_help; exit 0 ;;
    esac
done

# Banner
echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║   ██████╗ ██╗██╗      ██████╗ ████████╗                          ║"
echo "║   ██╔══██╗██║██║     ██╔═══██╗╚══██╔══╝                          ║"
echo "║   ██████╔╝██║██║     ██║   ██║   ██║                             ║"
echo "║   ██╔═══╝ ██║██║     ██║   ██║   ██║                             ║"
echo "║   ██║     ██║███████╗╚██████╔╝   ██║                             ║"
echo "║   ╚═╝     ╚═╝╚══════╝ ╚═════╝    ╚═╝                             ║"
echo "║                                                                   ║"
echo "║   Personal Intelligence Layer for Optimized Tasks                ║"
echo "║   Self-Learning System for Kiro CLI          v${VERSION}             ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Verify source directories exist
if [[ ! -d "${SCRIPT_DIR}/agents" ]] || [[ ! -d "${SCRIPT_DIR}/hooks" ]]; then
    log "ERROR" "Source files not found in $SCRIPT_DIR"
    exit 1
fi

# Step 1: Backup if updating
if [[ "$UPDATE_MODE" == "true" ]] && [[ -d "$PILOT_HOME" ]]; then
    log "INFO" "Creating backup..."
    BACKUP_DIR="${PILOT_HOME}/backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    # Backup user data only
    [[ -d "${PILOT_HOME}/identity" ]] && cp -r "${PILOT_HOME}/identity" "$BACKUP_DIR/"
    [[ -d "${PILOT_HOME}/learnings" ]] && cp -r "${PILOT_HOME}/learnings" "$BACKUP_DIR/"
    [[ -d "${PILOT_HOME}/observations" ]] && cp -r "${PILOT_HOME}/observations" "$BACKUP_DIR/"
    log "SUCCESS" "Backup created: $BACKUP_DIR"
fi

# Step 2: Create directories
log "INFO" "Creating directories..."

# Kiro directory (only for agent config)
mkdir -p "${KIRO_HOME}/agents"

# PILOT directories
mkdir -p "${PILOT_HOME}/hooks"
mkdir -p "${PILOT_HOME}/steering"
mkdir -p "${PILOT_HOME}/system/helpers"
mkdir -p "${PILOT_HOME}/system/scripts"
mkdir -p "${PILOT_HOME}/system/resources"
mkdir -p "${PILOT_HOME}/system/config"
mkdir -p "${PILOT_HOME}/identity"
mkdir -p "${PILOT_HOME}/identity/.history"
mkdir -p "${PILOT_HOME}/learnings"
mkdir -p "${PILOT_HOME}/observations"
mkdir -p "${PILOT_HOME}/memory/hot"
mkdir -p "${PILOT_HOME}/memory/warm"
mkdir -p "${PILOT_HOME}/memory/cold"
mkdir -p "${PILOT_HOME}/sessions"
mkdir -p "${PILOT_HOME}/patterns"
mkdir -p "${PILOT_HOME}/logs"
mkdir -p "${PILOT_HOME}/backups"
mkdir -p "${PILOT_HOME}/.cache"

log "SUCCESS" "Directories created"

# Step 3: Install agent configuration (only file in ~/.kiro/)
log "INFO" "Installing agent configuration..."
cp "${SCRIPT_DIR}/agents/pilot.json" "${KIRO_HOME}/agents/"
log "SUCCESS" "Agent installed: ~/.kiro/agents/pilot.json"

# Step 4: Install hooks
log "INFO" "Installing hooks..."
cp "${SCRIPT_DIR}/hooks/"*.sh "${PILOT_HOME}/hooks/"
chmod +x "${PILOT_HOME}/hooks/"*.sh
log "SUCCESS" "Hooks installed"

# Step 5: Install steering files
log "INFO" "Installing steering files..."
cp "${SCRIPT_DIR}/steering/"*.md "${PILOT_HOME}/steering/"
log "SUCCESS" "Steering files installed"

# Step 6: Install system files
log "INFO" "Installing system files..."

# Helpers (consolidated libraries and detectors)
if [[ -d "${SCRIPT_DIR}/helpers" ]]; then
    cp "${SCRIPT_DIR}/helpers/"*.sh "${PILOT_HOME}/system/helpers/" 2>/dev/null || true
    chmod +x "${PILOT_HOME}/system/helpers/"*.sh 2>/dev/null || true
fi

# Scripts
if [[ -d "${SCRIPT_DIR}/scripts" ]]; then
    cp "${SCRIPT_DIR}/scripts/"*.sh "${PILOT_HOME}/system/scripts/" 2>/dev/null || true
    chmod +x "${PILOT_HOME}/system/scripts/"*.sh 2>/dev/null || true
fi

# Resources
cp "${SCRIPT_DIR}/resources/"*.md "${PILOT_HOME}/system/resources/"

# Config
if [[ -d "${SCRIPT_DIR}/config" ]]; then
    cp "${SCRIPT_DIR}/config/"*.json "${PILOT_HOME}/system/config/" 2>/dev/null || true
fi

log "SUCCESS" "System files installed"

# Step 7: Install identity templates (skip if updating and files exist)
if [[ "$UPDATE_MODE" == "true" ]] && [[ -f "${PILOT_HOME}/identity/MISSION.md" ]]; then
    log "INFO" "Preserving existing identity files"
else
    log "INFO" "Installing identity templates..."
    cp "${SCRIPT_DIR}/identity/"*.md "${PILOT_HOME}/identity/"
    log "SUCCESS" "Identity templates installed"
fi

# Step 8: Create main config
log "INFO" "Creating configuration..."
cat > "${PILOT_HOME}/config.json" << EOF
{
  "version": "${VERSION}",
  "installed_at": "$(date -Iseconds)",
  "paths": {
    "pilot_home": "~/.pilot",
    "agent_config": "~/.kiro/agents/pilot.json"
  },
  "features": {
    "self_learning": true,
    "memory": true,
    "methodology": true,
    "pattern_detection": true,
    "identity_automation": true
  }
}
EOF
log "SUCCESS" "Configuration created"

# Step 9: Initialize observation files
log "INFO" "Initializing observation system..."
OBSERVATIONS_DIR="${PILOT_HOME}/observations"

# Initialize all observation JSON files
for file in projects sessions patterns challenges prompts time-allocation goals working-style evolution cross-file performance strategies ideas beliefs models narratives; do
    if [[ ! -f "${OBSERVATIONS_DIR}/${file}.json" ]]; then
        case $file in
            projects)
                echo '{"projects": {}, "lastUpdated": null}' > "${OBSERVATIONS_DIR}/${file}.json" ;;
            sessions)
                echo '{"sessions": [], "currentSession": null, "lastUpdated": null}' > "${OBSERVATIONS_DIR}/${file}.json" ;;
            patterns)
                echo '{"beliefs": {}, "strategies": {}, "ideas": {}, "models": {}, "narratives": {}, "workingStyle": {}, "lastUpdated": null}' > "${OBSERVATIONS_DIR}/${file}.json" ;;
            challenges)
                echo '{"challenges": {}, "resolved": [], "lastUpdated": null}' > "${OBSERVATIONS_DIR}/${file}.json" ;;
            prompts)
                echo '{"history": [], "stats": {"totalShown": 0, "totalAccepted": 0, "acceptanceRate": 0, "consecutiveDismissals": 0, "frequencyMultiplier": 1.0}, "limits": {"sessionPrompts": 0, "weekStart": null, "weekPrompts": 0}}' > "${OBSERVATIONS_DIR}/${file}.json" ;;
            time-allocation)
                echo '{"activeSessions": {}, "allocations": {}, "weeklyTotals": {}, "monthlyTotals": {}, "warnings": [], "lastUpdated": null}' > "${OBSERVATIONS_DIR}/${file}.json" ;;
            goals)
                echo '{"inferredGoals": {}, "projectClusters": {}, "missionHints": [], "lastUpdated": null}' > "${OBSERVATIONS_DIR}/${file}.json" ;;
            working-style)
                echo '{"responseFormat": {"prefersBullets": 0, "prefersCode": 0, "prefersConcise": 0, "prefersDetailed": 0}, "sessionTimes": [], "technologies": {}, "communicationPatterns": {"directRequests": 0, "questionStyle": 0, "contextProvided": 0}, "detectedPreferences": {}, "lastUpdated": null}' > "${OBSERVATIONS_DIR}/${file}.json" ;;
            evolution)
                echo '{"staleProjects": [], "techSnapshots": [], "completedGoals": [], "evolutionEvents": [], "lastCheck": null, "lastUpdated": null}' > "${OBSERVATIONS_DIR}/${file}.json" ;;
            cross-file)
                echo '{"connections": [], "suggestions": [], "lastReview": null}' > "${OBSERVATIONS_DIR}/${file}.json" ;;
            performance)
                echo '{"currentTier": "standard", "detectorMetrics": {}, "disabledDetectors": [], "tierHistory": [], "lastUpdated": null}' > "${OBSERVATIONS_DIR}/${file}.json" ;;
            *)
                echo '{"'${file}'": {}, "detections": [], "lastUpdated": null}' > "${OBSERVATIONS_DIR}/${file}.json" ;;
        esac
    fi
done
log "SUCCESS" "Observation system initialized"

# Verification
log "INFO" "Verifying installation..."

ERRORS=0
[[ -f "${KIRO_HOME}/agents/pilot.json" ]] || { log "ERROR" "Agent config missing"; ((ERRORS++)); }
[[ -d "${PILOT_HOME}/hooks" ]] || { log "ERROR" "Hooks missing"; ((ERRORS++)); }
[[ -d "${PILOT_HOME}/steering" ]] || { log "ERROR" "Steering missing"; ((ERRORS++)); }
[[ -d "${PILOT_HOME}/identity" ]] || { log "ERROR" "Identity missing"; ((ERRORS++)); }
[[ -d "${PILOT_HOME}/memory" ]] || { log "ERROR" "Memory missing"; ((ERRORS++)); }
[[ -d "${PILOT_HOME}/learnings" ]] || { log "ERROR" "Learnings missing"; ((ERRORS++)); }
[[ -d "${PILOT_HOME}/observations" ]] || { log "ERROR" "Observations missing"; ((ERRORS++)); }

if [[ $ERRORS -eq 0 ]]; then
    log "SUCCESS" "Installation verified"
else
    log "ERROR" "Installation has $ERRORS errors"
    exit 1
fi

# Summary
echo ""
echo "========================================="
echo "🎉 PILOT Installation Complete!"
echo "========================================="
echo ""
echo "📍 Locations:"
echo "   ~/.kiro/agents/pilot.json  - Agent config (only file in .kiro)"
echo "   ~/.pilot/                  - Everything else"
echo ""
echo "📁 Structure:"
echo "   ~/.pilot/"
echo "   ├── hooks/           # Hook scripts"
echo "   ├── steering/        # Methodology"
echo "   ├── system/helpers/  # Consolidated libraries & detectors"
echo "   ├── identity/        # Your context"
echo "   ├── learnings/       # Auto-captured learnings"
echo "   ├── observations/    # Adaptive identity capture"
echo "   ├── memory/          # Hot/warm/cold storage"
echo "   └── logs/            # System logs"
echo ""
echo "🚀 Next Steps:"
echo "   1. Select 'pilot' agent in Kiro"
echo "   2. Start working - learnings captured automatically!"
echo ""
echo "========================================="
