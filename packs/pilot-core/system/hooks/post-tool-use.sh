#!/usr/bin/env bash
# post-tool-use.sh - Capture results for memory and learning extraction
# Part of PILOT (Platform for Intelligent Lifecycle Operations and Tools)
#
# FOUNDATION FEATURES:
# - Memory: Log tool results to hot memory
# - Intelligence: Extract patterns for learning
# - Monitoring: Update tool success/failure metrics
#
# INPUT: JSON from Kiro (first argument) with "tool", "result", "success" fields
# OUTPUT: None (silent hook)

set -euo pipefail

PILOT_HOME="${HOME}/.kiro/pilot"
MEMORY_DIR="${PILOT_HOME}/memory"
HOT_MEMORY="${MEMORY_DIR}/hot"
METRICS_DIR="${PILOT_HOME}/metrics"

# Ensure directories exist
mkdir -p "${HOT_MEMORY}" "${METRICS_DIR}"

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Parse input JSON (Kiro provides this as first argument)
input_json="${1:-{}}"

# Extract tool info from JSON
TOOL_NAME=$(echo "${input_json}" | grep -o '"tool"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/"tool"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "unknown")

# Extract success status
TOOL_SUCCESS=$(echo "${input_json}" | grep -o '"success"[[:space:]]*:[[:space:]]*[^,}]*' 2>/dev/null | sed 's/"success"[[:space:]]*:[[:space:]]*//' || echo "true")

# Extract result/output
TOOL_OUTPUT=$(echo "${input_json}" | grep -o '"result"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/"result"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "")

# Extract session ID
SESSION_ID=$(echo "${input_json}" | grep -o '"sessionId"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/"sessionId"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "unknown")

# Normalize success value
case "${TOOL_SUCCESS}" in
    true|1|"true")
        TOOL_SUCCESS="true"
        ;;
    *)
        TOOL_SUCCESS="false"
        ;;
esac

# ============================================================================
# MEMORY: Log tool result to hot memory
# ============================================================================
TOOL_LOG="${HOT_MEMORY}/tool-usage.jsonl"
echo "{\"timestamp\":\"${TIMESTAMP}\",\"session_id\":\"${SESSION_ID}\",\"tool\":\"${TOOL_NAME}\",\"success\":${TOOL_SUCCESS}}" >> "${TOOL_LOG}"

# Rotate log if too large
if [ -f "${TOOL_LOG}" ]; then
    line_count=$(wc -l < "${TOOL_LOG}" 2>/dev/null | tr -d ' ' || echo 0)
    if [ "${line_count}" -gt 10000 ]; then
        tail -n 5000 "${TOOL_LOG}" > "${TOOL_LOG}.tmp"
        mv "${TOOL_LOG}.tmp" "${TOOL_LOG}"
    fi
fi

# ============================================================================
# MONITORING: Update metrics
# ============================================================================
EVENTS_LOG="${METRICS_DIR}/events.jsonl"
echo "{\"timestamp\":\"${TIMESTAMP}\",\"event\":\"tool_use\",\"tool\":\"${TOOL_NAME}\",\"success\":${TOOL_SUCCESS}}" >> "${EVENTS_LOG}"

# ============================================================================
# INTELLIGENCE: Capture failures for learning
# ============================================================================
if [ "${TOOL_SUCCESS}" = "false" ]; then
    FAILURES_LOG="${HOT_MEMORY}/failures.jsonl"
    
    # Escape output for JSON
    OUTPUT_ESCAPED=$(echo "${TOOL_OUTPUT}" | head -c 500 | sed 's/\\/\\\\/g;s/"/\\"/g' | tr '\n' ' ')
    
    echo "{\"timestamp\":\"${TIMESTAMP}\",\"session_id\":\"${SESSION_ID}\",\"tool\":\"${TOOL_NAME}\",\"output\":\"${OUTPUT_ESCAPED}\"}" >> "${FAILURES_LOG}"
    
    # Rotate failures log
    if [ -f "${FAILURES_LOG}" ]; then
        line_count=$(wc -l < "${FAILURES_LOG}" 2>/dev/null | tr -d ' ' || echo 0)
        if [ "${line_count}" -gt 500 ]; then
            tail -n 250 "${FAILURES_LOG}" > "${FAILURES_LOG}.tmp"
            mv "${FAILURES_LOG}.tmp" "${FAILURES_LOG}"
        fi
    fi
fi

# ============================================================================
# INTELLIGENCE: Track tool usage patterns
# ============================================================================
PATTERNS_LOG="${HOT_MEMORY}/tool-patterns.jsonl"

# Get recent tools for pattern detection
if [ -f "${TOOL_LOG}" ]; then
    RECENT_TOOLS=$(grep "\"session_id\":\"${SESSION_ID}\"" "${TOOL_LOG}" 2>/dev/null | tail -5 | grep -o '"tool":"[^"]*"' | sed 's/"tool":"//;s/"$//' | tr '\n' ',' | sed 's/,$//' || echo "")
    
    if [ -n "${RECENT_TOOLS}" ]; then
        echo "{\"timestamp\":\"${TIMESTAMP}\",\"session_id\":\"${SESSION_ID}\",\"pattern\":\"${RECENT_TOOLS}\"}" >> "${PATTERNS_LOG}"
    fi
fi

# Rotate patterns log
if [ -f "${PATTERNS_LOG}" ]; then
    line_count=$(wc -l < "${PATTERNS_LOG}" 2>/dev/null | tr -d ' ' || echo 0)
    if [ "${line_count}" -gt 1000 ]; then
        tail -n 500 "${PATTERNS_LOG}" > "${PATTERNS_LOG}.tmp"
        mv "${PATTERNS_LOG}.tmp" "${PATTERNS_LOG}"
    fi
fi

# No output (silent hook)
exit 0
