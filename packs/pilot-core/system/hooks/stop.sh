#!/usr/bin/env bash
# stop.sh - Self-learning: Detect and capture learnings from responses
# Part of PILOT - Fail-safe design (always exits 0)

# PILOT directories
PILOT_DIR="${PILOT_DIR:-$HOME/.pilot}"
PILOT_HOME="${HOME}/.kiro/pilot"
LEARNINGS_DIR="${PILOT_DIR}/learnings"
SESSIONS_DIR="${PILOT_DIR}/sessions"
LOGS_DIR="${PILOT_DIR}/logs"
HOT_MEMORY="${PILOT_HOME}/memory/hot"
COLD_MEMORY="${PILOT_HOME}/memory/cold"
METRICS_DIR="${PILOT_HOME}/metrics"
CACHE_DIR="${PILOT_HOME}/.cache"

# Ensure directories exist
mkdir -p "$LEARNINGS_DIR" "$SESSIONS_DIR" "$LOGS_DIR" "$HOT_MEMORY" "$COLD_MEMORY" "$METRICS_DIR" 2>/dev/null || true

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

# Extract learning summary (first 500 chars of relevant content)
extract_learning_summary() {
    local text="$1"
    # Get first 500 characters, clean up
    echo "$text" | head -c 500 | tr '\n' ' ' | sed 's/  */ /g'
}

SESSION_ID=$(get_session_id "$input_json")
RESPONSE=$(get_response "$input_json")

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
        
        # Output confirmation (visible to user)
        echo ""
        echo "<pilot-learning-captured>"
        echo "📚 Learning automatically captured to knowledge base"
        echo "File: $LEARNING_FILE"
        echo "</pilot-learning-captured>"
    fi
fi

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

echo "✅ Session archived: $ARCHIVE_DIR/summary-$SESSION_TIME.md"
[ "$TODAYS_LEARNINGS" -gt 0 ] && echo "📚 Learnings captured today: $TODAYS_LEARNINGS"
exit 0
