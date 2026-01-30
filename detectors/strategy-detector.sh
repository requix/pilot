#!/usr/bin/env bash
# strategy-detector.sh - Strategy detection for Adaptive Identity Capture
# Part of PILOT - Identifies repeatable problem-solving approaches
#
# Features:
# - Approach pattern tracking
# - Step similarity detection
# - Strategy matching for current problems
# - Failure tracking
#
# Usage:
#   source strategy-detector.sh
#   strategy_record_approach "problem_type" "step1|step2|step3"
#   strategy_get_suggestions
#   strategy_find_matching "problem_type"
#   strategy_record_failure "$strategy_id" "context"

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
[[ -f "${LIB_DIR}/json-helpers.sh" ]] && source "${LIB_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
STRATEGIES_FILE="${OBSERVATIONS_DIR}/strategies.json"
IDENTITY_DIR="${PILOT_DATA}/identity"
STRATEGIES_MD="${IDENTITY_DIR}/STRATEGIES.md"

# Configuration
STRATEGY_OCCURRENCE_THRESHOLD=3   # Similar approaches before suggesting
STRATEGY_STEP_SIMILARITY=0.6      # 60% step overlap for similarity

# ============================================
# INITIALIZATION
# ============================================

_strategy_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$STRATEGIES_FILE" ]]; then
        cat > "$STRATEGIES_FILE" 2>/dev/null << 'EOF'
{
  "strategies": {},
  "approaches": [],
  "failures": [],
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# STRATEGY ID GENERATION
# ============================================

# Generate a strategy ID from problem type
strategy_generate_id() {
    local problem_type="$1"
    
    # Normalize (lowercase, first 50 chars)
    local normalized
    normalized=$(echo "$problem_type" | tr '[:upper:]' '[:lower:]' | head -c 50)
    
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
# APPROACH RECORDING
# ============================================

# Record a problem-solving approach
# Steps should be pipe-separated: "step1|step2|step3"
strategy_record_approach() {
    local problem_type="$1"
    local steps="$2"
    local success="${3:-true}"
    
    _strategy_ensure_file
    
    local strategy_id
    strategy_id=$(strategy_generate_id "$problem_type")
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Convert steps to array format
    local steps_json="["
    local first=true
    IFS='|' read -ra step_array <<< "$steps"
    for step in "${step_array[@]}"; do
        [[ -z "$step" ]] && continue
        if [[ "$first" == "true" ]]; then
            steps_json+="\"$step\""
            first=false
        else
            steps_json+=", \"$step\""
        fi
    done
    steps_json+="]"
    
    # Record approach
    local approach_record="{\"problemType\": \"$problem_type\", \"steps\": $steps_json, \"success\": $success, \"timestamp\": \"$timestamp\"}"
    json_array_append "$STRATEGIES_FILE" ".approaches" "$approach_record"
    
    # Trim to last 100 approaches
    local approach_count
    approach_count=$(json_array_length "$STRATEGIES_FILE" ".approaches")
    while [[ $approach_count -gt 100 ]]; do
        json_array_remove "$STRATEGIES_FILE" ".approaches" 0
        approach_count=$((approach_count - 1))
    done
    
    # Get existing strategy data
    local existing
    existing=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
        # Create new strategy entry
        local new_strategy="{
            \"strategyId\": \"$strategy_id\",
            \"problemType\": \"$problem_type\",
            \"commonSteps\": $steps_json,
            \"occurrences\": 1,
            \"successCount\": $([ "$success" == "true" ] && echo 1 || echo 0),
            \"failureCount\": $([ "$success" == "false" ] && echo 1 || echo 0),
            \"firstSeen\": \"$timestamp\",
            \"lastSeen\": \"$timestamp\",
            \"status\": \"pending\",
            \"documented\": false
        }"
        
        json_set_nested "$STRATEGIES_FILE" ".strategies.\"$strategy_id\"" "$new_strategy"
    else
        # Update existing strategy
        local current_count success_count failure_count
        current_count=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".occurrences")
        success_count=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".successCount")
        failure_count=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".failureCount")
        
        current_count=${current_count:-0}
        success_count=${success_count:-0}
        failure_count=${failure_count:-0}
        
        json_update_field "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".occurrences" "$((current_count + 1))"
        json_update_field "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".lastSeen" "\"$timestamp\""
        
        if [[ "$success" == "true" ]]; then
            json_update_field "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".successCount" "$((success_count + 1))"
        else
            json_update_field "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".failureCount" "$((failure_count + 1))"
        fi
        
        # Update common steps (merge with existing)
        # For simplicity, keep the most recent steps
        json_update_field "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".commonSteps" "$steps_json"
    fi
    
    json_touch_file "$STRATEGIES_FILE"
}

