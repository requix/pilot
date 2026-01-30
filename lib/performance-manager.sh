#!/usr/bin/env bash
# performance-manager.sh - Performance management for Adaptive Identity Capture
# Part of PILOT - Manages observation system performance and adaptive behavior
#
# Features:
# - Processing time tracking per detector
# - Tier management (minimal/standard/full)
# - Auto-disable logic for slow detectors
# - Queue buildup detection
#
# Usage:
#   source performance-manager.sh
#   perf_start_processing
#   perf_record_time "ProjectDetector" 25
#   perf_end_processing

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/json-helpers.sh" ]] && source "${SCRIPT_DIR}/json-helpers.sh"

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
PERF_REENABLE_MS=3600000  # 1 hour in ms
PERF_SESSION_OVERHEAD_WARN=5  # 5%

# Observation tiers
TIER_MINIMAL="minimal"
TIER_STANDARD="standard"
TIER_FULL="full"

# Detectors by tier
DETECTORS_MINIMAL="ProjectDetector ChallengeDetector"
DETECTORS_STANDARD="ProjectDetector ChallengeDetector LearningExtractor StrategyDetector IdeaCapturer BeliefDetector"
DETECTORS_FULL="ProjectDetector ChallengeDetector LearningExtractor StrategyDetector IdeaCapturer BeliefDetector ModelDetector NarrativeDetector"

# ============================================
# INITIALIZATION
# ============================================

# Ensure performance file exists with defaults
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

# ============================================
# PROCESSING LOCK (Queue Buildup Prevention)
# ============================================

# Check if previous hook is still processing
perf_is_processing() {
    if [[ -f "$LOCK_FILE" ]]; then
        # Check if lock is stale (older than 5 seconds)
        local lock_age
        if [[ "$(uname)" == "Darwin" ]]; then
            lock_age=$(( $(date +%s) - $(stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0) ))
        else
            lock_age=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
        fi
        
        if [[ $lock_age -gt 5 ]]; then
            rm -f "$LOCK_FILE" 2>/dev/null || true
            return 1  # Not processing (stale lock)
        fi
        return 0  # Still processing
    fi
    return 1  # Not processing
}

# Mark processing start
perf_start_processing() {
    _perf_ensure_file
    echo "$$" > "$LOCK_FILE" 2>/dev/null || true
}

# Mark processing end
perf_end_processing() {
    rm -f "$LOCK_FILE" 2>/dev/null || true
}

# ============================================
# TIER MANAGEMENT
# ============================================

# Get current observation tier
perf_get_tier() {
    _perf_ensure_file
    local tier
    tier=$(json_read_file "$PERFORMANCE_FILE" ".currentTier")
    echo "${tier:-$TIER_STANDARD}"
}

# Set observation tier
perf_set_tier() {
    local new_tier="$1"
    local reason="${2:-manual}"
    
    _perf_ensure_file
    
    local old_tier
    old_tier=$(perf_get_tier)
    
    if [[ "$old_tier" != "$new_tier" ]]; then
        local timestamp
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        
        # Update tier
        json_update_field "$PERFORMANCE_FILE" ".currentTier" "\"$new_tier\""
        
        # Record tier change in history
        local change_record="{\"from\": \"$old_tier\", \"to\": \"$new_tier\", \"timestamp\": \"$timestamp\", \"reason\": \"$reason\"}"
        json_array_append "$PERFORMANCE_FILE" ".tierHistory" "$change_record"
        
        json_touch_file "$PERFORMANCE_FILE"
    fi
}

# Get detectors for current tier
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

# Check if detector is in current tier
perf_detector_in_tier() {
    local detector="$1"
    local detectors
    detectors=$(perf_get_tier_detectors)
    
    [[ " $detectors " == *" $detector "* ]]
}

# ============================================
# PROCESSING TIME TRACKING
# ============================================

# Record processing time for a detector
perf_record_time() {
    local detector="$1"
    local duration_ms="$2"
    
    _perf_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Get current metrics for detector
    local current_avg current_max call_count slow_count
    current_avg=$(json_read_file "$PERFORMANCE_FILE" ".detectorMetrics.\"$detector\".avgMs")
    current_max=$(json_read_file "$PERFORMANCE_FILE" ".detectorMetrics.\"$detector\".maxMs")
    call_count=$(json_read_file "$PERFORMANCE_FILE" ".detectorMetrics.\"$detector\".callCount")
    slow_count=$(json_read_file "$PERFORMANCE_FILE" ".detectorMetrics.\"$detector\".consecutiveSlowCalls")
    
    # Default values
    current_avg=${current_avg:-0}
    current_max=${current_max:-0}
    call_count=${call_count:-0}
    slow_count=${slow_count:-0}
    
    # Calculate new average (exponential moving average)
    local new_avg
    if [[ $call_count -eq 0 ]]; then
        new_avg=$duration_ms
    else
        # EMA with alpha=0.3
        new_avg=$(( (duration_ms * 30 + current_avg * 70) / 100 ))
    fi
    
    # Update max
    local new_max=$current_max
    [[ $duration_ms -gt $current_max ]] && new_max=$duration_ms
    
    # Track consecutive slow calls
    if [[ $duration_ms -gt $PERF_WARNING_MS ]]; then
        slow_count=$((slow_count + 1))
    else
        slow_count=0
    fi
    
    # Update metrics
    local metrics="{\"avgMs\": $new_avg, \"maxMs\": $new_max, \"callCount\": $((call_count + 1)), \"consecutiveSlowCalls\": $slow_count, \"lastCall\": \"$timestamp\", \"lastDuration\": $duration_ms}"
    json_set_nested "$PERFORMANCE_FILE" ".detectorMetrics.\"$detector\"" "$metrics"
    
    # Update session totals
    json_increment "$PERFORMANCE_FILE" ".sessionMetrics.totalProcessingMs" "$duration_ms"
    json_increment "$PERFORMANCE_FILE" ".sessionMetrics.callCount" 1
    
    # Check for auto-disable
    if [[ $slow_count -ge $PERF_CONSECUTIVE_SLOW ]] && [[ $duration_ms -gt $PERF_WARNING_MS ]]; then
        _perf_disable_detector "$detector" "consecutive_slow_calls"
    fi
    
    # Log warning if slow
    if [[ $duration_ms -gt $PERF_WARNING_MS ]]; then
        echo "[PERF WARNING] $detector took ${duration_ms}ms (threshold: ${PERF_WARNING_MS}ms)" >&2
    fi
    
    json_touch_file "$PERFORMANCE_FILE"
}

