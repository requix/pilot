#!/usr/bin/env bash
# analysis.sh - Analysis and performance for PILOT
# Part of PILOT - Personal Intelligence Layer for Optimized Tasks
# Location: src/helpers/analysis.sh (consolidated from performance-manager.sh + cross-file-intelligence.sh)
#
# Combines performance management with cross-file intelligence.
#
# Usage:
#   source analysis.sh
#   perf_start_processing
#   perf_record_time "ProjectDetector" 25
#   crossfile_generate_review

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/json.sh" ]] && source "${SCRIPT_DIR}/json.sh"

# ============================================
# PERFORMANCE MANAGEMENT (from performance-manager.sh)
# ============================================

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
PERFORMANCE_FILE="${OBSERVATIONS_DIR}/performance.json"
LOCK_FILE="${OBSERVATIONS_DIR}/.processing.lock"

# Performance thresholds (in milliseconds)
PERF_NORMAL_MS=50
PERF_WARNING_MS=100
PERF_CRITICAL_MS=200
PERF_CONSECUTIVE_SLOW=3
PERF_REENABLE_MS=3600000
PERF_SESSION_OVERHEAD_WARN=5

# Observation tiers
TIER_MINIMAL="minimal"
TIER_STANDARD="standard"
TIER_FULL="full"

# Detectors by tier
DETECTORS_MINIMAL="ProjectDetector ChallengeDetector"
DETECTORS_STANDARD="ProjectDetector ChallengeDetector LearningExtractor StrategyDetector IdeaCapturer BeliefDetector"
DETECTORS_FULL="ProjectDetector ChallengeDetector LearningExtractor StrategyDetector IdeaCapturer BeliefDetector ModelDetector NarrativeDetector"

_perf_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$PERFORMANCE_FILE" ]]; then
        cat > "$PERFORMANCE_FILE" 2>/dev/null << 'EOF'
{
  "currentTier": "standard",
  "detectorMetrics": {},
  "disabledDetectors": [],
  "tierHistory": [],
  "sessionMetrics": {
    "totalProcessingMs": 0,
    "totalSessionMs": 0,
    "callCount": 0
  },
  "lastUpdated": null
}
EOF
    fi
}

perf_is_processing() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_age
        if [[ "$(uname)" == "Darwin" ]]; then
            lock_age=$(( $(date +%s) - $(stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0) ))
        else
            lock_age=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
        fi
        
        if [[ $lock_age -gt 5 ]]; then
            rm -f "$LOCK_FILE" 2>/dev/null || true
            return 1
        fi
        return 0
    fi
    return 1
}

perf_start_processing() {
    _perf_ensure_file
    echo "$" > "$LOCK_FILE" 2>/dev/null || true
}

perf_end_processing() {
    rm -f "$LOCK_FILE" 2>/dev/null || true
}

perf_get_tier() {
    _perf_ensure_file
    local tier
    tier=$(json_read_file "$PERFORMANCE_FILE" ".currentTier")
    echo "${tier:-$TIER_STANDARD}"
}

perf_set_tier() {
    local new_tier="$1"
    local reason="${2:-manual}"
    
    _perf_ensure_file
    
    local old_tier
    old_tier=$(perf_get_tier)
    
    if [[ "$old_tier" != "$new_tier" ]]; then
        local timestamp
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        
        json_update_field "$PERFORMANCE_FILE" ".currentTier" "\"$new_tier\""
        
        local change_record="{\"from\": \"$old_tier\", \"to\": \"$new_tier\", \"timestamp\": \"$timestamp\", \"reason\": \"$reason\"}"
        json_array_append "$PERFORMANCE_FILE" ".tierHistory" "$change_record"
        
        json_touch_file "$PERFORMANCE_FILE"
    fi
}

perf_get_tier_detectors() {
    local tier
    tier=$(perf_get_tier)
    
    case "$tier" in
        "$TIER_MINIMAL")  echo "$DETECTORS_MINIMAL" ;;
        "$TIER_STANDARD") echo "$DETECTORS_STANDARD" ;;
        "$TIER_FULL")     echo "$DETECTORS_FULL" ;;
        *)                echo "$DETECTORS_STANDARD" ;;
    esac
}

perf_detector_in_tier() {
    local detector="$1"
    local detectors
    detectors=$(perf_get_tier_detectors)
    
    [[ " $detectors " == *" $detector "* ]]
}

