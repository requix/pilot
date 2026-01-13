#!/usr/bin/env bash
# pre-tool-use.sh - Security validation and monitoring before tool execution
# Part of PILOT (Platform for Intelligent Lifecycle Operations and Tools)
#
# FOUNDATION FEATURES:
# - Security: Validate commands against dangerous patterns
# - Security: Block system directory modifications
# - Monitoring: Log tool usage attempts
#
# INPUT: JSON from Kiro (first argument) with "tool" and "args" fields
# OUTPUT: Error message to stdout if blocked (exit 1), nothing if allowed (exit 0)

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
TOOL_INPUT=$(echo "${input_json}" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "")

# Also try "args" field if "command" not found
if [ -z "${TOOL_INPUT}" ]; then
    TOOL_INPUT=$(echo "${input_json}" | grep -o '"args"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/"args"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "")
fi

# Extract session ID
SESSION_ID=$(echo "${input_json}" | grep -o '"sessionId"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/"sessionId"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "unknown")

# ============================================================================
# MONITORING: Log tool attempt
# ============================================================================
TOOL_LOG="${HOT_MEMORY}/tool-attempts.jsonl"
TOOL_ESCAPED=$(echo "${TOOL_INPUT}" | head -c 200 | sed 's/\\/\\\\/g;s/"/\\"/g' | tr '\n' ' ')
echo "{\"timestamp\":\"${TIMESTAMP}\",\"session_id\":\"${SESSION_ID}\",\"tool\":\"${TOOL_NAME}\",\"input\":\"${TOOL_ESCAPED}\"}" >> "${TOOL_LOG}"

# Only validate shell/bash commands
case "${TOOL_NAME}" in
    shell|Bash|bash|executeBash)
        ;;
    *)
        exit 0
        ;;
esac

SECURITY_LOG="${HOT_MEMORY}/security.log"

# ============================================================================
# SECURITY: Tier 1 - Catastrophic patterns (immediate block)
# ============================================================================
CATASTROPHIC_PATTERNS=(
    'rm -rf /'
    'rm -rf /\*'
    'rm -rf ~'
    'rm -rf ~/'
    'rm -rf \$HOME'
    '> /dev/sda'
    '> /dev/nvme'
    'dd if=/dev/zero of=/dev'
    'dd if=/dev/random of=/dev'
    'mkfs\.'
    ':\(\)\{ :\|:& \};:'
    'chmod -R 777 /'
    'chown -R .* /'
)

for pattern in "${CATASTROPHIC_PATTERNS[@]}"; do
    if echo "${TOOL_INPUT}" | grep -qE "${pattern}" 2>/dev/null; then
        echo "[${TIMESTAMP}] BLOCKED (CATASTROPHIC): ${pattern}" >> "${SECURITY_LOG}"
        echo "{\"timestamp\":\"${TIMESTAMP}\",\"event\":\"security_block\",\"tier\":\"catastrophic\",\"pattern\":\"${pattern}\"}" >> "${METRICS_DIR}/events.jsonl"
        
        echo "🚨 PILOT Security: BLOCKED - Catastrophic command detected"
        echo "   This command could destroy your system."
        exit 1
    fi
done

# ============================================================================
# SECURITY: Tier 2 - Remote code execution patterns
# ============================================================================
RCE_PATTERNS=(
    'curl.*|.*sh'
    'curl.*|.*bash'
    'wget.*|.*sh'
    'wget.*|.*bash'
    'curl.*|.*python'
    'wget.*|.*python'
)

for pattern in "${RCE_PATTERNS[@]}"; do
    if echo "${TOOL_INPUT}" | grep -qE "${pattern}" 2>/dev/null; then
        echo "[${TIMESTAMP}] BLOCKED (RCE): ${pattern}" >> "${SECURITY_LOG}"
        
        echo "🚨 PILOT Security: BLOCKED - Remote code execution pattern"
        echo "   Downloading and executing remote code is dangerous."
        exit 1
    fi
done

# ============================================================================
# SECURITY: Tier 3 - System directory protection
# ============================================================================
PROTECTED_DIRS=(
    "/etc"
    "/bin"
    "/sbin"
    "/usr/bin"
    "/usr/sbin"
    "/System"
    "/Library/System"
)

for dir in "${PROTECTED_DIRS[@]}"; do
    if echo "${TOOL_INPUT}" | grep -qE "(>|>>|tee|mv|cp|rm|chmod|chown).*${dir}" 2>/dev/null; then
        echo "[${TIMESTAMP}] BLOCKED (SYSTEM_DIR): ${dir}" >> "${SECURITY_LOG}"
        
        echo "⛔ PILOT Security: BLOCKED - System directory modification"
        echo "   Directory: ${dir}"
        exit 1
    fi
done

# ============================================================================
# SECURITY: Log approved command
# ============================================================================
echo "[${TIMESTAMP}] ALLOWED: ${TOOL_INPUT:0:200}" >> "${SECURITY_LOG}"

# Rotate security log if too large
if [ -f "${SECURITY_LOG}" ]; then
    line_count=$(wc -l < "${SECURITY_LOG}" 2>/dev/null | tr -d ' ' || echo 0)
    if [ "${line_count}" -gt 2000 ]; then
        tail -n 1000 "${SECURITY_LOG}" > "${SECURITY_LOG}.tmp"
        mv "${SECURITY_LOG}.tmp" "${SECURITY_LOG}"
    fi
fi

exit 0
