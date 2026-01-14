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
mkdir -p "${PILOT_DATA}/logs"

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

# Step 4b: Install scripts
log "INFO" "Installing scripts..."
mkdir -p "${PILOT_HOME}/scripts"
if [[ -d "${PACK_DIR}/scripts" ]]; then
    cp "${PACK_DIR}/scripts/"*.sh "${PILOT_HOME}/scripts/" 2>/dev/null || true
    chmod +x "${PILOT_HOME}/scripts/"*.sh 2>/dev/null || true
    log "SUCCESS" "Scripts installed"
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
    "pattern_detection": true
  }
}
EOF
log "SUCCESS" "Configuration created"

# Verification
log "INFO" "Verifying installation..."

ERRORS=0
[[ -f "${KIRO_HOME}/agents/pilot.json" ]] || { log "ERROR" "Agent missing"; ((ERRORS++)); }
[[ -d "${KIRO_HOME}/hooks/pilot" ]] || { log "ERROR" "Hooks missing"; ((ERRORS++)); }
[[ -d "${PILOT_HOME}/identity" ]] || { log "ERROR" "Identity missing"; ((ERRORS++)); }
[[ -d "${PILOT_HOME}/memory" ]] || { log "ERROR" "Memory missing"; ((ERRORS++)); }
[[ -d "${PILOT_DATA}/learnings" ]] || { log "ERROR" "Learnings directory missing"; ((ERRORS++)); }
[[ -d "${PILOT_DATA}/patterns" ]] || { log "ERROR" "Patterns directory missing"; ((ERRORS++)); }

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
echo "   └── logs/                 # System logs"
echo ""
echo "🚀 Next Steps:"
echo "   1. Select 'pilot' agent in Kiro CLI"
echo "   2. Customize ~/.pilot/identity/context.md"
echo "   3. Start working - learnings captured automatically!"
echo ""
echo "📚 Self-Learning Features:"
echo "   • Auto-capture: Learnings detected and saved"
echo "   • Context loading: Past learnings inform new sessions"
echo "   • Pattern detection: Repeated questions flagged"
echo "   • Session archiving: Work history preserved"
echo ""
echo "🔮 Future (when available):"
echo "   • /knowledge integration for semantic search"
echo "   • Power conversion for cross-tool compatibility"
echo ""
echo "========================================="
