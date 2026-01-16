#!/usr/bin/env bash
# identity-automation.sh - Identity Automation Controls for Adaptive Identity Capture
# Part of PILOT - Manages automation toggle and user controls
#
# Features:
# - Identity automation toggle (enable/disable)
# - Observation data viewing
# - Observation data deletion
# - Performance metrics display
# - Manual tier override
#
# Usage:
#   source identity-automation.sh
#   automation_is_enabled
#   automation_enable
#   automation_disable
#   automation_view_observations
#   automation_delete_observations
#   automation_get_metrics
#   automation_set_tier "minimal"

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/json-helpers.sh" ]] && source "${SCRIPT_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
PILOT_HOME="${HOME}/.kiro/pilot"
CONFIG_FILE="${PILOT_DATA}/config/pilot.json"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"

# ============================================
# INITIALIZATION
# ============================================

_automation_ensure_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")" 2>/dev/null || true
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" 2>/dev/null << 'EOF'
{
  "identity_automation_enabled": true,
  "observation_tier": "standard",
  "capture_limits": {
    "max_per_session": 1,
    "max_per_week": 3,
    "cooldown_days": 14,
    "dismiss_threshold": 3
  },
  "detection_thresholds": {
    "project_sessions": 2,
    "challenge_occurrences": 3,
    "belief_occurrences": 5,
    "strategy_occurrences": 3,
    "model_uses": 3,
    "stale_days": 30,
    "idea_stale_days": 90
  },
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# AUTOMATION TOGGLE
# ============================================

# Check if identity automation is enabled
automation_is_enabled() {
    _automation_ensure_config
    
    local enabled
    enabled=$(json_read_file "$CONFIG_FILE" ".identity_automation_enabled")
    
    [[ "$enabled" == "true" ]]
}

# Enable identity automation
automation_enable() {
    _automation_ensure_config
    
    json_update_field "$CONFIG_FILE" ".identity_automation_enabled" "true"
    json_touch_file "$CONFIG_FILE"
    
    echo "Identity automation enabled"
}

# Disable identity automation
automation_disable() {
    _automation_ensure_config
    
    json_update_field "$CONFIG_FILE" ".identity_automation_enabled" "false"
    json_touch_file "$CONFIG_FILE"
    
    echo "Identity automation disabled"
}

# Toggle identity automation
automation_toggle() {
    if automation_is_enabled; then
        automation_disable
    else
        automation_enable
    fi
}

# ============================================
# OBSERVATION DATA COMMANDS
# ============================================

# View observation data summary
automation_view_observations() {
    local format="${1:-summary}"  # summary, detailed, json
    
    if [[ ! -d "$OBSERVATIONS_DIR" ]]; then
        echo "No observation data found"
        return 1
    fi
    
    case "$format" in
        "json")
            # Output raw JSON files
            for file in "$OBSERVATIONS_DIR"/*.json; do
                [[ -f "$file" ]] || continue
                echo "=== $(basename "$file") ==="
                cat "$file"
                echo ""
            done
            ;;
        "detailed")
            # Detailed view with counts
            echo "=== Observation Data ==="
            echo ""
            
            # Projects
            if [[ -f "${OBSERVATIONS_DIR}/projects.json" ]]; then
                local project_count
                project_count=$(json_read_file "${OBSERVATIONS_DIR}/projects.json" ".projects | keys | length" 2>/dev/null || echo "0")
                echo "Projects tracked: $project_count"
                
                local project_ids
                project_ids=$(json_read_file "${OBSERVATIONS_DIR}/projects.json" ".projects | keys[]" 2>/dev/null)
                for pid in $project_ids; do
                    [[ -z "$pid" ]] && continue
                    local name sessions
                    name=$(json_read_file "${OBSERVATIONS_DIR}/projects.json" ".projects.\"$pid\".suggestedName")
                    sessions=$(json_read_file "${OBSERVATIONS_DIR}/projects.json" ".projects.\"$pid\".sessionCount")
                    echo "  - $name: $sessions sessions"
                done
            fi
            echo ""
            
            # Challenges
            if [[ -f "${OBSERVATIONS_DIR}/challenges.json" ]]; then
                local challenge_count
                challenge_count=$(json_read_file "${OBSERVATIONS_DIR}/challenges.json" ".challenges | keys | length" 2>/dev/null || echo "0")
                echo "Challenges tracked: $challenge_count"
            fi
            echo ""
            
            # Strategies
            if [[ -f "${OBSERVATIONS_DIR}/strategies.json" ]]; then
                local strategy_count
                strategy_count=$(json_read_file "${OBSERVATIONS_DIR}/strategies.json" ".strategies | keys | length" 2>/dev/null || echo "0")
                echo "Strategies tracked: $strategy_count"
            fi
            echo ""
            
            # Ideas
            if [[ -f "${OBSERVATIONS_DIR}/ideas.json" ]]; then
                local idea_count
                idea_count=$(json_read_file "${OBSERVATIONS_DIR}/ideas.json" ".ideas | keys | length" 2>/dev/null || echo "0")
                echo "Ideas tracked: $idea_count"
            fi
            echo ""
            
            # Beliefs
            if [[ -f "${OBSERVATIONS_DIR}/beliefs.json" ]]; then
                local belief_count
                belief_count=$(json_read_file "${OBSERVATIONS_DIR}/beliefs.json" ".beliefs | keys | length" 2>/dev/null || echo "0")
                echo "Beliefs tracked: $belief_count"
            fi
            ;;
        *)
            # Summary view
            echo "=== Observation Summary ==="
            
            local total_files=0
            local total_size=0
            
            for file in "$OBSERVATIONS_DIR"/*.json; do
                [[ -f "$file" ]] || continue
                total_files=$((total_files + 1))
                local size
                size=$(wc -c < "$file" 2>/dev/null || echo 0)
                total_size=$((total_size + size))
            done
            
            echo "Files: $total_files"
            echo "Total size: $((total_size / 1024)) KB"
            echo "Location: $OBSERVATIONS_DIR"
            
            # Quick counts
            local projects=0 challenges=0 strategies=0 ideas=0 beliefs=0
            [[ -f "${OBSERVATIONS_DIR}/projects.json" ]] && projects=$(json_read_file "${OBSERVATIONS_DIR}/projects.json" ".projects | keys | length" 2>/dev/null || echo "0")
            [[ -f "${OBSERVATIONS_DIR}/challenges.json" ]] && challenges=$(json_read_file "${OBSERVATIONS_DIR}/challenges.json" ".challenges | keys | length" 2>/dev/null || echo "0")
            [[ -f "${OBSERVATIONS_DIR}/strategies.json" ]] && strategies=$(json_read_file "${OBSERVATIONS_DIR}/strategies.json" ".strategies | keys | length" 2>/dev/null || echo "0")
            [[ -f "${OBSERVATIONS_DIR}/ideas.json" ]] && ideas=$(json_read_file "${OBSERVATIONS_DIR}/ideas.json" ".ideas | keys | length" 2>/dev/null || echo "0")
            [[ -f "${OBSERVATIONS_DIR}/beliefs.json" ]] && beliefs=$(json_read_file "${OBSERVATIONS_DIR}/beliefs.json" ".beliefs | keys | length" 2>/dev/null || echo "0")
            
            echo ""
            echo "Tracked items:"
            echo "  Projects: $projects"
            echo "  Challenges: $challenges"
            echo "  Strategies: $strategies"
            echo "  Ideas: $ideas"
            echo "  Beliefs: $beliefs"
            ;;
    esac
}

# Delete all observation data
automation_delete_observations() {
    local confirm="${1:-}"
    
    if [[ "$confirm" != "yes" ]] && [[ "$confirm" != "--force" ]]; then
        echo "This will delete all observation data."
        echo "To confirm, run: automation_delete_observations yes"
        return 1
    fi
    
    if [[ ! -d "$OBSERVATIONS_DIR" ]]; then
        echo "No observation data to delete"
        return 0
    fi
    
    # Delete all JSON files in observations directory
    rm -f "${OBSERVATIONS_DIR}"/*.json 2>/dev/null || true
    
    # Recreate empty files
    [[ -f "${PILOT_HOME}/lib/observation-init.sh" ]] && source "${PILOT_HOME}/lib/observation-init.sh" 2>/dev/null
    ensure_observation_dirs 2>/dev/null || true
    
    echo "Observation data deleted and reset"
}

# Delete specific observation type
automation_delete_observation_type() {
    local type="$1"
    
    case "$type" in
        "projects")
            rm -f "${OBSERVATIONS_DIR}/projects.json" 2>/dev/null
            echo '{"projects": {}, "lastUpdated": null}' > "${OBSERVATIONS_DIR}/projects.json"
            ;;
        "challenges")
            rm -f "${OBSERVATIONS_DIR}/challenges.json" 2>/dev/null
            echo '{"challenges": {}, "resolved": [], "lastUpdated": null}' > "${OBSERVATIONS_DIR}/challenges.json"
            ;;
        "strategies")
            rm -f "${OBSERVATIONS_DIR}/strategies.json" 2>/dev/null
            echo '{"strategies": {}, "approaches": [], "failures": [], "lastUpdated": null}' > "${OBSERVATIONS_DIR}/strategies.json"
            ;;
        "ideas")
            rm -f "${OBSERVATIONS_DIR}/ideas.json" 2>/dev/null
            echo '{"ideas": {}, "detections": [], "lastUpdated": null}' > "${OBSERVATIONS_DIR}/ideas.json"
            ;;
        "beliefs")
            rm -f "${OBSERVATIONS_DIR}/beliefs.json" 2>/dev/null
            echo '{"beliefs": {}, "decisions": [], "lastUpdated": null}' > "${OBSERVATIONS_DIR}/beliefs.json"
            ;;
        "prompts")
            rm -f "${OBSERVATIONS_DIR}/prompts.json" 2>/dev/null
            echo '{"history": [], "stats": {"totalShown": 0, "totalAccepted": 0}, "limits": {"sessionPrompts": 0, "weekPrompts": 0}}' > "${OBSERVATIONS_DIR}/prompts.json"
            ;;
        *)
            echo "Unknown observation type: $type"
            echo "Valid types: projects, challenges, strategies, ideas, beliefs, prompts"
            return 1
            ;;
    esac
    
    echo "Deleted $type observation data"
}

# ============================================
# PERFORMANCE METRICS
# ============================================

# Get performance metrics
automation_get_metrics() {
    local format="${1:-summary}"
    
    local perf_file="${OBSERVATIONS_DIR}/performance.json"
    
    if [[ ! -f "$perf_file" ]]; then
        echo "No performance data available"
        return 1
    fi
    
    case "$format" in
        "json")
            cat "$perf_file"
            ;;
        "detailed")
            echo "=== Performance Metrics ==="
            echo ""
            
            local tier
            tier=$(json_read_file "$perf_file" ".currentTier")
            echo "Current tier: $tier"
            echo ""
            
            echo "Detector metrics:"
            local detectors
            detectors=$(json_read_file "$perf_file" ".detectorMetrics | keys[]" 2>/dev/null)
            for detector in $detectors; do
                [[ -z "$detector" ]] && continue
                local avg_time call_count
                avg_time=$(json_read_file "$perf_file" ".detectorMetrics.\"$detector\".avgTime")
                call_count=$(json_read_file "$perf_file" ".detectorMetrics.\"$detector\".callCount")
                echo "  $detector: ${avg_time}ms avg, $call_count calls"
            done
            echo ""
            
            local disabled
            disabled=$(json_read_file "$perf_file" ".disabledDetectors | length" 2>/dev/null || echo "0")
            echo "Disabled detectors: $disabled"
            ;;
        *)
            local tier avg_time
            tier=$(json_read_file "$perf_file" ".currentTier")
            echo "Tier: $tier"
            
            # Calculate overall average
            local total_time=0 total_calls=0
            local detectors
            detectors=$(json_read_file "$perf_file" ".detectorMetrics | keys[]" 2>/dev/null)
            for detector in $detectors; do
                [[ -z "$detector" ]] && continue
                local avg call_count
                avg=$(json_read_file "$perf_file" ".detectorMetrics.\"$detector\".avgTime")
                call_count=$(json_read_file "$perf_file" ".detectorMetrics.\"$detector\".callCount")
                avg=${avg:-0}
                call_count=${call_count:-0}
                total_time=$((total_time + avg * call_count))
                total_calls=$((total_calls + call_count))
            done
            
            if [[ $total_calls -gt 0 ]]; then
                avg_time=$((total_time / total_calls))
                echo "Avg processing: ${avg_time}ms"
            fi
            ;;
    esac
}

# ============================================
# TIER OVERRIDE
# ============================================

# Set observation tier manually
automation_set_tier() {
    local tier="$1"
    
    case "$tier" in
        "minimal"|"standard"|"full")
            _automation_ensure_config
            json_update_field "$CONFIG_FILE" ".observation_tier" "\"$tier\""
            json_touch_file "$CONFIG_FILE"
            
            # Also update performance file if it exists
            local perf_file="${OBSERVATIONS_DIR}/performance.json"
            if [[ -f "$perf_file" ]]; then
                json_update_field "$perf_file" ".currentTier" "\"$tier\""
                json_update_field "$perf_file" ".tierOverride" "true"
                json_touch_file "$perf_file"
            fi
            
            echo "Observation tier set to: $tier"
            ;;
        "auto")
            _automation_ensure_config
            json_update_field "$CONFIG_FILE" ".observation_tier" "\"standard\""
            json_touch_file "$CONFIG_FILE"
            
            local perf_file="${OBSERVATIONS_DIR}/performance.json"
            if [[ -f "$perf_file" ]]; then
                json_update_field "$perf_file" ".tierOverride" "false"
                json_touch_file "$perf_file"
            fi
            
            echo "Observation tier set to auto (default: standard)"
            ;;
        *)
            echo "Invalid tier: $tier"
            echo "Valid tiers: minimal, standard, full, auto"
            return 1
            ;;
    esac
}

# Get current tier
automation_get_tier() {
    _automation_ensure_config
    
    local tier
    tier=$(json_read_file "$CONFIG_FILE" ".observation_tier")
    echo "${tier:-standard}"
}

# ============================================
# CONFIGURATION
# ============================================

# Get configuration value
automation_get_config() {
    local key="$1"
    
    _automation_ensure_config
    
    json_read_file "$CONFIG_FILE" ".$key"
}

# Set configuration value
automation_set_config() {
    local key="$1"
    local value="$2"
    
    _automation_ensure_config
    
    # Determine if value is numeric or string
    if [[ "$value" =~ ^[0-9]+$ ]]; then
        json_update_field "$CONFIG_FILE" ".$key" "$value"
    elif [[ "$value" == "true" ]] || [[ "$value" == "false" ]]; then
        json_update_field "$CONFIG_FILE" ".$key" "$value"
    else
        json_update_field "$CONFIG_FILE" ".$key" "\"$value\""
    fi
    
    json_touch_file "$CONFIG_FILE"
    echo "Set $key = $value"
}

# Show all configuration
automation_show_config() {
    _automation_ensure_config
    
    echo "=== Identity Automation Configuration ==="
    cat "$CONFIG_FILE"
}

# ============================================
# EXPORTS
# ============================================

export -f automation_is_enabled
export -f automation_enable
export -f automation_disable
export -f automation_toggle
export -f automation_view_observations
export -f automation_delete_observations
export -f automation_delete_observation_type
export -f automation_get_metrics
export -f automation_set_tier
export -f automation_get_tier
export -f automation_get_config
export -f automation_set_config
export -f automation_show_config
