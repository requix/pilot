#!/usr/bin/env bash
# capture.sh - Capture management for PILOT
# Part of PILOT - Personal Intelligence Layer for Optimized Tasks
# Location: src/helpers/capture.sh (consolidated from capture-controller.sh + silent-capture.sh)
#
# Combines prompt frequency control with silent identity auto-capture.
#
# Usage:
#   source capture.sh
#   capture_can_show_prompt
#   capture_from_prompt "$prompt"
#   capture_from_response "$response"

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/json.sh" ]] && source "${SCRIPT_DIR}/json.sh"
[[ -f "${SCRIPT_DIR}/identity.sh" ]] && source "${SCRIPT_DIR}/identity.sh"

# ============================================
# CAPTURE CONTROLLER (from capture-controller.sh)
# ============================================

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
        local day_of_week
        day_of_week=$(date +%u)
        local days_since_monday=$((day_of_week - 1))
        date -u -v-${days_since_monday}d +"%Y-%m-%dT00:00:00Z"
    else
        date -u -d "last monday" +"%Y-%m-%dT00:00:00Z" 2>/dev/null || date -u +"%Y-%m-%dT00:00:00Z"
    fi
}

# Check if a prompt can be shown now
capture_can_show_prompt() {
    _capture_ensure_file
    
    local session_prompts
    session_prompts=$(json_read_file "$PROMPTS_FILE" ".limits.sessionPrompts")
    session_prompts=${session_prompts:-0}
    
    if [[ $session_prompts -ge $CAPTURE_MAX_PER_SESSION ]]; then
        return 1
    fi
    
    local week_start week_prompts frequency_multiplier
    week_start=$(json_read_file "$PROMPTS_FILE" ".limits.weekStart")
    week_prompts=$(json_read_file "$PROMPTS_FILE" ".limits.weekPrompts")
    frequency_multiplier=$(json_read_file "$PROMPTS_FILE" ".stats.frequencyMultiplier")
    
    week_prompts=${week_prompts:-0}
    frequency_multiplier=${frequency_multiplier:-1.0}
    
    local current_week_start
    current_week_start=$(_capture_get_week_start)
    
    if [[ "$week_start" != "$current_week_start" ]]; then
        json_update_field "$PROMPTS_FILE" ".limits.weekStart" "\"$current_week_start\""
        json_update_field "$PROMPTS_FILE" ".limits.weekPrompts" "0"
        week_prompts=0
    fi
    
    local effective_limit
    effective_limit=$(echo "$CAPTURE_MAX_PER_WEEK * $frequency_multiplier" | bc 2>/dev/null || echo "$CAPTURE_MAX_PER_WEEK")
    effective_limit=${effective_limit%.*}
    [[ $effective_limit -lt 1 ]] && effective_limit=1
    
    if [[ $week_prompts -ge $effective_limit ]]; then
        return 1
    fi
    
    return 0
}

