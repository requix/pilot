#!/usr/bin/env bash
# time-allocation.sh - Time Allocation Tracking for Adaptive Identity Capture
# Part of PILOT - Tracks time spent on projects and detects allocation issues
#
# Features:
# - Session time tracking per project
# - Allocation variance detection
# - Overflow warning when exceeding planned allocation
# - Weekly/monthly time summaries
#
# Usage:
#   source time-allocation.sh
#   time_start_session "$project_id"
#   time_end_session "$project_id"
#   time_get_allocation_status "$project_id"
#   time_check_overflow

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/json-helpers.sh" ]] && source "${SCRIPT_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
TIME_FILE="${OBSERVATIONS_DIR}/time-allocation.json"
PROJECTS_FILE="${OBSERVATIONS_DIR}/projects.json"

# Configuration
TIME_OVERFLOW_THRESHOLD=1.2      # 120% of planned allocation triggers warning
TIME_VARIANCE_THRESHOLD=0.3      # 30% variance from average triggers detection
TIME_MIN_SESSIONS_FOR_AVERAGE=3  # Minimum sessions before calculating average

# ============================================
# INITIALIZATION
# ============================================

_time_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$TIME_FILE" ]]; then
        cat > "$TIME_FILE" 2>/dev/null << 'EOF'
{
  "activeSessions": {},
  "allocations": {},
  "weeklyTotals": {},
  "monthlyTotals": {},
  "warnings": [],
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# SESSION TRACKING
# ============================================

# Start tracking time for a session
time_start_session() {
    local project_id="$1"
    local working_dir="${2:-}"
    
    _time_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local epoch
    epoch=$(date +%s)
    
    # Record active session
    local session_data="{
        \"projectId\": \"$project_id\",
        \"workingDir\": \"$working_dir\",
        \"startTime\": \"$timestamp\",
        \"startEpoch\": $epoch
    }"
    
    json_set_nested "$TIME_FILE" ".activeSessions.\"$project_id\"" "$session_data"
    json_touch_file "$TIME_FILE"
    
    echo "$epoch"
}

# End tracking time for a session and record duration
time_end_session() {
    local project_id="$1"
    
    _time_ensure_file
    
    # Get active session
    local session_data
    session_data=$(json_read_file "$TIME_FILE" ".activeSessions.\"$project_id\"")
    
    if [[ -z "$session_data" ]] || [[ "$session_data" == "null" ]]; then
        echo "0"
        return 1
    fi
    
    local start_epoch
    start_epoch=$(echo "$session_data" | grep -o '"startEpoch":[0-9]*' | cut -d: -f2)
    start_epoch=${start_epoch:-0}
    
    local end_epoch
    end_epoch=$(date +%s)
    
    local duration=$((end_epoch - start_epoch))
    
    # Remove active session
    json_delete_field "$TIME_FILE" ".activeSessions.\"$project_id\""
    
    # Record to weekly/monthly totals
    _time_record_duration "$project_id" "$duration"
    
    json_touch_file "$TIME_FILE"
    
    echo "$duration"
}

# Record duration to weekly and monthly totals
_time_record_duration() {
    local project_id="$1"
    local duration="$2"
    
    local week_key month_key
    week_key=$(date +"%Y-W%V")
    month_key=$(date +"%Y-%m")
    
    # Update weekly total
    local current_weekly
    current_weekly=$(json_read_file "$TIME_FILE" ".weeklyTotals.\"$week_key\".\"$project_id\"")
    current_weekly=${current_weekly:-0}
    [[ "$current_weekly" == "null" ]] && current_weekly=0
    
    local new_weekly=$((current_weekly + duration))
    json_set_nested "$TIME_FILE" ".weeklyTotals.\"$week_key\".\"$project_id\"" "$new_weekly"
    
    # Update monthly total
    local current_monthly
    current_monthly=$(json_read_file "$TIME_FILE" ".monthlyTotals.\"$month_key\".\"$project_id\"")
    current_monthly=${current_monthly:-0}
    [[ "$current_monthly" == "null" ]] && current_monthly=0
    
    local new_monthly=$((current_monthly + duration))
    json_set_nested "$TIME_FILE" ".monthlyTotals.\"$month_key\".\"$project_id\"" "$new_monthly"
}

# ============================================
# ALLOCATION MANAGEMENT
# ============================================

# Set planned allocation for a project (hours per week)
time_set_allocation() {
    local project_id="$1"
    local hours_per_week="$2"
    
    _time_ensure_file
    
    local seconds_per_week=$((hours_per_week * 3600))
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local allocation_data="{
        \"hoursPerWeek\": $hours_per_week,
        \"secondsPerWeek\": $seconds_per_week,
        \"setAt\": \"$timestamp\"
    }"
    
    json_set_nested "$TIME_FILE" ".allocations.\"$project_id\"" "$allocation_data"
    json_touch_file "$TIME_FILE"
}

