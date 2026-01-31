#!/usr/bin/env bash
# stop.sh - Self-learning: Detect and capture learnings from responses
# Part of PILOT - Fail-safe design (always exits 0)

# PILOT directories
PILOT_DIR="${PILOT_DIR:-$HOME/.pilot}"
PILOT_HOME="${HOME}/.pilot"
LEARNINGS_DIR="${PILOT_DIR}/learnings"
SESSIONS_DIR="${PILOT_DIR}/sessions"
LOGS_DIR="${PILOT_DIR}/logs"
HOT_MEMORY="${PILOT_HOME}/memory/hot"
COLD_MEMORY="${PILOT_HOME}/memory/cold"
METRICS_DIR="${PILOT_HOME}/metrics"
CACHE_DIR="${PILOT_HOME}/.cache"
OBSERVATIONS_DIR="${PILOT_DIR}/observations"

# Ensure directories exist
mkdir -p "$LEARNINGS_DIR" "$SESSIONS_DIR" "$LOGS_DIR" "$HOT_MEMORY" "$COLD_MEMORY" "$METRICS_DIR" "$OBSERVATIONS_DIR" 2>/dev/null || true

# Source helper libraries (fail-safe)
[[ -f "${PILOT_HOME}/system/helpers/json.sh" ]] && source "${PILOT_HOME}/system/helpers/json.sh" 2>/dev/null || true
[[ -f "${PILOT_HOME}/system/helpers/analysis.sh" ]] && source "${PILOT_HOME}/system/helpers/analysis.sh" 2>/dev/null || true
[[ -f "${PILOT_HOME}/system/helpers/capture.sh" ]] && source "${PILOT_HOME}/system/helpers/capture.sh" 2>/dev/null || true
# Use only dashboard.sh (consolidated emitter library)
[[ -f "${PILOT_HOME}/system/helpers/dashboard.sh" ]] && source "${PILOT_HOME}/system/helpers/dashboard.sh" 2>/dev/null || true
# Source consolidated detectors
[[ -f "${PILOT_HOME}/system/helpers/detectors.sh" ]] && source "${PILOT_HOME}/system/helpers/detectors.sh" 2>/dev/null || true

# Get input JSON from STDIN (Kiro sends hook events via STDIN, not arguments)
input_json=$(cat 2>/dev/null || echo "{}")

# Timestamps
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_DATE=$(date +"%Y-%m-%d")
SESSION_TIME=$(date +"%H-%M-%S")
FILE_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Get session ID (from input or persisted file)
get_session_id() {
    local json="$1"
    local sid=""
    if command -v jq >/dev/null 2>&1; then
        sid=$(echo "$json" | jq -r '.sessionId // .session_id // empty' 2>/dev/null) || true
    fi
    if [ -z "$sid" ] && [ -f "$CACHE_DIR/current-session-id" ]; then
        sid=$(cat "$CACHE_DIR/current-session-id" 2>/dev/null) || true
    fi
    echo "${sid:-unknown}"
}

# Get response content from JSON
get_response() {
    local json="$1"
    local response=""
    if command -v jq >/dev/null 2>&1; then
        response=$(echo "$json" | jq -r '.response // .content // .message // .text // empty' 2>/dev/null) || true
    fi
    # Fallback: try to extract from raw JSON if jq failed
    if [ -z "$response" ]; then
        response=$(echo "$json" | grep -oP '"(?:response|content|message)":\s*"[^"]*"' | head -1 | sed 's/.*":\s*"//;s/"$//' 2>/dev/null) || true
    fi
    echo "$response"
}

# Detect learning patterns in text
detect_learning() {
    local text="$1"
    local lower=$(echo "$text" | tr '[:upper:]' '[:lower:]')
    
    # Learning indicators - problem-solving narratives
    local patterns="fixed|solved|discovered|learned|realized|figured out|root cause|the issue was|the problem was|turned out|mistake was|bug was|solution is|answer is|key insight|now i understand|the fix was|resolved by|working now"
    
    # Count matches
    local matches=$(echo "$lower" | grep -oE "$patterns" | wc -l)
    
    # Need at least 2 indicators for a learning
    [ "$matches" -ge 2 ] && echo "true" || echo "false"
}

