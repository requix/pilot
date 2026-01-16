#!/usr/bin/env bash
# PILOT Installation Script
# Personal Intelligence Layer for Optimized Tasks
#
# Installs PILOT to ~/.kiro/ and ~/.pilot/
#
# Usage: ./install.sh [OPTIONS]
#   --update    Update existing installation
#   --help      Show help

set -euo pipefail

VERSION="1.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIRO_HOME="${HOME}/.kiro"
PILOT_HOME="${KIRO_HOME}/pilot"
PILOT_DATA="${HOME}/.pilot"  # Self-learning data directory

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
    
    ~/.kiro/           - Kiro integration
    ├── agents/        - PILOT agent configuration
    ├── hooks/pilot/   - Self-learning hooks
    └── steering/pilot/- Methodology guidance
    
    ~/.pilot/          - Self-learning data
    ├── learnings/     - Auto-captured learnings
    ├── sessions/      - Session archives
    ├── patterns/      - Pattern detection
    ├── identity/      - User context
    └── logs/          - System logs

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

# Check for pilot-core pack
PACK_DIR="${SCRIPT_DIR}/packs/pilot-core"
if [[ ! -d "$PACK_DIR" ]]; then
    log "ERROR" "pilot-core pack not found at $PACK_DIR"
    exit 1
fi

# Step 1: Backup if updating
if [[ "$UPDATE_MODE" == "true" ]] && [[ -d "$PILOT_HOME" ]]; then
    log "INFO" "Creating backup..."
    BACKUP_DIR="${KIRO_HOME}/backups/pilot-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp -r "$PILOT_HOME" "$BACKUP_DIR/" 2>/dev/null || true
    [[ -f "${KIRO_HOME}/agents/pilot.json" ]] && cp "${KIRO_HOME}/agents/pilot.json" "$BACKUP_DIR/"
    [[ -d "${KIRO_HOME}/hooks/pilot" ]] && cp -r "${KIRO_HOME}/hooks/pilot" "$BACKUP_DIR/"
    [[ -d "$PILOT_DATA" ]] && cp -r "$PILOT_DATA" "$BACKUP_DIR/pilot-data" 2>/dev/null || true
    log "SUCCESS" "Backup created: $BACKUP_DIR"
fi

# Step 2: Create directories
log "INFO" "Creating directories..."

# Kiro integration directories
mkdir -p "${PILOT_HOME}/identity"
mkdir -p "${PILOT_HOME}/resources"
mkdir -p "${PILOT_HOME}/memory/hot"
mkdir -p "${PILOT_HOME}/memory/warm"
mkdir -p "${PILOT_HOME}/memory/cold"
mkdir -p "${PILOT_HOME}/metrics"
mkdir -p "${PILOT_HOME}/packs"
mkdir -p "${PILOT_HOME}/.cache"
mkdir -p "${KIRO_HOME}/agents"
mkdir -p "${KIRO_HOME}/hooks/pilot"
mkdir -p "${KIRO_HOME}/steering/pilot"
mkdir -p "${KIRO_HOME}/backups"

# Self-learning data directories
mkdir -p "${PILOT_DATA}/learnings"
mkdir -p "${PILOT_DATA}/sessions"
mkdir -p "${PILOT_DATA}/patterns"
mkdir -p "${PILOT_DATA}/identity"
mkdir -p "${PILOT_DATA}/identity/.history"
mkdir -p "${PILOT_DATA}/logs"

# Observation directories (Adaptive Identity Capture)
mkdir -p "${PILOT_DATA}/observations"

log "SUCCESS" "Directories created"

# Step 3: Install agent configuration
log "INFO" "Installing agent configuration..."
cp "${PACK_DIR}/agents/pilot.json" "${KIRO_HOME}/agents/"
log "SUCCESS" "Agent installed: ~/.kiro/agents/pilot.json"

# Step 4: Install hooks
log "INFO" "Installing hooks..."
cp "${PACK_DIR}/system/hooks/"*.sh "${KIRO_HOME}/hooks/pilot/"
chmod +x "${KIRO_HOME}/hooks/pilot/"*.sh
log "SUCCESS" "Hooks installed (5 scripts)"

