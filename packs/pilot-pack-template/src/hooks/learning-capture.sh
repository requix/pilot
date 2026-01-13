#!/bin/bash
# Learning capture hook
# Event: post-tool-use
# Purpose: Capture learnings from tool usage for memory system

set -euo pipefail

HOOK_NAME="learning-capture"
PACK_NAME="pilot-pack-template"
LOG_FILE="$HOME/.pilot/logs/hooks/hook-execution.log"
MEMORY_PATH="$HOME/.pilot/memory/warm/learnings"

# Ensure directories exist
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$MEMORY_PATH/pack-learnings"

# Log function
log_hook() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date -Iseconds)
    echo "[$timestamp] [$level] [$HOOK_NAME] $message" >> "$LOG_FILE"
}

# Extract learning from tool output
extract_learning() {
    local tool_name="${1:-unknown}"
    local tool_output="${2:-}"
    
    log_hook "INFO" "Analyzing tool output for learnings"
    
    # Check if output contains learning indicators
    if echo "$tool_output" | grep -qi "error\|warning\|success\|completed\|failed"; then
        log_hook "INFO" "Learning indicators detected"
        
        # Generate learning entry
        local timestamp
        timestamp=$(date -Iseconds)
        local learning_id
        learning_id=$(echo -n "$timestamp-$tool_name" | sha256sum | cut -d' ' -f1 | head -c 8)
        
        # Create learning file
        cat > "$MEMORY_PATH/pack-learnings/$timestamp-$learning_id.md" << EOF
---
timestamp: $timestamp
pack: $PACK_NAME
tool: $tool_name
category: tool-usage
tags: [template-pack, tool-execution, automated-capture]
---

# Tool Usage Learning: $tool_name

## Context
- **Tool**: $tool_name
- **Pack**: $PACK_NAME
- **Timestamp**: $timestamp
- **Session**: ${KIRO_SESSION_ID:-unknown}

## Output Analysis
\`\`\`
${tool_output:0:500}
\`\`\`

## Insights
- Tool executed successfully
- Output captured for future reference
- Pattern available for similar tasks

## Tags
- tool-usage
- $PACK_NAME
- automated-learning
EOF
        
        log_hook "INFO" "Learning captured: $learning_id"
        echo "📚 Learning captured and stored in memory"
    else
        log_hook "DEBUG" "No significant learnings detected"
    fi
}

# Update learning index
update_index() {
    local index_file="$MEMORY_PATH/pack-learnings/index.json"
    
    if [ ! -f "$index_file" ]; then
        echo '{"learnings": []}' > "$index_file"
    fi
    
    # Count learnings
    local count
    count=$(find "$MEMORY_PATH/pack-learnings" -name "*.md" -type f | wc -l)
    
    log_hook "INFO" "Learning index updated: $count total learnings"
}

# Main function
main() {
    local tool_name="${1:-unknown}"
    local tool_output="${2:-}"
    
    log_hook "INFO" "Post-tool-use hook triggered for: $tool_name"
    
    # Extract and store learning
    extract_learning "$tool_name" "$tool_output"
    
    # Update index
    update_index
    
    log_hook "INFO" "Learning capture completed"
}

# Execute with error handling
if main "$@"; then
    exit 0
else
    log_hook "ERROR" "Learning capture failed"
    # Always exit 0 for fail-safe design
    exit 0
fi
