#!/usr/bin/env bash
# challenge-detector.sh - Challenge detection for Adaptive Identity Capture
# Part of PILOT - Identifies recurring problems or blockers
#
# Features:
# - Error/blocker pattern tracking
# - Occurrence counting (3+ threshold)
# - Resolution detection (14 days inactive)
#
# Usage:
#   source challenge-detector.sh
#   challenge_record_blocker "type" "context"
#   challenge_get_suggestions
#   challenge_get_resolved

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
[[ -f "${LIB_DIR}/json-helpers.sh" ]] && source "${LIB_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
CHALLENGES_FILE="${OBSERVATIONS_DIR}/challenges.json"

# Configuration
CHALLENGE_OCCURRENCE_THRESHOLD=3   # Occurrences before suggesting
CHALLENGE_RESOLUTION_DAYS=14       # Days inactive to consider resolved

# ============================================
# INITIALIZATION
# ============================================

_challenge_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$CHALLENGES_FILE" ]]; then
        cat > "$CHALLENGES_FILE" 2>/dev/null << 'EOF'
{
  "challenges": {},
  "resolved": [],
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# CHALLENGE ID GENERATION
# ============================================

# Generate a challenge ID from type/pattern
challenge_generate_id() {
    local type="$1"
    
    # Normalize type (lowercase, replace spaces with dashes)
    local normalized
    normalized=$(echo "$type" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    
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
# BLOCKER RECORDING
# ============================================

# Record an error or blocker occurrence
challenge_record_blocker() {
    local type="$1"
    local context="${2:-}"
    
    _challenge_ensure_file
    
    local challenge_id
    challenge_id=$(challenge_generate_id "$type")
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Get existing challenge data
    local existing
    existing=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
        # Create new challenge entry
        local new_challenge="{
            \"challengeId\": \"$challenge_id\",
            \"pattern\": \"$type\",
            \"occurrences\": 1,
            \"contexts\": [\"$context\"],
            \"firstSeen\": \"$timestamp\",
            \"lastSeen\": \"$timestamp\",
            \"status\": \"pending\",
            \"documented\": false
        }"
        
        json_set_nested "$CHALLENGES_FILE" ".challenges.\"$challenge_id\"" "$new_challenge"
    else
        # Update existing challenge
        local current_count
        current_count=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".occurrences")
        current_count=${current_count:-0}
        
        # Update occurrence count
        json_update_field "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".occurrences" "$((current_count + 1))"
        json_update_field "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".lastSeen" "\"$timestamp\""
        
        # Add context to array (keep last 5)
        if [[ -n "$context" ]]; then
            json_array_append "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".contexts" "\"$context\""
            
            # Trim to last 5 contexts
            local context_count
            context_count=$(json_array_length "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".contexts")
            while [[ $context_count -gt 5 ]]; do
                json_array_remove "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".contexts" 0
                context_count=$((context_count - 1))
            done
        fi
    fi
    
    json_touch_file "$CHALLENGES_FILE"
}

# ============================================
# SUGGESTION LOGIC
# ============================================

# Get challenges that meet suggestion threshold
challenge_get_suggestions() {
    _challenge_ensure_file
    
    # Get all challenge IDs
    local challenge_ids
    challenge_ids=$(json_read_file "$CHALLENGES_FILE" ".challenges | keys[]" 2>/dev/null)
    
    for challenge_id in $challenge_ids; do
        [[ -z "$challenge_id" ]] && continue
        
        local occurrences documented status
        occurrences=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".occurrences")
        documented=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".documented")
        status=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".status")
        
        occurrences=${occurrences:-0}
        
        # Skip if already documented
        [[ "$documented" == "true" ]] && continue
        
        # Skip if resolved
        [[ "$status" == "resolved" ]] && continue
        
        # Skip if below threshold
        [[ $occurrences -lt $CHALLENGE_OCCURRENCE_THRESHOLD ]] && continue
        
        # Get challenge details
        local pattern first_seen last_seen
        pattern=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".pattern")
        first_seen=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".firstSeen")
        last_seen=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".lastSeen")
        
        echo "{\"challengeId\": \"$challenge_id\", \"pattern\": \"$pattern\", \"occurrences\": $occurrences, \"firstSeen\": \"$first_seen\", \"lastSeen\": \"$last_seen\"}"
    done
}

