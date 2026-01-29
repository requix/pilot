#!/usr/bin/env bash
# post-tool-use.sh - Enhanced tool usage logging with BUILD phase detection

PILOT_HOME="${HOME}/.kiro/pilot"
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
SESSION_ID="${PILOT_SESSION_ID:-unknown}"
DEBUG_DIR="${PILOT_HOME}/debug"

# Ensure directories exist
mkdir -p "$DEBUG_DIR" 2>/dev/null || true

# Source dashboard emission library
if [[ -f "${PILOT_HOME}/lib/dashboard-emitter.sh" ]]; then
    source "${PILOT_HOME}/lib/dashboard-emitter.sh" 2>/dev/null || true
fi

# Get input JSON from STDIN
input_json=$(cat 2>/dev/null || echo "{}")

# Extract tool name and content
TOOL_NAME=""
TOOL_CONTENT=""
if command -v jq >/dev/null 2>&1; then
    TOOL_NAME=$(echo "$input_json" | jq -r '.tool_name // empty' 2>/dev/null) || true
    TOOL_CONTENT=$(echo "$input_json" | jq -r '.tool_input.file_text // .tool_input.command // empty' 2>/dev/null) || true
fi

# Debug logging
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) HOOK: tool=$TOOL_NAME content_len=${#TOOL_CONTENT}" >> "$DEBUG_DIR/hook-debug.log" 2>/dev/null || true

# Phase detection for BUILD
if [[ -n "$TOOL_CONTENT" ]] && declare -f dashboard_emit_phase >/dev/null 2>&1; then
    if echo "$TOOL_CONTENT" | grep -qi "success criteria\|requirements\|what success looks like\|acceptance criteria"; then
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) HOOK: BUILD phase detected!" >> "$DEBUG_DIR/hook-debug.log" 2>/dev/null || true
        dashboard_emit_phase "BUILD" 2>/dev/null || true
    fi
fi

# Original logging
LOG_FILE="${PILOT_DATA}/logs/tool-usage.log"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [$SESSION_ID] ${TOOL_NAME:-unknown}" >> "$LOG_FILE" 2>/dev/null || true

exit 0
