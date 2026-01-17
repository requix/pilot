#!/usr/bin/env bash
# dashboard-emit.sh - Dashboard emission library for PILOT
# Integrates PILOT sessions with dashboard real-time updates

# Dashboard paths
DASHBOARD_DIR="$HOME/.kiro/pilot/dashboard"
SESSIONS_DIR="$DASHBOARD_DIR/sessions"
EVENTS_FILE="$DASHBOARD_DIR/events.jsonl"

# Ensure dashboard directories exist
mkdir -p "$SESSIONS_DIR"

# Get current session ID from environment or generate
get_session_id() {
    if [[ -n "$PILOT_SESSION_ID" ]]; then
        echo "$PILOT_SESSION_ID"
    elif [[ -n "$KIRO_SESSION_ID" ]]; then
        echo "$KIRO_SESSION_ID"
    else
        echo "pilot-$(date +%s)-$$"
    fi
}

# Emit phase transition to dashboard
emit_phase() {
    local phase="$1"
    local session_id=$(get_session_id)
    local timestamp=$(date +%s)
    
    # Update session file
    cat > "$SESSIONS_DIR/${session_id}.json" << EOF
{"id":"$session_id","phase":"$phase","updated":$timestamp}
EOF
    
    # Append event
    echo "{\"type\":\"phase\",\"sessionId\":\"$session_id\",\"phase\":\"$phase\",\"timestamp\":$timestamp}" >> "$EVENTS_FILE"
}

# Emit learning capture to dashboard
emit_learning() {
    local title="$1"
    local session_id=$(get_session_id)
    local timestamp=$(date +%s)
    
    echo "{\"type\":\"learning\",\"sessionId\":\"$session_id\",\"title\":\"$title\",\"timestamp\":$timestamp}" >> "$EVENTS_FILE"
}

# Emit identity access to dashboard
emit_identity() {
    local component="$1"
    local session_id=$(get_session_id)
    local timestamp=$(date +%s)
    
    echo "{\"type\":\"identity\",\"sessionId\":\"$session_id\",\"component\":\"$component\",\"timestamp\":$timestamp}" >> "$EVENTS_FILE"
}

# Detect current algorithm phase from context
detect_phase() {
    local prompt="$1"
    
    # Simple phase detection based on keywords
    if echo "$prompt" | grep -qi "observe\|understand\|check\|examine\|analyze"; then
        echo "OBSERVE"
    elif echo "$prompt" | grep -qi "think\|consider\|approach\|option\|alternative"; then
        echo "THINK"
    elif echo "$prompt" | grep -qi "plan\|strategy\|steps\|sequence"; then
        echo "PLAN"
    elif echo "$prompt" | grep -qi "build\|criteria\|success\|define\|specify"; then
        echo "BUILD"
    elif echo "$prompt" | grep -qi "execute\|implement\|run\|create\|do"; then
        echo "EXECUTE"
    elif echo "$prompt" | grep -qi "verify\|test\|check\|validate\|confirm"; then
        echo "VERIFY"
    elif echo "$prompt" | grep -qi "learn\|insight\|lesson\|capture"; then
        echo "LEARN"
    else
        echo "EXECUTE"  # Default phase
    fi
}

# Export functions for use in hooks
export -f get_session_id emit_phase emit_learning emit_identity detect_phase