# Step 4a: Install lib files
log "INFO" "Installing lib files..."
mkdir -p "${PILOT_HOME}/lib"
if [[ -d "${PACK_DIR}/system/lib" ]]; then
    cp "${PACK_DIR}/system/lib/"*.sh "${PILOT_HOME}/lib/" 2>/dev/null || true
    chmod +x "${PILOT_HOME}/lib/"*.sh 2>/dev/null || true
    log "SUCCESS" "Lib files installed"
fi

# Step 4b: Install scripts
log "INFO" "Installing scripts..."
mkdir -p "${PILOT_HOME}/scripts"
if [[ -d "${PACK_DIR}/scripts" ]]; then
    cp "${PACK_DIR}/scripts/"*.sh "${PILOT_HOME}/scripts/" 2>/dev/null || true
    chmod +x "${PILOT_HOME}/scripts/"*.sh 2>/dev/null || true
    log "SUCCESS" "Scripts installed"
fi

# Step 4c: Install detectors
log "INFO" "Installing detectors..."
mkdir -p "${PILOT_HOME}/detectors"
if [[ -d "${PACK_DIR}/system/detectors" ]]; then
    cp "${PACK_DIR}/system/detectors/"*.sh "${PILOT_HOME}/detectors/" 2>/dev/null || true
    chmod +x "${PILOT_HOME}/detectors/"*.sh 2>/dev/null || true
    DETECTOR_COUNT=$(ls -1 "${PILOT_HOME}/detectors/"*.sh 2>/dev/null | wc -l | tr -d ' ')
    log "SUCCESS" "Detectors installed (${DETECTOR_COUNT} scripts)"
fi

# Step 5: Install resources
log "INFO" "Installing resources..."
cp "${PACK_DIR}/resources/"*.md "${PILOT_HOME}/resources/"
log "SUCCESS" "Resources installed (Algorithm, Principles)"

# Step 6: Install identity templates (skip if updating and files exist)
if [[ "$UPDATE_MODE" == "true" ]] && [[ -f "${PILOT_DATA}/identity/context.md" ]]; then
    log "INFO" "Preserving existing identity files"
else
    log "INFO" "Installing identity templates..."
    cp "${PACK_DIR}/identity/"*.md "${PILOT_HOME}/identity/"
    # Also copy identity template to self-learning directory
    if [[ -f "${PACK_DIR}/steering/identity-template.md" ]]; then
        cp "${PACK_DIR}/steering/identity-template.md" "${PILOT_DATA}/identity/context.md.template"
    fi
    log "SUCCESS" "Identity templates installed"
fi

# Step 7: Install steering files
log "INFO" "Installing steering files..."
cp "${PACK_DIR}/steering/"*.md "${KIRO_HOME}/steering/pilot/"
log "SUCCESS" "Steering files installed"

