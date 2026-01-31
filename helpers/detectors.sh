#!/usr/bin/env bash
# detectors.sh - All detectors for PILOT
# Part of PILOT - Personal Intelligence Layer for Optimized Tasks
# Location: src/helpers/detectors.sh (consolidated from 8 detector files)
#
# Combines all detector functionality with shared base functions.
#
# Usage:
#   source detectors.sh
#   belief_record_decision "Always use TypeScript" "code-quality"
#   challenge_record_blocker "Memory leak in production"
#   idea_record "Build a CLI tool"

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/json.sh" ]] && source "${SCRIPT_DIR}/json.sh"

# Directories
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
IDENTITY_DIR="${PILOT_DATA}/identity"

# ============================================
# SHARED BASE FUNCTIONS
# ============================================

# Generate ID from text (used by all detectors)
_detector_generate_id() {
    local text="$1"
    local normalized
    normalized=$(echo "$text" | tr '[:upper:]' '[:lower:]' | head -c 50)
    
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

# Ensure observation file exists with default structure
_detector_ensure_file() {
    local file="$1"
    local default_content="$2"
    
    mkdir -p "$(dirname "$file")" 2>/dev/null || true
    
    if [[ ! -f "$file" ]]; then
        echo "$default_content" > "$file" 2>/dev/null
    fi
}

# Get timestamp in ISO format
_detector_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}


# ============================================
# BELIEF DETECTOR
# ============================================

BELIEFS_FILE="${OBSERVATIONS_DIR}/beliefs.json"
BELIEFS_MD="${IDENTITY_DIR}/BELIEFS.md"
BELIEF_OCCURRENCE_THRESHOLD=5

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

belief_generate_id() {
    _detector_generate_id "$1"
}

belief_detect_domain() {
    local text="$1"
    local text_lower
    text_lower=$(echo "$text" | tr '[:upper:]' '[:lower:]')
    
    local code_quality_keywords="clean readable maintainable test coverage lint format"
    local architecture_keywords="pattern design structure layer module component"
    local process_keywords="workflow agile sprint review deploy release"
    local tools_keywords="editor ide terminal cli tool framework"
    local collaboration_keywords="team review pair communicate document"
    local performance_keywords="fast optimize cache efficient scale"
    local security_keywords="secure auth encrypt validate sanitize"
    
    local best_domain="general"
    local best_score=0
    
    local score=0
    for keyword in $code_quality_keywords; do
        [[ "$text_lower" == *"$keyword"* ]] && score=$((score + 1))
    done
    if [[ $score -gt $best_score ]]; then best_score=$score; best_domain="code_quality"; fi
    
    score=0
    for keyword in $architecture_keywords; do
        [[ "$text_lower" == *"$keyword"* ]] && score=$((score + 1))
    done
    if [[ $score -gt $best_score ]]; then best_score=$score; best_domain="architecture"; fi
    
    score=0
    for keyword in $process_keywords; do
        [[ "$text_lower" == *"$keyword"* ]] && score=$((score + 1))
    done
    if [[ $score -gt $best_score ]]; then best_score=$score; best_domain="process"; fi
    
    score=0
    for keyword in $tools_keywords; do
        [[ "$text_lower" == *"$keyword"* ]] && score=$((score + 1))
    done
    if [[ $score -gt $best_score ]]; then best_score=$score; best_domain="tools"; fi
    
    score=0
    for keyword in $collaboration_keywords; do
        [[ "$text_lower" == *"$keyword"* ]] && score=$((score + 1))
    done
    if [[ $score -gt $best_score ]]; then best_score=$score; best_domain="collaboration"; fi
    
    score=0
    for keyword in $performance_keywords; do
        [[ "$text_lower" == *"$keyword"* ]] && score=$((score + 1))
    done
    if [[ $score -gt $best_score ]]; then best_score=$score; best_domain="performance"; fi
    
    score=0
    for keyword in $security_keywords; do
        [[ "$text_lower" == *"$keyword"* ]] && score=$((score + 1))
    done
    if [[ $score -gt $best_score ]]; then best_score=$score; best_domain="security"; fi
    
    echo "$best_domain"
}

belief_record_decision() {
    local decision="$1"
    local reasoning="${2:-}"
    local domain="${3:-}"
    
    _belief_ensure_file
    
    local timestamp
    timestamp=$(_detector_timestamp)
    
    if [[ -z "$domain" ]]; then
        domain=$(belief_detect_domain "$decision $reasoning")
    fi
    
    local decision_record="{\"decision\": \"$decision\", \"reasoning\": \"$reasoning\", \"domain\": \"$domain\", \"timestamp\": \"$timestamp\"}"
    json_array_append "$BELIEFS_FILE" ".decisions" "$decision_record"
    
    local decision_count
    decision_count=$(json_array_length "$BELIEFS_FILE" ".decisions")
    while [[ $decision_count -gt 100 ]]; do
        json_array_remove "$BELIEFS_FILE" ".decisions" 0
        decision_count=$((decision_count - 1))
    done
    
    local pattern="$reasoning"
    [[ -z "$pattern" ]] && pattern="$decision"
    
    local belief_id
    belief_id=$(belief_generate_id "$pattern")
    
    local existing
    existing=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
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
        local current_count
        current_count=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".occurrences")
        current_count=${current_count:-0}
        
        json_update_field "$BELIEFS_FILE" ".beliefs.\"$belief_id\".occurrences" "$((current_count + 1))"
        json_update_field "$BELIEFS_FILE" ".beliefs.\"$belief_id\".lastSeen" "\"$timestamp\""
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

belief_get_suggestions() {
    _belief_ensure_file
    
    local belief_ids
    belief_ids=$(json_read_file "$BELIEFS_FILE" ".beliefs | keys[]" 2>/dev/null)
    
    for belief_id in $belief_ids; do
        [[ -z "$belief_id" ]] && continue
        
        local occurrences documented
        occurrences=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".occurrences")
        documented=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".documented")
        
        occurrences=${occurrences:-0}
        
        [[ "$documented" == "true" ]] && continue
        [[ $occurrences -lt $BELIEF_OCCURRENCE_THRESHOLD ]] && continue
        
        local pattern domain
        pattern=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".pattern")
        domain=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\".domain")
        
        echo "{\"beliefId\": \"$belief_id\", \"pattern\": \"$pattern\", \"domain\": \"$domain\", \"occurrences\": $occurrences}"
    done
}

