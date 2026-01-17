#!/usr/bin/env bash
# post-tool-use.sh - Capture tool results for memory and metrics
# Part of PILOT - Fail-safe design (always exits 0)

PILOT_HOME="${HOME}/.kiro/pilot"
HOT_MEMORY="${PILOT_HOME}/memory/hot"
METRICS_DIR="${PILOT_HOME}/metrics"
CACHE_DIR="${PILOT_HOME}/.cache"
DEBUG_DIR="${PILOT_HOME}/debug"

# Ensure directories exist
mkdir -p "$HOT_MEMORY" "$METRICS_DIR" "$DEBUG_DIR" 2>/dev/null || true

# Source dashboard emission library (fail-safe)
[[ -f "${PILOT_HOME}/lib/dashboard-emit.sh" ]] && source "${PILOT_HOME}/lib/dashboard-emit.sh" 2>/dev/null || true

# Get input JSON from STDIN (Kiro sends hook events via STDIN, not arguments)
input_json=$(cat 2>/dev/null || echo "{}")

# DEBUG: Log raw input to see what Kiro sends
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) post-tool-use: $input_json" >> "$DEBUG_DIR/raw-input.log" 2>/dev/null || true

# Simple JSON extraction using jq (with fallback)
get_json_field() {
    local json="$1"
    local field="$2"
    local default="$3"
    local val=""
    if command -v jq >/dev/null 2>&1; then
        val=$(echo "$json" | jq -r ".$field // empty" 2>/dev/null) || true
    fi
    echo "${val:-$default}"
}

# Extract tool name (Kiro sends tool_name at top level per docs)
get_tool_name() {
    local json="$1"
    local tool=""
    if command -v jq >/dev/null 2>&1; then
        tool=$(echo "$json" | jq -r '.tool_name // .toolName // empty' 2>/dev/null) || true
    fi
    echo "${tool:-unknown}"
}

# Get session ID (from input or persisted file)
get_session_id() {
    local json="$1"
    local sid=""
    if command -v jq >/dev/null 2>&1; then
        sid=$(echo "$json" | jq -r '.sessionId // .session_id // empty' 2>/dev/null) || true
    fi
    # Fallback to persisted session ID
    if [ -z "$sid" ] && [ -f "$CACHE_DIR/current-session-id" ]; then
        sid=$(cat "$CACHE_DIR/current-session-id" 2>/dev/null) || true
    fi
    echo "${sid:-unknown}"
}

# Extract fields
TOOL_NAME=$(get_tool_name "$input_json")
SESSION_ID=$(get_session_id "$input_json")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get success from tool_response.success (per Kiro docs)
TOOL_SUCCESS="true"
if command -v jq >/dev/null 2>&1; then
    TOOL_SUCCESS=$(echo "$input_json" | jq -r '.tool_response.success // true' 2>/dev/null) || TOOL_SUCCESS="true"
fi

# Normalize success value
case "$TOOL_SUCCESS" in
    true|1|"true") TOOL_SUCCESS="true" ;;
    *) TOOL_SUCCESS="false" ;;
esac

# Log tool usage to hot memory
TOOL_LOG="$HOT_MEMORY/tool-usage.jsonl"
echo "{\"timestamp\":\"$TIMESTAMP\",\"session_id\":\"$SESSION_ID\",\"tool\":\"$TOOL_NAME\",\"success\":$TOOL_SUCCESS}" >> "$TOOL_LOG" 2>/dev/null || true

# Log to metrics events
echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"tool_use\",\"tool\":\"$TOOL_NAME\",\"success\":$TOOL_SUCCESS}" >> "$METRICS_DIR/events.jsonl" 2>/dev/null || true

# Track tool patterns (last 5 tools in session)
if [ -f "$TOOL_LOG" ]; then
    RECENT=$(grep "\"session_id\":\"$SESSION_ID\"" "$TOOL_LOG" 2>/dev/null | tail -5 | \
             grep -o '"tool":"[^"]*"' | sed 's/"tool":"//;s/"$//' | tr '\n' ',' | sed 's/,$//' || true)
    if [ -n "$RECENT" ]; then
        echo "{\"timestamp\":\"$TIMESTAMP\",\"session_id\":\"$SESSION_ID\",\"pattern\":\"$RECENT\"}" >> "$HOT_MEMORY/tool-patterns.jsonl" 2>/dev/null || true
    fi
fi

# Dashboard integration - emit learning if fs_write to learnings directory
if command -v emit_learning >/dev/null 2>&1; then
    if [[ "$TOOL_NAME" == "fs_write" ]] && echo "$input_json" | grep -q "learnings" 2>/dev/null; then
        LEARNING_TITLE=$(echo "$input_json" | jq -r '.parameters.summary // "Learning captured"' 2>/dev/null || echo "Learning captured")
        emit_learning "$LEARNING_TITLE" 2>/dev/null || true
    fi
fi

# Silent hook - no output
exit 0
