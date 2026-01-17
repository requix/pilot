#!/usr/bin/env bash
# idea-capturer.sh - Idea capture for Adaptive Identity Capture
# Part of PILOT - Captures future possibilities mentioned by the user
#
# Features:
# - Future possibility detection patterns
# - Staleness detection (90 days backlog)
# - Idea-to-work matching
#
# Usage:
#   source idea-capturer.sh
#   idea_detect "user input text"
#   idea_get_stale
#   idea_match_work "work context"

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
[[ -f "${LIB_DIR}/json-helpers.sh" ]] && source "${LIB_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
IDEAS_FILE="${OBSERVATIONS_DIR}/ideas.json"
IDENTITY_DIR="${PILOT_DATA}/identity"
IDEAS_MD="${IDENTITY_DIR}/IDEAS.md"

# Configuration
IDEA_STALENESS_DAYS=90  # Days in backlog before suggesting action

# Idea detection patterns (phrases that suggest future possibilities)
IDEA_PATTERNS=(
    "should try"
    "could try"
    "might try"
    "want to try"
    "would be nice"
    "would be cool"
    "someday"
    "eventually"
    "in the future"
    "later on"
    "when I have time"
    "idea:"
    "thought:"
    "maybe we could"
    "what if we"
    "it would be great"
    "I've been thinking"
    "been meaning to"
    "on my list"
    "backlog"
    "todo"
    "experiment with"
    "explore"
)

# ============================================
# INITIALIZATION
# ============================================