perf_record_time() {
    local detector="$1"
    local duration_ms="$2"
    
    _perf_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local current_avg current_max call_count slow_count
    current_avg=$(json_read_file "$PERFORMANCE_FILE" ".detectorMetrics.\"$detector\".avgMs")
    current_max=$(json_read_file "$PERFORMANCE_FILE" ".detectorMetrics.\"$detector\".maxMs")
    call_count=$(json_read_file "$PERFORMANCE_FILE" ".detectorMetrics.\"$detector\".callCount")
    slow_count=$(json_read_file "$PERFORMANCE_FILE" ".detectorMetrics.\"$detector\".consecutiveSlowCalls")
    
    current_avg=${current_avg:-0}
    current_max=${current_max:-0}
    call_count=${call_count:-0}
    slow_count=${slow_count:-0}
    
    local new_avg
    if [[ $call_count -eq 0 ]]; then
        new_avg=$duration_ms
    else
        new_avg=$(( (duration_ms * 30 + current_avg * 70) / 100 ))
    fi
    
    local new_max=$current_max
    [[ $duration_ms -gt $current_max ]] && new_max=$duration_ms
    
    if [[ $duration_ms -gt $PERF_WARNING_MS ]]; then
        slow_count=$((slow_count + 1))
    else
        slow_count=0
    fi
    
    local metrics="{\"avgMs\": $new_avg, \"maxMs\": $new_max, \"callCount\": $((call_count + 1)), \"consecutiveSlowCalls\": $slow_count, \"lastCall\": \"$timestamp\", \"lastDuration\": $duration_ms}"
    json_set_nested "$PERFORMANCE_FILE" ".detectorMetrics.\"$detector\"" "$metrics"
    
    json_increment "$PERFORMANCE_FILE" ".sessionMetrics.totalProcessingMs" "$duration_ms"
    json_increment "$PERFORMANCE_FILE" ".sessionMetrics.callCount" 1
    
    if [[ $slow_count -ge $PERF_CONSECUTIVE_SLOW ]] && [[ $duration_ms -gt $PERF_WARNING_MS ]]; then
        _perf_disable_detector "$detector" "consecutive_slow_calls"
    fi
    
    if [[ $duration_ms -gt $PERF_WARNING_MS ]]; then
        echo "[PERF WARNING] $detector took ${duration_ms}ms (threshold: ${PERF_WARNING_MS}ms)" >&2
    fi
    
    json_touch_file "$PERFORMANCE_FILE"
}

_perf_disable_detector() {
    local detector="$1"
    local reason="$2"
    
    local timestamp reenable_at
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    if [[ "$(uname)" == "Darwin" ]]; then
        reenable_at=$(date -u -v+1H +"%Y-%m-%dT%H:%M:%SZ")
    else
        reenable_at=$(date -u -d "+1 hour" +"%Y-%m-%dT%H:%M:%SZ")
    fi
    
    local disable_record="{\"detector\": \"$detector\", \"timestamp\": \"$timestamp\", \"reason\": \"$reason\", \"reEnableAt\": \"$reenable_at\"}"
    json_array_append "$PERFORMANCE_FILE" ".disabledDetectors" "$disable_record"
    
    echo "[PERF] Auto-disabled $detector due to $reason. Will re-enable at $reenable_at" >&2
}

perf_should_run_detector() {
    local detector="$1"
    
    _perf_ensure_file
    
    if ! perf_detector_in_tier "$detector"; then
        return 1
    fi
    
    local disabled_count
    disabled_count=$(json_array_length "$PERFORMANCE_FILE" ".disabledDetectors")
    
    if [[ $disabled_count -gt 0 ]]; then
        local now_epoch
        now_epoch=$(date +%s)
        
        local i=0
        while [[ $i -lt $disabled_count ]]; do
            local disabled_detector reenable_at
            disabled_detector=$(json_read_file "$PERFORMANCE_FILE" ".disabledDetectors[$i].detector")
            reenable_at=$(json_read_file "$PERFORMANCE_FILE" ".disabledDetectors[$i].reEnableAt")
            
            if [[ "$disabled_detector" == "$detector" ]]; then
                local reenable_epoch
                if [[ "$(uname)" == "Darwin" ]]; then
                    reenable_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$reenable_at" +%s 2>/dev/null || echo 0)
                else
                    reenable_epoch=$(date -d "$reenable_at" +%s 2>/dev/null || echo 0)
                fi
                
                if [[ $now_epoch -lt $reenable_epoch ]]; then
                    return 1
                else
                    json_array_remove "$PERFORMANCE_FILE" ".disabledDetectors" "$i"
                    echo "[PERF] Re-enabled $detector after cooldown" >&2
                    return 0
                fi
            fi
            i=$((i + 1))
        done
    fi
    
    return 0
}

