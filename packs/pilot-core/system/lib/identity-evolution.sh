#!/usr/bin/env bash
# identity-evolution.sh - Identity Evolution Detection for Adaptive Identity Capture
# Part of PILOT - Detects when identity elements become stale or change
#
# Features:
# - Stale project detection (30 days inactive)
# - Technology preference change detection
# - Goal completion detection
# - Identity drift warnings
#
# Usage:
#   source identity-evolution.sh
#   evolution_check_stale_projects
#   evolution_detect_tech_changes
#   evolution_check_goal_completion

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/json-helpers.sh" ]] && source "${SCRIPT_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
IDENTITY_DIR="${PILOT_DATA}/identity"
PROJECTS_FILE="${OBSERVATIONS_DIR}/projects.json"
EVOLUTION_FILE="${OBSERVATIONS_DIR}/evolution.json"
STYLE_FILE="${OBSERVATIONS_DIR}/working-style.json"

# Configuration
STALE_PROJECT_DAYS=30            # Days before project is considered stale
TECH_CHANGE_THRESHOLD=0.5        # 50% change in tech mentions triggers detection
GOAL_COMPLETION_KEYWORDS="done|complete|finished|shipped|launched|deployed"

# ============================================
# INITIALIZATION
# ============================================

_evolution_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$EVOLUTION_FILE" ]]; then
        cat > "$EVOLUTION_FILE" 2>/dev/null << 'EOF'
{
  "staleProjects": [],
  "techSnapshots": [],
  "completedGoals": [],
  "evolutionEvents": [],
  "lastCheck": null,
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# STALE PROJECT DETECTION
# ============================================

# Check for stale projects (not accessed in 30 days)
evolution_check_stale_projects() {
    _evolution_ensure_file
    
    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo '{"staleProjects": []}'
        return
    fi
    
    local now_epoch
    now_epoch=$(date +%s)
    local stale_threshold=$((STALE_PROJECT_DAYS * 86400))
    
    local stale_projects=""
    
    # Get all projects
    local project_ids
    project_ids=$(json_read_file "$PROJECTS_FILE" ".projects | keys[]" 2>/dev/null)
    
    for project_id in $project_ids; do
        [[ -z "$project_id" ]] && continue
        
        local last_seen project_status
        last_seen=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".lastSeen")
        project_status=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".status")
        
        # Skip if already marked as stale or archived
        [[ "$project_status" == "stale" ]] && continue
        [[ "$project_status" == "archived" ]] && continue
        
        [[ -z "$last_seen" ]] && continue
        
        # Parse last seen date
        local last_seen_epoch
        if [[ "$(uname)" == "Darwin" ]]; then
            last_seen_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_seen" +%s 2>/dev/null || echo 0)
        else
            last_seen_epoch=$(date -d "$last_seen" +%s 2>/dev/null || echo 0)
        fi
        
        local age=$((now_epoch - last_seen_epoch))
        
        if [[ $age -gt $stale_threshold ]]; then
            local suggested_name days_inactive
            suggested_name=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".suggestedName")
            days_inactive=$((age / 86400))
            
            echo "{\"projectId\": \"$project_id\", \"name\": \"$suggested_name\", \"daysInactive\": $days_inactive, \"lastSeen\": \"$last_seen\"}"
        fi
    done
}

# Mark project as stale
evolution_mark_project_stale() {
    local project_id="$1"
    
    if [[ ! -f "$PROJECTS_FILE" ]]; then
        return 1
    fi
    
    json_update_field "$PROJECTS_FILE" ".projects.\"$project_id\".status" "\"stale\""
    json_touch_file "$PROJECTS_FILE"
    
    # Record evolution event
    _evolution_record_event "project_stale" "$project_id"
}

# Archive a stale project
evolution_archive_project() {
    local project_id="$1"
    
    if [[ ! -f "$PROJECTS_FILE" ]]; then
        return 1
    fi
    
    json_update_field "$PROJECTS_FILE" ".projects.\"$project_id\".status" "\"archived\""
    json_touch_file "$PROJECTS_FILE"
    
    _evolution_record_event "project_archived" "$project_id"
}

