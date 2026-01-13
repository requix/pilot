#!/usr/bin/env bash
# pre-tool-use.sh - Security validation before tool execution
# Part of PILOT - Fail-safe design (exits 0 to allow, 1 to block)

PILOT_HOME="${HOME}/.kiro/pilot"
HOT_MEMORY="${PILOT_HOME}/memory/hot"
METRICS_DIR="${PILOT_HOME}/metrics"
CACHE_DIR="${PILOT_HOME}/.cache"

# Ensure directories exist
mkdir -p "$HOT_MEMORY" "$METRICS_DIR" 2>/dev/null || true

# Get input JSON from STDIN (Kiro sends hook events via STDIN, not arguments)
input_json=$(cat 2>/dev/null || echo "{}")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Extract tool name (Kiro sends tool_name at top level per docs)
get_tool_name() {
    local json="$1"
    local tool=""
    if command -v jq >/dev/null 2>&1; then
        tool=$(echo "$json" | jq -r '.tool_name // .toolName // empty' 2>/dev/null) || true
    fi
    echo "${tool:-unknown}"
}

# Extract tool_input (per Kiro docs)
get_tool_input() {
    local json="$1"
    local input=""
    if command -v jq >/dev/null 2>&1; then
        input=$(echo "$json" | jq -r '.tool_input // empty' 2>/dev/null) || true
    fi
    echo "$input"
}

# Get session ID
get_session_id() {
    local json="$1"
    local sid=""
    if command -v jq >/dev/null 2>&1; then
        sid=$(echo "$json" | jq -r '.sessionId // .session_id // empty' 2>/dev/null) || true
    fi
    if [ -z "$sid" ] && [ -f "$CACHE_DIR/current-session-id" ]; then
        sid=$(cat "$CACHE_DIR/current-session-id" 2>/dev/null) || true
    fi
    echo "${sid:-unknown}"
}

TOOL_NAME=$(get_tool_name "$input_json")
TOOL_INPUT=$(get_tool_input "$input_json")
SESSION_ID=$(get_session_id "$input_json")

# Log tool attempt
TOOL_ESCAPED=$(echo "$TOOL_INPUT" | head -c 200 | sed 's/\\/\\\\/g;s/"/\\"/g' | tr '\n' ' ')
echo "{\"timestamp\":\"$TIMESTAMP\",\"session_id\":\"$SESSION_ID\",\"tool\":\"$TOOL_NAME\",\"input\":\"$TOOL_ESCAPED\"}" >> "$HOT_MEMORY/tool-attempts.jsonl" 2>/dev/null || true

# Only validate shell commands
case "$TOOL_NAME" in
    shell|Bash|bash|executeBash) ;;
    *) exit 0 ;;
esac

SECURITY_LOG="$HOT_MEMORY/security.log"

# Security checks for dangerous patterns
check_dangerous() {
    local input="$1"
    
    # Catastrophic patterns
    if echo "$input" | grep -qE 'rm -rf /|rm -rf ~|rm -rf \$HOME|> /dev/sd|> /dev/nvme|dd if=/dev/zero|mkfs\.|chmod -R 777 /' 2>/dev/null; then
        echo "[$TIMESTAMP] BLOCKED (CATASTROPHIC)" >> "$SECURITY_LOG" 2>/dev/null || true
        echo "🚨 PILOT Security: BLOCKED - Catastrophic command detected"
        return 1
    fi
    
    # Remote code execution
    if echo "$input" | grep -qE 'curl.*\|.*sh|curl.*\|.*bash|wget.*\|.*sh|wget.*\|.*bash' 2>/dev/null; then
        echo "[$TIMESTAMP] BLOCKED (RCE)" >> "$SECURITY_LOG" 2>/dev/null || true
        echo "🚨 PILOT Security: BLOCKED - Remote code execution pattern"
        return 1
    fi
    
    # System directory protection
    if echo "$input" | grep -qE '(>|>>|tee|mv|cp|rm|chmod|chown).*/etc|.*/bin|.*/sbin|.*/System' 2>/dev/null; then
        echo "[$TIMESTAMP] BLOCKED (SYSTEM_DIR)" >> "$SECURITY_LOG" 2>/dev/null || true
        echo "⛔ PILOT Security: BLOCKED - System directory modification"
        return 1
    fi
    
    return 0
}

if ! check_dangerous "$TOOL_INPUT"; then
    exit 1
fi

echo "[$TIMESTAMP] ALLOWED: ${TOOL_INPUT:0:100}" >> "$SECURITY_LOG" 2>/dev/null || true
exit 0
