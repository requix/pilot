#!/usr/bin/env bash
# silent-capture.sh - Silent Identity Auto-Capture
# Part of PILOT - Keyword indicator approach for identity detection
#
# PILOT's keyword indicator approach:
# - Simple keyword matching (not complex regex)
# - Threshold-based capture (2+ indicators required)
# - Lightweight and fast
#
# Usage:
#   source silent-capture.sh
#   capture_from_prompt "$prompt"
#   capture_from_response "$response"

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/identity-writer.sh" ]] && source "${SCRIPT_DIR}/identity-writer.sh"

# Directories
PILOT_HOME="${PILOT_HOME:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_HOME}/observations"
LOGS_DIR="${PILOT_HOME}/logs"

# Ensure directories exist
mkdir -p "$OBSERVATIONS_DIR" "$LOGS_DIR" 2>/dev/null || true

# ============================================
# KEYWORD INDICATORS
# ============================================

# Each category has indicators - need 2+ matches to trigger capture
# Pipe-separated for grep -E compatibility

LEARNING_INDICATORS="problem|solved|discovered|fixed|learned|realized|figured out|root cause|issue was|turned out|bug|solution|mistake|error|debugging"
BELIEF_INDICATORS="i always|i never|i believe|i prefer|i think|should always|must always|principle|value|important to me"
CHALLENGE_INDICATORS="struggling|stuck|frustrated|difficult|hard time|problem with|issue with|error|failing|broken|cant|cannot|can't figure"
PROJECT_INDICATORS="working on|my project|the project|building|developing|shipping|launching|maintaining"
IDEA_INDICATORS="would be cool|could try|might try|someday|idea|interesting to|explore|wonder if|what if"
GOAL_INDICATORS="my goal|trying to|want to|need to|aiming to|deadline|ship by|finish by|complete by"
STRATEGY_INDICATORS="my approach|i usually|i typically|my method|my process|when i|first i|before i"

# ============================================
# INDICATOR COUNTING
# ============================================

# Count how many indicators match in text
# Usage: count_indicators "$text" "$indicators"
# Returns: number of matches
count_indicators() {
    local text="$1"
    local indicators="$2"
    local text_lower
    text_lower=$(echo "$text" | tr '[:upper:]' '[:lower:]')
    
    # Count matches using grep
    local count
    count=$(echo "$text_lower" | grep -oE "$indicators" 2>/dev/null | wc -l | tr -d ' ')
    echo "${count:-0}"
}

# ============================================
# PROMPT CAPTURE (called on user prompts)
# ============================================

capture_from_prompt() {
    local prompt="$1"
    [[ -z "$prompt" ]] && return 0
    
    local prompt_lower
    prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')
    
    # Check each category
    _check_and_capture_belief "$prompt" "$prompt_lower"
    _check_and_capture_challenge "$prompt" "$prompt_lower"
    _check_and_capture_project "$prompt" "$prompt_lower"
    _check_and_capture_idea "$prompt" "$prompt_lower"
    _check_and_capture_goal "$prompt" "$prompt_lower"
    _check_and_capture_strategy "$prompt" "$prompt_lower"
}

# ============================================
# RESPONSE CAPTURE (called on AI responses)
# ============================================

capture_from_response() {
    local response="$1"
    [[ -z "$response" ]] && return 0
    
    # Primary use: detect learnings from AI responses
    _check_and_capture_learning "$response"
}

# ============================================
# CATEGORY CHECKERS
# ============================================

_check_and_capture_learning() {
    local text="$1"
    local count
    count=$(count_indicators "$text" "$LEARNING_INDICATORS")
    
    if [[ $count -ge 2 ]]; then
        # Extract a summary (first sentence with learning indicator)
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
        # Extract belief statement
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
        # Projects only need 1 indicator but we extract the name
        local project
        if [[ "$text_lower" =~ (working on|my project|the project)[[:space:]]+([a-z0-9_-]+) ]]; then
            project="${BASH_REMATCH[2]}"
            # Filter common words that aren't project names
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
        # Ideas captured on first mention (they're fleeting)
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

# ============================================
# OBSERVATION TRACKING & CAPTURE
# ============================================

_record_and_maybe_capture() {
    local category="$1"
    local content="$2"
    local indicator_count="$3"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Generate content hash for deduplication
    local content_hash
    content_hash=$(echo "$content" | md5sum 2>/dev/null | cut -c1-8 || echo "$RANDOM")
    
    local obs_file="${OBSERVATIONS_DIR}/${category}-observations.json"
    
    # Initialize if needed
    if [[ ! -f "$obs_file" ]]; then
        echo '{"observations": {}}' > "$obs_file"
    fi
    
    # Check if already captured to identity (look in .captured file)
    local already_captured
    already_captured=$(cat "${obs_file}.captured" 2>/dev/null | grep -o "\"hash\": \"${content_hash}\"" | head -1)
    
    if [[ -n "$already_captured" ]]; then
        # Already captured, log detection but skip capture
        _log_detection "$category" "$content" "$indicator_count"
        return 0
    fi
    
    # Log the detection
    _log_detection "$category" "$content" "$indicator_count"
    
    # Capture thresholds by category
    local threshold=2
    case "$category" in
        idea) threshold=1 ;;      # Ideas captured immediately
        project) threshold=1 ;;   # Projects captured immediately  
        learning) threshold=2 ;;  # Learnings need 2+ indicators
        *) threshold=2 ;;         # Default: 2+ indicators
    esac
    
    if [[ $indicator_count -ge $threshold ]]; then
        _capture_to_identity "$category" "$content" "$content_hash"
    fi
}

_capture_to_identity() {
    local category="$1"
    local content="$2"
    local content_hash="$3"
    
    # Call appropriate identity writer function
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
    
    # Mark as captured in observations
    local obs_file="${OBSERVATIONS_DIR}/${category}-observations.json"
    # Simple append to track captured items
    echo "{\"hash\": \"$content_hash\", \"content\": \"$content\", \"captured\": true, \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "${obs_file}.captured" 2>/dev/null || true
}

# ============================================
# LOGGING
# ============================================

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

export -f capture_from_prompt
export -f capture_from_response
export -f count_indicators
