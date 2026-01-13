#!/usr/bin/env bash
# PILOT Installation Script
# Platform for Intelligent Lifecycle Operations and Tools
#
# Installs PILOT to ~/.kiro/ (Kiro's home directory)
#
# Usage: ./install.sh [OPTIONS]
#   --update    Update existing installation
#   --help      Show help

set -euo pipefail

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIRO_HOME="${HOME}/.kiro"
PILOT_HOME="${KIRO_HOME}/pilot"

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
    --update, -u     Update existing installation (preserves identity files)
    --help, -h       Show this help message

DESCRIPTION:
    Installs PILOT to ~/.kiro/ with:
    - Agent configuration
    - Hook scripts (memory, intelligence, security, monitoring)
    - Identity templates
    - Resources (Algorithm, Principles)
    - Steering files

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
echo "║   Platform for Intelligent Lifecycle Operations and Tools        ║"
echo "║                         v${VERSION}                                  ║"
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
    log "SUCCESS" "Backup created: $BACKUP_DIR"
fi

# Step 2: Create directories
log "INFO" "Creating directories..."

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

# Step 5: Install resources
log "INFO" "Installing resources..."
cp "${PACK_DIR}/resources/"*.md "${PILOT_HOME}/resources/"
log "SUCCESS" "Resources installed (Algorithm, Principles)"

# Step 6: Install identity templates (skip if updating and files exist)
if [[ "$UPDATE_MODE" == "true" ]] && [[ -f "${PILOT_HOME}/identity/MISSION.md" ]]; then
    log "INFO" "Preserving existing identity files"
else
    log "INFO" "Installing identity templates..."
    cp "${PACK_DIR}/identity/"*.md "${PILOT_HOME}/identity/"
    log "SUCCESS" "Identity templates installed (10 files)"
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
  "features": {
    "memory": true,
    "intelligence": true,
    "security": true,
    "monitoring": true
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
echo "📍 Location: ~/.kiro/pilot/"
echo ""
echo "📁 Structure:"
echo "   ~/.kiro/"
echo "   ├── pilot/           # PILOT home"
echo "   │   ├── identity/    # Your context (10 files)"
echo "   │   ├── resources/   # Algorithm & Principles"
echo "   │   ├── memory/      # Hot/Warm/Cold"
echo "   │   └── metrics/     # Session metrics"
echo "   ├── agents/pilot.json"
echo "   ├── hooks/pilot/     # 5 hook scripts"
echo "   └── steering/pilot/"
echo ""
echo "🚀 Next Steps:"
echo "   1. Select 'pilot' agent in Kiro"
echo "   2. Customize ~/.kiro/pilot/identity/ files"
echo "   3. Start using PILOT!"
echo ""
echo "📚 Foundation Features:"
echo "   • Memory: Three-tier (hot/warm/cold)"
echo "   • Intelligence: Algorithm phase tracking"
echo "   • Security: Multi-tier command validation"
echo "   • Monitoring: Session metrics"
echo ""
echo "========================================="