# Extract learning summary (first meaningful sentence)
extract_learning_summary() {
    local text="$1"

    # Try to extract meaningful learning from common patterns
    local learning=""

    # Look for "the issue was" / "the problem was" patterns (root cause)
    learning=$(echo "$text" | grep -ioE "(the issue was|the problem was|root cause was)[^.]*" | head -1 | head -c 100)

    # Look for "fixed by" / "solved by" patterns
    if [ -z "$learning" ]; then
        learning=$(echo "$text" | grep -ioE "(fixed by|solved by|resolved by)[^.]*" | head -1 | head -c 100)
    fi

    # Look for "✅" completion patterns (common in our responses)
    if [ -z "$learning" ]; then
        learning=$(echo "$text" | grep "✅" | head -1 | sed 's/.*✅[[:space:]]*//' | head -c 100)
    fi

    # Look for "Fixed:" or "Implemented:" patterns
    if [ -z "$learning" ]; then
        learning=$(echo "$text" | grep -iE "^(fixed|implemented|added|created|resolved):" | head -1 | head -c 100)
    fi

    # Look for "discovered that..." patterns
    if [ -z "$learning" ]; then
        learning=$(echo "$text" | grep -ioE "discovered (that )?[^.]{10,}" | head -1 | head -c 100)
    fi

    # Look for "found that..." patterns
    if [ -z "$learning" ]; then
        learning=$(echo "$text" | grep -ioE "found that [^.]{10,}" | head -1 | head -c 100)
    fi

    # Look for "learned:" patterns
    if [ -z "$learning" ]; then
        learning=$(echo "$text" | grep -i "learning:" | head -1 | sed 's/.*learning://i' | sed 's/^[[:space:]]*//' | head -c 100)
    fi

    # Fallback: extract first sentence that looks meaningful (>20 chars, not generic)
    if [ -z "$learning" ]; then
        learning=$(echo "$text" | tr '\n' ' ' | grep -oE '[A-Z][^.!?]{20,}[.!?]' | head -1 | head -c 100)
    fi

    # Final fallback: first 80 chars if nothing else worked
    if [ -z "$learning" ]; then
        learning=$(echo "$text" | tr '\n' ' ' | head -c 80)
    fi

    # Clean up: remove markdown, extra spaces, leading/trailing whitespace
    echo "$learning" | sed 's/[*#`]//g' | tr -s ' ' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//'
}

SESSION_ID=$(get_session_id "$input_json")
RESPONSE=$(get_response "$input_json")

# Detect phase from response content
detect_phase_from_response() {
    local response="$1"
    local lower_response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    
    # VERIFY phase indicators in responses
    if echo "$lower_response" | grep -qE "(✅|❌|passed|failed|test.*result|verification|validated|confirmed|checked|works|doesn't work|success|error|issue resolved|problem fixed)"; then
        echo "VERIFY"
        return
    fi
    
    # BUILD phase indicators in responses  
    if echo "$lower_response" | grep -qE "(success criteria|requirements|define.*success|what.*looks like|criteria.*met|specification|test plan)"; then
        echo "BUILD"
        return
    fi
    
    # LEARN phase indicators
    if echo "$lower_response" | grep -qE "(learned|insight|lesson|takeaway|conclusion|discovered|found that|realized|key finding)"; then
        echo "LEARN"
        return
    fi
}

# Emit phase based on response content
if [ -n "$RESPONSE" ] && command -v dashboard_emit_phase >/dev/null 2>&1; then
    DETECTED_PHASE=$(detect_phase_from_response "$RESPONSE")
    if [ -n "$DETECTED_PHASE" ]; then
        dashboard_emit_phase "$DETECTED_PHASE" 2>/dev/null || true
    fi
fi

# Archive directory
ARCHIVE_DIR="$COLD_MEMORY/sessions/$SESSION_DATE"
mkdir -p "$ARCHIVE_DIR" 2>/dev/null || true

# ============================================
# SELF-LEARNING: Detect and capture learnings
# ============================================