_idea_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$IDEAS_FILE" ]]; then
        cat > "$IDEAS_FILE" 2>/dev/null << 'EOF'
{
  "ideas": {},
  "detections": [],
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# IDEA ID GENERATION
# ============================================

# Generate an idea ID from idea text
idea_generate_id() {
    local idea="$1"
    
    # Normalize (lowercase, first 50 chars)
    local normalized
    normalized=$(echo "$idea" | tr '[:upper:]' '[:lower:]' | head -c 50)
    
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
# IDEA DETECTION
# ============================================

# Detect idea mentions in user input
# Returns JSON with idea candidate or empty if none found
idea_detect() {
    local input="$1"
    
    _idea_ensure_file
    
    local input_lower
    input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    
    # Check for idea patterns
    local matched_pattern=""
    for pattern in "${IDEA_PATTERNS[@]}"; do
        if [[ "$input_lower" == *"$pattern"* ]]; then
            matched_pattern="$pattern"
            break
        fi
    done
    
    if [[ -z "$matched_pattern" ]]; then
        return 1  # No idea detected
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Extract the idea (text after the pattern, or the whole input if short)
    local idea_text="$input"
    if [[ ${#input} -gt 100 ]]; then
        # Try to extract just the relevant part
        idea_text=$(echo "$input" | head -c 200)
    fi
    
    # Suggest category based on content
    local suggested_category="General"
    if [[ "$input_lower" == *"tool"* ]] || [[ "$input_lower" == *"script"* ]]; then
        suggested_category="Tools"
    elif [[ "$input_lower" == *"learn"* ]] || [[ "$input_lower" == *"study"* ]]; then
        suggested_category="Learning"
    elif [[ "$input_lower" == *"project"* ]] || [[ "$input_lower" == *"build"* ]]; then
        suggested_category="Projects"
    elif [[ "$input_lower" == *"automat"* ]] || [[ "$input_lower" == *"workflow"* ]]; then
        suggested_category="Automation"
    fi
    
    # Record detection
    local detection_record="{\"input\": \"$input\", \"pattern\": \"$matched_pattern\", \"timestamp\": \"$timestamp\"}"
    json_array_append "$IDEAS_FILE" ".detections" "$detection_record"
    
    # Trim to last 50 detections
    local detection_count
    detection_count=$(json_array_length "$IDEAS_FILE" ".detections")
    while [[ $detection_count -gt 50 ]]; do
        json_array_remove "$IDEAS_FILE" ".detections" 0
        detection_count=$((detection_count - 1))
    done
    
    json_touch_file "$IDEAS_FILE"
    
    # Return idea candidate
    cat << EOF
{
  "idea": "$idea_text",
  "detectedFrom": "$matched_pattern",
  "suggestedCategory": "$suggested_category",
  "timestamp": "$timestamp"
}
EOF
    
    return 0
}

# ============================================
# IDEA RECORDING
# ============================================

# Record an idea for tracking
idea_record() {
    local idea="$1"
    local category="${2:-General}"
    local status="${3:-Backlog}"
    
    _idea_ensure_file
    
    local idea_id
    idea_id=$(idea_generate_id "$idea")
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Get existing idea data
    local existing
    existing=$(json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
        # Create new idea entry
        local new_idea="{
            \"ideaId\": \"$idea_id\",
            \"idea\": \"$idea\",
            \"category\": \"$category\",
            \"status\": \"$status\",
            \"addedAt\": \"$timestamp\",
            \"lastUpdated\": \"$timestamp\",
            \"documented\": false
        }"
        
        json_set_nested "$IDEAS_FILE" ".ideas.\"$idea_id\"" "$new_idea"
    else
        # Update existing
        json_update_field "$IDEAS_FILE" ".ideas.\"$idea_id\".lastUpdated" "\"$timestamp\""
    fi
    
    json_touch_file "$IDEAS_FILE"
}

# ============================================
# STALENESS DETECTION
# ============================================

# Get stale ideas (backlog for 90+ days)
idea_get_stale() {
    _idea_ensure_file
    
    local now_epoch
    now_epoch=$(date +%s)
    
    local staleness_seconds=$((IDEA_STALENESS_DAYS * 24 * 60 * 60))
    
    # Check documented ideas in IDEAS.md
    if [[ -f "$IDEAS_MD" ]]; then
        # Parse IDEAS.md for backlog items with dates
        # This is a simplified check - looks for "Added:" dates
        while IFS= read -r line; do
            if [[ "$line" == *"Added:"* ]] && [[ "$line" == *"Backlog"* ]]; then
                # Extract date (format: Added: YYYY-MM-DD)
                local date_str
                date_str=$(echo "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
                
                if [[ -n "$date_str" ]]; then
                    local added_epoch
                    if [[ "$(uname)" == "Darwin" ]]; then
                        added_epoch=$(date -j -f "%Y-%m-%d" "$date_str" +%s 2>/dev/null || echo 0)
                    else
                        added_epoch=$(date -d "$date_str" +%s 2>/dev/null || echo 0)
                    fi
                    
                    local age_seconds=$((now_epoch - added_epoch))
                    
                    if [[ $age_seconds -ge $staleness_seconds ]]; then
                        echo "{\"source\": \"documented\", \"date\": \"$date_str\", \"ageDays\": $((age_seconds / 86400))}"
                    fi
                fi
            fi
        done < "$IDEAS_MD"
    fi
    
    # Check observed ideas
    local idea_ids
    idea_ids=$(json_read_file "$IDEAS_FILE" ".ideas | keys[]" 2>/dev/null)
    
    for idea_id in $idea_ids; do
        [[ -z "$idea_id" ]] && continue
        
        local status added_at
        status=$(json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\".status")
        added_at=$(json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\".addedAt")
        
        # Only check backlog items
        [[ "$status" != "Backlog" ]] && continue
        
        if [[ -n "$added_at" ]]; then
            local added_epoch
            if [[ "$(uname)" == "Darwin" ]]; then
                added_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$added_at" +%s 2>/dev/null || echo 0)
            else
                added_epoch=$(date -d "$added_at" +%s 2>/dev/null || echo 0)
            fi
            
            local age_seconds=$((now_epoch - added_epoch))
            
            if [[ $age_seconds -ge $staleness_seconds ]]; then
                local idea
                idea=$(json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\".idea")
                echo "{\"ideaId\": \"$idea_id\", \"idea\": \"$idea\", \"addedAt\": \"$added_at\", \"ageDays\": $((age_seconds / 86400))}"
            fi
        fi
    done
}

# ============================================
# IDEA-TO-WORK MATCHING
# ============================================

# Check if current work matches a documented idea
idea_match_work() {
    local work_context="$1"
    
    local context_lower
    context_lower=$(echo "$work_context" | tr '[:upper:]' '[:lower:]')
    
    # Extract keywords from context
    local keywords
    keywords=$(echo "$context_lower" | tr -cs '[:alnum:]' ' ')
    
    # Check documented ideas in IDEAS.md
    if [[ -f "$IDEAS_MD" ]]; then
        for keyword in $keywords; do
            # Skip short words
            [[ ${#keyword} -lt 4 ]] && continue
            
            # Search for keyword in IDEAS.md
            local match
            match=$(grep -i "$keyword" "$IDEAS_MD" 2>/dev/null | head -1)
            
            if [[ -n "$match" ]]; then
                # Found a potential match - extract the idea header
                local idea_header
                idea_header=$(grep -B5 -i "$keyword" "$IDEAS_MD" 2>/dev/null | grep "^## " | tail -1)
                
                if [[ -n "$idea_header" ]]; then
                    local idea_name="${idea_header#\#\# }"
                    echo "{\"name\": \"$idea_name\", \"matchedKeyword\": \"$keyword\", \"source\": \"documented\"}"
                    return 0
                fi
            fi
        done
    fi
    
    # Check observed ideas
    _idea_ensure_file
    
    local idea_ids
    idea_ids=$(json_read_file "$IDEAS_FILE" ".ideas | keys[]" 2>/dev/null)
    
    for idea_id in $idea_ids; do
        [[ -z "$idea_id" ]] && continue
        
        local idea
        idea=$(json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\".idea")
        local idea_lower
        idea_lower=$(echo "$idea" | tr '[:upper:]' '[:lower:]')
        
        for keyword in $keywords; do
            [[ ${#keyword} -lt 4 ]] && continue
            
            if [[ "$idea_lower" == *"$keyword"* ]]; then
                echo "{\"ideaId\": \"$idea_id\", \"idea\": \"$idea\", \"matchedKeyword\": \"$keyword\", \"source\": \"observed\"}"
                return 0
            fi
        done
    done
    
    return 1
}

# ============================================
# STATUS MANAGEMENT
# ============================================

# Update idea status
idea_update_status() {
    local idea_id="$1"
    local new_status="$2"
    
    _idea_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    json_update_field "$IDEAS_FILE" ".ideas.\"$idea_id\".status" "\"$new_status\""
    json_update_field "$IDEAS_FILE" ".ideas.\"$idea_id\".lastUpdated" "\"$timestamp\""
    json_touch_file "$IDEAS_FILE"
}

# Mark idea as documented
idea_mark_documented() {
    local idea_id="$1"
    
    _idea_ensure_file
    
    json_update_field "$IDEAS_FILE" ".ideas.\"$idea_id\".documented" "true"
    json_touch_file "$IDEAS_FILE"
}

# ============================================
# UTILITY FUNCTIONS
# ============================================

# Get idea info by ID
idea_get_info() {
    local idea_id="$1"
    
    _idea_ensure_file
    
    json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\""
}

# Check if idea exists
idea_exists() {
    local idea_id="$1"
    
    _idea_ensure_file
    
    local existing
    existing=$(json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\"")
    
    [[ -n "$existing" ]] && [[ "$existing" != "null" ]]
}

# Get all pending ideas (not documented)
idea_get_pending() {
    _idea_ensure_file
    
    local idea_ids
    idea_ids=$(json_read_file "$IDEAS_FILE" ".ideas | keys[]" 2>/dev/null)
    
    for idea_id in $idea_ids; do
        [[ -z "$idea_id" ]] && continue
        
        local documented
        documented=$(json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\".documented")
        
        [[ "$documented" == "true" ]] && continue
        
        local idea category status
        idea=$(json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\".idea")
        category=$(json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\".category")
        status=$(json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\".status")
        
        echo "{\"ideaId\": \"$idea_id\", \"idea\": \"$idea\", \"category\": \"$category\", \"status\": \"$status\"}"
    done
}

# ============================================
# EXPORTS
# ============================================

export -f idea_generate_id
export -f idea_detect
export -f idea_record
export -f idea_get_stale
export -f idea_match_work
export -f idea_update_status
export -f idea_mark_documented
export -f idea_get_info
export -f idea_exists
export -f idea_get_pending
