#!/usr/bin/env bash
# agent-spawn.sh - Initialize PILOT session
# Part of PILOT - Fail-safe design (always exits 0)

PILOT_HOME="${HOME}/.kiro/pilot"
CACHE_DIR="${PILOT_HOME}/.cache"
METRICS_DIR="${PILOT_HOME}/metrics"
IDENTITY_DIR="${PILOT_HOME}/identity"

# Get input JSON from STDIN (Kiro sends hook events via STDIN, not arguments)
input_json=$(cat 2>/dev/null || echo "{}")

# Simple session ID extraction using jq (with fallback)
get_session_id() {
    local json="$1"
    local sid=""
    if command -v jq >/dev/null 2>&1; then
        sid=$(echo "$json" | jq -r '.sessionId // .session_id // empty' 2>/dev/null) || true
    fi
    # Generate if empty
    if [ -z "$sid" ]; then
        sid="pilot-$(date +%s)-$$"
    fi
    echo "$sid"
}

SESSION_ID=$(get_session_id "$input_json")

# Ensure directories exist
mkdir -p "$CACHE_DIR" "$METRICS_DIR" "${PILOT_HOME}/memory/hot" 2>/dev/null || true

# Persist session ID for other hooks
echo "$SESSION_ID" > "$CACHE_DIR/current-session-id" 2>/dev/null || true

# Create session metrics file
cat > "$METRICS_DIR/session-${SESSION_ID}.json" 2>/dev/null << EOF || true
{"session_id":"${SESSION_ID}","started_at":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","status":"active"}
EOF

# Output context
cat << EOF
<pilot-context>
PILOT Session: ${SESSION_ID}
Time: $(date '+%Y-%m-%d %H:%M:%S %Z')

## Universal Algorithm
OBSERVE → THINK → PLAN → BUILD → EXECUTE → VERIFY → LEARN

## Guidelines
- First-person voice
- Show algorithm phase when working
</pilot-context>
EOF

exit 0