# Reactivate a stale project
evolution_reactivate_project() {
    local project_id="$1"
    
    if [[ ! -f "$PROJECTS_FILE" ]]; then
        return 1
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    json_update_field "$PROJECTS_FILE" ".projects.\"$project_id\".status" "\"active\""
    json_update_field "$PROJECTS_FILE" ".projects.\"$project_id\".lastSeen" "\"$timestamp\""
    json_touch_file "$PROJECTS_FILE"
    
    _evolution_record_event "project_reactivated" "$project_id"
}

# ============================================
# TECHNOLOGY PREFERENCE CHANGES
# ============================================

# Take a snapshot of current tech preferences
evolution_snapshot_tech() {
    _evolution_ensure_file
    
    if [[ ! -f "$STYLE_FILE" ]]; then
        return
    fi
    
    local techs
    techs=$(json_read_file "$STYLE_FILE" ".technologies")
    
    [[ -z "$techs" ]] && return
    [[ "$techs" == "null" ]] && return
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local snapshot="{\"timestamp\": \"$timestamp\", \"technologies\": $techs}"
    
    json_array_append "$EVOLUTION_FILE" ".techSnapshots" "$snapshot"
    
    # Keep only last 10 snapshots
    local count
    count=$(json_array_length "$EVOLUTION_FILE" ".techSnapshots")
    
    while [[ $count -gt 10 ]]; do
        json_array_remove "$EVOLUTION_FILE" ".techSnapshots" "0"
        ((count--))
    done
    
    json_touch_file "$EVOLUTION_FILE"
}

# Detect significant changes in tech preferences
evolution_detect_tech_changes() {
    _evolution_ensure_file
    
    local snapshot_count
    snapshot_count=$(json_array_length "$EVOLUTION_FILE" ".techSnapshots")
    
    if [[ $snapshot_count -lt 2 ]]; then
        echo '{"hasChanges": false, "reason": "insufficient_data"}'
        return
    fi
    
    # Get first and last snapshots
    local first_snapshot last_snapshot
    first_snapshot=$(json_read_file "$EVOLUTION_FILE" ".techSnapshots[0].technologies")
    last_snapshot=$(json_read_file "$EVOLUTION_FILE" ".techSnapshots[-1].technologies")
    
    [[ -z "$first_snapshot" ]] && { echo '{"hasChanges": false, "reason": "no_first_snapshot"}'; return; }
    [[ -z "$last_snapshot" ]] && { echo '{"hasChanges": false, "reason": "no_last_snapshot"}'; return; }
    
    # Compare top technologies
    local first_top last_top
    first_top=$(echo "$first_snapshot" | grep -o '"[^"]*":[0-9]*' | sort -t: -k2 -rn | head -3 | cut -d'"' -f2)
    last_top=$(echo "$last_snapshot" | grep -o '"[^"]*":[0-9]*' | sort -t: -k2 -rn | head -3 | cut -d'"' -f2)
    
    # Check for new technologies in top 3
    local new_techs=""
    local dropped_techs=""
    
    for tech in $last_top; do
        if ! echo "$first_top" | grep -q "$tech"; then
            new_techs="$new_techs $tech"
        fi
    done
    
    for tech in $first_top; do
        if ! echo "$last_top" | grep -q "$tech"; then
            dropped_techs="$dropped_techs $tech"
        fi
    done
    
    if [[ -n "$new_techs" ]] || [[ -n "$dropped_techs" ]]; then
        cat << EOF
{
  "hasChanges": true,
  "newTechnologies": "${new_techs# }",
  "droppedTechnologies": "${dropped_techs# }",
  "snapshotCount": $snapshot_count
}
EOF
    else
        echo '{"hasChanges": false, "reason": "no_significant_changes"}'
    fi
}

# ============================================
# GOAL COMPLETION DETECTION
# ============================================