# ============================================
# SUGGESTION LOGIC
# ============================================

# Get strategies that meet suggestion threshold
strategy_get_suggestions() {
    _strategy_ensure_file
    
    # Get all strategy IDs
    local strategy_ids
    strategy_ids=$(json_read_file "$STRATEGIES_FILE" ".strategies | keys[]" 2>/dev/null)
    
    for strategy_id in $strategy_ids; do
        [[ -z "$strategy_id" ]] && continue
        
        local occurrences documented status
        occurrences=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".occurrences")
        documented=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".documented")
        status=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".status")
        
        occurrences=${occurrences:-0}
        
        # Skip if already documented
        [[ "$documented" == "true" ]] && continue
        
        # Skip if below threshold
        [[ $occurrences -lt $STRATEGY_OCCURRENCE_THRESHOLD ]] && continue
        
        # Get strategy details
        local problem_type success_count failure_count
        problem_type=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".problemType")
        success_count=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".successCount")
        failure_count=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".failureCount")
        
        echo "{\"strategyId\": \"$strategy_id\", \"problemType\": \"$problem_type\", \"occurrences\": $occurrences, \"successCount\": ${success_count:-0}, \"failureCount\": ${failure_count:-0}}"
    done
}

# ============================================
# STRATEGY MATCHING
# ============================================

# Find matching strategy for a problem type
strategy_find_matching() {
    local problem_type="$1"
    
    # First check documented strategies in STRATEGIES.md
    if [[ -f "$STRATEGIES_MD" ]]; then
        local problem_lower
        problem_lower=$(echo "$problem_type" | tr '[:upper:]' '[:lower:]')
        
        # Search for matching strategy
        if grep -qi "$problem_lower" "$STRATEGIES_MD" 2>/dev/null; then
            # Extract strategy name from header
            local strategy_header
            strategy_header=$(grep -B5 -i "$problem_lower" "$STRATEGIES_MD" 2>/dev/null | grep "^## " | tail -1)
            
            if [[ -n "$strategy_header" ]]; then
                local strategy_name="${strategy_header#\#\# }"
                echo "{\"name\": \"$strategy_name\", \"source\": \"documented\"}"
                return 0
            fi
        fi
    fi
    
    # Check observed strategies
    _strategy_ensure_file
    
    local strategy_id
    strategy_id=$(strategy_generate_id "$problem_type")
    
    local existing
    existing=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\"")
    
    if [[ -n "$existing" ]] && [[ "$existing" != "null" ]]; then
        local occurrences
        occurrences=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".occurrences")
        occurrences=${occurrences:-0}
        
        if [[ $occurrences -ge 2 ]]; then
            echo "{\"strategyId\": \"$strategy_id\", \"problemType\": \"$problem_type\", \"occurrences\": $occurrences, \"source\": \"observed\"}"
            return 0
        fi
    fi
    
    return 1
}

# ============================================
# FAILURE TRACKING
# ============================================

# Record strategy failure for "when it doesn't work" updates
strategy_record_failure() {
    local strategy_id="$1"
    local context="${2:-}"
    
    _strategy_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Record failure
    local failure_record="{\"strategyId\": \"$strategy_id\", \"context\": \"$context\", \"timestamp\": \"$timestamp\"}"
    json_array_append "$STRATEGIES_FILE" ".failures" "$failure_record"
    
    # Update failure count
    local failure_count
    failure_count=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".failureCount")
    failure_count=${failure_count:-0}
    
    json_update_field "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".failureCount" "$((failure_count + 1))"
    json_touch_file "$STRATEGIES_FILE"
}

# ============================================
# STATUS MANAGEMENT
# ============================================

# Mark strategy as documented
strategy_mark_documented() {
    local strategy_id="$1"
    
    _strategy_ensure_file
    
    json_update_field "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".documented" "true"
    json_update_field "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".status" "\"documented\""
    json_touch_file "$STRATEGIES_FILE"
}

# ============================================
# UTILITY FUNCTIONS
# ============================================

# Get strategy info by ID
strategy_get_info() {
    local strategy_id="$1"
    
    _strategy_ensure_file
    
    json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\""
}

# Check if strategy exists
strategy_exists() {
    local strategy_id="$1"
    
    _strategy_ensure_file
    
    local existing
    existing=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\"")
    
    [[ -n "$existing" ]] && [[ "$existing" != "null" ]]
}

# ============================================
# EXPORTS
# ============================================

export -f strategy_generate_id
export -f strategy_record_approach
export -f strategy_get_suggestions
export -f strategy_find_matching
export -f strategy_record_failure
export -f strategy_mark_documented
export -f strategy_get_info
export -f strategy_exists
