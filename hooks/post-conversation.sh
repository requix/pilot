#!/usr/bin/env bash
# Identity capture hook - post conversation
# Extracts identity information from conversations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PILOT_LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

source "${PILOT_LIB_DIR}/identity-writer.sh" 2>/dev/null || true

CONVERSATION_TEXT="${1:-$(cat)}"
SESSION_ID="${2:-unknown}"

extract_identity() {
    local text="$1"
    local log_file="${PILOT_DATA:-$HOME/.pilot}/identity/.history/auto-capture.log"
    
    mkdir -p "$(dirname "$log_file")"
    
    # Extract projects
    if echo "$text" | grep -qi "working on\|project\|building\|implementing"; then
        project=$(echo "$text" | grep -oiE "(pilot|dashboard|terraform|kubernetes|aws|api)[[:space:]]*[a-zA-Z]*" | head -1)
        [[ -n "$project" ]] && echo "$(date): Project: $project" >> "$log_file"
    fi
    
    # Extract learnings
    if echo "$text" | grep -qi "learned\|discovered\|found out"; then
        learning=$(echo "$text" | grep -iE "learned|discovered|found out" | head -1 | cut -c1-100)
        [[ -n "$learning" ]] && echo "$(date): Learning: $learning" >> "$log_file"
    fi
    
    # Extract preferences
    if echo "$text" | grep -qi "prefer\|better than\|like.*more"; then
        pref=$(echo "$text" | grep -iE "prefer|better than|like.*more" | head -1 | cut -c1-100)
        [[ -n "$pref" ]] && echo "$(date): Preference: $pref" >> "$log_file"
    fi
}

extract_identity "$CONVERSATION_TEXT"
echo "$(date): Hook executed for session $SESSION_ID" >> "${PILOT_DATA:-$HOME/.pilot}/identity/.history/hook-activity.log"