belief_check_contradiction() {
    local decision="$1"
    local decision_lower
    decision_lower=$(echo "$decision" | tr '[:upper:]' '[:lower:]')
    
    if [[ -f "$BELIEFS_MD" ]]; then
        local contradiction_words=("never" "always" "must" "should not" "avoid" "prefer")
        
        for word in "${contradiction_words[@]}"; do
            if [[ "$decision_lower" == *"$word"* ]]; then
                local opposite=""
                case "$word" in
                    "never") opposite="always" ;;
                    "always") opposite="never" ;;
                    "must") opposite="avoid" ;;
                    "avoid") opposite="prefer" ;;
                    "prefer") opposite="avoid" ;;
                esac
                
                if [[ -n "$opposite" ]]; then
                    local subject
                    subject=$(echo "$decision_lower" | sed "s/.*$word //" | head -c 30)
                    
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
    
    return 1
}

belief_mark_documented() {
    local belief_id="$1"
    _belief_ensure_file
    json_update_field "$BELIEFS_FILE" ".beliefs.\"$belief_id\".documented" "true"
    json_update_field "$BELIEFS_FILE" ".beliefs.\"$belief_id\".status" "\"documented\""
    json_touch_file "$BELIEFS_FILE"
}

belief_get_info() {
    local belief_id="$1"
    _belief_ensure_file
    json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\""
}

belief_exists() {
    local belief_id="$1"
    _belief_ensure_file
    local existing
    existing=$(json_read_file "$BELIEFS_FILE" ".beliefs.\"$belief_id\"")
    [[ -n "$existing" ]] && [[ "$existing" != "null" ]]
}

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
# CHALLENGE DETECTOR
# ============================================

CHALLENGES_FILE="${OBSERVATIONS_DIR}/challenges.json"
CHALLENGE_OCCURRENCE_THRESHOLD=3
CHALLENGE_RESOLUTION_DAYS=14

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

challenge_generate_id() {
    local type="$1"
    local normalized
    normalized=$(echo "$type" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    _detector_generate_id "$normalized"
}

challenge_record_blocker() {
    local type="$1"
    local context="${2:-}"
    
    _challenge_ensure_file
    
    local challenge_id
    challenge_id=$(challenge_generate_id "$type")
    
    local timestamp
    timestamp=$(_detector_timestamp)
    
    local existing
    existing=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
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
        local current_count
        current_count=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".occurrences")
        current_count=${current_count:-0}
        
        json_update_field "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".occurrences" "$((current_count + 1))"
        json_update_field "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".lastSeen" "\"$timestamp\""
        
        if [[ -n "$context" ]]; then
            json_array_append "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".contexts" "\"$context\""
            
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

challenge_get_suggestions() {
    _challenge_ensure_file
    
    local challenge_ids
    challenge_ids=$(json_read_file "$CHALLENGES_FILE" ".challenges | keys[]" 2>/dev/null)
    
    for challenge_id in $challenge_ids; do
        [[ -z "$challenge_id" ]] && continue
        
        local occurrences documented status
        occurrences=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".occurrences")
        documented=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".documented")
        status=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".status")
        
        occurrences=${occurrences:-0}
        
        [[ "$documented" == "true" ]] && continue
        [[ "$status" == "resolved" ]] && continue
        [[ $occurrences -lt $CHALLENGE_OCCURRENCE_THRESHOLD ]] && continue
        
        local pattern first_seen last_seen
        pattern=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".pattern")
        first_seen=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".firstSeen")
        last_seen=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".lastSeen")
        
        echo "{\"challengeId\": \"$challenge_id\", \"pattern\": \"$pattern\", \"occurrences\": $occurrences, \"firstSeen\": \"$first_seen\", \"lastSeen\": \"$last_seen\"}"
    done
}

challenge_should_suggest() {
    local challenge_id="$1"
    _challenge_ensure_file
    
    local occurrences documented status
    occurrences=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".occurrences")
    documented=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".documented")
    status=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".status")
    
    occurrences=${occurrences:-0}
    
    [[ "$documented" == "true" ]] && return 1
    [[ "$status" == "resolved" ]] && return 1
    [[ $occurrences -lt $CHALLENGE_OCCURRENCE_THRESHOLD ]] && return 1
    return 0
}

challenge_get_resolved() {
    _challenge_ensure_file
    
    local now_epoch
    now_epoch=$(date +%s)
    local resolution_seconds=$((CHALLENGE_RESOLUTION_DAYS * 24 * 60 * 60))
    
    local challenge_ids
    challenge_ids=$(json_read_file "$CHALLENGES_FILE" ".challenges | keys[]" 2>/dev/null)
    
    for challenge_id in $challenge_ids; do
        [[ -z "$challenge_id" ]] && continue
        
        local status last_seen occurrences
        status=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".status")
        last_seen=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".lastSeen")
        occurrences=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".occurrences")
        
        occurrences=${occurrences:-0}
        
        [[ "$status" == "resolved" ]] && continue
        [[ $occurrences -lt $CHALLENGE_OCCURRENCE_THRESHOLD ]] && continue
        
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

challenge_mark_documented() {
    local challenge_id="$1"
    _challenge_ensure_file
    json_update_field "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".documented" "true"
    json_update_field "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".status" "\"documented\""
    json_touch_file "$CHALLENGES_FILE"
}

challenge_mark_resolved() {
    local challenge_id="$1"
    _challenge_ensure_file
    
    local timestamp
    timestamp=$(_detector_timestamp)
    
    json_update_field "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".status" "\"resolved\""
    json_update_field "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".resolvedAt" "\"$timestamp\""
    
    local pattern
    pattern=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".pattern")
    local resolved_record="{\"challengeId\": \"$challenge_id\", \"pattern\": \"$pattern\", \"resolvedAt\": \"$timestamp\"}"
    json_array_append "$CHALLENGES_FILE" ".resolved" "$resolved_record"
    
    json_touch_file "$CHALLENGES_FILE"
}

challenge_get_info() {
    local challenge_id="$1"
    _challenge_ensure_file
    json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\""
}

challenge_exists() {
    local challenge_id="$1"
    _challenge_ensure_file
    local existing
    existing=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\"")
    [[ -n "$existing" ]] && [[ "$existing" != "null" ]]
}

challenge_get_occurrence_count() {
    local challenge_id="$1"
    _challenge_ensure_file
    local count
    count=$(json_read_file "$CHALLENGES_FILE" ".challenges.\"$challenge_id\".occurrences")
    echo "${count:-0}"
}


# ============================================
# IDEA CAPTURER
# ============================================

IDEAS_FILE="${OBSERVATIONS_DIR}/ideas.json"
IDEAS_MD="${IDENTITY_DIR}/IDEAS.md"
IDEA_STALENESS_DAYS=90

IDEA_PATTERNS=(
    "should try" "could try" "might try" "want to try" "would be nice" "would be cool"
    "someday" "eventually" "in the future" "later on" "when I have time" "idea:" "thought:"
    "maybe we could" "what if we" "it would be great" "I've been thinking" "been meaning to"
    "on my list" "backlog" "todo" "experiment with" "explore"
)

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

