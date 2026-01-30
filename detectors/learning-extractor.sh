#!/usr/bin/env bash
# learning-extractor.sh - Learning extraction for Adaptive Identity Capture
# Part of PILOT - Identifies lessons learned from problem-solving sessions
#
# Features:
# - Problem-solving session analysis
# - Non-triviality filter (duration > 10min or multiple attempts)
# - Duplicate detection
# - Repeated mistake detection
#
# Usage:
#   source learning-extractor.sh
#   learning_analyze_session "problem" "solution" 900
#   learning_check_duplicate "lesson"
#   learning_check_repeated_mistake "context"

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
[[ -f "${LIB_DIR}/json-helpers.sh" ]] && source "${LIB_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
PATTERNS_FILE="${OBSERVATIONS_DIR}/patterns.json"
IDENTITY_DIR="${PILOT_DATA}/identity"
LEARNED_FILE="${IDENTITY_DIR}/LEARNED.md"

# Configuration
LEARNING_MIN_DURATION_SECONDS=600  # 10 minutes
LEARNING_MIN_ATTEMPTS=2            # Multiple attempts threshold

# ============================================
# INITIALIZATION
# ============================================

_learning_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$PATTERNS_FILE" ]]; then
        cat > "$PATTERNS_FILE" 2>/dev/null << 'EOF'
{
  "learnings": {},
  "problemSessions": [],
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# LEARNING ID GENERATION
# ============================================

# Generate a learning ID from lesson text
learning_generate_id() {
    local lesson="$1"
    
    # Normalize (lowercase, first 50 chars)
    local normalized
    normalized=$(echo "$lesson" | tr '[:upper:]' '[:lower:]' | head -c 50)
    
    # Generate hash
    local hash
    if command -v md5 >/dev/null 2>&1; then
        hash=$(echo -n "$normalized" | md5)
    elif command -v md5sum >/dev/null 2>&1; then
        hash=$(echo -n "$normalized" | md5sum | cut -d' ' -f1)
    else
        hash=$(echo -n "$normalized" | cksum | cut -d' ' -f1)
    fi
    
    echo "${hash:0:12}"
}

# ============================================
# SESSION ANALYSIS
# ============================================

# Analyze a problem-solving session for potential learnings
# Returns JSON with learning candidate or empty if trivial
learning_analyze_session() {
    local problem="$1"
    local solution="$2"
    local duration="${3:-0}"
    local attempts="${4:-1}"
    
    _learning_ensure_file
    
    # Check non-triviality
    local is_nontrivial=false
    
    if [[ $duration -ge $LEARNING_MIN_DURATION_SECONDS ]]; then
        is_nontrivial=true
    fi
    
    if [[ $attempts -ge $LEARNING_MIN_ATTEMPTS ]]; then
        is_nontrivial=true
    fi
    
    if [[ "$is_nontrivial" != "true" ]]; then
        # Trivial session, no learning to extract
        return 1
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Generate suggested lesson
    local suggested_lesson="$solution"
    local suggested_cost=""
    local suggested_application=""
    
    # Calculate cost based on duration
    if [[ $duration -ge 3600 ]]; then
        suggested_cost="$((duration / 3600)) hours"
    elif [[ $duration -ge 60 ]]; then
        suggested_cost="$((duration / 60)) minutes"
    fi
    
    # Suggest application context
    suggested_application="When facing similar $problem issues"
    
    # Calculate confidence based on duration and attempts
    local confidence=50
    [[ $duration -ge $LEARNING_MIN_DURATION_SECONDS ]] && confidence=$((confidence + 25))
    [[ $attempts -ge $LEARNING_MIN_ATTEMPTS ]] && confidence=$((confidence + 25))
    
    # Record session
    local session_record="{\"problem\": \"$problem\", \"solution\": \"$solution\", \"duration\": $duration, \"attempts\": $attempts, \"timestamp\": \"$timestamp\"}"
    json_array_append "$PATTERNS_FILE" ".problemSessions" "$session_record"
    
    # Trim to last 50 sessions
    local session_count
    session_count=$(json_array_length "$PATTERNS_FILE" ".problemSessions")
    while [[ $session_count -gt 50 ]]; do
        json_array_remove "$PATTERNS_FILE" ".problemSessions" 0
        session_count=$((session_count - 1))
    done
    
    json_touch_file "$PATTERNS_FILE"
    
    # Return learning candidate
    cat << EOF
{
  "lesson": "$suggested_lesson",
  "context": "$problem",
  "suggestedCost": "$suggested_cost",
  "suggestedApplication": "$suggested_application",
  "confidence": $confidence,
  "duration": $duration,
  "attempts": $attempts
}
EOF
    
    return 0
}

# ============================================
# DUPLICATE DETECTION
# ============================================

# Check if a learning already exists (avoid duplicates)
learning_check_duplicate() {
    local lesson="$1"
    
    # Check in LEARNED.md if it exists
    if [[ -f "$LEARNED_FILE" ]]; then
        # Simple substring match (case-insensitive)
        local lesson_lower
        lesson_lower=$(echo "$lesson" | tr '[:upper:]' '[:lower:]')
        
        if grep -qi "$lesson_lower" "$LEARNED_FILE" 2>/dev/null; then
            return 0  # Is duplicate
        fi
    fi
    
    # Check in patterns file
    _learning_ensure_file
    
    local learning_id
    learning_id=$(learning_generate_id "$lesson")
    
    local existing
    existing=$(json_read_file "$PATTERNS_FILE" ".learnings.\"$learning_id\"")
    
    if [[ -n "$existing" ]] && [[ "$existing" != "null" ]]; then
        return 0  # Is duplicate
    fi
    
    return 1  # Not duplicate
}

# Record a learning to prevent future duplicates
learning_record() {
    local lesson="$1"
    local context="${2:-}"
    
    _learning_ensure_file
    
    local learning_id
    learning_id=$(learning_generate_id "$lesson")
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local learning_record="{\"lesson\": \"$lesson\", \"context\": \"$context\", \"recordedAt\": \"$timestamp\"}"
    json_set_nested "$PATTERNS_FILE" ".learnings.\"$learning_id\"" "$learning_record"
    json_touch_file "$PATTERNS_FILE"
}

# ============================================
# REPEATED MISTAKE DETECTION
# ============================================

# Check if user is repeating a documented mistake
# Returns existing learning info if found
learning_check_repeated_mistake() {
    local context="$1"
    
    if [[ ! -f "$LEARNED_FILE" ]]; then
        return 1
    fi
    
    # Extract keywords from context
    local keywords
    keywords=$(echo "$context" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' ' ')
    
    # Search for matching lessons in LEARNED.md
    for keyword in $keywords; do
        # Skip short words
        [[ ${#keyword} -lt 4 ]] && continue
        
        # Search for keyword in LEARNED.md
        local match
        match=$(grep -i "$keyword" "$LEARNED_FILE" 2>/dev/null | head -1)
        
        if [[ -n "$match" ]]; then
            # Found a potential match - extract the lesson
            # Look for the ## header above this line
            local lesson_header
            lesson_header=$(grep -B5 "$keyword" "$LEARNED_FILE" 2>/dev/null | grep "^## " | tail -1)
            
            if [[ -n "$lesson_header" ]]; then
                local lesson="${lesson_header#\#\# }"
                echo "{\"lesson\": \"$lesson\", \"matchedKeyword\": \"$keyword\"}"
                return 0
            fi
        fi
    done
    
    return 1
}

# ============================================
# PATTERN TRACKING
# ============================================

# Track a problem pattern for repeated mistake detection
learning_track_problem() {
    local problem="$1"
    local context="${2:-}"
    
    _learning_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Generate problem ID
    local problem_id
    problem_id=$(learning_generate_id "$problem")
    
    # Get existing problem data
    local existing
    existing=$(json_read_file "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
        # Create new problem pattern
        local new_pattern="{\"problem\": \"$problem\", \"occurrences\": 1, \"contexts\": [\"$context\"], \"firstSeen\": \"$timestamp\", \"lastSeen\": \"$timestamp\"}"
        json_set_nested "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\"" "$new_pattern"
    else
        # Update existing
        local current_count
        current_count=$(json_read_file "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\".occurrences")
        current_count=${current_count:-0}
        
        json_update_field "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\".occurrences" "$((current_count + 1))"
        json_update_field "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\".lastSeen" "\"$timestamp\""
        
        if [[ -n "$context" ]]; then
            json_array_append "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\".contexts" "\"$context\""
        fi
    fi
    
    json_touch_file "$PATTERNS_FILE"
}

# Get problems that keep recurring (potential learnings needed)
learning_get_recurring_problems() {
    _learning_ensure_file
    
    local problem_ids
    problem_ids=$(json_read_file "$PATTERNS_FILE" ".problemPatterns | keys[]" 2>/dev/null)
    
    for problem_id in $problem_ids; do
        [[ -z "$problem_id" ]] && continue
        
        local occurrences
        occurrences=$(json_read_file "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\".occurrences")
        occurrences=${occurrences:-0}
        
        # Return problems with 3+ occurrences
        if [[ $occurrences -ge 3 ]]; then
            local problem
            problem=$(json_read_file "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\".problem")
            echo "{\"problemId\": \"$problem_id\", \"problem\": \"$problem\", \"occurrences\": $occurrences}"
        fi
    done
}

# ============================================
# EXPORTS
# ============================================

export -f learning_generate_id
export -f learning_analyze_session
export -f learning_check_duplicate
export -f learning_record
export -f learning_check_repeated_mistake
export -f learning_track_problem
export -f learning_get_recurring_problems