perf_adjust_tier() {
    _perf_ensure_file
    
    local current_tier avg_time
    current_tier=$(perf_get_tier)
    
    local total_ms call_count
    total_ms=$(json_read_file "$PERFORMANCE_FILE" ".sessionMetrics.totalProcessingMs")
    call_count=$(json_read_file "$PERFORMANCE_FILE" ".sessionMetrics.callCount")
    
    total_ms=${total_ms:-0}
    call_count=${call_count:-1}
    
    avg_time=$((total_ms / call_count))
    
    if [[ $avg_time -gt $PERF_WARNING_MS ]]; then
        case "$current_tier" in
            "$TIER_FULL")
                perf_set_tier "$TIER_STANDARD" "performance_degradation"
                ;;
            "$TIER_STANDARD")
                perf_set_tier "$TIER_MINIMAL" "performance_degradation"
                ;;
        esac
    elif [[ $avg_time -lt $((PERF_NORMAL_MS / 2)) ]]; then
        case "$current_tier" in
            "$TIER_MINIMAL")
                perf_set_tier "$TIER_STANDARD" "performance_improvement"
                ;;
            "$TIER_STANDARD")
                perf_set_tier "$TIER_FULL" "performance_improvement"
                ;;
        esac
    fi
}

perf_get_metrics() {
    _perf_ensure_file
    
    local total_ms call_count
    total_ms=$(json_read_file "$PERFORMANCE_FILE" ".sessionMetrics.totalProcessingMs")
    call_count=$(json_read_file "$PERFORMANCE_FILE" ".sessionMetrics.callCount")
    
    total_ms=${total_ms:-0}
    call_count=${call_count:-0}
    
    local avg_ms=0
    [[ $call_count -gt 0 ]] && avg_ms=$((total_ms / call_count))
    
    local disabled_count
    disabled_count=$(json_array_length "$PERFORMANCE_FILE" ".disabledDetectors")
    
    local tier
    tier=$(perf_get_tier)
    
    echo "Tier: $tier"
    echo "Avg Processing: ${avg_ms}ms"
    echo "Total Calls: $call_count"
    echo "Disabled Detectors: $disabled_count"
}

perf_get_session_overhead() {
    _perf_ensure_file
    
    local total_processing total_session
    total_processing=$(json_read_file "$PERFORMANCE_FILE" ".sessionMetrics.totalProcessingMs")
    total_session=$(json_read_file "$PERFORMANCE_FILE" ".sessionMetrics.totalSessionMs")
    
    total_processing=${total_processing:-0}
    total_session=${total_session:-1}
    
    if [[ $total_session -gt 0 ]]; then
        echo $((total_processing * 100 / total_session))
    else
        echo 0
    fi
}

perf_update_session_time() {
    local session_ms="$1"
    json_update_field "$PERFORMANCE_FILE" ".sessionMetrics.totalSessionMs" "$session_ms"
}

perf_check_overhead_warning() {
    local overhead
    overhead=$(perf_get_session_overhead)
    
    if [[ $overhead -gt $PERF_SESSION_OVERHEAD_WARN ]]; then
        echo "[PERF WARNING] Observation overhead is ${overhead}% of session time (threshold: ${PERF_SESSION_OVERHEAD_WARN}%)" >&2
        return 0
    fi
    return 1
}

perf_reset_session_metrics() {
    _perf_ensure_file
    
    local reset_metrics='{"totalProcessingMs": 0, "totalSessionMs": 0, "callCount": 0}'
    json_update_field "$PERFORMANCE_FILE" ".sessionMetrics" "$reset_metrics"
}


# ============================================
# CROSS-FILE INTELLIGENCE (from cross-file-intelligence.sh)
# ============================================

# Files
CROSSFILE_FILE="${OBSERVATIONS_DIR}/cross-file.json"
IDENTITY_DIR="${PILOT_DATA}/identity"