idea_generate_id() {
    _detector_generate_id "$1"
}

idea_detect() {
    local input="$1"
    _idea_ensure_file
    
    local input_lower
    input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    
    local matched_pattern=""
    for pattern in "${IDEA_PATTERNS[@]}"; do
        if [[ "$input_lower" == *"$pattern"* ]]; then
            matched_pattern="$pattern"
            break
        fi
    done
    
    [[ -z "$matched_pattern" ]] && return 1
    
    local timestamp
    timestamp=$(_detector_timestamp)
    
    local idea_text="$input"
    [[ ${#input} -gt 100 ]] && idea_text=$(echo "$input" | head -c 200)
    
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
    
    local detection_record="{\"input\": \"$input\", \"pattern\": \"$matched_pattern\", \"timestamp\": \"$timestamp\"}"
    json_array_append "$IDEAS_FILE" ".detections" "$detection_record"
    
    local detection_count
    detection_count=$(json_array_length "$IDEAS_FILE" ".detections")
    while [[ $detection_count -gt 50 ]]; do
        json_array_remove "$IDEAS_FILE" ".detections" 0
        detection_count=$((detection_count - 1))
    done
    
    json_touch_file "$IDEAS_FILE"
    
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

idea_record() {
    local idea="$1"
    local category="${2:-General}"
    local status="${3:-Backlog}"
    
    _idea_ensure_file
    
    local idea_id
    idea_id=$(idea_generate_id "$idea")
    
    local timestamp
    timestamp=$(_detector_timestamp)
    
    local existing
    existing=$(json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
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
        json_update_field "$IDEAS_FILE" ".ideas.\"$idea_id\".lastUpdated" "\"$timestamp\""
    fi
    
    json_touch_file "$IDEAS_FILE"
}

idea_get_stale() {
    _idea_ensure_file
    
    local now_epoch
    now_epoch=$(date +%s)
    local staleness_seconds=$((IDEA_STALENESS_DAYS * 24 * 60 * 60))
    
    local idea_ids
    idea_ids=$(json_read_file "$IDEAS_FILE" ".ideas | keys[]" 2>/dev/null)
    
    for idea_id in $idea_ids; do
        [[ -z "$idea_id" ]] && continue
        
        local status added_at
        status=$(json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\".status")
        added_at=$(json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\".addedAt")
        
        [[ "$status" != "Backlog" ]] && continue
        
        if [[ -n "$added_at" ]]; then
            local added_epoch
            if [[ "$(uname)" == "Darwin" ]]; then
                added_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$added_at" +%s 2>/dev/null || echo "$now_epoch")
            else
                added_epoch=$(date -d "$added_at" +%s 2>/dev/null || echo "$now_epoch")
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

idea_match_work() {
    local work_context="$1"
    local context_lower
    context_lower=$(echo "$work_context" | tr '[:upper:]' '[:lower:]')
    local keywords
    keywords=$(echo "$context_lower" | tr -cs '[:alnum:]' ' ')
    
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

idea_update_status() {
    local idea_id="$1"
    local new_status="$2"
    _idea_ensure_file
    local timestamp
    timestamp=$(_detector_timestamp)
    json_update_field "$IDEAS_FILE" ".ideas.\"$idea_id\".status" "\"$new_status\""
    json_update_field "$IDEAS_FILE" ".ideas.\"$idea_id\".lastUpdated" "\"$timestamp\""
    json_touch_file "$IDEAS_FILE"
}

idea_mark_documented() {
    local idea_id="$1"
    _idea_ensure_file
    json_update_field "$IDEAS_FILE" ".ideas.\"$idea_id\".documented" "true"
    json_touch_file "$IDEAS_FILE"
}

idea_get_info() {
    local idea_id="$1"
    _idea_ensure_file
    json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\""
}

idea_exists() {
    local idea_id="$1"
    _idea_ensure_file
    local existing
    existing=$(json_read_file "$IDEAS_FILE" ".ideas.\"$idea_id\"")
    [[ -n "$existing" ]] && [[ "$existing" != "null" ]]
}

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
# LEARNING EXTRACTOR
# ============================================

PATTERNS_FILE="${OBSERVATIONS_DIR}/patterns.json"
LEARNED_FILE="${IDENTITY_DIR}/LEARNED.md"
LEARNING_MIN_DURATION_SECONDS=600
LEARNING_MIN_ATTEMPTS=2

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

learning_generate_id() {
    _detector_generate_id "$1"
}

learning_analyze_session() {
    local problem="$1"
    local solution="$2"
    local duration="${3:-0}"
    local attempts="${4:-1}"
    
    _learning_ensure_file
    
    local is_nontrivial=false
    [[ $duration -ge $LEARNING_MIN_DURATION_SECONDS ]] && is_nontrivial=true
    [[ $attempts -ge $LEARNING_MIN_ATTEMPTS ]] && is_nontrivial=true
    [[ "$is_nontrivial" != "true" ]] && return 1
    
    local timestamp
    timestamp=$(_detector_timestamp)
    
    local suggested_lesson="$solution"
    local suggested_cost=""
    local suggested_application=""
    
    if [[ $duration -ge 3600 ]]; then
        suggested_cost="$((duration / 3600)) hours"
    elif [[ $duration -ge 60 ]]; then
        suggested_cost="$((duration / 60)) minutes"
    fi
    
    suggested_application="When facing similar $problem issues"
    
    local confidence=50
    [[ $duration -ge $LEARNING_MIN_DURATION_SECONDS ]] && confidence=$((confidence + 25))
    [[ $attempts -ge $LEARNING_MIN_ATTEMPTS ]] && confidence=$((confidence + 25))
    
    local session_record="{\"problem\": \"$problem\", \"solution\": \"$solution\", \"duration\": $duration, \"attempts\": $attempts, \"timestamp\": \"$timestamp\"}"
    json_array_append "$PATTERNS_FILE" ".problemSessions" "$session_record"
    
    local session_count
    session_count=$(json_array_length "$PATTERNS_FILE" ".problemSessions")
    while [[ $session_count -gt 50 ]]; do
        json_array_remove "$PATTERNS_FILE" ".problemSessions" 0
        session_count=$((session_count - 1))
    done
    
    json_touch_file "$PATTERNS_FILE"
    
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

learning_check_duplicate() {
    local lesson="$1"
    
    if [[ -f "$LEARNED_FILE" ]]; then
        local lesson_lower
        lesson_lower=$(echo "$lesson" | tr '[:upper:]' '[:lower:]')
        grep -qi "$lesson_lower" "$LEARNED_FILE" 2>/dev/null && return 0
    fi
    
    _learning_ensure_file
    local learning_id
    learning_id=$(learning_generate_id "$lesson")
    local existing
    existing=$(json_read_file "$PATTERNS_FILE" ".learnings.\"$learning_id\"")
    [[ -n "$existing" ]] && [[ "$existing" != "null" ]] && return 0
    return 1
}

learning_record() {
    local lesson="$1"
    local context="${2:-}"
    _learning_ensure_file
    local learning_id
    learning_id=$(learning_generate_id "$lesson")
    local timestamp
    timestamp=$(_detector_timestamp)
    local learning_record="{\"lesson\": \"$lesson\", \"context\": \"$context\", \"recordedAt\": \"$timestamp\"}"
    json_set_nested "$PATTERNS_FILE" ".learnings.\"$learning_id\"" "$learning_record"
    json_touch_file "$PATTERNS_FILE"
}

learning_check_repeated_mistake() {
    local context="$1"
    [[ ! -f "$LEARNED_FILE" ]] && return 1
    
    local keywords
    keywords=$(echo "$context" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' ' ')
    
    for keyword in $keywords; do
        [[ ${#keyword} -lt 4 ]] && continue
        local match
        match=$(grep -i "$keyword" "$LEARNED_FILE" 2>/dev/null | head -1)
        if [[ -n "$match" ]]; then
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

learning_track_problem() {
    local problem="$1"
    local context="${2:-}"
    _learning_ensure_file
    local timestamp
    timestamp=$(_detector_timestamp)
    local problem_id
    problem_id=$(learning_generate_id "$problem")
    
    local existing
    existing=$(json_read_file "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
        local new_pattern="{\"problem\": \"$problem\", \"occurrences\": 1, \"contexts\": [\"$context\"], \"firstSeen\": \"$timestamp\", \"lastSeen\": \"$timestamp\"}"
        json_set_nested "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\"" "$new_pattern"
    else
        local current_count
        current_count=$(json_read_file "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\".occurrences")
        current_count=${current_count:-0}
        json_update_field "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\".occurrences" "$((current_count + 1))"
        json_update_field "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\".lastSeen" "\"$timestamp\""
        [[ -n "$context" ]] && json_array_append "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\".contexts" "\"$context\""
    fi
    json_touch_file "$PATTERNS_FILE"
}

learning_get_recurring_problems() {
    _learning_ensure_file
    local problem_ids
    problem_ids=$(json_read_file "$PATTERNS_FILE" ".problemPatterns | keys[]" 2>/dev/null)
    
    for problem_id in $problem_ids; do
        [[ -z "$problem_id" ]] && continue
        local occurrences
        occurrences=$(json_read_file "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\".occurrences")
        occurrences=${occurrences:-0}
        if [[ $occurrences -ge 3 ]]; then
            local problem
            problem=$(json_read_file "$PATTERNS_FILE" ".problemPatterns.\"$problem_id\".problem")
            echo "{\"problemId\": \"$problem_id\", \"problem\": \"$problem\", \"occurrences\": $occurrences}"
        fi
    done
}


# ============================================
# MODEL DETECTOR
# ============================================

MODELS_FILE="${OBSERVATIONS_DIR}/models.json"
MODELS_MD="${IDENTITY_DIR}/MODELS.md"
MODEL_USAGE_THRESHOLD=3

KNOWN_MODELS=(
    "pareto:80/20,pareto,80-20,eighty twenty"
    "conways_law:conway,organization structure,team structure mirrors"
    "yagni:yagni,you aren't gonna need it,premature"
    "dry:dry,don't repeat yourself,duplication"
    "kiss:kiss,keep it simple,simplicity"
    "solid:solid,single responsibility,open closed,liskov,interface segregation,dependency inversion"
    "mvp:mvp,minimum viable,minimal viable"
    "technical_debt:technical debt,tech debt,shortcut"
    "rubber_duck:rubber duck,explain to,talk through"
    "occams_razor:occam,simplest explanation,simplest solution"
    "broken_windows:broken window,small issues lead"
    "boy_scout:boy scout,leave it better,clean as you go"
    "separation_of_concerns:separation of concerns,single purpose,one thing"
    "fail_fast:fail fast,early failure,quick feedback"
    "iterative:iterative,incremental,small steps"
)

_model_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    if [[ ! -f "$MODELS_FILE" ]]; then
        cat > "$MODELS_FILE" 2>/dev/null << 'EOF'
{
  "models": {},
  "detections": [],
  "lastUpdated": null
}
EOF
    fi
}

model_generate_id() {
    local name="$1"
    local normalized
    normalized=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | head -c 50)
    _detector_generate_id "$normalized"
}

_model_record_usage() {
    local model_name="$1"
    local context="$2"
    local is_known="$3"
    
    local model_id
    model_id=$(model_generate_id "$model_name")
    local timestamp
    timestamp=$(_detector_timestamp)
    
    local detection_record="{\"model\": \"$model_name\", \"context\": \"$context\", \"isKnown\": $is_known, \"timestamp\": \"$timestamp\"}"
    json_array_append "$MODELS_FILE" ".detections" "$detection_record"
    
    local detection_count
    detection_count=$(json_array_length "$MODELS_FILE" ".detections")
    while [[ $detection_count -gt 50 ]]; do
        json_array_remove "$MODELS_FILE" ".detections" 0
        detection_count=$((detection_count - 1))
    done
    
    local existing
    existing=$(json_read_file "$MODELS_FILE" ".models.\"$model_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
        local new_model="{
            \"modelId\": \"$model_id\",
            \"name\": \"$model_name\",
            \"isKnownModel\": $is_known,
            \"usageCount\": 1,
            \"contexts\": [\"$context\"],
            \"firstSeen\": \"$timestamp\",
            \"lastSeen\": \"$timestamp\",
            \"documented\": false
        }"
        json_set_nested "$MODELS_FILE" ".models.\"$model_id\"" "$new_model"
    else
        local current_count
        current_count=$(json_read_file "$MODELS_FILE" ".models.\"$model_id\".usageCount")
        current_count=${current_count:-0}
        json_update_field "$MODELS_FILE" ".models.\"$model_id\".usageCount" "$((current_count + 1))"
        json_update_field "$MODELS_FILE" ".models.\"$model_id\".lastSeen" "\"$timestamp\""
        json_array_append "$MODELS_FILE" ".models.\"$model_id\".contexts" "\"$context\""
        
        local context_count
        context_count=$(json_array_length "$MODELS_FILE" ".models.\"$model_id\".contexts")
        while [[ $context_count -gt 5 ]]; do
            json_array_remove "$MODELS_FILE" ".models.\"$model_id\".contexts" 0
            context_count=$((context_count - 1))
        done
    fi
    json_touch_file "$MODELS_FILE"
}

model_detect() {
    local input="$1"
    _model_ensure_file
    
    local input_lower
    input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    local timestamp
    timestamp=$(_detector_timestamp)
    
    for model_entry in "${KNOWN_MODELS[@]}"; do
        local model_name="${model_entry%%:*}"
        local keywords="${model_entry#*:}"
        
        IFS=',' read -ra keyword_array <<< "$keywords"
        for keyword in "${keyword_array[@]}"; do
            if [[ "$input_lower" == *"$keyword"* ]]; then
                _model_record_usage "$model_name" "$input" "true"
                cat << EOF
{
  "name": "$model_name",
  "isKnownModel": true,
  "usageContext": "$input",
  "matchedKeyword": "$keyword",
  "timestamp": "$timestamp"
}
EOF
                return 0
            fi
        done
    done
    
    local model_indicators=("like" "similar to" "analogy" "framework" "principle" "rule of" "law of" "pattern")
    for indicator in "${model_indicators[@]}"; do
        if [[ "$input_lower" == *"$indicator"* ]]; then
            _model_record_usage "custom_analogy" "$input" "false"
            cat << EOF
{
  "name": "custom_analogy",
  "isKnownModel": false,
  "usageContext": "$input",
  "matchedIndicator": "$indicator",
  "timestamp": "$timestamp"
}
EOF
            return 0
        fi
    done
    return 1
}

model_get_suggestions() {
    _model_ensure_file
    local model_ids
    model_ids=$(json_read_file "$MODELS_FILE" ".models | keys[]" 2>/dev/null)
    
    for model_id in $model_ids; do
        [[ -z "$model_id" ]] && continue
        local usage_count documented
        usage_count=$(json_read_file "$MODELS_FILE" ".models.\"$model_id\".usageCount")
        documented=$(json_read_file "$MODELS_FILE" ".models.\"$model_id\".documented")
        usage_count=${usage_count:-0}
        
        [[ "$documented" == "true" ]] && continue
        [[ $usage_count -lt $MODEL_USAGE_THRESHOLD ]] && continue
        
        local name is_known
        name=$(json_read_file "$MODELS_FILE" ".models.\"$model_id\".name")
        is_known=$(json_read_file "$MODELS_FILE" ".models.\"$model_id\".isKnownModel")
        echo "{\"modelId\": \"$model_id\", \"name\": \"$name\", \"usageCount\": $usage_count, \"isKnownModel\": $is_known}"
    done
}

model_suggest_for_problem() {
    local problem_context="$1"
    local context_lower
    context_lower=$(echo "$problem_context" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$context_lower" == *"priorit"* ]] || [[ "$context_lower" == *"focus"* ]] || [[ "$context_lower" == *"important"* ]]; then
        echo "{\"name\": \"Pareto Principle (80/20)\", \"suggestion\": \"Focus on the 20% that delivers 80% of value\", \"source\": \"known\"}"
        return 0
    fi
    if [[ "$context_lower" == *"stuck"* ]] || [[ "$context_lower" == *"debug"* ]] || [[ "$context_lower" == *"understand"* ]]; then
        echo "{\"name\": \"Rubber Duck Debugging\", \"suggestion\": \"Try explaining the problem out loud\", \"source\": \"known\"}"
        return 0
    fi
    if [[ "$context_lower" == *"future"* ]] || [[ "$context_lower" == *"might need"* ]] || [[ "$context_lower" == *"just in case"* ]]; then
        echo "{\"name\": \"YAGNI\", \"suggestion\": \"You Aren't Gonna Need It - build only what's needed now\", \"source\": \"known\"}"
        return 0
    fi
    if [[ "$context_lower" == *"scope"* ]] || [[ "$context_lower" == *"feature"* ]] || [[ "$context_lower" == *"launch"* ]]; then
        echo "{\"name\": \"MVP\", \"suggestion\": \"Start with minimum viable product\", \"source\": \"known\"}"
        return 0
    fi
    return 1
}

model_mark_documented() {
    local model_id="$1"
    _model_ensure_file
    json_update_field "$MODELS_FILE" ".models.\"$model_id\".documented" "true"
    json_touch_file "$MODELS_FILE"
}

model_get_info() {
    local model_id="$1"
    _model_ensure_file
    json_read_file "$MODELS_FILE" ".models.\"$model_id\""
}

model_exists() {
    local model_id="$1"
    _model_ensure_file
    local existing
    existing=$(json_read_file "$MODELS_FILE" ".models.\"$model_id\"")
    [[ -n "$existing" ]] && [[ "$existing" != "null" ]]
}

model_get_known_models() {
    for model_entry in "${KNOWN_MODELS[@]}"; do
        local model_name="${model_entry%%:*}"
        echo "$model_name"
    done
}


# ============================================
# NARRATIVE DETECTOR
# ============================================

NARRATIVES_FILE="${OBSERVATIONS_DIR}/narratives.json"
NARRATIVES_MD="${IDENTITY_DIR}/NARRATIVES.md"
NARRATIVE_OCCURRENCE_THRESHOLD=3

LIMITING_PATTERNS=(
    "i can't" "i'm not good at" "i always fail" "i never" "i'm bad at" "i don't understand"
    "i'm terrible at" "i'll never be able to" "i'm not smart enough" "i'm not experienced enough"
    "that's too hard for me" "i'm not a" "i suck at" "i hate" "i'm afraid of" "i'm scared to"
)

EMPOWERING_PATTERNS=(
    "i can" "i'm good at" "i enjoy" "i love" "i'm learning" "i'm getting better at"
    "i figured out" "i solved" "i understand" "i'm confident" "i'm capable" "i excel at"
)

_narrative_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    if [[ ! -f "$NARRATIVES_FILE" ]]; then
        cat > "$NARRATIVES_FILE" 2>/dev/null << 'EOF'
{
  "narratives": {},
  "detections": [],
  "lastUpdated": null
}
EOF
    fi
}

narrative_generate_id() {
    _detector_generate_id "$1"
}

_narrative_record() {
    local statement="$1"
    local classification="$2"
    local pattern="$3"
    
    local narrative_id
    narrative_id=$(narrative_generate_id "$statement")
    local timestamp
    timestamp=$(_detector_timestamp)
    
    local detection_record="{\"statement\": \"$statement\", \"classification\": \"$classification\", \"pattern\": \"$pattern\", \"timestamp\": \"$timestamp\"}"
    json_array_append "$NARRATIVES_FILE" ".detections" "$detection_record"
    
    local detection_count
    detection_count=$(json_array_length "$NARRATIVES_FILE" ".detections")
    while [[ $detection_count -gt 50 ]]; do
        json_array_remove "$NARRATIVES_FILE" ".detections" 0
        detection_count=$((detection_count - 1))
    done
    
    local existing
    existing=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
        local new_narrative="{
            \"narrativeId\": \"$narrative_id\",
            \"statement\": \"$statement\",
            \"classification\": \"$classification\",
            \"pattern\": \"$pattern\",
            \"occurrences\": 1,
            \"firstSeen\": \"$timestamp\",
            \"lastSeen\": \"$timestamp\",
            \"addressed\": false
        }"
        json_set_nested "$NARRATIVES_FILE" ".narratives.\"$narrative_id\"" "$new_narrative"
    else
        local current_count
        current_count=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".occurrences")
        current_count=${current_count:-0}
        json_update_field "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".occurrences" "$((current_count + 1))"
        json_update_field "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".lastSeen" "\"$timestamp\""
    fi
    json_touch_file "$NARRATIVES_FILE"
}

narrative_detect() {
    local input="$1"
    _narrative_ensure_file
    
    local input_lower
    input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    local timestamp
    timestamp=$(_detector_timestamp)
    
    for pattern in "${LIMITING_PATTERNS[@]}"; do
        if [[ "$input_lower" == *"$pattern"* ]]; then
            local reframe
            reframe=$(narrative_suggest_reframe "$input")
            _narrative_record "$input" "limiting" "$pattern"
            cat << EOF
{
  "statement": "$input",
  "classification": "limiting",
  "matchedPattern": "$pattern",
  "suggestedReframe": "$reframe",
  "timestamp": "$timestamp"
}
EOF
            return 0
        fi
    done
    
    for pattern in "${EMPOWERING_PATTERNS[@]}"; do
        if [[ "$input_lower" == *"$pattern"* ]]; then
            _narrative_record "$input" "empowering" "$pattern"
            cat << EOF
{
  "statement": "$input",
  "classification": "empowering",
  "matchedPattern": "$pattern",
  "timestamp": "$timestamp"
}
EOF
            return 0
        fi
    done
    return 1
}

narrative_classify() {
    local statement="$1"
    local statement_lower
    statement_lower=$(echo "$statement" | tr '[:upper:]' '[:lower:]')
    
    for pattern in "${LIMITING_PATTERNS[@]}"; do
        [[ "$statement_lower" == *"$pattern"* ]] && echo "limiting" && return 0
    done
    for pattern in "${EMPOWERING_PATTERNS[@]}"; do
        [[ "$statement_lower" == *"$pattern"* ]] && echo "empowering" && return 0
    done
    echo "neutral"
}

narrative_suggest_reframe() {
    local statement="$1"
    local statement_lower
    statement_lower=$(echo "$statement" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$statement_lower" == *"i can't"* ]]; then echo "I'm learning to... / I haven't yet..."
    elif [[ "$statement_lower" == *"i'm not good at"* ]]; then echo "I'm developing skills in... / I'm improving at..."
    elif [[ "$statement_lower" == *"i always fail"* ]]; then echo "I'm learning from each attempt... / Each try teaches me..."
    elif [[ "$statement_lower" == *"i never"* ]]; then echo "I haven't yet... / I'm working toward..."
    elif [[ "$statement_lower" == *"i'm bad at"* ]]; then echo "I'm still learning... / This is a growth area for me..."
    elif [[ "$statement_lower" == *"i don't understand"* ]]; then echo "I'm working to understand... / I need more context on..."
    elif [[ "$statement_lower" == *"i'm terrible at"* ]]; then echo "I'm developing... / This is challenging and I'm growing..."
    elif [[ "$statement_lower" == *"i'll never be able to"* ]]; then echo "With practice, I can... / I'm on the path to..."
    elif [[ "$statement_lower" == *"i'm not smart enough"* ]]; then echo "I can learn this... / Intelligence grows with effort..."
    elif [[ "$statement_lower" == *"i'm not experienced enough"* ]]; then echo "I'm building experience... / Every expert was once a beginner..."
    elif [[ "$statement_lower" == *"that's too hard"* ]]; then echo "This is challenging and achievable... / I can break this down..."
    elif [[ "$statement_lower" == *"i suck at"* ]]; then echo "I'm developing skills in... / This is a growth opportunity..."
    elif [[ "$statement_lower" == *"i hate"* ]]; then echo "I find this challenging... / I'm working on my relationship with..."
    elif [[ "$statement_lower" == *"i'm afraid"* ]] || [[ "$statement_lower" == *"i'm scared"* ]]; then echo "I'm cautious about... / I'm building confidence in..."
    else echo "Consider: What would a growth mindset version of this be?"
    fi
}

narrative_get_limiting() {
    _narrative_ensure_file
    local narrative_ids
    narrative_ids=$(json_read_file "$NARRATIVES_FILE" ".narratives | keys[]" 2>/dev/null)
    
    for narrative_id in $narrative_ids; do
        [[ -z "$narrative_id" ]] && continue
        local classification occurrences addressed
        classification=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".classification")
        occurrences=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".occurrences")
        addressed=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".addressed")
        occurrences=${occurrences:-0}
        
        [[ "$classification" != "limiting" ]] && continue
        [[ "$addressed" == "true" ]] && continue
        [[ $occurrences -lt $NARRATIVE_OCCURRENCE_THRESHOLD ]] && continue
        
        local statement pattern
        statement=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".statement")
        pattern=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".pattern")
        local reframe
        reframe=$(narrative_suggest_reframe "$statement")
        echo "{\"narrativeId\": \"$narrative_id\", \"statement\": \"$statement\", \"pattern\": \"$pattern\", \"occurrences\": $occurrences, \"suggestedReframe\": \"$reframe\"}"
    done
}

narrative_get_empowering() {
    _narrative_ensure_file
    local narrative_ids
    narrative_ids=$(json_read_file "$NARRATIVES_FILE" ".narratives | keys[]" 2>/dev/null)
    
    for narrative_id in $narrative_ids; do
        [[ -z "$narrative_id" ]] && continue
        local classification occurrences
        classification=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".classification")
        occurrences=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".occurrences")
        occurrences=${occurrences:-0}
        [[ "$classification" != "empowering" ]] && continue
        
        local statement
        statement=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".statement")
        echo "{\"narrativeId\": \"$narrative_id\", \"statement\": \"$statement\", \"occurrences\": $occurrences}"
    done
}

narrative_mark_addressed() {
    local narrative_id="$1"
    _narrative_ensure_file
    json_update_field "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".addressed" "true"
    json_touch_file "$NARRATIVES_FILE"
}

narrative_get_info() {
    local narrative_id="$1"
    _narrative_ensure_file
    json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\""
}

narrative_exists() {
    local narrative_id="$1"
    _narrative_ensure_file
    local existing
    existing=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\"")
    [[ -n "$existing" ]] && [[ "$existing" != "null" ]]
}

narrative_get_stats() {
    _narrative_ensure_file
    local limiting_count=0 empowering_count=0 neutral_count=0
    local narrative_ids
    narrative_ids=$(json_read_file "$NARRATIVES_FILE" ".narratives | keys[]" 2>/dev/null)
    
    for narrative_id in $narrative_ids; do
        [[ -z "$narrative_id" ]] && continue
        local classification
        classification=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".classification")
        case "$classification" in
            "limiting") limiting_count=$((limiting_count + 1)) ;;
            "empowering") empowering_count=$((empowering_count + 1)) ;;
            *) neutral_count=$((neutral_count + 1)) ;;
        esac
    done
    echo "{\"limiting\": $limiting_count, \"empowering\": $empowering_count, \"neutral\": $neutral_count}"
}


