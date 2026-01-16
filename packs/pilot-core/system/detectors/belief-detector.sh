#!/usr/bin/env bash
# belief-detector.sh - Belief detection for Adaptive Identity Capture
# Part of PILOT - Identifies consistent principles in user decisions
#
# Features:
# - Decision pattern tracking
# - Consistency detection (5+ occurrences)
# - Contradiction detection
# - Domain categorization
#
# Usage:
#   source belief-detector.sh
#   belief_record_decision "decision" "reasoning" "domain"
#   belief_get_suggestions
#   belief_check_contradiction "decision"

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
[[ -f "${LIB_DIR}/json-helpers.sh" ]] && source "${LIB_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
BELIEFS_FILE="${OBSERVATIONS_DIR}/beliefs.json"
IDENTITY_DIR="${PILOT_DATA}/identity"
BELIEFS_MD="${IDENTITY_DIR}/BELIEFS.md"

# Configuration
BELIEF_OCCURRENCE_THRESHOLD=5  # Consistent decisions before suggesting

# ============================================
# INITIALIZATION
# ============================================

_belief_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$BELIEFS_FILE" ]]; then
        cat > "$BELIEFS_FILE" 2>/dev/null << 'EOF'
{
  "beliefs": {},
  "decisions": [],
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# BELIEF ID GENERATION
# ============================================

# Generate a belief ID from pattern
belief_generate_id() {
    local pattern="$1"
    
    # Normalize (lowercase, first 50 chars)
    local normalized
    normalized=$(echo "$pattern" | tr '[:upper:]' '[:lower:]' | head -c 50)
    
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
# DOMAIN DETECTION
# ============================================

# Detect domain from decision/reasoning text
belief_detect_domain() {
    local text="$1"
    
    local text_lower
    text_lower=$(echo "$text" | tr '[:upper:]' '[:lower:]')
    
    # Domain keywords
    local code_quality_keywords="clean readable maintainable test coverage lint format"
    local architecture_keywords="pattern design structure layer module component"
    local process_keywords="workflow agile sprint review deploy release"
    local tools_keywords="editor ide terminal cli tool framework"
    local collaboration_keywords="team review pair communicate document"
    local performance_keywords="fast optimize cache efficient scale"
    local security_keywords="secure auth encrypt validate sanitize"
    
    local best_domain="general"
    local best_score=0
    
    # Check code_quality
    local score=0
    for keyword in $code_quality_keywords; do
        [[ "$text_lower" == *"$keyword"* ]] && score=$((score + 1))
    done
    if [[ $score -gt $best_score ]]; then
        best_score=$score
        best_domain="code_quality"
    fi
    
    # Check architecture
    score=0
    for keyword in $architecture_keywords; do
        [[ "$text_lower" == *"$keyword"* ]] && score=$((score + 1))
    done
    if [[ $score -gt $best_score ]]; then
        best_score=$score
        best_domain="architecture"
    fi
    
    # Check process
    score=0
    for keyword in $process_keywords; do
        [[ "$text_lower" == *"$keyword"* ]] && score=$((score + 1))
    done
    if [[ $score -gt $best_score ]]; then
        best_score=$score
        best_domain="process"
    fi
    
    # Check tools
    score=0
    for keyword in $tools_keywords; do
        [[ "$text_lower" == *"$keyword"* ]] && score=$((score + 1))
    done
    if [[ $score -gt $best_score ]]; then
        best_score=$score
        best_domain="tools"
    fi
    
    # Check collaboration
    score=0
    for keyword in $collaboration_keywords; do
        [[ "$text_lower" == *"$keyword"* ]] && score=$((score + 1))
    done
    if [[ $score -gt $best_score ]]; then
        best_score=$score
        best_domain="collaboration"
    fi
    
    # Check performance
    score=0
    for keyword in $performance_keywords; do
        [[ "$text_lower" == *"$keyword"* ]] && score=$((score + 1))
    done
    if [[ $score -gt $best_score ]]; then
        best_score=$score
        best_domain="performance"
    fi
    
    # Check security
    score=0
    for keyword in $security_keywords; do
        [[ "$text_lower" == *"$keyword"* ]] && score=$((score + 1))
    done
    if [[ $score -gt $best_score ]]; then
        best_score=$score
        best_domain="security"
    fi
    
    echo "$best_domain"
}

# ============================================
# DECISION RECORDING
# ============================================

# Record a decision and its reasoning
belief_record_decision() {
    local decision="$1"
    local reasoning="${2:-}"
    local domain="${3:-}"
    
    _belief_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Auto-detect domain if not provided
    if [[ -z "$domain" ]]; then
        domain=$(belief_detect_domain "$decision $reasoning")
    fi
    
    # Record decision
    local decision_record="{\"decision\": \"$decision\", \"reasoning\": \"$reasoning\", \"domain\": \"$domain\", \"timestamp\": \"$timestamp\"}"
    json_array_append "$BELIEFS_FILE" ".decisions" "$decision_record"
    
    # Trim to last 100 decisions
    local decision_count
    decision_count=$(json_array_length "$BELIEFS_FILE" ".decisions")
    while [[ $decision_count -gt 100 ]]; do
        json_array_remove "$BELIEFS_FILE" ".decisions" 0
        decision_count=$((decision_count - 1))
    done
    
    # Extract pattern from reasoning (simplified - use first sentence or key phrase)
    local pattern="$reasoning"
    if [[ -z "$pattern" ]]; then
        pattern="$decision"
    fi
    
    # Generate belief ID from pattern
    local belief_id
    belief_id=$(belief_generate_id "$pattern")
    
    # Get existing belief data
    local existing
    existing=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
        # Create new belief entry
        local new_belief="{
            \"beliefId\": \"$belief_id\",
            \"pattern\": \"$pattern\",
            \"domain\": \"$domain\",
            \"supportingDecisions\": [\"$decision\"],
            \"occurrences\": 1,
            \"firstSeen\": \"$timestamp\",
            \"lastSeen\": \"$timestamp\",
            \"status\": \"pending\",
            \"documented\": false
        }"
        
        json_set_nested "$BELIEFS_FILE" ".beliefs.\"$belief_id\"" "$new_belief"
    else
        # Update existing belief
        local current_count
        current_count=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".occurrences")
        current_count=${current_count:-0}
        
        json_update_field "$BELIEFS_FILE" ".beliefs.\"$belief_id\".occurrences" "$((current_count + 1))"
        json_update_field "$BELIEFS_FILE" ".beliefs.\"$belief_id\".lastSeen" "\"$timestamp\""
        
        # Add to supporting decisions (keep last 5)
        json_array_append "$BELIEFS_FILE" ".beliefs.\"$belief_id\".supportingDecisions" "\"$decision\""
        
        local support_count
        support_count=$(json_array_length "$BELIEFS_FILE" ".beliefs.\"$belief_id\".supportingDecisions")
        while [[ $support_count -gt 5 ]]; do
            json_array_remove "$BELIEFS_FILE" ".beliefs.\"$belief_id\".supportingDecisions" 0
            support_count=$((support_count - 1))
        done
    fi
    
    json_touch_file "$BELIEFS_FILE"
}