# Get allocation status for a project
time_get_allocation_status() {
    local project_id="$1"
    
    _time_ensure_file
    
    local week_key
    week_key=$(date +"%Y-W%V")
    
    # Get planned allocation
    local planned_seconds
    planned_seconds=$(json_read_file "$TIME_FILE" ".allocations.\"$project_id\".secondsPerWeek")
    planned_seconds=${planned_seconds:-0}
    [[ "$planned_seconds" == "null" ]] && planned_seconds=0
    
    # Get actual time this week
    local actual_seconds
    actual_seconds=$(json_read_file "$TIME_FILE" ".weeklyTotals.\"$week_key\".\"$project_id\"")
    actual_seconds=${actual_seconds:-0}
    [[ "$actual_seconds" == "null" ]] && actual_seconds=0
    
    # Calculate percentage
    local percentage=0
    if [[ $planned_seconds -gt 0 ]]; then
        percentage=$((actual_seconds * 100 / planned_seconds))
    fi
    
    # Determine allocation status
    local alloc_status="on_track"
    if [[ $planned_seconds -gt 0 ]]; then
        local threshold_seconds
        threshold_seconds=$(echo "$planned_seconds * $TIME_OVERFLOW_THRESHOLD" | bc 2>/dev/null || echo $((planned_seconds * 12 / 10)))
        threshold_seconds=${threshold_seconds%.*}
        
        if [[ $actual_seconds -gt $threshold_seconds ]]; then
            alloc_status="overflow"
        elif [[ $actual_seconds -gt $planned_seconds ]]; then
            alloc_status="over"
        elif [[ $actual_seconds -lt $((planned_seconds / 2)) ]]; then
            alloc_status="under"
        fi
    fi
    
    cat << EOF
{
  "projectId": "$project_id",
  "plannedSeconds": $planned_seconds,
  "actualSeconds": $actual_seconds,
  "percentage": $percentage,
  "status": "$alloc_status",
  "weekKey": "$week_key"
}
EOF
}

# ============================================
# OVERFLOW DETECTION
# ============================================

