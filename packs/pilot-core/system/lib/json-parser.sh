#!/usr/bin/env bash
# json-parser.sh - JSON parsing for PILOT hooks using jq
# Part of PILOT (Platform for Intelligent Lifecycle Operations and Tools)
#
# Requires: jq (standard JSON processor)
# Install: brew install jq (macOS) or apt install jq (Linux)
#
# Usage:
#   source json-parser.sh
#   tool=$(json_get "$json" '.tool')
#   session=$(json_get "$json" '.sessionId // .session_id')

# Check if jq is available
json_check() {
    command -v jq >/dev/null 2>&1
}

# Get a value from JSON using jq query
# Usage: value=$(json_get "$json" ".field")
# Returns empty string on error (fail-safe for set -e)
json_get() {
    local json="$1"
    local query="$2"
    [ -z "$json" ] && return 0
    echo "$json" | jq -r "$query // empty" 2>/dev/null || true
}

# Convenience: extract tool name (handles multiple formats)
json_get_tool() {
    json_get "$1" '
        (if .tool | type == "object" then .tool.name else null end) //
        (if .tool | type == "string" then .tool else null end) //
        .toolName // .tool_name
    '
}

# Convenience: extract session ID
json_get_session() {
    json_get "$1" '.sessionId // .session_id // .id'
}

# Convenience: extract success status (returns "true" or "false")
json_get_success() {
    local val
    val=$(json_get "$1" '.success // .succeeded')
    case "$val" in
        true|1) echo "true" ;;
        false|0) echo "false" ;;
        *) echo "true" ;;
    esac
}

# Convenience: extract message/prompt
json_get_message() {
    json_get "$1" '.message // .prompt // .content'
}