# Record that a prompt was shown
capture_record_prompt_shown() {
    local prompt_type="$1"
    local item_id="${2:-}"
    
    _capture_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local history_record="{\"timestamp\": \"$timestamp\", \"type\": \"$prompt_type\", \"itemId\": \"$item_id\", \"accepted\": null}"
    json_array_append "$PROMPTS_FILE" ".history" "$history_record"
    
    local history_count
    history_count=$(json_array_length "$PROMPTS_FILE" ".history")
    while [[ $history_count -gt 100 ]]; do
        json_array_remove "$PROMPTS_FILE" ".history" 0
        history_count=$((history_count - 1))
    done
    
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
    local accepted="$1"
    
    _capture_ensure_file
    
    local history_count
    history_count=$(json_array_length "$PROMPTS_FILE" ".history")
    
    if [[ $history_count -gt 0 ]]; then
        local last_index=$((history_count - 1))
        json_update_field "$PROMPTS_FILE" ".history[$last_index].accepted" "$accepted"
    fi
    
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
        if [[ $(echo "$frequency_multiplier < 1.0" | bc 2>/dev/null || echo 0) -eq 1 ]]; then
            frequency_multiplier=$(echo "$frequency_multiplier + 0.1" | bc 2>/dev/null || echo "1.0")
            [[ $(echo "$frequency_multiplier > 1.0" | bc 2>/dev/null || echo 0) -eq 1 ]] && frequency_multiplier="1.0"
        fi
    else
        consecutive_dismissals=$((consecutive_dismissals + 1))
        if [[ $consecutive_dismissals -ge $CAPTURE_DISMISS_THRESHOLD ]]; then
            frequency_multiplier=$(echo "$frequency_multiplier * 0.5" | bc 2>/dev/null || echo "0.5")
            [[ $(echo "$frequency_multiplier < 0.25" | bc 2>/dev/null || echo 0) -eq 1 ]] && frequency_multiplier="0.25"
        fi
    fi
    
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

# Reset session prompt counter
capture_reset_session() {
    _capture_ensure_file
    json_update_field "$PROMPTS_FILE" ".limits.sessionPrompts" "0"
    json_touch_file "$PROMPTS_FILE"
}

# Check if current context is appropriate for prompts
capture_is_good_timing() {
    local is_debugging="${1:-false}"
    local recent_errors="${2:-0}"
    local task_completed="${3:-false}"
    local session_gap_hours="${4:-0}"
    local organization_requested="${5:-false}"
    
    if [[ "$is_debugging" == "true" ]]; then return 1; fi
    if [[ $recent_errors -gt 2 ]]; then return 1; fi
    if [[ "$task_completed" == "true" ]]; then return 0; fi
    if [[ $session_gap_hours -ge 4 ]]; then return 0; fi
    if [[ "$organization_requested" == "true" ]]; then return 0; fi
    return 1
}

# Detect if user is in debugging context
capture_detect_debugging() {
    local user_input="$1"
    local input_lower
    input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
    
    local debug_indicators=("error" "bug" "fix" "broken" "doesn't work" "not working" "failed" "crash" "exception" "stack trace")
    
    for indicator in "${debug_indicators[@]}"; do
        if [[ "$input_lower" == *"$indicator"* ]]; then return 0; fi
    done
    return 1
}

# Detect if user completed a task
capture_detect_task_completion() {
    local user_input="$1"
    local input_lower
    input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
    
    local completion_indicators=("done" "finished" "completed" "works" "working now" "fixed" "solved" "success" "ship it" "merge" "deploy")
    
    for indicator in "${completion_indicators[@]}"; do
        if [[ "$input_lower" == *"$indicator"* ]]; then return 0; fi
    done
    return 1
}

# Detect if user requested organization help
capture_detect_organization_request() {
    local user_input="$1"
    local input_lower
    input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
    
    local org_indicators=("organize" "plan" "prioritize" "review" "what should" "help me decide" "next steps" "roadmap")
    
    for indicator in "${org_indicators[@]}"; do
        if [[ "$input_lower" == *"$indicator"* ]]; then return 0; fi
    done
    return 1
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

# Get the next prompt to show
capture_get_next_prompt() {
    local pending_prompts="$1"
    
    if [[ -z "$pending_prompts" ]]; then return 1; fi
    if ! capture_can_show_prompt; then return 1; fi
    
    local best_prompt=""
    local best_priority=999
    
    while IFS= read -r prompt; do
        [[ -z "$prompt" ]] && continue
        
        local prompt_type
        prompt_type=$(echo "$prompt" | grep -o '"type"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')
        
        if [[ -z "$prompt_type" ]]; then
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
# SILENT CAPTURE (from silent-capture.sh)
# ============================================

# Directories for silent capture
PILOT_HOME="${PILOT_HOME:-$HOME/.pilot}"
LOGS_DIR="${PILOT_HOME}/logs"

# Ensure directories exist
mkdir -p "$OBSERVATIONS_DIR" "$LOGS_DIR" 2>/dev/null || true

# Keyword indicators - need 2+ matches to trigger capture
LEARNING_INDICATORS="problem|solved|discovered|fixed|learned|realized|figured out|root cause|issue was|turned out|bug|solution|mistake|error|debugging"
BELIEF_INDICATORS="i always|i never|i believe|i prefer|i think|should always|must always|principle|value|important to me"
CHALLENGE_INDICATORS="struggling|stuck|frustrated|difficult|hard time|problem with|issue with|error|failing|broken|cant|cannot|can't figure"
PROJECT_INDICATORS="working on|my project|the project|building|developing|shipping|launching|maintaining"
IDEA_INDICATORS="would be cool|could try|might try|someday|idea|interesting to|explore|wonder if|what if"
GOAL_INDICATORS="my goal|trying to|want to|need to|aiming to|deadline|ship by|finish by|complete by"
STRATEGY_INDICATORS="my approach|i usually|i typically|my method|my process|when i|first i|before i"

# Count how many indicators match in text
count_indicators() {
    local text="$1"
    local indicators="$2"
    local text_lower
    text_lower=$(echo "$text" | tr '[:upper:]' '[:lower:]')
    
    local count
    count=$(echo "$text_lower" | grep -oE "$indicators" 2>/dev/null | wc -l | tr -d ' ')
    echo "${count:-0}"
}

# Capture from user prompts
capture_from_prompt() {
    local prompt="$1"
    [[ -z "$prompt" ]] && return 0
    
    local prompt_lower
    prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')
    
    _check_and_capture_belief "$prompt" "$prompt_lower"
    _check_and_capture_challenge "$prompt" "$prompt_lower"
    _check_and_capture_project "$prompt" "$prompt_lower"
    _check_and_capture_idea "$prompt" "$prompt_lower"
    _check_and_capture_goal "$prompt" "$prompt_lower"
    _check_and_capture_strategy "$prompt" "$prompt_lower"
}

# Capture from AI responses
capture_from_response() {
    local response="$1"
    [[ -z "$response" ]] && return 0
    _check_and_capture_learning "$response"
}

_check_and_capture_learning() {
    local text="$1"
    local count
    count=$(count_indicators "$text" "$LEARNING_INDICATORS")
    
    if [[ $count -ge 2 ]]; then
        local summary
        summary=$(echo "$text" | tr '[:upper:]' '[:lower:]' | grep -oE "[^.]*($LEARNING_INDICATORS)[^.]*\." | head -1 | cut -c1-150)
        
        if [[ -n "$summary" ]]; then
            _record_and_maybe_capture "learning" "$summary" "$count"
        fi
    fi
}

_check_and_capture_belief() {
    local text="$1"
    local text_lower="$2"
    local count
    count=$(count_indicators "$text" "$BELIEF_INDICATORS")
    
    if [[ $count -ge 2 ]]; then
        local belief
        belief=$(echo "$text_lower" | grep -oE "(i always|i never|i believe|i prefer)[^.]*" | head -1 | cut -c1-100)
        
        if [[ -n "$belief" ]]; then
            _record_and_maybe_capture "belief" "$belief" "$count"
        fi
    fi
}

_check_and_capture_challenge() {
    local text="$1"
    local text_lower="$2"
    local count
    count=$(count_indicators "$text" "$CHALLENGE_INDICATORS")
    
    if [[ $count -ge 2 ]]; then
        local challenge
        challenge=$(echo "$text_lower" | grep -oE "(struggling|stuck|frustrated|problem|issue|error)[^.]*" | head -1 | cut -c1-100)
        
        if [[ -n "$challenge" ]]; then
            _record_and_maybe_capture "challenge" "$challenge" "$count"
        fi
    fi
}

_check_and_capture_project() {
    local text="$1"
    local text_lower="$2"
    local count
    count=$(count_indicators "$text" "$PROJECT_INDICATORS")
    
    if [[ $count -ge 1 ]]; then
        local project
        if [[ "$text_lower" =~ (working on|my project|the project)[[:space:]]+([a-z0-9_-]+) ]]; then
            project="${BASH_REMATCH[2]}"
            if [[ ! "$project" =~ ^(the|a|an|this|that|some|it|my|these|those|new|old|our|your)$ ]] && [[ ${#project} -gt 2 ]]; then
                _record_and_maybe_capture "project" "$project" "$count"
            fi
        fi
    fi
}

_check_and_capture_idea() {
    local text="$1"
    local text_lower="$2"
    local count
    count=$(count_indicators "$text" "$IDEA_INDICATORS")
    
    if [[ $count -ge 1 ]]; then
        local idea
        idea=$(echo "$text_lower" | grep -oE "(would be cool|could try|might try|idea)[^.]*" | head -1 | cut -c1-100)
        
        if [[ -n "$idea" ]]; then
            _record_and_maybe_capture "idea" "$idea" "$count"
        fi
    fi
}

_check_and_capture_goal() {
    local text="$1"
    local text_lower="$2"
    local count
    count=$(count_indicators "$text" "$GOAL_INDICATORS")
    
    if [[ $count -ge 2 ]]; then
        local goal
        goal=$(echo "$text_lower" | grep -oE "(my goal|trying to|want to|need to)[^.]*" | head -1 | cut -c1-100)
        
        if [[ -n "$goal" ]]; then
            _record_and_maybe_capture "goal" "$goal" "$count"
        fi
    fi
}

_check_and_capture_strategy() {
    local text="$1"
    local text_lower="$2"
    local count
    count=$(count_indicators "$text" "$STRATEGY_INDICATORS")
    
    if [[ $count -ge 2 ]]; then
        local strategy
        strategy=$(echo "$text_lower" | grep -oE "(my approach|i usually|i typically|my method)[^.]*" | head -1 | cut -c1-100)
        
        if [[ -n "$strategy" ]]; then
            _record_and_maybe_capture "strategy" "$strategy" "$count"
        fi
    fi
}

_record_and_maybe_capture() {
    local category="$1"
    local content="$2"
    local indicator_count="$3"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local content_hash
    content_hash=$(echo "$content" | md5sum 2>/dev/null | cut -c1-8 || echo "$RANDOM")
    
    local obs_file="${OBSERVATIONS_DIR}/${category}-observations.json"
    
    if [[ ! -f "$obs_file" ]]; then
        echo '{"observations": {}}' > "$obs_file"
    fi
    
    local already_captured
    already_captured=$(cat "${obs_file}.captured" 2>/dev/null | grep -o "\"hash\": \"${content_hash}\"" | head -1)
    
    if [[ -n "$already_captured" ]]; then
        _log_detection "$category" "$content" "$indicator_count"
        return 0
    fi
    
    _log_detection "$category" "$content" "$indicator_count"
    
    local threshold=2
    case "$category" in
        idea) threshold=1 ;;
        project) threshold=1 ;;
        learning) threshold=2 ;;
        *) threshold=2 ;;
    esac
    
    if [[ $indicator_count -ge $threshold ]]; then
        _capture_to_identity "$category" "$content" "$content_hash"
    fi
}

_capture_to_identity() {
    local category="$1"
    local content="$2"
    local content_hash="$3"
    
    case "$category" in
        learning)
            identity_add_learning "$content" "Auto-captured" "" "" 2>/dev/null || true
            ;;
        belief)
            identity_add_belief "$content" "general" "" 2>/dev/null || true
            ;;
        challenge)
            identity_add_challenge "$content" "" "" 2>/dev/null || true
            ;;
        project)
            if ! identity_project_exists "$content" 2>/dev/null; then
                identity_add_project "$content" "Auto-detected" "$(pwd)" "0" 2>/dev/null || true
            fi
            ;;
        idea)
            identity_add_idea "$content" "Auto-captured" "" "" 2>/dev/null || true
            ;;
        goal)
            identity_add_goal "$content" "" "" 2>/dev/null || true
            ;;
        strategy)
            identity_add_strategy "$content" "" "" "" 2>/dev/null || true
            ;;
    esac
    
    _log_capture "$category" "$content"
    
    local obs_file="${OBSERVATIONS_DIR}/${category}-observations.json"
    echo "{\"hash\": \"$content_hash\", \"content\": \"$content\", \"captured\": true, \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "${obs_file}.captured" 2>/dev/null || true
}

_log_detection() {
    local category="$1"
    local content="$2"
    local count="$3"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "[$timestamp] [detect] [$category] indicators=$count content=\"${content:0:80}\"" >> "$LOGS_DIR/identity-capture.log" 2>/dev/null || true
}

_log_capture() {
    local category="$1"
    local content="$2"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "[$timestamp] [capture] [$category] content=\"${content:0:80}\"" >> "$LOGS_DIR/identity-capture.log" 2>/dev/null || true
}

# ============================================
# EXPORTS
# ============================================

# Capture controller exports
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

# Silent capture exports
export -f capture_from_prompt
export -f capture_from_response
export -f count_indicators