# ============================================
# PROJECT DETECTOR
# ============================================

PROJECTS_OBS_FILE="${OBSERVATIONS_DIR}/projects.json"
PROJECT_SESSION_THRESHOLD=2
PROJECT_DECLINE_COOLDOWN_DAYS=7

_project_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    if [[ ! -f "$PROJECTS_OBS_FILE" ]]; then
        cat > "$PROJECTS_OBS_FILE" 2>/dev/null << 'EOF'
{
  "projects": {},
  "lastUpdated": null
}
EOF
    fi
}

project_generate_id() {
    local dir="$1"
    local normalized
    normalized=$(cd "$dir" 2>/dev/null && pwd -P) || normalized="$dir"
    normalized="${normalized%/}"
    _detector_generate_id "$normalized"
}

project_suggest_name() {
    local dir="$1"
    local name
    name=$(basename "$dir")
    name="${name#.}"
    echo "$name"
}

project_detect() {
    local working_dir="$1"
    _project_ensure_file
    
    local project_id suggested_name
    project_id=$(project_generate_id "$working_dir")
    suggested_name=$(project_suggest_name "$working_dir")
    
    local existing
    existing=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\"")
    
    local is_new="true"
    local session_count=0
    local last_seen=""
    
    if [[ -n "$existing" ]] && [[ "$existing" != "null" ]]; then
        is_new="false"
        session_count=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".sessionCount")
        last_seen=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".lastSeen")
        session_count=${session_count:-0}
    fi
    
    cat << EOF
{
  "projectId": "$project_id",
  "isNew": $is_new,
  "sessionCount": $session_count,
  "lastSeen": "$last_seen",
  "suggestedName": "$suggested_name",
  "workingDir": "$working_dir"
}
EOF
}