# Identity files
PROJECTS_MD="${IDENTITY_DIR}/PROJECTS.md"
GOALS_MD="${IDENTITY_DIR}/GOALS.md"
CHALLENGES_MD="${IDENTITY_DIR}/CHALLENGES.md"
LEARNED_MD="${IDENTITY_DIR}/LEARNED.md"
STRATEGIES_MD="${IDENTITY_DIR}/STRATEGIES.md"
BELIEFS_MD="${IDENTITY_DIR}/BELIEFS.md"
IDEAS_MD="${IDENTITY_DIR}/IDEAS.md"

# Configuration
CROSSFILE_STALE_DAYS=30
CROSSFILE_IDEA_STALE_DAYS=90

_crossfile_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$CROSSFILE_FILE" ]]; then
        cat > "$CROSSFILE_FILE" 2>/dev/null << 'EOF'
{
  "connections": [],
  "suggestions": [],
  "lastReview": null,
  "lastUpdated": null
}
EOF
    fi
}

crossfile_on_challenge_resolved() {
    local challenge_id="$1"
    
    _crossfile_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local challenges_file="${OBSERVATIONS_DIR}/challenges.json"
    if [[ ! -f "$challenges_file" ]]; then
        return 1
    fi
    
    local pattern
    pattern=$(json_read_file "$challenges_file" ".challenges.\"$challenge_id\".pattern")
    
    if [[ -z "$pattern" ]] || [[ "$pattern" == "null" ]]; then
        return 1
    fi
    
    local suggestion="{
        \"type\": \"challenge_to_learning\",
        \"sourceFile\": \"CHALLENGES.md\",
        \"sourceId\": \"$challenge_id\",
        \"targetFile\": \"LEARNED.md\",
        \"pattern\": \"$pattern\",
        \"suggestedAction\": \"Document what you learned from resolving this challenge\",
        \"timestamp\": \"$timestamp\",
        \"status\": \"pending\"
    }"
    
    json_array_append "$CROSSFILE_FILE" ".suggestions" "$suggestion"
    json_touch_file "$CROSSFILE_FILE"
    
    cat << EOF
{
  "type": "challenge_to_learning",
  "challenge": "$pattern",
  "suggestion": "You resolved a recurring challenge. Would you like to document what you learned?",
  "targetFile": "LEARNED.md"
}
EOF
    
    return 0
}

crossfile_on_strategy_success() {
    local strategy_id="$1"
    local success_count="${2:-0}"
    
    _crossfile_ensure_file
    
    if [[ $success_count -lt 5 ]]; then
        return 1
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local strategies_file="${OBSERVATIONS_DIR}/strategies.json"
    if [[ ! -f "$strategies_file" ]]; then
        return 1
    fi
    
    local problem_type
    problem_type=$(json_read_file "$strategies_file" ".strategies.\"$strategy_id\".problemType")
    
    if [[ -z "$problem_type" ]] || [[ "$problem_type" == "null" ]]; then
        return 1
    fi
    
    local suggestion="{
        \"type\": \"strategy_to_belief\",
        \"sourceFile\": \"STRATEGIES.md\",
        \"sourceId\": \"$strategy_id\",
        \"targetFile\": \"BELIEFS.md\",
        \"problemType\": \"$problem_type\",
        \"successCount\": $success_count,
        \"suggestedAction\": \"This strategy works consistently - consider documenting it as a belief\",
        \"timestamp\": \"$timestamp\",
        \"status\": \"pending\"
    }"
    
    json_array_append "$CROSSFILE_FILE" ".suggestions" "$suggestion"
    json_touch_file "$CROSSFILE_FILE"
    
    cat << EOF
{
  "type": "strategy_to_belief",
  "strategy": "$problem_type",
  "successCount": $success_count,
  "suggestion": "Your strategy for '$problem_type' has worked $success_count times. This might be a core belief worth documenting.",
  "targetFile": "BELIEFS.md"
}
EOF
    
    return 0
}

crossfile_on_project_theme_detected() {
    local project_ids="$1"
    local theme="${2:-}"
    
    _crossfile_ensure_file
    
    local project_count
    project_count=$(echo "$project_ids" | wc -w | tr -d ' ')
    
    if [[ $project_count -lt 3 ]]; then
        return 1
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local suggestion="{
        \"type\": \"project_to_goal\",
        \"sourceFile\": \"PROJECTS.md\",
        \"projectIds\": \"$project_ids\",
        \"targetFile\": \"GOALS.md\",
        \"theme\": \"$theme\",
        \"projectCount\": $project_count,
        \"suggestedAction\": \"Multiple related projects detected - consider grouping under a goal\",
        \"timestamp\": \"$timestamp\",
        \"status\": \"pending\"
    }"
    
    json_array_append "$CROSSFILE_FILE" ".suggestions" "$suggestion"
    json_touch_file "$CROSSFILE_FILE"
    
    cat << EOF
{
  "type": "project_to_goal",
  "projectCount": $project_count,
  "theme": "$theme",
  "suggestion": "You have $project_count related projects. Would you like to group them under a common goal?",
  "targetFile": "GOALS.md"
}
EOF
    
    return 0
}