# ============================================
# SUGGESTION LOGIC
# ============================================

# Get beliefs that meet suggestion threshold
belief_get_suggestions() {
    _belief_ensure_file
    
    # Get all belief IDs
    local belief_ids
    belief_ids=$(json_read_file "$BELIEFS_FILE" ".beliefs | keys[]" 2>/dev/null)
    
    for belief_id in $belief_ids; do
        [[ -z "$belief_id" ]] && continue
        
        local occurrences documented status
        occurrences=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".occurrences")
        documented=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".documented")
        status=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".status")
        
        occurrences=${occurrences:-0}
        
        # Skip if already documented
        [[ "$documented" == "true" ]] && continue
        
        # Skip if below threshold
        [[ $occurrences -lt $BELIEF_OCCURRENCE_THRESHOLD ]] && continue
        
        # Get belief details
        local pattern domain
        pattern=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".pattern")
        domain=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".domain")
        
        echo "{\"beliefId\": \"$belief_id\", \"pattern\": \"$pattern\", \"domain\": \"$domain\", \"occurrences\": $occurrences}"
    done
}

# ============================================
# CONTRADICTION DETECTION
# ============================================

# Check if a decision contradicts a documented belief
belief_check_contradiction() {
    local decision="$1"
    
    local decision_lower
    decision_lower=$(echo "$decision" | tr '[:upper:]' '[:lower:]')
    
    # Check documented beliefs in BELIEFS.md
    if [[ -f "$BELIEFS_MD" ]]; then
        # Look for contradiction indicators
        local contradiction_words=("never" "always" "must" "should not" "avoid" "prefer")
        
        for word in "${contradiction_words[@]}"; do
            if [[ "$decision_lower" == *"$word"* ]]; then
                # Check if there's a belief about the opposite
                local opposite=""
                case "$word" in
                    "never") opposite="always" ;;
                    "always") opposite="never" ;;
                    "must") opposite="avoid" ;;
                    "avoid") opposite="prefer" ;;
                    "prefer") opposite="avoid" ;;
                esac
                
                if [[ -n "$opposite" ]]; then
                    # Extract the subject of the decision
                    local subject
                    subject=$(echo "$decision_lower" | sed "s/.*$word //" | head -c 30)
                    
                    # Search for contradicting belief
                    if grep -qi "$opposite.*$subject\|$subject.*$opposite" "$BELIEFS_MD" 2>/dev/null; then
                        local belief_line
                        belief_line=$(grep -i "$opposite.*$subject\|$subject.*$opposite" "$BELIEFS_MD" 2>/dev/null | head -1)
                        
                        echo "{\"contradiction\": \"$decision\", \"existingBelief\": \"$belief_line\", \"source\": \"documented\"}"
                        return 0
                    fi
                fi
            fi
        done
    fi
    
    # Check observed beliefs
    _belief_ensure_file
    
    local belief_ids
    belief_ids=$(json_read_file "$BELIEFS_FILE" ".beliefs | keys[]" 2>/dev/null)
    
    for belief_id in $belief_ids; do
        [[ -z "$belief_id" ]] && continue
        
        local pattern occurrences
        pattern=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".pattern")
        occurrences=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".occurrences")
        
        occurrences=${occurrences:-0}
        
        # Only check established beliefs (3+ occurrences)
        [[ $occurrences -lt 3 ]] && continue
        
        local pattern_lower
        pattern_lower=$(echo "$pattern" | tr '[:upper:]' '[:lower:]')
        
        # Simple contradiction check - look for negation patterns
        if [[ "$decision_lower" == *"not"* ]] && [[ "$pattern_lower" != *"not"* ]]; then
            # Decision has negation, pattern doesn't
            local decision_subject
            decision_subject=$(echo "$decision_lower" | sed 's/.*not //' | head -c 20)
            
            if [[ "$pattern_lower" == *"$decision_subject"* ]]; then
                echo "{\"beliefId\": \"$belief_id\", \"contradiction\": \"$decision\", \"existingPattern\": \"$pattern\", \"source\": \"observed\"}"
                return 0
            fi
        fi
    done
    
    return 1
}

