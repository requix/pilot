#!/usr/bin/env bash
# error-recovery.sh - Error Handling and Recovery for Adaptive Identity Capture
# Part of PILOT - Provides graceful degradation and error recovery
#
# Features:
# - Try-catch patterns for detectors
# - Error logging
# - Corrupted file recovery
# - Session overhead tracking
#
# Usage:
#   source error-recovery.sh
#   error_try "command" "fallback"
#   error_recover_file "$file"
#   error_track_overhead "$start_time"

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/json-helpers.sh" ]] && source "${SCRIPT_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
LOGS_DIR="${PILOT_DATA}/logs"
ERROR_LOG="${LOGS_DIR}/errors.log"
OVERHEAD_FILE="${OBSERVATIONS_DIR}/overhead.json"

# Configuration
ERROR_LOG_MAX_SIZE=1048576       # 1MB max log size
OVERHEAD_WARNING_THRESHOLD=0.05  # 5% of session time
OVERHEAD_CRITICAL_THRESHOLD=0.10 # 10% of session time

# ============================================
# INITIALIZATION
# ============================================

_error_ensure_dirs() {
    mkdir -p "$LOGS_DIR" 2>/dev/null || true
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$OVERHEAD_FILE" ]]; then
        cat > "$OVERHEAD_FILE" 2>/dev/null << 'EOF'
{
  "sessions": [],
  "totalSessionTime": 0,
  "totalOverheadTime": 0,
  "averageOverheadPercent": 0,
  "warnings": [],
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# TRY-CATCH PATTERNS
# ============================================

# Execute command with fallback on error
error_try() {
    local command="$1"
    local fallback="${2:-}"
    local context="${3:-unknown}"
    
    local result
    local exit_code
    
    # Execute command and capture output/exit code
    result=$(eval "$command" 2>&1)
    exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        # Log error
        error_log "ERROR" "$context" "Command failed: $command" "$result"
        
        # Execute fallback if provided
        if [[ -n "$fallback" ]]; then
            result=$(eval "$fallback" 2>&1)
            exit_code=$?
        fi
    fi
    
    echo "$result"
    return $exit_code
}

# Execute with timeout
error_try_timeout() {
    local timeout_ms="$1"
    local command="$2"
    local fallback="${3:-}"
    local context="${4:-unknown}"
    
    local timeout_sec
    timeout_sec=$(echo "scale=2; $timeout_ms / 1000" | bc 2>/dev/null || echo "5")
    
    local result
    local exit_code
    
    # Use timeout command if available
    if command -v timeout >/dev/null 2>&1; then
        result=$(timeout "$timeout_sec" bash -c "$command" 2>&1)
        exit_code=$?
    elif command -v gtimeout >/dev/null 2>&1; then
        result=$(gtimeout "$timeout_sec" bash -c "$command" 2>&1)
        exit_code=$?
    else
        # Fallback: run without timeout
        result=$(eval "$command" 2>&1)
        exit_code=$?
    fi
    
    # Check for timeout (exit code 124)
    if [[ $exit_code -eq 124 ]]; then
        error_log "TIMEOUT" "$context" "Command timed out after ${timeout_ms}ms: $command"
        
        if [[ -n "$fallback" ]]; then
            result=$(eval "$fallback" 2>&1)
            exit_code=$?
        fi
    elif [[ $exit_code -ne 0 ]]; then
        error_log "ERROR" "$context" "Command failed: $command" "$result"
        
        if [[ -n "$fallback" ]]; then
            result=$(eval "$fallback" 2>&1)
            exit_code=$?
        fi
    fi
    
    echo "$result"
    return $exit_code
}

# Safe detector execution wrapper
error_safe_detector() {
    local detector_name="$1"
    local detector_func="$2"
    shift 2
    local args=("$@")
    
    local start_time
    start_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    local result
    local exit_code
    
    # Execute detector with error handling
    result=$("$detector_func" "${args[@]}" 2>&1)
    exit_code=$?
    
    local end_time
    end_time=$(date +%s%3N 2>/dev/null || date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $exit_code -ne 0 ]]; then
        error_log "DETECTOR_ERROR" "$detector_name" "Detector failed" "$result"
        echo '{"error": true, "detector": "'"$detector_name"'", "duration": '"$duration"'}'
        return 1
    fi
    
    echo "$result"
    return 0
}

# ============================================
# ERROR LOGGING
# ============================================

# Log an error
error_log() {
    local level="$1"
    local context="$2"
    local message="$3"
    local details="${4:-}"
    
    _error_ensure_dirs
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Rotate log if too large
    if [[ -f "$ERROR_LOG" ]]; then
        local size
        size=$(wc -c < "$ERROR_LOG" | tr -d ' ')
        if [[ $size -gt $ERROR_LOG_MAX_SIZE ]]; then
            mv "$ERROR_LOG" "${ERROR_LOG}.old" 2>/dev/null || true
        fi
    fi
    
    # Write log entry
    cat >> "$ERROR_LOG" << EOF
[$timestamp] [$level] [$context]
  Message: $message
EOF
    
    if [[ -n "$details" ]]; then
        echo "  Details: $details" >> "$ERROR_LOG"
    fi
    
    echo "" >> "$ERROR_LOG"
}

# Get recent errors
error_get_recent() {
    local count="${1:-10}"
    
    _error_ensure_dirs
    
    if [[ ! -f "$ERROR_LOG" ]]; then
        echo "No errors logged"
        return
    fi
    
    # Get last N entries (each entry is ~4 lines)
    tail -n $((count * 5)) "$ERROR_LOG"
}

# Clear error log
error_clear_log() {
    _error_ensure_dirs
    
    if [[ -f "$ERROR_LOG" ]]; then
        local backup="${ERROR_LOG}.$(date +%Y%m%d%H%M%S)"
        mv "$ERROR_LOG" "$backup" 2>/dev/null || true
    fi
    
    touch "$ERROR_LOG"
}

# ============================================
# FILE RECOVERY
# ============================================

# Recover a corrupted JSON file
error_recover_file() {
    local file="$1"
    local default_content="${2:-{}}"
    
    _error_ensure_dirs
    
    if [[ ! -f "$file" ]]; then
        # File doesn't exist - create with default
        echo "$default_content" > "$file"
        error_log "RECOVERY" "file_recovery" "Created missing file: $file"
        return 0
    fi
    
    # Check if file is valid JSON
    if command -v jq >/dev/null 2>&1; then
        if jq . "$file" >/dev/null 2>&1; then
            # File is valid
            return 0
        fi
    fi
    
    # File is corrupted - attempt recovery
    error_log "RECOVERY" "file_recovery" "Attempting to recover corrupted file: $file"
    
    # Backup corrupted file
    local backup="${file}.corrupted.$(date +%s)"
    mv "$file" "$backup" 2>/dev/null || true
    
    # Check for backup file
    if [[ -f "${file}.backup" ]]; then
        if command -v jq >/dev/null 2>&1 && jq . "${file}.backup" >/dev/null 2>&1; then
            # Backup is valid - restore it
            cp "${file}.backup" "$file"
            error_log "RECOVERY" "file_recovery" "Restored from backup: $file"
            return 0
        fi
    fi
    
    # No valid backup - create fresh file
    echo "$default_content" > "$file"
    error_log "RECOVERY" "file_recovery" "Created fresh file (no valid backup): $file"
    return 0
}

# Validate and repair all observation files
error_validate_observations() {
    _error_ensure_dirs
    
    local files_checked=0
    local files_repaired=0
    
    # Define default content for each file type
    declare -A defaults
    defaults["projects.json"]='{"projects": {}, "lastUpdated": null}'
    defaults["challenges.json"]='{"challenges": {}, "resolved": [], "lastUpdated": null}'
    defaults["patterns.json"]='{"beliefs": {}, "strategies": {}, "ideas": {}, "models": {}, "narratives": {}, "workingStyle": {}, "lastUpdated": null}'
    defaults["prompts.json"]='{"history": [], "stats": {"totalShown": 0, "totalAccepted": 0}, "limits": {"sessionPrompts": 0, "weekPrompts": 0}}'
    defaults["time-allocation.json"]='{"activeSessions": {}, "allocations": {}, "weeklyTotals": {}, "monthlyTotals": {}, "warnings": [], "lastUpdated": null}'
    defaults["goals.json"]='{"inferredGoals": {}, "projectClusters": {}, "missionHints": [], "lastUpdated": null}'
    defaults["working-style.json"]='{"responseFormat": {}, "sessionTimes": [], "technologies": {}, "communicationPatterns": {}, "lastUpdated": null}'
    defaults["evolution.json"]='{"staleProjects": [], "techSnapshots": [], "completedGoals": [], "evolutionEvents": [], "lastUpdated": null}'
    
    for filename in "${!defaults[@]}"; do
        local file="${OBSERVATIONS_DIR}/${filename}"
        ((files_checked++))
        
        if ! error_recover_file "$file" "${defaults[$filename]}"; then
            ((files_repaired++))
        fi
    done
    
    echo "{\"filesChecked\": $files_checked, \"filesRepaired\": $files_repaired}"
}

# ============================================
# OVERHEAD TRACKING
# ============================================

# Start overhead tracking for a session
error_start_overhead_tracking() {
    _error_ensure_dirs
    
    local start_time
    start_time=$(date +%s)
    
    echo "$start_time"
}

# Record overhead time
error_record_overhead() {
    local operation="$1"
    local duration_ms="$2"
    
    _error_ensure_dirs
    
    # This is tracked per-operation for detailed analysis
    # Aggregated in error_end_overhead_tracking
}

# End overhead tracking and calculate totals
error_end_overhead_tracking() {
    local session_start="$1"
    local total_overhead_ms="$2"
    
    _error_ensure_dirs
    
    local session_end
    session_end=$(date +%s)
    local session_duration=$((session_end - session_start))
    
    # Avoid division by zero
    [[ $session_duration -eq 0 ]] && session_duration=1
    
    local overhead_seconds
    overhead_seconds=$(echo "scale=2; $total_overhead_ms / 1000" | bc 2>/dev/null || echo "0")
    
    local overhead_percent
    overhead_percent=$(echo "scale=4; $overhead_seconds / $session_duration" | bc 2>/dev/null || echo "0")
    
    # Record session
    local session_data="{
        \"sessionStart\": $session_start,
        \"sessionDuration\": $session_duration,
        \"overheadMs\": $total_overhead_ms,
        \"overheadPercent\": $overhead_percent
    }"
    
    json_array_append "$OVERHEAD_FILE" ".sessions" "$session_data"
    
    # Update totals
    local current_total_session current_total_overhead
    current_total_session=$(json_read_file "$OVERHEAD_FILE" ".totalSessionTime")
    current_total_overhead=$(json_read_file "$OVERHEAD_FILE" ".totalOverheadTime")
    
    current_total_session=${current_total_session:-0}
    current_total_overhead=${current_total_overhead:-0}
    
    local new_total_session=$((current_total_session + session_duration))
    local new_total_overhead=$((current_total_overhead + total_overhead_ms))
    
    json_update_field "$OVERHEAD_FILE" ".totalSessionTime" "$new_total_session"
    json_update_field "$OVERHEAD_FILE" ".totalOverheadTime" "$new_total_overhead"
    
    # Calculate average
    local avg_percent
    if [[ $new_total_session -gt 0 ]]; then
        avg_percent=$(echo "scale=4; ($new_total_overhead / 1000) / $new_total_session" | bc 2>/dev/null || echo "0")
    else
        avg_percent="0"
    fi
    
    json_update_field "$OVERHEAD_FILE" ".averageOverheadPercent" "$avg_percent"
    json_touch_file "$OVERHEAD_FILE"
    
    # Check thresholds and warn
    local warning=""
    if (( $(echo "$overhead_percent > $OVERHEAD_CRITICAL_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
        warning="critical"
        error_log "OVERHEAD" "session" "Critical overhead: ${overhead_percent}% of session time"
    elif (( $(echo "$overhead_percent > $OVERHEAD_WARNING_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
        warning="warning"
        error_log "OVERHEAD" "session" "High overhead: ${overhead_percent}% of session time"
    fi
    
    cat << EOF
{
  "sessionDuration": $session_duration,
  "overheadMs": $total_overhead_ms,
  "overheadPercent": $overhead_percent,
  "warning": "$warning"
}
EOF
}

# Get overhead statistics
error_get_overhead_stats() {
    _error_ensure_dirs
    
    if [[ ! -f "$OVERHEAD_FILE" ]]; then
        echo '{"totalSessionTime": 0, "totalOverheadTime": 0, "averageOverheadPercent": 0}'
        return
    fi
    
    local total_session total_overhead avg_percent
    total_session=$(json_read_file "$OVERHEAD_FILE" ".totalSessionTime")
    total_overhead=$(json_read_file "$OVERHEAD_FILE" ".totalOverheadTime")
    avg_percent=$(json_read_file "$OVERHEAD_FILE" ".averageOverheadPercent")
    
    cat << EOF
{
  "totalSessionTime": ${total_session:-0},
  "totalOverheadTime": ${total_overhead:-0},
  "averageOverheadPercent": ${avg_percent:-0}
}
EOF
}

# ============================================
# GRACEFUL DEGRADATION
# ============================================

# Check if system should degrade gracefully
error_should_degrade() {
    _error_ensure_dirs
    
    # Check overhead
    local avg_percent
    avg_percent=$(json_read_file "$OVERHEAD_FILE" ".averageOverheadPercent")
    avg_percent=${avg_percent:-0}
    
    if (( $(echo "$avg_percent > $OVERHEAD_CRITICAL_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
        echo '{"shouldDegrade": true, "reason": "high_overhead", "overheadPercent": '"$avg_percent"'}'
        return 0
    fi
    
    # Check for repeated errors
    if [[ -f "$ERROR_LOG" ]]; then
        local recent_errors
        recent_errors=$(grep -c "^\[" "$ERROR_LOG" 2>/dev/null || echo 0)
        
        if [[ $recent_errors -gt 50 ]]; then
            echo '{"shouldDegrade": true, "reason": "many_errors", "errorCount": '"$recent_errors"'}'
            return 0
        fi
    fi
    
    echo '{"shouldDegrade": false}'
    return 1
}

# ============================================
# EXPORTS
# ============================================

export -f error_try
export -f error_try_timeout
export -f error_safe_detector
export -f error_log
export -f error_get_recent
export -f error_clear_log
export -f error_recover_file
export -f error_validate_observations
export -f error_start_overhead_tracking
export -f error_record_overhead
export -f error_end_overhead_tracking
export -f error_get_overhead_stats
export -f error_should_degrade