crossfile_on_idea_becomes_work() {
    local idea_id="$1"
    local work_context="${2:-}"
    
    _crossfile_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local ideas_file="${OBSERVATIONS_DIR}/ideas.json"
    if [[ ! -f "$ideas_file" ]]; then
        return 1
    fi
    
    local idea
    idea=$(json_read_file "$ideas_file" ".ideas.\"$idea_id\".idea")
    
    if [[ -z "$idea" ]] || [[ "$idea" == "null" ]]; then
        return 1
    fi
    
    local suggestion="{
        \"type\": \"idea_to_project\",
        \"sourceFile\": \"IDEAS.md\",
        \"sourceId\": \"$idea_id\",
        \"targetFile\": \"PROJECTS.md\",
        \"idea\": \"$idea\",
        \"workContext\": \"$work_context\",
        \"suggestedAction\": \"You're working on a documented idea - consider making it a project\",
        \"timestamp\": \"$timestamp\",
        \"status\": \"pending\"
    }"
    
    json_array_append "$CROSSFILE_FILE" ".suggestions" "$suggestion"
    json_touch_file "$CROSSFILE_FILE"
    
    cat << EOF
{
  "type": "idea_to_project",
  "idea": "$idea",
  "suggestion": "You're actively working on '$idea'. Would you like to promote it to a project?",
  "targetFile": "PROJECTS.md"
}
EOF
    
    return 0
}

crossfile_generate_review() {
    _crossfile_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local now_epoch
    now_epoch=$(date +%s)
    
    local stale_projects=""
    local resolved_challenges=""
    local stale_ideas=""
    
    local projects_file="${OBSERVATIONS_DIR}/projects.json"
    if [[ -f "$projects_file" ]]; then
        local project_ids
        project_ids=$(json_read_file "$projects_file" ".projects | keys[]" 2>/dev/null)
        
        for project_id in $project_ids; do
            [[ -z "$project_id" ]] && continue
            
            local last_seen status
            last_seen=$(json_read_file "$projects_file" ".projects.\"$project_id\".lastSeen")
            status=$(json_read_file "$projects_file" ".projects.\"$project_id\".status")
            
            [[ "$status" != "added" ]] && continue
            
            if [[ -n "$last_seen" ]]; then
                local last_epoch
                if [[ "$(uname)" == "Darwin" ]]; then
                    last_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_seen" +%s 2>/dev/null || echo "$now_epoch")
                else
                    last_epoch=$(date -d "$last_seen" +%s 2>/dev/null || echo "$now_epoch")
                fi
                
                local days_inactive=$(( (now_epoch - last_epoch) / 86400 ))
                
                if [[ $days_inactive -ge $CROSSFILE_STALE_DAYS ]]; then
                    local name
                    name=$(json_read_file "$projects_file" ".projects.\"$project_id\".suggestedName")
                    stale_projects+="$name ($days_inactive days), "
                fi
            fi
        done
    fi
    
    local challenges_file="${OBSERVATIONS_DIR}/challenges.json"
    if [[ -f "$challenges_file" ]]; then
        local challenge_ids
        challenge_ids=$(json_read_file "$challenges_file" ".challenges | keys[]" 2>/dev/null)
        
        for challenge_id in $challenge_ids; do
            [[ -z "$challenge_id" ]] && continue
            
            local status
            status=$(json_read_file "$challenges_file" ".challenges.\"$challenge_id\".status")
            
            if [[ "$status" == "resolved" ]]; then
                local pattern
                pattern=$(json_read_file "$challenges_file" ".challenges.\"$challenge_id\".pattern")
                resolved_challenges+="$pattern, "
            fi
        done
    fi
    
    local ideas_file="${OBSERVATIONS_DIR}/ideas.json"
    if [[ -f "$ideas_file" ]]; then
        local idea_ids
        idea_ids=$(json_read_file "$ideas_file" ".ideas | keys[]" 2>/dev/null)
        
        for idea_id in $idea_ids; do
            [[ -z "$idea_id" ]] && continue
            
            local status added_at
            status=$(json_read_file "$ideas_file" ".ideas.\"$idea_id\".status")
            added_at=$(json_read_file "$ideas_file" ".ideas.\"$idea_id\".addedAt")
            
            [[ "$status" != "Backlog" ]] && continue
            
            if [[ -n "$added_at" ]]; then
                local added_epoch
                if [[ "$(uname)" == "Darwin" ]]; then
                    added_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$added_at" +%s 2>/dev/null || echo "$now_epoch")
                else
                    added_epoch=$(date -d "$added_at" +%s 2>/dev/null || echo "$now_epoch")
                fi
                
                local days_old=$(( (now_epoch - added_epoch) / 86400 ))
                
                if [[ $days_old -ge $CROSSFILE_IDEA_STALE_DAYS ]]; then
                    local idea
                    idea=$(json_read_file "$ideas_file" ".ideas.\"$idea_id\".idea")
                    stale_ideas+="$idea ($days_old days), "
                fi
            fi
        done
    fi
    
    local pending_count
    pending_count=$(json_read_file "$CROSSFILE_FILE" '.suggestions | map(select(.status == "pending")) | length' 2>/dev/null)
    pending_count=${pending_count:-0}
    
    json_update_field "$CROSSFILE_FILE" ".lastReview" "\"$timestamp\""
    json_touch_file "$CROSSFILE_FILE"
    
    cat << EOF
{
  "timestamp": "$timestamp",
  "staleProjects": "${stale_projects%, }",
  "resolvedChallenges": "${resolved_challenges%, }",
  "staleIdeas": "${stale_ideas%, }",
  "pendingSuggestions": $pending_count
}
EOF
}

