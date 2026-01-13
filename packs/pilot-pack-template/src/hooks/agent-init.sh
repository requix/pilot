#!/bin/bash
# Agent initialization hook
# Event: agent-spawn
# Purpose: Initialize pack context when agent starts

set -euo pipefail

HOOK_NAME="agent-init"
PACK_NAME="pilot-pack-template"
PACK_PATH="$HOME/.pilot/packs/$PACK_NAME"
LOG_FILE="$HOME/.pilot/logs/hooks/hook-execution.log"

# Ensure directories exist
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$PACK_PATH/cache"

# Log function
log_hook() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date -Iseconds)
    echo "[$timestamp] [$level] [$HOOK_NAME] $message" >> "$LOG_FILE"
}

# Initialize pack context
initialize_context() {
    log_hook "INFO" "Initializing $PACK_NAME context"
    
    # Create context file
    cat > "$PACK_PATH/cache/context.json" << EOF
{
  "pack": "$PACK_NAME",
  "initialized_at": "$(date -Iseconds)",
  "session_id": "${KIRO_SESSION_ID:-unknown}",
  "workspace": "${KIRO_WORKSPACE_ROOT:-$(pwd)}",
  "agent": "template-agent",
  "features": {
    "steering_files": true,
    "hooks": true,
    "tools": true,
    "mcp_servers": false
  },
  "status": "ready"
}
EOF
    
    log_hook "INFO" "Context initialized successfully"
}

# Check pack health
check_health() {
    log_hook "INFO" "Checking pack health"
    
    local health_status="healthy"
    local issues=()
    
    # Check steering files
    if [ ! -d "$HOME/.kiro/steering/packs/$PACK_NAME" ]; then
        health_status="degraded"
        issues+=("steering_files_missing")
        log_hook "WARN" "Steering files not found"
    fi
    
    # Check tools
    if [ ! -x "$PACK_PATH/src/tools/template-tool.sh" ]; then
        health_status="degraded"
        issues+=("tools_not_executable")
        log_hook "WARN" "Tools not executable"
    fi
    
    # Update context with health status
    if [ -f "$PACK_PATH/cache/context.json" ]; then
        local temp_file
        temp_file=$(mktemp)
        jq --arg status "$health_status" --argjson issues "$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)" \
           '.health_status = $status | .health_issues = $issues' \
           "$PACK_PATH/cache/context.json" > "$temp_file"
        mv "$temp_file" "$PACK_PATH/cache/context.json"
    fi
    
    log_hook "INFO" "Health check completed: $health_status"
}

# Load pack configuration
load_configuration() {
    log_hook "INFO" "Loading pack configuration"
    
    if [ -f "$PACK_PATH/pack.json" ]; then
        # Validate pack.json
        if jq empty "$PACK_PATH/pack.json" 2>/dev/null; then
            log_hook "INFO" "Pack configuration valid"
        else
            log_hook "ERROR" "Invalid pack.json"
        fi
    else
        log_hook "ERROR" "pack.json not found"
    fi
}

# Main initialization
main() {
    log_hook "INFO" "Agent spawn hook triggered"
    
    # Initialize context
    initialize_context
    
    # Load configuration
    load_configuration
    
    # Check health
    check_health
    
    # Output initialization message
    echo "✅ $PACK_NAME initialized successfully"
    echo "📦 Pack version: $(jq -r '.version' "$PACK_PATH/pack.json" 2>/dev/null || echo 'unknown')"
    echo "🔗 Kiro CLI integration: active"
    
    log_hook "INFO" "Initialization completed"
}

# Execute with error handling
if main "$@"; then
    exit 0
else
    log_hook "ERROR" "Initialization failed"
    # Always exit 0 for fail-safe design
    exit 0
fi
