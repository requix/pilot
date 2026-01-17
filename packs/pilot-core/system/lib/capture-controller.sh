#!/usr/bin/env bash
# capture-controller.sh - Capture Controller for Adaptive Identity Capture
# Part of PILOT - Manages when and how capture prompts are presented
#
# Features:
# - Session prompt limit (max 1)
# - Weekly prompt limit (max 3)
# - Dismissal tracking and frequency reduction
# - Timing detection (task completion, session gaps, debugging context)
# - Priority queue for prompts
#
# Usage:
#   source capture-controller.sh
#   capture_can_show_prompt
#   capture_record_prompt_shown "project"
#   capture_record_response true
#   capture_is_good_timing
#   capture_get_next_prompt

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/json-helpers.sh" ]] && source "${SCRIPT_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
PROMPTS_FILE="${OBSERVATIONS_DIR}/prompts.json"
SESSIONS_FILE="${OBSERVATIONS_DIR}/sessions.json"

# Configuration - Frequency Limits
CAPTURE_MAX_PER_SESSION=1
CAPTURE_MAX_PER_WEEK=3
CAPTURE_COOLDOWN_DAYS=14
CAPTURE_DISMISS_THRESHOLD=3

# Priority order (lower = higher priority)
# 1=PROJECT, 2=CHALLENGE, 3=LEARNING, 4=STRATEGY, 5=GOAL,
# 6=BELIEF, 7=IDEA, 8=MODEL, 9=PREFERENCE, 10=NARRATIVE, 11=MISSION

# ============================================
# INITIALIZATION
# ============================================

_capture_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$PROMPTS_FILE" ]]; then
        local now
        now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        local week_start
        week_start=$(_capture_get_week_start)
        
        cat > "$PROMPTS_FILE" 2>/dev/null << EOF
{
  "history": [],
  "stats": {
    "totalShown": 0,
    "totalAccepted": 0,
    "acceptanceRate": 0,
    "consecutiveDismissals": 0,
    "frequencyMultiplier": 1.0
  },
  "limits": {
    "sessionPrompts": 0,
    "weekStart": "$week_start",
    "weekPrompts": 0
  },
  "lastUpdated": "$now"
}
EOF
    fi
}

# Get the start of the current week (Monday)
_capture_get_week_start() {
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS: Get Monday of current week
        local day_of_week
        day_of_week=$(date +%u)  # 1=Monday, 7=Sunday
        local days_since_monday=$((day_of_week - 1))
        date -u -v-${days_since_monday}d +"%Y-%m-%dT00:00:00Z"
    else
        # Linux
        date -u -d "last monday" +"%Y-%m-%dT00:00:00Z" 2>/dev/null || date -u +"%Y-%m-%dT00:00:00Z"
    fi
}

# ============================================
# FREQUENCY LIMITING
# ============================================

# Check if a prompt can be shown now
capture_can_show_prompt() {
    _capture_ensure_file
    
    # Check session limit
    local session_prompts
    session_prompts=$(json_read_file "$PROMPTS_FILE" ".limits.sessionPrompts")
    session_prompts=${session_prompts:-0}
    
    if [[ $session_prompts -ge $CAPTURE_MAX_PER_SESSION ]]; then
        return 1  # Session limit reached
    fi
    
    # Check weekly limit (with frequency multiplier)
    local week_start week_prompts frequency_multiplier
    week_start=$(json_read_file "$PROMPTS_FILE" ".limits.weekStart")
    week_prompts=$(json_read_file "$PROMPTS_FILE" ".limits.weekPrompts")
    frequency_multiplier=$(json_read_file "$PROMPTS_FILE" ".stats.frequencyMultiplier")
    
    week_prompts=${week_prompts:-0}
    frequency_multiplier=${frequency_multiplier:-1.0}
    
    # Check if we're in a new week
    local current_week_start
    current_week_start=$(_capture_get_week_start)
    
    if [[ "$week_start" != "$current_week_start" ]]; then
        # New week - reset counter
        json_update_field "$PROMPTS_FILE" ".limits.weekStart" "\"$current_week_start\""
        json_update_field "$PROMPTS_FILE" ".limits.weekPrompts" "0"
        week_prompts=0
    fi
    
    # Calculate effective weekly limit (reduced if user dismisses often)
    local effective_limit
    effective_limit=$(echo "$CAPTURE_MAX_PER_WEEK * $frequency_multiplier" | bc 2>/dev/null || echo "$CAPTURE_MAX_PER_WEEK")
    effective_limit=${effective_limit%.*}  # Truncate to integer
    [[ $effective_limit -lt 1 ]] && effective_limit=1
    
    if [[ $week_prompts -ge $effective_limit ]]; then
        return 1  # Weekly limit reached
    fi
    
    return 0  # Can show prompt
}

