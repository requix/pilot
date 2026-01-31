#!/usr/bin/env bash
# dashboard.sh - Emit state to PILOT dashboard
# Part of PILOT - Personal Intelligence Layer for Optimized Tasks
# Location: src/helpers/dashboard.sh (consolidated from src/lib/dashboard-emitter.sh)
#
# Source this in hooks to send state updates to the dashboard.
#
# Usage:
#   source dashboard.sh
#   dashboard_init
#   dashboard_emit_phase OBSERVE "Working on feature"
#   dashboard_emit_learning "Discovered pattern" "category" "tag1,tag2"

DASHBOARD_DIR="${HOME}/.kiro/pilot/dashboard"
SESSIONS_DIR="${DASHBOARD_DIR}/sessions"
EVENTS_FILE="${DASHBOARD_DIR}/events.jsonl"

# Initialize dashboard directories
dashboard_init() {
    mkdir -p "$SESSIONS_DIR" 2>/dev/null || true
}

# Get or create session ID
dashboard_session_id() {
    if [ -n "$PILOT_SESSION" ]; then
        echo "$PILOT_SESSION"
    elif [ -f "${HOME}/.kiro/pilot/.cache/current-session-id" ]; then
        cat "${HOME}/.kiro/pilot/.cache/current-session-id" 2>/dev/null
    else
        # Generate unique session ID with timestamp and random component
        echo "pilot-$(date +%s)-$-$RANDOM"
    fi
}

# Emit phase change
# Usage: dashboard_emit_phase OBSERVE [title]
dashboard_emit_phase() {
    local phase="$1"
    local title="$2"
    local session_id
    session_id=$(dashboard_session_id)
    local timestamp
    timestamp=$(date +%s)
    local cwd
    cwd=$(pwd)
    
    dashboard_init
    
    # Check if session file exists to preserve start time and increment command count
    local session_file="${SESSIONS_DIR}/${session_id}.json"
    local start_time="$timestamp"
    local command_count=1
    
    if [ -f "$session_file" ]; then
        # Preserve existing start time and increment command count
        start_time=$(jq -r '.startTime // '${timestamp}'' "$session_file" 2>/dev/null || echo "$timestamp")
        command_count=$(jq -r '.commandCount // 0' "$session_file" 2>/dev/null || echo 0)
        command_count=$((command_count + 1))
    fi
    
    # Build JSON with optional title
    local json="{\"id\":\"${session_id}\",\"phase\":\"${phase}\",\"updated\":${timestamp},\"startTime\":${start_time},\"commandCount\":${command_count},\"workingDirectory\":\"${cwd}\""
    if [ -n "$title" ]; then
        json="${json},\"title\":\"${title}\""
    fi
    json="${json}}"
    
    # Update session file with preserved start time
    echo "$json" > "$session_file" 2>/dev/null
    
    # Append event
    echo "{\"type\":\"phase\",\"sessionId\":\"${session_id}\",\"phase\":\"${phase}\",\"timestamp\":${timestamp}}" >> "$EVENTS_FILE" 2>/dev/null || true
}

# Emit learning capture
# Usage: dashboard_emit_learning "Discovered caching pattern" [category] [tag1,tag2]
dashboard_emit_learning() {
    local title="$1"
    local category="$2"
    local tags="$3"
    local session_id
    session_id=$(dashboard_session_id)
    local timestamp
    timestamp=$(date +%s)
    
    dashboard_init
    
    # Escape quotes in title
    title="${title//\"/\\\"}"
    
    # Build JSON with optional fields
    local json="{\"type\":\"learning\",\"sessionId\":\"${session_id}\",\"title\":\"${title}\",\"timestamp\":${timestamp}"
    if [ -n "$category" ]; then
        json="${json},\"category\":\"${category}\""
    fi
    if [ -n "$tags" ]; then
        json="${json},\"tags\":[\"${tags//,/\",\"}\"]"
    fi
    json="${json}}"
    
    echo "$json" >> "$EVENTS_FILE" 2>/dev/null || true
}

# Emit identity access
# Usage: dashboard_emit_identity GOALS
dashboard_emit_identity() {
    local component="$1"
    local session_id
    session_id=$(dashboard_session_id)
    local timestamp
    timestamp=$(date +%s)
    
    dashboard_init
    
    echo "{\"type\":\"identity\",\"sessionId\":\"${session_id}\",\"component\":\"${component}\",\"timestamp\":${timestamp}}" >> "$EVENTS_FILE" 2>/dev/null || true
}

# Clean up session on exit
# Usage: dashboard_cleanup
dashboard_cleanup() {
    local session_id
    session_id=$(dashboard_session_id)
    rm -f "${SESSIONS_DIR}/${session_id}.json" 2>/dev/null || true
}
