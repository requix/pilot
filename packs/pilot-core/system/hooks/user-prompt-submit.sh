#!/usr/bin/env bash
# user-prompt-submit.sh - Process user prompts with intelligence and memory
# Part of PILOT (Platform for Intelligent Lifecycle Operations and Tools)
#
# FOUNDATION FEATURES:
# - Memory: Log interaction to hot memory
# - Intelligence: Detect algorithm phase from prompt
# - Monitoring: Update session metrics
#
# INPUT: JSON from Kiro (first argument) with "message" field
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

# Extract message from JSON
USER_PROMPT=$(echo "${input_json}" | grep -o '"message"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/"message"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "")

# Extract session ID
SESSION_ID=$(echo "${input_json}" | grep -o '"sessionId"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/"sessionId"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "")
if [ -z "${SESSION_ID}" ]; then
    SESSION_ID="pilot-$(date +%s)"
fi

# If no message, exit silently
if [ -z "${USER_PROMPT}" ]; then
    exit 0
fi

# ============================================================================
# INTELLIGENCE: Detect algorithm phase from prompt
# ============================================================================
detect_algorithm_phase() {
    local prompt="$1"
    local prompt_lower=$(echo "${prompt}" | tr '[:upper:]' '[:lower:]')
    
    if echo "${prompt_lower}" | grep -qE "(what is|show me|explain|describe|current state|understand)"; then
        echo "OBSERVE"
    elif echo "${prompt_lower}" | grep -qE "(how could|options|approaches|alternatives|ideas|think about)"; then
        echo "THINK"
    elif echo "${prompt_lower}" | grep -qE "(plan|strategy|steps|approach|how to|roadmap)"; then
        echo "PLAN"
    elif echo "${prompt_lower}" | grep -qE "(criteria|success|define|requirements|spec|build)"; then
        echo "BUILD"
    elif echo "${prompt_lower}" | grep -qE "(do it|implement|create|make|execute|run|fix|change|update|add|remove)"; then
        echo "EXECUTE"
    elif echo "${prompt_lower}" | grep -qE "(test|verify|check|validate|confirm|works)"; then
        echo "VERIFY"
    elif echo "${prompt_lower}" | grep -qE "(learned|takeaway|insight|summary|what worked)"; then
        echo "LEARN"
    else
        echo "UNKNOWN"
    fi
}

DETECTED_PHASE=$(detect_algorithm_phase "${USER_PROMPT}")

# ============================================================================
# MEMORY: Log to hot memory
# ============================================================================
SESSION_LOG="${HOT_MEMORY}/current-session.jsonl"

# Escape prompt for JSON (truncate to 200 chars, escape quotes and newlines)
PROMPT_ESCAPED=$(echo "${USER_PROMPT}" | head -c 200 | sed 's/\\/\\\\/g;s/"/\\"/g' | tr '\n' ' ')

# Log interaction
echo "{\"timestamp\":\"${TIMESTAMP}\",\"type\":\"prompt\",\"session_id\":\"${SESSION_ID}\",\"phase\":\"${DETECTED_PHASE}\",\"prompt\":\"${PROMPT_ESCAPED}\"}" >> "${SESSION_LOG}"

# ============================================================================
# INTELLIGENCE: Track algorithm phase transitions
# ============================================================================
PHASE_LOG="${HOT_MEMORY}/algorithm-phases.jsonl"
echo "{\"timestamp\":\"${TIMESTAMP}\",\"session_id\":\"${SESSION_ID}\",\"phase\":\"${DETECTED_PHASE}\"}" >> "${PHASE_LOG}"

# Rotate logs if too large
for log_file in "${SESSION_LOG}" "${PHASE_LOG}"; do
    if [ -f "${log_file}" ]; then
        line_count=$(wc -l < "${log_file}" 2>/dev/null | tr -d ' ' || echo 0)
        if [ "${line_count}" -gt 1000 ]; then
            tail -n 500 "${log_file}" > "${log_file}.tmp"
            mv "${log_file}.tmp" "${log_file}"
        fi
    fi
done

# No output (silent hook)
exit 0