# Record that a prompt was shown
capture_record_prompt_shown() {
    local prompt_type="$1"
    local item_id="${2:-}"
    
    _capture_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Add to history
    local history_record="{\"timestamp\": \"$timestamp\", \"type\": \"$prompt_type\", \"itemId\": \"$item_id\", \"accepted\": null}"
    json_array_append "$PROMPTS_FILE" ".history" "$history_record"
    
    # Trim history to last 100 entries
    local history_count
    history_count=$(json_array_length "$PROMPTS_FILE" ".history")
    while [[ $history_count -gt 100 ]]; do
        json_array_remove "$PROMPTS_FILE" ".history" 0
        history_count=$((history_count - 1))
    done
    
    # Update counters
    local session_prompts week_prompts total_shown
    session_prompts=$(json_read_file "$PROMPTS_FILE" ".limits.sessionPrompts")
    week_prompts=$(json_read_file "$PROMPTS_FILE" ".limits.weekPrompts")
    total_shown=$(json_read_file "$PROMPTS_FILE" ".stats.totalShown")
    
    session_prompts=${session_prompts:-0}
    week_prompts=${week_prompts:-0}
    total_shown=${total_shown:-0}
    
    json_update_field "$PROMPTS_FILE" ".limits.sessionPrompts" "$((session_prompts + 1))"
    json_update_field "$PROMPTS_FILE" ".limits.weekPrompts" "$((week_prompts + 1))"
    json_update_field "$PROMPTS_FILE" ".stats.totalShown" "$((total_shown + 1))"
    
    json_touch_file "$PROMPTS_FILE"
}