if [ -n "$RESPONSE" ]; then
    IS_LEARNING=$(detect_learning "$RESPONSE")
    
    if [ "$IS_LEARNING" = "true" ]; then
        LEARNING_FILE="$LEARNINGS_DIR/${FILE_TIMESTAMP}_learning.md"
        LEARNING_SUMMARY=$(extract_learning_summary "$RESPONSE")
        
        # Create learning file with YAML frontmatter
        cat > "$LEARNING_FILE" 2>/dev/null << EOF || true
---
date: $TIMESTAMP
type: learning
session_id: $SESSION_ID
source: auto-captured
---

# Learning: $FILE_TIMESTAMP

## Summary
$LEARNING_SUMMARY

## Full Context
$RESPONSE
EOF
        
        # Log the capture
        echo "[$(date -Iseconds)] [stop] [INFO] Learning captured: $LEARNING_FILE" >> "$LOGS_DIR/pilot.log" 2>/dev/null || true
        
        # Emit to dashboard
        type dashboard_emit_learning &>/dev/null && dashboard_emit_learning "$LEARNING_SUMMARY"
        
        # Output confirmation (visible to user)
        echo ""
        echo "<pilot-learning-captured>"
        echo "📚 Learning automatically captured to knowledge base"
        echo "File: $LEARNING_FILE"
        echo "</pilot-learning-captured>"
    fi
    
    # Also run silent capture on response for identity extraction
    if type capture_from_response &>/dev/null; then
        capture_from_response "$RESPONSE" 2>/dev/null || true
    fi
fi

# Cleanup dashboard session on stop
type dashboard_cleanup &>/dev/null && dashboard_cleanup

# ============================================
# SESSION METRICS (existing functionality)
# ============================================

# Calculate metrics
calc_metrics() {
    local prompts=0 tools=0 success=0 failures=0
    
    [ -f "$HOT_MEMORY/current-session.jsonl" ] && prompts=$(wc -l < "$HOT_MEMORY/current-session.jsonl" 2>/dev/null | tr -d ' ') || true
    
    if [ -f "$HOT_MEMORY/tool-usage.jsonl" ]; then
        tools=$(grep -c "\"session_id\":\"$SESSION_ID\"" "$HOT_MEMORY/tool-usage.jsonl" 2>/dev/null) || true
        success=$(grep "\"session_id\":\"$SESSION_ID\"" "$HOT_MEMORY/tool-usage.jsonl" 2>/dev/null | grep -c '"success":true') || true
        failures=$(grep "\"session_id\":\"$SESSION_ID\"" "$HOT_MEMORY/tool-usage.jsonl" 2>/dev/null | grep -c '"success":false') || true
    fi
    
    echo "{\"prompts\":${prompts:-0},\"tools\":${tools:-0},\"success\":${success:-0},\"failures\":${failures:-0}}"
}

# Analyze algorithm phases
analyze_phases() {
    [ ! -f "$HOT_MEMORY/algorithm-phases.jsonl" ] && echo "No phase data" && return
    
    local o=$(grep -c '"phase":"OBSERVE"' "$HOT_MEMORY/algorithm-phases.jsonl" 2>/dev/null) || o=0
    local t=$(grep -c '"phase":"THINK"' "$HOT_MEMORY/algorithm-phases.jsonl" 2>/dev/null) || t=0
    local p=$(grep -c '"phase":"PLAN"' "$HOT_MEMORY/algorithm-phases.jsonl" 2>/dev/null) || p=0
    local b=$(grep -c '"phase":"BUILD"' "$HOT_MEMORY/algorithm-phases.jsonl" 2>/dev/null) || b=0
    local e=$(grep -c '"phase":"EXECUTE"' "$HOT_MEMORY/algorithm-phases.jsonl" 2>/dev/null) || e=0
    local v=$(grep -c '"phase":"VERIFY"' "$HOT_MEMORY/algorithm-phases.jsonl" 2>/dev/null) || v=0
    local l=$(grep -c '"phase":"LEARN"' "$HOT_MEMORY/algorithm-phases.jsonl" 2>/dev/null) || l=0
    
    echo "O:$o T:$t P:$p B:$b E:$e V:$v L:$l"
}

METRICS=$(calc_metrics)
PHASES=$(analyze_phases)