project_record_session() {
    local project_id="$1"
    local duration="${2:-0}"
    local working_dir="${3:-}"
    
    _project_ensure_file
    local timestamp
    timestamp=$(_detector_timestamp)
    
    local existing
    existing=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
        local suggested_name=""
        [[ -n "$working_dir" ]] && suggested_name=$(project_suggest_name "$working_dir")
        
        local new_project="{
            \"projectId\": \"$project_id\",
            \"workingDir\": \"$working_dir\",
            \"suggestedName\": \"$suggested_name\",
            \"sessions\": [{\"start\": \"$timestamp\", \"duration\": $duration}],
            \"sessionCount\": 1,
            \"totalTime\": $duration,
            \"firstSeen\": \"$timestamp\",
            \"lastSeen\": \"$timestamp\",
            \"status\": \"pending\",
            \"declinedUntil\": null
        }"
        json_set_nested "$PROJECTS_OBS_FILE" ".projects.\"$project_id\"" "$new_project"
    else
        local current_count current_time
        current_count=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".sessionCount")
        current_time=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".totalTime")
        current_count=${current_count:-0}
        current_time=${current_time:-0}
        
        local session_record="{\"start\": \"$timestamp\", \"duration\": $duration}"
        json_array_append "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".sessions" "$session_record"
        json_update_field "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".sessionCount" "$((current_count + 1))"
        json_update_field "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".totalTime" "$((current_time + duration))"
        json_update_field "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".lastSeen" "\"$timestamp\""
    fi
    json_touch_file "$PROJECTS_OBS_FILE"
}