# Record user response to prompt
capture_record_response() {
    local accepted="$1"  # true or false
    
    _capture_ensure_file
    
    # Update last history entry
    local history_count
    history_count=$(json_array_length "$PROMPTS_FILE" ".history")
    
    if [[ $history_count -gt 0 ]]; then
        local last_index=$((history_count - 1))
        json_update_field "$PROMPTS_FILE" ".history[$last_index].accepted" "$accepted"
    fi
    
    # Update stats
    local total_accepted consecutive_dismissals frequency_multiplier total_shown
    total_accepted=$(json_read_file "$PROMPTS_FILE" ".stats.totalAccepted")
    consecutive_dismissals=$(json_read_file "$PROMPTS_FILE" ".stats.consecutiveDismissals")
    frequency_multiplier=$(json_read_file "$PROMPTS_FILE" ".stats.frequencyMultiplier")
    total_shown=$(json_read_file "$PROMPTS_FILE" ".stats.totalShown")
    
    total_accepted=${total_accepted:-0}
    consecutive_dismissals=${consecutive_dismissals:-0}
    frequency_multiplier=${frequency_multiplier:-1.0}
    total_shown=${total_shown:-0}
    
    if [[ "$accepted" == "true" ]]; then
        total_accepted=$((total_accepted + 1))
        consecutive_dismissals=0
        # Slowly restore frequency if user accepts
        if [[ $(echo "$frequency_multiplier < 1.0" | bc 2>/dev/null || echo 0) -eq 1 ]]; then
            frequency_multiplier=$(echo "$frequency_multiplier + 0.1" | bc 2>/dev/null || echo "1.0")
            [[ $(echo "$frequency_multiplier > 1.0" | bc 2>/dev/null || echo 0) -eq 1 ]] && frequency_multiplier="1.0"
        fi
    else
        consecutive_dismissals=$((consecutive_dismissals + 1))
        
        # Reduce frequency after threshold dismissals
        if [[ $consecutive_dismissals -ge $CAPTURE_DISMISS_THRESHOLD ]]; then
            frequency_multiplier=$(echo "$frequency_multiplier * 0.5" | bc 2>/dev/null || echo "0.5")
            [[ $(echo "$frequency_multiplier < 0.25" | bc 2>/dev/null || echo 0) -eq 1 ]] && frequency_multiplier="0.25"
        fi
    fi
    
    # Calculate acceptance rate
    local acceptance_rate=0
    if [[ $total_shown -gt 0 ]]; then
        acceptance_rate=$(echo "scale=2; $total_accepted / $total_shown" | bc 2>/dev/null || echo "0")
    fi
    
    json_update_field "$PROMPTS_FILE" ".stats.totalAccepted" "$total_accepted"
    json_update_field "$PROMPTS_FILE" ".stats.consecutiveDismissals" "$consecutive_dismissals"
    json_update_field "$PROMPTS_FILE" ".stats.frequencyMultiplier" "$frequency_multiplier"
    json_update_field "$PROMPTS_FILE" ".stats.acceptanceRate" "$acceptance_rate"
    
    json_touch_file "$PROMPTS_FILE"
}

# Reset session prompt counter (call at session start)
capture_reset_session() {
    _capture_ensure_file
    
    json_update_field "$PROMPTS_FILE" ".limits.sessionPrompts" "0"
    json_touch_file "$PROMPTS_FILE"
}

# ============================================
# TIMING DETECTION
# ============================================

# Check if current context is appropriate for prompts
capture_is_good_timing() {
    local is_debugging="${1:-false}"
    local recent_errors="${2:-0}"
    local task_completed="${3:-false}"
    local session_gap_hours="${4:-0}"
    local organization_requested="${5:-false}"
    
    # Don't prompt during debugging
    if [[ "$is_debugging" == "true" ]]; then
        return 1
    fi
    
    # Don't prompt if recent errors
    if [[ $recent_errors -gt 2 ]]; then
        return 1
    fi
    
    # Good timing: task completed
    if [[ "$task_completed" == "true" ]]; then
        return 0
    fi
    
    # Good timing: session gap of 4+ hours (fresh start)
    if [[ $session_gap_hours -ge 4 ]]; then
        return 0
    fi
    
    # Good timing: user requested organization help
    if [[ "$organization_requested" == "true" ]]; then
        return 0
    fi
    
    # Default: not a good time
    return 1
}

# Detect if user is in debugging context
capture_detect_debugging() {
    local user_input="$1"
    
    local input_lower
    input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
    
    local debug_indicators=("error" "bug" "fix" "broken" "doesn't work" "not working" "failed" "crash" "exception" "stack trace")
    
    for indicator in "${debug_indicators[@]}"; do
        if [[ "$input_lower" == *"$indicator"* ]]; then
            return 0  # Is debugging
        fi
    done
    
    return 1  # Not debugging
}

# Detect if user completed a task
capture_detect_task_completion() {
    local user_input="$1"
    
    local input_lower
    input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
    
    local completion_indicators=("done" "finished" "completed" "works" "working now" "fixed" "solved" "success" "ship it" "merge" "deploy")
    
    for indicator in "${completion_indicators[@]}"; do
        if [[ "$input_lower" == *"$indicator"* ]]; then
            return 0  # Task completed
        fi
    done
    
    return 1  # Not completed
}