# ============================================
# STATUS MANAGEMENT
# ============================================

# Mark belief as documented
belief_mark_documented() {
    local belief_id="$1"
    
    _belief_ensure_file
    
    json_update_field "$BELIEFS_FILE" ".beliefs.\"$belief_id\".documented" "true"
    json_update_field "$BELIEFS_FILE" ".beliefs.\"$belief_id\".status" "\"documented\""
    json_touch_file "$BELIEFS_FILE"
}

# ============================================
# UTILITY FUNCTIONS
# ============================================

# Get belief info by ID
belief_get_info() {
    local belief_id="$1"
    
    _belief_ensure_file
    
    json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\""
}

# Check if belief exists
belief_exists() {
    local belief_id="$1"
    
    _belief_ensure_file
    
    local existing
    existing=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\"")
    
    [[ -n "$existing" ]] && [[ "$existing" != "null" ]]
}

# Get beliefs by domain
belief_get_by_domain() {
    local target_domain="$1"
    
    _belief_ensure_file
    
    local belief_ids
    belief_ids=$(json_read_file "$BELIEFS_FILE" ".beliefs | keys[]" 2>/dev/null)
    
    for belief_id in $belief_ids; do
        [[ -z "$belief_id" ]] && continue
        
        local domain
        domain=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".domain")
        
        if [[ "$domain" == "$target_domain" ]]; then
            local pattern occurrences
            pattern=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".pattern")
            occurrences=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".occurrences")
            
            echo "{\"beliefId\": \"$belief_id\", \"pattern\": \"$pattern\", \"occurrences\": ${occurrences:-0}}"
        fi
    done
}

# ============================================
# EXPORTS
# ============================================

export -f belief_generate_id
export -f belief_detect_domain
export -f belief_record_decision
export -f belief_get_suggestions
export -f belief_check_contradiction
export -f belief_mark_documented
export -f belief_get_info
export -f belief_exists
export -f belief_get_by_domain