project_get_suggestions() {
    _project_ensure_file
    local now_epoch
    now_epoch=$(date +%s)
    
    local project_ids
    project_ids=$(json_read_file "$PROJECTS_OBS_FILE" ".projects | keys[]" 2>/dev/null)
    
    for project_id in $project_ids; do
        [[ -z "$project_id" ]] && continue
        
        local status session_count declined_until
        status=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".status")
        session_count=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".sessionCount")
        declined_until=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".declinedUntil")
        session_count=${session_count:-0}
        
        [[ "$status" == "added" ]] && continue
        [[ $session_count -lt $PROJECT_SESSION_THRESHOLD ]] && continue
        
        if [[ -n "$declined_until" ]] && [[ "$declined_until" != "null" ]]; then
            local declined_epoch
            if [[ "$(uname)" == "Darwin" ]]; then
                declined_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$declined_until" +%s 2>/dev/null || echo 0)
            else
                declined_epoch=$(date -d "$declined_until" +%s 2>/dev/null || echo 0)
            fi
            [[ $now_epoch -lt $declined_epoch ]] && continue
        fi
        
        local suggested_name working_dir total_time
        suggested_name=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".suggestedName")
        working_dir=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".workingDir")
        total_time=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".totalTime")
        
        echo "{\"projectId\": \"$project_id\", \"suggestedName\": \"$suggested_name\", \"workingDir\": \"$working_dir\", \"sessionCount\": $session_count, \"totalTime\": ${total_time:-0}}"
    done
}

