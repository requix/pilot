#!/usr/bin/env bash
# agent-spawn.sh - Initialize PILOT session with self-learning context
# Part of PILOT - Fail-safe design (always exits 0)

# PILOT directories - everything in ~/.pilot/
PILOT_HOME="${HOME}/.pilot"
LEARNINGS_DIR="${PILOT_HOME}/learnings"
IDENTITY_DIR="${PILOT_HOME}/identity"
LOGS_DIR="${PILOT_HOME}/logs"
CACHE_DIR="${PILOT_HOME}/.cache"
METRICS_DIR="${PILOT_HOME}/metrics"
OBSERVATIONS_DIR="${PILOT_HOME}/observations"
SYSTEM_DIR="${PILOT_HOME}/system"

# Source dashboard emitter (use consolidated emitter library)
[[ -f "${SYSTEM_DIR}/lib/dashboard-emitter.sh" ]] && source "${SYSTEM_DIR}/lib/dashboard-emitter.sh" 2>/dev/null || true

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

# Ensure directories exist (fail-safe auto-creation)
mkdir -p "$CACHE_DIR" "$METRICS_DIR" "$LEARNINGS_DIR" "$IDENTITY_DIR" "$LOGS_DIR" "${PILOT_HOME}/memory/hot" 2>/dev/null || true

# Auto-create observation directories if missing (fail-safe)
mkdir -p "$OBSERVATIONS_DIR" "${IDENTITY_DIR}/.history" 2>/dev/null || true

# Source observation-init if available for full initialization
if [[ -f "${SYSTEM_DIR}/lib/observation-init.sh" ]]; then
    source "${SYSTEM_DIR}/lib/observation-init.sh" 2>/dev/null || true
    ensure_observation_dirs 2>/dev/null || true
fi

# Source performance manager for tier management
if [[ -f "${SYSTEM_DIR}/lib/performance-manager.sh" ]]; then
    source "${SYSTEM_DIR}/lib/performance-manager.sh" 2>/dev/null || true
    perf_init 2>/dev/null || true
fi

# Source capture controller for session reset
if [[ -f "${SYSTEM_DIR}/lib/capture-controller.sh" ]]; then
    source "${SYSTEM_DIR}/lib/capture-controller.sh" 2>/dev/null || true
    capture_reset_session 2>/dev/null || true
fi

# Record session start for project detection
if [[ -f "${SYSTEM_DIR}/detectors/project-detector.sh" ]]; then
    source "${SYSTEM_DIR}/detectors/project-detector.sh" 2>/dev/null || true
    WORKING_DIR=$(pwd 2>/dev/null || echo "$HOME")
    PROJECT_ID=$(project_generate_id "$WORKING_DIR" 2>/dev/null || echo "")
    if [[ -n "$PROJECT_ID" ]]; then
        project_record_session "$PROJECT_ID" 0 "$WORKING_DIR" 2>/dev/null || true
    fi
fi

# Persist session ID for other hooks
echo "$SESSION_ID" > "$CACHE_DIR/current-session-id" 2>/dev/null || true

# Create session metrics file
cat > "$METRICS_DIR/session-${SESSION_ID}.json" 2>/dev/null << EOF || true
{"session_id":"${SESSION_ID}","started_at":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","status":"active"}
EOF

# ============================================
# SELF-LEARNING: Load context from past learnings
# ============================================

# Load identity context if exists
IDENTITY_CONTEXT=""
if [ -f "$IDENTITY_DIR/context.md" ]; then
    IDENTITY_CONTEXT=$(cat "$IDENTITY_DIR/context.md" 2>/dev/null | head -50)
fi

# Emit initial OBSERVE phase to dashboard
type dashboard_emit_phase &>/dev/null && dashboard_emit_phase "OBSERVE"

# Get recent learnings (last 7 days, max 5)
RECENT_LEARNINGS=""
if [ -d "$LEARNINGS_DIR" ]; then
    LEARNING_FILES=$(find "$LEARNINGS_DIR" -name "*_learning.md" -mtime -7 -type f 2>/dev/null | sort -r | head -5)
    if [ -n "$LEARNING_FILES" ]; then
        RECENT_LEARNINGS="Recent learnings available:"
        for f in $LEARNING_FILES; do
            # Extract just the summary line
            SUMMARY=$(grep -A1 "^## Summary" "$f" 2>/dev/null | tail -1 | head -c 100)
            [ -n "$SUMMARY" ] && RECENT_LEARNINGS="$RECENT_LEARNINGS
- $SUMMARY..."
        done
    fi
fi

# Count total learnings
TOTAL_LEARNINGS=$(find "$LEARNINGS_DIR" -name "*_learning.md" -type f 2>/dev/null | wc -l | tr -d ' ')

# Get current observation tier
CURRENT_TIER="standard"
if [[ -f "${SYSTEM_DIR}/lib/performance-manager.sh" ]]; then
    source "${SYSTEM_DIR}/lib/performance-manager.sh" 2>/dev/null || true
    CURRENT_TIER=$(perf_get_tier 2>/dev/null || echo "standard")
fi

# List active steering files
ACTIVE_STEERING=""
STEERING_DIR="${PILOT_HOME}/steering"
if [ -d "$STEERING_DIR" ]; then
    ACTIVE_STEERING=$(find "$STEERING_DIR" -name "*.md" -type f 2>/dev/null | xargs -I{} basename {} 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
fi

# Output context
cat << EOF
<pilot-context>
PILOT Session: ${SESSION_ID}
Time: $(date '+%Y-%m-%d %H:%M:%S %Z')
Learnings in knowledge base: ${TOTAL_LEARNINGS:-0}

## ⚡ Path Reference (CRITICAL)
| Purpose | Path |
|---------|------|
| Save learnings to | ${LEARNINGS_DIR} |
| Identity files | ${IDENTITY_DIR} |
| System memory (internal) | ${PILOT_HOME}/memory |

**IMPORTANT:** Always save learnings to ${LEARNINGS_DIR}/ - NOT to ${PILOT_HOME}/

## Active Steering
Files: ${ACTIVE_STEERING:-none loaded}

## Universal Algorithm
OBSERVE → THINK → PLAN → BUILD → EXECUTE → VERIFY → LEARN

For complex tasks, follow these phases:
1. OBSERVE - Understand current state before acting
2. THINK - Generate multiple approaches
3. PLAN - Select strategy, define success criteria
4. BUILD - Refine criteria to be testable
5. EXECUTE - Do the work
6. VERIFY - Test against criteria
7. LEARN - Extract insights for future reference
EOF

# Add identity if available
if [ -n "$IDENTITY_CONTEXT" ]; then
    cat << EOF

## Identity Context
$IDENTITY_CONTEXT
EOF
fi

# Add recent learnings if available
if [ -n "$RECENT_LEARNINGS" ]; then
    cat << EOF

## $RECENT_LEARNINGS
EOF
fi

cat << EOF

## Guidelines
- First-person voice
- Show algorithm phase when working on complex tasks
- Learnings are automatically captured when you solve problems
</pilot-context>
EOF

exit 0