# Check all projects for overflow warnings
time_check_overflow() {
    _time_ensure_file
    
    local week_key
    week_key=$(date +"%Y-W%V")
    
    local warnings="[]"
    
    # Get all allocations
    local project_ids
    project_ids=$(json_read_file "$TIME_FILE" ".allocations | keys[]" 2>/dev/null)
    
    for project_id in $project_ids; do
        [[ -z "$project_id" ]] && continue
        
        local status_json
        status_json=$(time_get_allocation_status "$project_id")
        
        local alloc_status
        alloc_status=$(echo "$status_json" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        
        if [[ "$alloc_status" == "overflow" ]]; then
            local actual percentage
            actual=$(echo "$status_json" | grep -o '"actualSeconds":[0-9]*' | cut -d: -f2)
            percentage=$(echo "$status_json" | grep -o '"percentage":[0-9]*' | cut -d: -f2)
            
            echo "{\"projectId\": \"$project_id\", \"status\": \"overflow\", \"percentage\": $percentage, \"actualSeconds\": $actual}"
        fi
    done
}

# ============================================
# VARIANCE DETECTION
# ============================================

# Detect significant variance from average session duration
time_detect_variance() {
    local project_id="$1"
    local current_duration="$2"
    
    _time_ensure_file
    
    # Get session history from projects.json
    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo '{"hasVariance": false, "reason": "no_history"}'
        return
    fi
    
    local sessions
    sessions=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".sessions")
    
    if [[ -z "$sessions" ]] || [[ "$sessions" == "null" ]]; then
        echo '{"hasVariance": false, "reason": "no_sessions"}'
        return
    fi
    
    # Count sessions
    local session_count
    session_count=$(echo "$sessions" | grep -c '"duration"' 2>/dev/null || echo 0)
    
    if [[ $session_count -lt $TIME_MIN_SESSIONS_FOR_AVERAGE ]]; then
        echo '{"hasVariance": false, "reason": "insufficient_data"}'
        return
    fi
    
    # Calculate average duration (simplified - sum durations and divide)
    local total_duration=0
    local durations
    durations=$(echo "$sessions" | grep -o '"duration":[0-9]*' | cut -d: -f2)
    
    for dur in $durations; do
        total_duration=$((total_duration + dur))
    done
    
    local average=$((total_duration / session_count))
    
    # Check variance
    local diff
    if [[ $current_duration -gt $average ]]; then
        diff=$((current_duration - average))
    else
        diff=$((average - current_duration))
    fi
    
    local variance_ratio=0
    if [[ $average -gt 0 ]]; then
        variance_ratio=$((diff * 100 / average))
    fi
    
    local threshold_percent=$((TIME_VARIANCE_THRESHOLD * 100))
    threshold_percent=${threshold_percent%.*}
    
    if [[ $variance_ratio -gt $threshold_percent ]]; then
        cat << EOF
{
  "hasVariance": true,
  "averageDuration": $average,
  "currentDuration": $current_duration,
  "variancePercent": $variance_ratio,
  "direction": "$([ $current_duration -gt $average ] && echo 'longer' || echo 'shorter')"
}
EOF
    else
        echo '{"hasVariance": false, "reason": "within_threshold"}'
    fi
}

# ============================================
# TIME SUMMARIES
# ============================================

# Get weekly time summary
time_get_weekly_summary() {
    local week_key="${1:-$(date +"%Y-W%V")}"
    
    _time_ensure_file
    
    local weekly_data
    weekly_data=$(json_read_file "$TIME_FILE" ".weeklyTotals.\"$week_key\"")
    
    if [[ -z "$weekly_data" ]] || [[ "$weekly_data" == "null" ]]; then
        echo '{"weekKey": "'"$week_key"'", "projects": {}, "totalSeconds": 0}'
        return
    fi
    
    # Calculate total
    local total=0
    local project_times
    project_times=$(echo "$weekly_data" | grep -o '"[^"]*":[0-9]*' | while read -r line; do
        local val
        val=$(echo "$line" | cut -d: -f2)
        echo "$val"
    done)
    
    for t in $project_times; do
        total=$((total + t))
    done
    
    cat << EOF
{
  "weekKey": "$week_key",
  "projects": $weekly_data,
  "totalSeconds": $total
}
EOF
}

# Get monthly time summary
time_get_monthly_summary() {
    local month_key="${1:-$(date +"%Y-%m")}"
    
    _time_ensure_file
    
    local monthly_data
    monthly_data=$(json_read_file "$TIME_FILE" ".monthlyTotals.\"$month_key\"")
    
    if [[ -z "$monthly_data" ]] || [[ "$monthly_data" == "null" ]]; then
        echo '{"monthKey": "'"$month_key"'", "projects": {}, "totalSeconds": 0}'
        return
    fi
    
    # Calculate total
    local total=0
    local project_times
    project_times=$(echo "$monthly_data" | grep -o '"[^"]*":[0-9]*' | while read -r line; do
        local val
        val=$(echo "$line" | cut -d: -f2)
        echo "$val"
    done)
    
    for t in $project_times; do
        total=$((total + t))
    done
    
    cat << EOF
{
  "monthKey": "$month_key",
  "projects": $monthly_data,
  "totalSeconds": $total
}
EOF
}

# Format seconds as human-readable duration
time_format_duration() {
    local seconds="$1"
    
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    
    if [[ $hours -gt 0 ]]; then
        echo "${hours}h ${minutes}m"
    else
        echo "${minutes}m"
    fi
}

# ============================================
# EXPORTS
# ============================================

export -f time_start_session
export -f time_end_session
export -f time_set_allocation
export -f time_get_allocation_status
export -f time_check_overflow
export -f time_detect_variance
export -f time_get_weekly_summary
export -f time_get_monthly_summary
export -f time_format_duration
