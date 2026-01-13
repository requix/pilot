#!/usr/bin/env bash
# agent-spawn.sh - Initialize PILOT session with context, memory, and monitoring
# Part of PILOT (Platform for Intelligent Lifecycle Operations and Tools)
#
# FOUNDATION FEATURES:
# - Memory: Load relevant warm memory context
# - Intelligence: Initialize algorithm tracking
# - Security: Load security context
# - Monitoring: Start session metrics
#
# INPUT: JSON from Kiro (first argument)
# OUTPUT: Context text to stdout (injected into agent context)

set -euo pipefail

PILOT_HOME="${HOME}/.kiro/pilot"
IDENTITY_DIR="${PILOT_HOME}/identity"
RESOURCES_DIR="${PILOT_HOME}/resources"
MEMORY_DIR="${PILOT_HOME}/memory"
CACHE_DIR="${PILOT_HOME}/.cache"
METRICS_DIR="${PILOT_HOME}/metrics"

# Parse input JSON (Kiro provides this as first argument)
input_json="${1:-{}}"

# Extract session ID from input or generate one
SESSION_ID=$(echo "${input_json}" | grep -o '"sessionId"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/"sessionId"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "")
if [ -z "${SESSION_ID}" ]; then
    SESSION_ID="pilot-$(date +%s)-$$"
fi

# Ensure directories exist
mkdir -p "${CACHE_DIR}" "${METRICS_DIR}" "${MEMORY_DIR}/hot" "${MEMORY_DIR}/warm" "${MEMORY_DIR}/cold"

# ============================================================================
# MONITORING: Start session metrics
# ============================================================================
SESSION_START=$(date +%s)
METRICS_FILE="${METRICS_DIR}/session-${SESSION_ID}.json"

cat > "${METRICS_FILE}" << EOF
{
  "session_id": "${SESSION_ID}",
  "started_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "status": "active",
  "tool_calls": 0,
  "security_blocks": 0,
  "errors": 0
}
EOF

# ============================================================================
# MEMORY: Load relevant warm memory
# ============================================================================
load_warm_memory() {
    local memory_context=""
    
    if [ -d "${MEMORY_DIR}/warm" ]; then
        local learnings=$(find "${MEMORY_DIR}/warm" -name "*.md" -type f 2>/dev/null | sort -r | head -5)
        if [ -n "${learnings}" ]; then
            memory_context="Recent learnings available in warm memory"
        fi
    fi
    
    echo "${memory_context}"
}

# ============================================================================
# CACHE: Check for cached context
# ============================================================================
generate_cache_key() {
    if [ -d "${IDENTITY_DIR}" ]; then
        find "${IDENTITY_DIR}" -type f -name "*.md" -exec stat -f "%m" {} \; 2>/dev/null | sort | md5 2>/dev/null || echo "none"
    else
        echo "none"
    fi
}

CACHE_KEY=$(generate_cache_key)
CACHE_FILE="${CACHE_DIR}/agent-spawn-${CACHE_KEY}.txt"

# Check if cached output exists and is recent (< 5 minutes)
if [ -f "${CACHE_FILE}" ]; then
    cache_age=$(($(date +%s) - $(stat -f "%m" "${CACHE_FILE}" 2>/dev/null || echo 0)))
    if [ ${cache_age} -lt 300 ]; then
        cat "${CACHE_FILE}"
        exit 0
    fi
fi

# ============================================================================
# Generate fresh context output
# ============================================================================
{
    echo "<pilot-context>"
    echo "PILOT Session: ${SESSION_ID}"
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo ""
    echo "## Foundation Systems"
    echo "- Memory: Three-tier (Hot/Warm/Cold) active"
    echo "- Intelligence: Algorithm phase tracking enabled"
    echo "- Security: Pre-tool validation active"
    echo "- Monitoring: Session metrics recording"
    echo ""
    echo "## Universal Algorithm"
    echo "OBSERVE → THINK → PLAN → BUILD → EXECUTE → VERIFY → LEARN"
    echo "Key: Define success criteria in BUILD before EXECUTE"
    echo ""
    echo "## Identity Files"
    if [ -d "${IDENTITY_DIR}" ]; then
        for file in "${IDENTITY_DIR}"/*.md; do
            [ -f "${file}" ] && echo "- $(basename "${file}" .md)"
        done 2>/dev/null || true
    fi
    echo ""
    echo "## Guidelines"
    echo "- First-person voice"
    echo "- Show algorithm phase when working"
    echo "- Extract learnings for future sessions"
    echo "</pilot-context>"
} | tee "${CACHE_FILE}"

# Clean old cache files
find "${CACHE_DIR}" -name "agent-spawn-*.txt" -type f 2>/dev/null | sort -r | tail -n +11 | xargs rm -f 2>/dev/null || true

exit 0