# Create session summary
cat > "$ARCHIVE_DIR/summary-$SESSION_TIME.md" 2>/dev/null << EOF || true
# Session: $SESSION_DATE $SESSION_TIME

**ID:** $SESSION_ID
**Archived:** $TIMESTAMP

## Metrics
\`\`\`
$METRICS
\`\`\`

## Algorithm Phases
$PHASES

---
*Generated by PILOT*
EOF

# Archive session files
[ -f "$HOT_MEMORY/current-session.jsonl" ] && cp "$HOT_MEMORY/current-session.jsonl" "$ARCHIVE_DIR/session-$SESSION_TIME.jsonl" 2>/dev/null || true
[ -f "$HOT_MEMORY/tool-usage.jsonl" ] && grep "\"session_id\":\"$SESSION_ID\"" "$HOT_MEMORY/tool-usage.jsonl" > "$ARCHIVE_DIR/tools-$SESSION_TIME.jsonl" 2>/dev/null || true
[ -f "$HOT_MEMORY/algorithm-phases.jsonl" ] && grep "\"session_id\":\"$SESSION_ID\"" "$HOT_MEMORY/algorithm-phases.jsonl" > "$ARCHIVE_DIR/phases-$SESSION_TIME.jsonl" 2>/dev/null || true

# Save final session metrics
cat > "$METRICS_DIR/session-$SESSION_ID.json" 2>/dev/null << EOF || true
{"session_id":"$SESSION_ID","ended_at":"$TIMESTAMP","status":"completed","metrics":$METRICS,"phases":"$PHASES"}
EOF

# Count today's learnings for summary
TODAYS_LEARNINGS=$(find "$LEARNINGS_DIR" -name "*_learning.md" -mtime 0 2>/dev/null | wc -l | tr -d ' ')

# ============================================
# ADAPTIVE IDENTITY CAPTURE: Deferred analysis
# ============================================

# Check for resolved challenges (functions available from detectors.sh)
RESOLVED=$(challenge_get_resolved 2>/dev/null) || true
if [[ -n "$RESOLVED" ]]; then
    # Suggest learning extraction for resolved challenges
    while IFS= read -r resolved_challenge; do
        [[ -z "$resolved_challenge" ]] && continue
        CHALLENGE_ID=$(echo "$resolved_challenge" | grep -o '"challengeId": "[^"]*"' | sed 's/.*": "//;s/"$//')
        if [[ -n "$CHALLENGE_ID" ]]; then
            crossfile_on_challenge_resolved "$CHALLENGE_ID" 2>/dev/null || true
        fi
    done <<< "$RESOLVED"
fi

# Check for strategy successes (functions available from detectors.sh)
SUGGESTIONS=$(strategy_get_suggestions 2>/dev/null) || true
while IFS= read -r suggestion; do
    [[ -z "$suggestion" ]] && continue
    STRATEGY_ID=$(echo "$suggestion" | grep -o '"strategyId": "[^"]*"' | sed 's/.*": "//;s/"$//')
    SUCCESS_COUNT=$(echo "$suggestion" | grep -o '"successCount": [0-9]*' | grep -o '[0-9]*')
    if [[ -n "$STRATEGY_ID" ]] && [[ "${SUCCESS_COUNT:-0}" -ge 5 ]]; then
        crossfile_on_strategy_success "$STRATEGY_ID" "$SUCCESS_COUNT" 2>/dev/null || true
    fi
done <<< "$SUGGESTIONS"

# Record session end time for project tracking (functions available from detectors.sh)
WORKING_DIR=$(pwd 2>/dev/null || echo "$HOME")
PROJECT_ID=$(project_generate_id "$WORKING_DIR" 2>/dev/null || echo "")
# Session duration would be calculated from session start, but we don't have that here
# The project detector already recorded the session start in agent-spawn

echo "✅ Session archived: $ARCHIVE_DIR/summary-$SESSION_TIME.md"
[ "$TODAYS_LEARNINGS" -gt 0 ] && echo "📚 Learnings captured today: $TODAYS_LEARNINGS"

# Emit LEARN phase to dashboard on session completion
type dashboard_emit_phase &>/dev/null && dashboard_emit_phase "LEARN"

exit 0