project_should_suggest() {
    local project_id="$1"
    _project_ensure_file
    
    local status session_count declined_until
    status=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".status")
    session_count=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".sessionCount")
    declined_until=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".declinedUntil")
    session_count=${session_count:-0}
    
    [[ "$status" == "added" ]] && return 1
    [[ $session_count -lt $PROJECT_SESSION_THRESHOLD ]] && return 1
    
    if [[ -n "$declined_until" ]] && [[ "$declined_until" != "null" ]]; then
        local now_epoch declined_epoch
        now_epoch=$(date +%s)
        if [[ "$(uname)" == "Darwin" ]]; then
            declined_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$declined_until" +%s 2>/dev/null || echo 0)
        else
            declined_epoch=$(date -d "$declined_until" +%s 2>/dev/null || echo 0)
        fi
        [[ $now_epoch -lt $declined_epoch ]] && return 1
    fi
    return 0
}

project_decline() {
    local project_id="$1"
    _project_ensure_file
    
    local declined_until
    if [[ "$(uname)" == "Darwin" ]]; then
        declined_until=$(date -u -v+${PROJECT_DECLINE_COOLDOWN_DAYS}d +"%Y-%m-%dT%H:%M:%SZ")
    else
        declined_until=$(date -u -d "+${PROJECT_DECLINE_COOLDOWN_DAYS} days" +"%Y-%m-%dT%H:%M:%SZ")
    fi
    
    json_update_field "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".declinedUntil" "\"$declined_until\""
    json_update_field "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".status" "\"declined\""
    json_touch_file "$PROJECTS_OBS_FILE"
}