# Step 8: Create config
log "INFO" "Creating configuration..."
cat > "${PILOT_HOME}/config.json" << EOF
{
  "version": "${VERSION}",
  "installed_at": "$(date -Iseconds)",
  "pilot_home": "~/.kiro/pilot",
  "pilot_data": "~/.pilot",
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
if [[ -f "${PILOT_HOME}/lib/observation-init.sh" ]]; then
    source "${PILOT_HOME}/lib/observation-init.sh"
    ensure_observation_dirs
    log "SUCCESS" "Observation system initialized"
else
    # Fallback: create observation files manually
    OBSERVATIONS_DIR="${PILOT_DATA}/observations"
    
    # Initialize projects.json
    [[ ! -f "${OBSERVATIONS_DIR}/projects.json" ]] && cat > "${OBSERVATIONS_DIR}/projects.json" << 'EOJSON'
{
  "projects": {},
  "lastUpdated": null
}
EOJSON

    # Initialize sessions.json
    [[ ! -f "${OBSERVATIONS_DIR}/sessions.json" ]] && cat > "${OBSERVATIONS_DIR}/sessions.json" << 'EOJSON'
{
  "sessions": [],
  "currentSession": null,
  "lastUpdated": null
}
EOJSON

    # Initialize patterns.json
    [[ ! -f "${OBSERVATIONS_DIR}/patterns.json" ]] && cat > "${OBSERVATIONS_DIR}/patterns.json" << 'EOJSON'
{
  "beliefs": {},
  "strategies": {},
  "ideas": {},
  "models": {},
  "narratives": {},
  "workingStyle": {},
  "lastUpdated": null
}
EOJSON

    # Initialize challenges.json
    [[ ! -f "${OBSERVATIONS_DIR}/challenges.json" ]] && cat > "${OBSERVATIONS_DIR}/challenges.json" << 'EOJSON'
{
  "challenges": {},
  "resolved": [],
  "lastUpdated": null
}
EOJSON

    # Initialize prompts.json
    [[ ! -f "${OBSERVATIONS_DIR}/prompts.json" ]] && cat > "${OBSERVATIONS_DIR}/prompts.json" << 'EOJSON'
{
  "history": [],
  "stats": {
    "totalShown": 0,
    "totalAccepted": 0,
    "acceptanceRate": 0,
    "consecutiveDismissals": 0,
    "frequencyMultiplier": 1.0
  },
  "limits": {
    "sessionPrompts": 0,
    "weekStart": null,
    "weekPrompts": 0
  }
}
EOJSON

    # Initialize time-allocation.json
    [[ ! -f "${OBSERVATIONS_DIR}/time-allocation.json" ]] && cat > "${OBSERVATIONS_DIR}/time-allocation.json" << 'EOJSON'
{
  "activeSessions": {},
  "allocations": {},
  "weeklyTotals": {},
  "monthlyTotals": {},
  "warnings": [],
  "lastUpdated": null
}
EOJSON

    # Initialize goals.json
    [[ ! -f "${OBSERVATIONS_DIR}/goals.json" ]] && cat > "${OBSERVATIONS_DIR}/goals.json" << 'EOJSON'
{
  "inferredGoals": {},
  "projectClusters": {},
  "missionHints": [],
  "lastUpdated": null
}
EOJSON

    # Initialize working-style.json
    [[ ! -f "${OBSERVATIONS_DIR}/working-style.json" ]] && cat > "${OBSERVATIONS_DIR}/working-style.json" << 'EOJSON'
{
  "responseFormat": {
    "prefersBullets": 0,
    "prefersCode": 0,
    "prefersConcise": 0,
    "prefersDetailed": 0
  },
  "sessionTimes": [],
  "technologies": {},
  "communicationPatterns": {
    "directRequests": 0,
    "questionStyle": 0,
    "contextProvided": 0
  },
  "detectedPreferences": {},
  "lastUpdated": null
}
EOJSON

    # Initialize evolution.json
    [[ ! -f "${OBSERVATIONS_DIR}/evolution.json" ]] && cat > "${OBSERVATIONS_DIR}/evolution.json" << 'EOJSON'
{
  "staleProjects": [],
  "techSnapshots": [],
  "completedGoals": [],
  "evolutionEvents": [],
  "lastCheck": null,
  "lastUpdated": null
}
EOJSON

    # Initialize cross-file.json
    [[ ! -f "${OBSERVATIONS_DIR}/cross-file.json" ]] && cat > "${OBSERVATIONS_DIR}/cross-file.json" << 'EOJSON'
{
  "connections": [],
  "suggestions": [],
  "lastReview": null
}
EOJSON

    # Initialize performance.json
    [[ ! -f "${OBSERVATIONS_DIR}/performance.json" ]] && cat > "${OBSERVATIONS_DIR}/performance.json" << 'EOJSON'
{
  "currentTier": "standard",
  "detectorMetrics": {},
  "disabledDetectors": [],
  "tierHistory": [],
  "lastUpdated": null
}
EOJSON

    # Initialize strategies.json
    [[ ! -f "${OBSERVATIONS_DIR}/strategies.json" ]] && cat > "${OBSERVATIONS_DIR}/strategies.json" << 'EOJSON'
{
  "strategies": {},
  "approaches": [],
  "failures": [],
  "lastUpdated": null
}
EOJSON

    # Initialize ideas.json
    [[ ! -f "${OBSERVATIONS_DIR}/ideas.json" ]] && cat > "${OBSERVATIONS_DIR}/ideas.json" << 'EOJSON'
{
  "ideas": {},
  "detections": [],
  "lastUpdated": null
}
EOJSON

    # Initialize beliefs.json
    [[ ! -f "${OBSERVATIONS_DIR}/beliefs.json" ]] && cat > "${OBSERVATIONS_DIR}/beliefs.json" << 'EOJSON'
{
  "beliefs": {},
  "decisions": [],
  "lastUpdated": null
}
EOJSON

    # Initialize models.json
    [[ ! -f "${OBSERVATIONS_DIR}/models.json" ]] && cat > "${OBSERVATIONS_DIR}/models.json" << 'EOJSON'
{
  "models": {},
  "detections": [],
  "lastUpdated": null
}
EOJSON

    # Initialize narratives.json
    [[ ! -f "${OBSERVATIONS_DIR}/narratives.json" ]] && cat > "${OBSERVATIONS_DIR}/narratives.json" << 'EOJSON'
{
  "narratives": {},
  "detections": [],
  "lastUpdated": null
}
EOJSON

    log "SUCCESS" "Observation files initialized (fallback)"
fi

# Verification
log "INFO" "Verifying installation..."

ERRORS=0
[[ -f "${KIRO_HOME}/agents/pilot.json" ]] || { log "ERROR" "Agent missing"; ((ERRORS++)); }
[[ -d "${KIRO_HOME}/hooks/pilot" ]] || { log "ERROR" "Hooks missing"; ((ERRORS++)); }
[[ -d "${PILOT_HOME}/identity" ]] || { log "ERROR" "Identity missing"; ((ERRORS++)); }
[[ -d "${PILOT_HOME}/memory" ]] || { log "ERROR" "Memory missing"; ((ERRORS++)); }
[[ -d "${PILOT_DATA}/learnings" ]] || { log "ERROR" "Learnings directory missing"; ((ERRORS++)); }
[[ -d "${PILOT_DATA}/patterns" ]] || { log "ERROR" "Patterns directory missing"; ((ERRORS++)); }
[[ -d "${PILOT_DATA}/observations" ]] || { log "ERROR" "Observations directory missing"; ((ERRORS++)); }
[[ -f "${PILOT_DATA}/observations/projects.json" ]] || { log "WARN" "Observation files not initialized"; }

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
echo "   ~/.kiro/pilot/    - Kiro integration"
echo "   ~/.pilot/         - Self-learning data"
echo ""
echo "📁 Structure:"
echo "   ~/.kiro/"
echo "   ├── agents/pilot.json     # Agent config"
echo "   ├── hooks/pilot/          # Self-learning hooks"
echo "   └── steering/pilot/       # Methodology"
echo ""
echo "   ~/.pilot/"
echo "   ├── learnings/            # Auto-captured learnings"
echo "   ├── sessions/             # Session archives"
echo "   ├── patterns/             # Pattern detection"
echo "   ├── identity/             # Your context"
echo "   ├── observations/         # Adaptive identity capture"
echo "   └── logs/                 # System logs"
echo ""
echo "🚀 Next Steps:"
echo "   1. Enable knowledge feature (experimental, recommended):"
echo "      kiro-cli settings chat.enableKnowledge true"
echo "   2. Select 'pilot' agent: kiro-cli chat --agent pilot"
echo "   3. Set up knowledge base:"
echo "      'Add my learnings folder to the knowledge base'"
echo "   4. Start working - learnings captured automatically!"
echo ""
echo "📚 Self-Learning Features:"
echo "   • Auto-capture: Learnings saved to ~/.pilot/learnings/"
echo "   • Semantic search: Find relevant past learnings (requires /knowledge)"
echo "   • Pattern detection: Repeated questions flagged"
echo "   • Session archiving: Work history preserved"
echo ""
echo "⚠️  Note: Semantic search requires the experimental /knowledge feature."
echo "   Without it, learnings are still captured but search is disabled."
echo ""
echo "========================================="