# Check user input for goal completion signals
evolution_check_goal_completion() {
    local input="$1"
    
    _evolution_ensure_file
    
    # Check for completion keywords
    if ! echo "$input" | grep -qiE "$GOAL_COMPLETION_KEYWORDS"; then
        return 1
    fi
    
    # Extract potential goal/project name
    local potential_goal=""
    
    # Pattern: "finished [project]" or "[project] is done"
    if [[ "$input" =~ (finished|completed|shipped|launched|deployed)[[:space:]]+([a-zA-Z0-9_-]+) ]]; then
        potential_goal="${BASH_REMATCH[2]}"
    elif [[ "$input" =~ ([a-zA-Z0-9_-]+)[[:space:]]+(is|are)[[:space:]]+(done|complete|finished) ]]; then
        potential_goal="${BASH_REMATCH[1]}"
    fi
    
    if [[ -n "$potential_goal" ]]; then
        echo "{\"detected\": true, \"potentialGoal\": \"$potential_goal\", \"input\": \"$input\"}"
        return 0
    fi
    
    return 1
}

# Record a completed goal
evolution_record_goal_completion() {
    local goal_name="$1"
    local completion_type="${2:-manual}"
    
    _evolution_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local completion_data="{
        \"goal\": \"$goal_name\",
        \"completedAt\": \"$timestamp\",
        \"type\": \"$completion_type\"
    }"
    
    json_array_append "$EVOLUTION_FILE" ".completedGoals" "$completion_data"
    json_touch_file "$EVOLUTION_FILE"
    
    _evolution_record_event "goal_completed" "$goal_name"
}

# ============================================
# EVOLUTION EVENTS
# ============================================

# Record an evolution event
_evolution_record_event() {
    local event_type="$1"
    local subject="$2"
    
    _evolution_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local event_data="{
        \"type\": \"$event_type\",
        \"subject\": \"$subject\",
        \"timestamp\": \"$timestamp\"
    }"
    
    json_array_append "$EVOLUTION_FILE" ".evolutionEvents" "$event_data"
    
    # Keep only last 50 events
    local count
    count=$(json_array_length "$EVOLUTION_FILE" ".evolutionEvents")
    
    while [[ $count -gt 50 ]]; do
        json_array_remove "$EVOLUTION_FILE" ".evolutionEvents" "0"
        ((count--))
    done
    
    json_touch_file "$EVOLUTION_FILE"
}

# Get recent evolution events
evolution_get_recent_events() {
    local limit="${1:-10}"
    
    _evolution_ensure_file
    
    json_read_file "$EVOLUTION_FILE" ".evolutionEvents | .[-$limit:]"
}

# ============================================
# IDENTITY REVIEW
# ============================================

# Generate identity evolution summary
evolution_get_summary() {
    _evolution_ensure_file
    
    # Count stale projects
    local stale_count=0
    local stale_output
    stale_output=$(evolution_check_stale_projects)
    stale_count=$(echo "$stale_output" | grep -c "projectId" || echo 0)
    
    # Check tech changes
    local tech_changes
    tech_changes=$(evolution_detect_tech_changes)
    local has_tech_changes
    has_tech_changes=$(echo "$tech_changes" | grep -o '"hasChanges":[a-z]*' | cut -d: -f2)
    
    # Count completed goals
    local completed_goals
    completed_goals=$(json_array_length "$EVOLUTION_FILE" ".completedGoals")
    
    # Count recent events
    local recent_events
    recent_events=$(json_array_length "$EVOLUTION_FILE" ".evolutionEvents")
    
    cat << EOF
{
  "staleProjectCount": $stale_count,
  "hasTechChanges": $has_tech_changes,
  "completedGoalCount": $completed_goals,
  "recentEventCount": $recent_events,
  "needsReview": $([ $stale_count -gt 0 ] || [ "$has_tech_changes" == "true" ] && echo "true" || echo "false")
}
EOF
}

# Run periodic evolution check
evolution_run_check() {
    _evolution_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Take tech snapshot
    evolution_snapshot_tech
    
    # Update last check time
    json_update_field "$EVOLUTION_FILE" ".lastCheck" "\"$timestamp\""
    json_touch_file "$EVOLUTION_FILE"
    
    # Return summary
    evolution_get_summary
}

# ============================================
# EXPORTS
# ============================================

export -f evolution_check_stale_projects
export -f evolution_mark_project_stale
export -f evolution_archive_project
export -f evolution_reactivate_project
export -f evolution_snapshot_tech
export -f evolution_detect_tech_changes
export -f evolution_check_goal_completion
export -f evolution_record_goal_completion
export -f evolution_get_recent_events
export -f evolution_get_summary
export -f evolution_run_check
