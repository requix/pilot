#!/bin/bash
# Template hook demonstrating Kiro CLI hook integration
# Event: user-prompt-submit
# Purpose: Detect when template pack capabilities are needed

set -euo pipefail

# Hook configuration
HOOK_NAME="template-hook"
PACK_NAME="pilot-pack-template"
PACK_PATH="$HOME/.pilot/packs/$PACK_NAME"
LOG_FILE="$HOME/.pilot/logs/hooks/hook-execution.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Log function
log_hook() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date -Iseconds)
    echo "[$timestamp] [$level] [$HOOK_NAME] $message" >> "$LOG_FILE"
}

# Main hook logic
main() {
    local user_input="${1:-}"
    
    log_hook "INFO" "Hook triggered with input: ${user_input:0:50}..."
    
    # Detect template-related keywords
    if echo "$user_input" | grep -qi "template\|example\|demo\|sample"; then
        log_hook "INFO" "Template keywords detected"
        
        # Output activation message (visible to user)
        echo "🔍 Template pack capabilities activated"
        echo "📚 Loading template knowledge from steering files"
        
        # Load pack context if available
        if [ -f "$PACK_PATH/cache/context.json" ]; then
            log_hook "INFO" "Loading cached context"
            cat "$PACK_PATH/cache/context.json"
        fi
        
        # Store activation in hot memory
        if [ -d "$HOME/.pilot/memory/hot" ]; then
            cat > "$HOME/.pilot/memory/hot/template-pack-activation.json" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "pack": "$PACK_NAME",
  "trigger": "user-prompt-submit",
  "keywords_matched": true,
  "user_input_preview": "${user_input:0:100}"
}
EOF
            log_hook "INFO" "Activation recorded in hot memory"
        fi
    else
        log_hook "DEBUG" "No template keywords detected"
    fi
    
    log_hook "INFO" "Hook completed successfully"
}

# Execute main function with error handling
if main "$@"; then
    exit 0
else
    log_hook "ERROR" "Hook execution failed"
    # Always exit 0 for fail-safe design
    exit 0
fi