project_mark_added() {
    local project_id="$1"
    _project_ensure_file
    json_update_field "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".status" "\"added\""
    json_update_field "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".declinedUntil" "null"
    json_touch_file "$PROJECTS_OBS_FILE"
}

project_get_info() {
    local project_id="$1"
    _project_ensure_file
    json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\""
}

project_exists() {
    local project_id="$1"
    _project_ensure_file
    local existing
    existing=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\"")
    [[ -n "$existing" ]] && [[ "$existing" != "null" ]]
}

project_get_session_count() {
    local project_id="$1"
    _project_ensure_file
    local count
    count=$(json_read_file "$PROJECTS_OBS_FILE" ".projects.\"$project_id\".sessionCount")
    echo "${count:-0}"
}


# ============================================
# STRATEGY DETECTOR
# ============================================

STRATEGIES_FILE="${OBSERVATIONS_DIR}/strategies.json"
STRATEGIES_MD="${IDENTITY_DIR}/STRATEGIES.md"
STRATEGY_OCCURRENCE_THRESHOLD=3
STRATEGY_STEP_SIMILARITY=0.6

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

strategy_generate_id() {
    local problem_type="$1"
    local normalized
    normalized=$(echo "$problem_type" | tr '[:upper:]' '[:lower:]' | head -c 50)
    _detector_generate_id "$normalized"
}

strategy_record_approach() {
    local problem_type="$1"
    local steps="$2"
    local success="${3:-true}"
    
    _strategy_ensure_file
    
    local strategy_id
    strategy_id=$(strategy_generate_id "$problem_type")
    
    local timestamp
    timestamp=$(_detector_timestamp)
    
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
        
        json_update_field "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".commonSteps" "$steps_json"
    fi
    
    json_touch_file "$STRATEGIES_FILE"
}

strategy_get_suggestions() {
    _strategy_ensure_file
    
    local strategy_ids
    strategy_ids=$(json_read_file "$STRATEGIES_FILE" ".strategies | keys[]" 2>/dev/null)
    
    for strategy_id in $strategy_ids; do
        [[ -z "$strategy_id" ]] && continue
        
        local occurrences documented status
        occurrences=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".occurrences")
        documented=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".documented")
        status=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".status")
        
        occurrences=${occurrences:-0}
        
        [[ "$documented" == "true" ]] && continue
        [[ $occurrences -lt $STRATEGY_OCCURRENCE_THRESHOLD ]] && continue
        
        local problem_type success_count failure_count
        problem_type=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".problemType")
        success_count=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".successCount")
        failure_count=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".failureCount")
        
        echo "{\"strategyId\": \"$strategy_id\", \"problemType\": \"$problem_type\", \"occurrences\": $occurrences, \"successCount\": ${success_count:-0}, \"failureCount\": ${failure_count:-0}}"
    done
}

strategy_find_matching() {
    local problem_type="$1"
    
    # First check documented strategies in STRATEGIES.md
    if [[ -f "$STRATEGIES_MD" ]]; then
        local problem_lower
        problem_lower=$(echo "$problem_type" | tr '[:upper:]' '[:lower:]')
        
        if grep -qi "$problem_lower" "$STRATEGIES_MD" 2>/dev/null; then
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

strategy_record_failure() {
    local strategy_id="$1"
    local context="${2:-}"
    
    _strategy_ensure_file
    
    local timestamp
    timestamp=$(_detector_timestamp)
    
    local failure_record="{\"strategyId\": \"$strategy_id\", \"context\": \"$context\", \"timestamp\": \"$timestamp\"}"
    json_array_append "$STRATEGIES_FILE" ".failures" "$failure_record"
    
    local failure_count
    failure_count=$(json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".failureCount")
    failure_count=${failure_count:-0}
    
    json_update_field "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".failureCount" "$((failure_count + 1))"
    json_touch_file "$STRATEGIES_FILE"
}

strategy_mark_documented() {
    local strategy_id="$1"
    
    _strategy_ensure_file
    
    json_update_field "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".documented" "true"
    json_update_field "$STRATEGIES_FILE" ".strategies.\"$strategy_id\".status" "\"documented\""
    json_touch_file "$STRATEGIES_FILE"
}

strategy_get_info() {
    local strategy_id="$1"
    
    _strategy_ensure_file
    
    json_read_file "$STRATEGIES_FILE" ".strategies.\"$strategy_id\""
}

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

# Shared base functions (internal)
export -f _detector_generate_id
export -f _detector_ensure_file
export -f _detector_timestamp

# Belief detector
export -f belief_generate_id
export -f belief_detect_domain
export -f belief_record_decision
export -f belief_get_suggestions
export -f belief_check_contradiction
export -f belief_mark_documented
export -f belief_get_info
export -f belief_exists
export -f belief_get_by_domain

# Challenge detector
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

# Idea capturer
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

# Learning extractor
export -f learning_generate_id
export -f learning_analyze_session
export -f learning_check_duplicate
export -f learning_record
export -f learning_check_repeated_mistake
export -f learning_track_problem
export -f learning_get_recurring_problems

# Model detector
export -f model_generate_id
export -f model_detect
export -f model_get_suggestions
export -f model_suggest_for_problem
export -f model_mark_documented
export -f model_get_info
export -f model_exists
export -f model_get_known_models

# Narrative detector
export -f narrative_generate_id
export -f narrative_detect
export -f narrative_classify
export -f narrative_suggest_reframe
export -f narrative_get_limiting
export -f narrative_get_empowering
export -f narrative_mark_addressed
export -f narrative_get_info
export -f narrative_exists
export -f narrative_get_stats

# Project detector
export -f project_generate_id
export -f project_suggest_name
export -f project_detect
export -f project_record_session
export -f project_get_suggestions
export -f project_should_suggest
export -f project_decline
export -f project_mark_added
export -f project_get_info
export -f project_exists
export -f project_get_session_count

# Strategy detector
export -f strategy_generate_id
export -f strategy_record_approach
export -f strategy_get_suggestions
export -f strategy_find_matching
export -f strategy_record_failure
export -f strategy_mark_documented
export -f strategy_get_info
export -f strategy_exists
