#!/usr/bin/env bash
# Identity capture hook - post tool use
# Captures technical patterns from tool usage

TOOL_NAME="${1}"
TOOL_ARGS="${2}"
TOOL_RESULT="${3}"

capture_tool_patterns() {
    local tool="$1"
    local args="$2"
    local log_file="${PILOT_DATA:-$HOME/.pilot}/identity/.history/tool-patterns.log"
    
    mkdir -p "$(dirname "$log_file")"
    
    case "$tool" in
        "execute_bash")
            if echo "$args" | grep -q "terraform\|aws\|kubectl\|docker"; then
                echo "$(date): Infrastructure tool: $tool with $(echo "$args" | cut -c1-50)" >> "$log_file"
            fi
            ;;
        "fs_write"|"fs_read")
            echo "$(date): File operation: $tool" >> "$log_file"
            ;;
        "web_search")
            echo "$(date): Research: web search" >> "$log_file"
            ;;
    esac
}

capture_tool_patterns "$TOOL_NAME" "$TOOL_ARGS"