# ============================================
# DETECTOR ENABLE/DISABLE
# ============================================

# Disable a detector
_perf_disable_detector() {
    local detector="$1"
    local reason="$2"
    
    local timestamp reenable_at
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Calculate re-enable time (1 hour from now)
    if [[ "$(uname)" == "Darwin" ]]; then
        reenable_at=$(date -u -v+1H +"%Y-%m-%dT%H:%M:%SZ")
    else
        reenable_at=$(date -u -d "+1 hour" +"%Y-%m-%dT%H:%M:%SZ")
    fi
    
    local disable_record="{\"detector\": \"$detector\", \"timestamp\": \"$timestamp\", \"reason\": \"$reason\", \"reEnableAt\": \"$reenable_at\"}"
    json_array_append "$PERFORMANCE_FILE" ".disabledDetectors" "$disable_record"
    
    echo "[PERF] Auto-disabled $detector due to $reason. Will re-enable at $reenable_at" >&2
}

# Check if detector should run
perf_should_run_detector() {
    local detector="$1"
    
    _perf_ensure_file
    
    # Check if in current tier
    if ! perf_detector_in_tier "$detector"; then
        return 1
    fi
    
    # Check if disabled
    local disabled_count
    disabled_count=$(json_array_length "$PERFORMANCE_FILE" ".disabledDetectors")
    
    if [[ $disabled_count -gt 0 ]]; then
        local now_epoch
        now_epoch=$(date +%s)
        
        # Check each disabled detector
        local i=0
        while [[ $i -lt $disabled_count ]]; do
            local disabled_detector reenable_at
            disabled_detector=$(json_read_file "$PERFORMANCE_FILE" ".disabledDetectors[$i].detector")
            reenable_at=$(json_read_file "$PERFORMANCE_FILE" ".disabledDetectors[$i].reEnableAt")
            
            if [[ "$disabled_detector" == "$detector" ]]; then
                # Check if cooldown has passed
                local reenable_epoch
                if [[ "$(uname)" == "Darwin" ]]; then
                    reenable_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$reenable_at" +%s 2>/dev/null || echo 0)
                else
                    reenable_epoch=$(date -d "$reenable_at" +%s 2>/dev/null || echo 0)
                fi
                
                if [[ $now_epoch -lt $reenable_epoch ]]; then
                    return 1  # Still disabled
                else
                    # Re-enable: remove from disabled list
                    json_array_remove "$PERFORMANCE_FILE" ".disabledDetectors" "$i"
                    echo "[PERF] Re-enabled $detector after cooldown" >&2
                    return 0
                fi
            fi
            i=$((i + 1))
        done
    fi
    
    return 0  # Should run
}

# ============================================
# TIER AUTO-ADJUSTMENT
# ============================================

# Auto-adjust tier based on performance
perf_adjust_tier() {
    _perf_ensure_file
    
    local current_tier avg_time
    current_tier=$(perf_get_tier)
    
    # Calculate overall average processing time
    local total_ms call_count
    total_ms=$(json_read_file "$PERFORMANCE_FILE" ".sessionMetrics.totalProcessingMs")
    call_count=$(json_read_file "$PERFORMANCE_FILE" ".sessionMetrics.callCount")
    
    total_ms=${total_ms:-0}
    call_count=${call_count:-1}
    
    avg_time=$((total_ms / call_count))
    
    # Downgrade if average exceeds warning threshold
    if [[ $avg_time -gt $PERF_WARNING_MS ]]; then
        case "$current_tier" in
            "$TIER_FULL")
                perf_set_tier "$TIER_STANDARD" "performance_degradation"
                ;;
            "$TIER_STANDARD")
                perf_set_tier "$TIER_MINIMAL" "performance_degradation"
                ;;
        esac
    # Upgrade if average is well under normal threshold
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

# ============================================
# METRICS
# ============================================

# Get performance metrics summary
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

# Calculate session overhead percentage
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

# Update total session time
perf_update_session_time() {
    local session_ms="$1"
    json_update_field "$PERFORMANCE_FILE" ".sessionMetrics.totalSessionMs" "$session_ms"
}

# Check and warn about session overhead
perf_check_overhead_warning() {
    local overhead
    overhead=$(perf_get_session_overhead)
    
    if [[ $overhead -gt $PERF_SESSION_OVERHEAD_WARN ]]; then
        echo "[PERF WARNING] Observation overhead is ${overhead}% of session time (threshold: ${PERF_SESSION_OVERHEAD_WARN}%)" >&2
        return 0
    fi
    return 1
}

# Reset session metrics (call at session start)
perf_reset_session_metrics() {
    _perf_ensure_file
    
    local reset_metrics='{"totalProcessingMs": 0, "totalSessionMs": 0, "callCount": 0}'
    json_update_field "$PERFORMANCE_FILE" ".sessionMetrics" "$reset_metrics"
}

# ============================================
# EXPORTS
# ============================================

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