# Check if a specific challenge should be suggested
challenge_should_suggest() {
    local challenge_id="$1"
    
    _challenge_ensure_file
    
    local occurrences documented status
    occurrences=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".occurrences")
    documented=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".documented")
    status=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".status")
    
    occurrences=${occurrences:-0}
    
    # Already documented
    [[ "$documented" == "true" ]] && return 1
    
    # Resolved
    [[ "$status" == "resolved" ]] && return 1
    
    # Below threshold
    [[ $occurrences -lt $CHALLENGE_OCCURRENCE_THRESHOLD ]] && return 1
    
    return 0
}

# ============================================
# RESOLUTION DETECTION
# ============================================

# Get challenges that appear resolved (no occurrences for 14+ days)
challenge_get_resolved() {
    _challenge_ensure_file
    
    local now_epoch
    now_epoch=$(date +%s)
    
    local resolution_seconds=$((CHALLENGE_RESOLUTION_DAYS * 24 * 60 * 60))
    
    # Get all challenge IDs
    local challenge_ids
    challenge_ids=$(json_read_file "$CHALLENGES_FILE" ".challenges | keys[]" 2>/dev/null)
    
    for challenge_id in $challenge_ids; do
        [[ -z "$challenge_id" ]] && continue
        
        local status last_seen occurrences
        status=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".status")
        last_seen=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".lastSeen")
        occurrences=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".occurrences")
        
        occurrences=${occurrences:-0}
        
        # Skip if already resolved or not active
        [[ "$status" == "resolved" ]] && continue
        [[ $occurrences -lt $CHALLENGE_OCCURRENCE_THRESHOLD ]] && continue
        
        # Check if inactive for resolution period
        if [[ -n "$last_seen" ]]; then
            local last_seen_epoch
            if [[ "$(uname)" == "Darwin" ]]; then
                last_seen_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_seen" +%s 2>/dev/null || echo 0)
            else
                last_seen_epoch=$(date -d "$last_seen" +%s 2>/dev/null || echo 0)
            fi
            
            local inactive_seconds=$((now_epoch - last_seen_epoch))
            
            if [[ $inactive_seconds -ge $resolution_seconds ]]; then
                local pattern
                pattern=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".pattern")
                echo "{\"challengeId\": \"$challenge_id\", \"pattern\": \"$pattern\", \"lastSeen\": \"$last_seen\", \"inactiveDays\": $((inactive_seconds / 86400))}"
            fi
        fi
    done
}

# ============================================
# STATUS MANAGEMENT
# ============================================

# Mark challenge as documented
challenge_mark_documented() {
    local challenge_id="$1"
    
    _challenge_ensure_file
    
    json_update_field "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".documented" "true"
    json_update_field "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".status" "\"documented\""
    json_touch_file "$CHALLENGES_FILE"
}

# Mark challenge as resolved
challenge_mark_resolved() {
    local challenge_id="$1"
    
    _challenge_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    json_update_field "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".status" "\"resolved\""
    json_update_field "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".resolvedAt" "\"$timestamp\""
    
    # Add to resolved list
    local pattern
    pattern=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".pattern")
    local resolved_record="{\"challengeId\": \"$challenge_id\", \"pattern\": \"$pattern\", \"resolvedAt\": \"$timestamp\"}"
    json_array_append "$CHALLENGES_FILE" ".resolved" "$resolved_record"
    
    json_touch_file "$CHALLENGES_FILE"
}

# ============================================
# UTILITY FUNCTIONS
# ============================================

# Get challenge info by ID
challenge_get_info() {
    local challenge_id="$1"
    
    _challenge_ensure_file
    
    json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\""
}

# Check if challenge exists
challenge_exists() {
    local challenge_id="$1"
    
    _challenge_ensure_file
    
    local existing
    existing=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\"")
    
    [[ -n "$existing" ]] && [[ "$existing" != "null" ]]
}

# Get occurrence count for challenge
challenge_get_occurrence_count() {
    local challenge_id="$1"
    
    _challenge_ensure_file
    
    local count
    count=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".occurrences")
    echo "${count:-0}"
}

# ============================================
# EXPORTS
# ============================================

export -f challenge_generate_id
export -f challenge_record_blocker
export -f challenge_get_suggestions
export -f challenge_should_suggest
export -f challenge_get_resolved
export -f challenge_mark_documented
export -f challenge_mark_resolved
export -f challenge_get_info
export -f challenge_exists
export -f challenge_get_occurrence_count