# Detect if user requested organization help
capture_detect_organization_request() {
    local user_input="$1"
    
    local input_lower
    input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
    
    local org_indicators=("organize" "plan" "prioritize" "review" "what should" "help me decide" "next steps" "roadmap")
    
    for indicator in "${org_indicators[@]}"; do
        if [[ "$input_lower" == *"$indicator"* ]]; then
            return 0  # Organization requested
        fi
    done
    
    return 1  # Not requested
}

# Calculate session gap in hours
capture_get_session_gap() {
    if [[ ! -f "$SESSIONS_FILE" ]]; then
        echo "0"
        return
    fi
    
    local last_session_end
    last_session_end=$(json_read_file "$SESSIONS_FILE" ".sessions[-1].endTime" 2>/dev/null)
    
    if [[ -z "$last_session_end" ]] || [[ "$last_session_end" == "null" ]]; then
        echo "0"
        return
    fi
    
    local now_epoch last_epoch
    now_epoch=$(date +%s)
    
    if [[ "$(uname)" == "Darwin" ]]; then
        last_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_session_end" +%s 2>/dev/null || echo "$now_epoch")
    else
        last_epoch=$(date -d "$last_session_end" +%s 2>/dev/null || echo "$now_epoch")
    fi
    
    local gap_seconds=$((now_epoch - last_epoch))
    local gap_hours=$((gap_seconds / 3600))
    
    echo "$gap_hours"
}

# ============================================
# PRIORITY QUEUE
# ============================================

# Get priority for a prompt type
_capture_get_priority() {
    local prompt_type="$1"
    
    case "$prompt_type" in
        "project")    echo 1 ;;
        "challenge")  echo 2 ;;
        "learning")   echo 3 ;;
        "strategy")   echo 4 ;;
        "goal")       echo 5 ;;
        "belief")     echo 6 ;;
        "idea")       echo 7 ;;
        "model")      echo 8 ;;
        "preference") echo 9 ;;
        "narrative")  echo 10 ;;
        "mission")    echo 11 ;;
        *)            echo 99 ;;
    esac
}

# Get the next prompt to show (if any)
# Takes a list of pending prompts as JSON lines
capture_get_next_prompt() {
    local pending_prompts="$1"
    
    if [[ -z "$pending_prompts" ]]; then
        return 1
    fi
    
    # Check if we can show a prompt
    if ! capture_can_show_prompt; then
        return 1
    fi
    
    # Sort by priority and return the highest priority prompt
    local best_prompt=""
    local best_priority=999
    
    while IFS= read -r prompt; do
        [[ -z "$prompt" ]] && continue
        
        # Extract type from JSON
        local prompt_type
        prompt_type=$(echo "$prompt" | grep -o '"type"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')
        
        if [[ -z "$prompt_type" ]]; then
            # Try alternative extraction for different JSON formats
            prompt_type=$(echo "$prompt" | grep -o '"promptType"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')
        fi
        
        local priority
        priority=$(_capture_get_priority "$prompt_type")
        
        if [[ $priority -lt $best_priority ]]; then
            best_priority=$priority
            best_prompt="$prompt"
        fi
    done <<< "$pending_prompts"
    
    if [[ -n "$best_prompt" ]]; then
        echo "$best_prompt"
        return 0
    fi
    
    return 1
}

# ============================================
# STATISTICS
# ============================================

# Get capture statistics
capture_get_stats() {
    _capture_ensure_file
    
    json_read_file "$PROMPTS_FILE" ".stats"
}

# Get prompt history
capture_get_history() {
    local limit="${1:-10}"
    
    _capture_ensure_file
    
    json_read_file "$PROMPTS_FILE" ".history | .[-$limit:]"
}

# ============================================
# EXPORTS
# ============================================

export -f capture_can_show_prompt
export -f capture_record_prompt_shown
export -f capture_record_response
export -f capture_reset_session
export -f capture_is_good_timing
export -f capture_detect_debugging
export -f capture_detect_task_completion
export -f capture_detect_organization_request
export -f capture_get_session_gap
export -f capture_get_next_prompt
export -f capture_get_stats
export -f capture_get_history