crossfile_get_pending_suggestions() {
    _crossfile_ensure_file
    json_read_file "$CROSSFILE_FILE" '.suggestions | map(select(.status == "pending"))'
}

crossfile_mark_suggestion_acted() {
    local index="$1"
    _crossfile_ensure_file
    json_update_field "$CROSSFILE_FILE" ".suggestions[$index].status" "\"acted\""
    json_touch_file "$CROSSFILE_FILE"
}

crossfile_mark_suggestion_dismissed() {
    local index="$1"
    _crossfile_ensure_file
    json_update_field "$CROSSFILE_FILE" ".suggestions[$index].status" "\"dismissed\""
    json_touch_file "$CROSSFILE_FILE"
}

crossfile_record_connection() {
    local source_file="$1"
    local source_item="$2"
    local target_file="$3"
    local target_item="$4"
    local connection_type="${5:-related}"
    
    _crossfile_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local connection="{
        \"sourceFile\": \"$source_file\",
        \"sourceItem\": \"$source_item\",
        \"targetFile\": \"$target_file\",
        \"targetItem\": \"$target_item\",
        \"type\": \"$connection_type\",
        \"timestamp\": \"$timestamp\"
    }"
    
    json_array_append "$CROSSFILE_FILE" ".connections" "$connection"
    json_touch_file "$CROSSFILE_FILE"
}

crossfile_get_connections() {
    local file="$1"
    local item="$2"
    
    _crossfile_ensure_file
    
    json_read_file "$CROSSFILE_FILE" ".connections | map(select(.sourceFile == \"$file\" and .sourceItem == \"$item\") or select(.targetFile == \"$file\" and .targetItem == \"$item\"))"
}

# ============================================
# EXPORTS
# ============================================

# Performance exports
export -f perf_is_processing
export -f perf_start_processing
export -f perf_end_processing
export -f perf_get_tier
export -f perf_set_tier
export -f perf_get_tier_detectors
export -f perf_detector_in_tier
export -f perf_record_time
export -f perf_should_run_detector
export -f perf_adjust_tier
export -f perf_get_metrics
export -f perf_get_session_overhead
export -f perf_update_session_time
export -f perf_check_overhead_warning
export -f perf_reset_session_metrics

# Cross-file exports
export -f crossfile_on_challenge_resolved
export -f crossfile_on_strategy_success
export -f crossfile_on_project_theme_detected
export -f crossfile_on_idea_becomes_work
export -f crossfile_generate_review
export -f crossfile_get_pending_suggestions
export -f crossfile_mark_suggestion_acted
export -f crossfile_mark_suggestion_dismissed
export -f crossfile_record_connection
export -f crossfile_get_connections
