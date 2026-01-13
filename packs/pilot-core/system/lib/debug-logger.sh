#!/usr/bin/env bash
# debug-logger.sh - Debug logging utilities for PILOT hooks
# Part of PILOT (Platform for Intelligent Lifecycle Operations and Tools)
#
# Enable debug logging with PILOT_DEBUG=1 environment variable
# Logs are written to ~/.kiro/pilot/debug/hook-input.log
#
# Usage:
#   source debug-logger.sh
#   debug_init
#   debug_log_input "hook_name" "$input_json"
#   debug_log "message"

# Debug configuration
PILOT_DEBUG_DIR="${HOME}/.kiro/pilot/debug"
PILOT_DEBUG_LOG="${PILOT_DEBUG_DIR}/hook-input.log"
PILOT_DEBUG_MAX_LINES=10000

# Initialize debug logging
# Creates debug directory if PILOT_DEBUG=1 is set
debug_init() {
    if [ "${PILOT_DEBUG:-0}" = "1" ]; then
        mkdir -p "$PILOT_DEBUG_DIR" 2>/dev/null || true
    fi
}

# Log raw hook input for debugging
# Usage: debug_log_input "hook_name" "$input_json"
# Arguments:
#   $1 - Hook name (e.g., "agent-spawn", "post-tool-use")
#   $2 - Raw input JSON received by the hook
debug_log_input() {
    # Early return if debug not enabled (fast path)
    [ "${PILOT_DEBUG:-0}" != "1" ] && return 0
    
    local hook_name="${1:-unknown}"
    local input="${2:-}"
    local timestamp
    
    # Get timestamp (cross-platform)
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
    
    # Ensure debug directory exists
    mkdir -p "$PILOT_DEBUG_DIR" 2>/dev/null || return 0
    
    # Write to debug log
    {
        echo "=== [$timestamp] $hook_name ==="
        echo "$input"
        echo ""
    } >> "$PILOT_DEBUG_LOG" 2>/dev/null || true
    
    # Rotate log if too large (non-blocking)
    _debug_rotate_log &
}

# Log general debug message
# Usage: debug_log "message"
# Arguments:
#   $1 - Debug message to log
debug_log() {
    # Early return if debug not enabled (fast path)
    [ "${PILOT_DEBUG:-0}" != "1" ] && return 0
    
    local message="${1:-}"
    local timestamp
    
    # Get timestamp (cross-platform)
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
    
    # Ensure debug directory exists
    mkdir -p "$PILOT_DEBUG_DIR" 2>/dev/null || return 0
    
    # Write to debug log
    echo "[$timestamp] $message" >> "$PILOT_DEBUG_LOG" 2>/dev/null || true
}

# Log error message (always logged, not just in debug mode)
# Usage: debug_log_error "error message"
# Arguments:
#   $1 - Error message to log
debug_log_error() {
    local message="${1:-}"
    local timestamp
    local error_log="${PILOT_DEBUG_DIR}/errors.log"
    
    # Get timestamp (cross-platform)
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
    
    # Ensure debug directory exists
    mkdir -p "$PILOT_DEBUG_DIR" 2>/dev/null || return 0
    
    # Write to error log
    echo "[$timestamp] ERROR: $message" >> "$error_log" 2>/dev/null || true
    
    # Also write to debug log if enabled
    if [ "${PILOT_DEBUG:-0}" = "1" ]; then
        echo "[$timestamp] ERROR: $message" >> "$PILOT_DEBUG_LOG" 2>/dev/null || true
    fi
}

# Internal: Rotate debug log if too large
# Runs in background to avoid blocking hook execution
_debug_rotate_log() {
    # Only rotate if file exists and is large
    if [ -f "$PILOT_DEBUG_LOG" ]; then
        local line_count
        line_count=$(wc -l < "$PILOT_DEBUG_LOG" 2>/dev/null | tr -d ' ' || echo 0)
        
        if [ "$line_count" -gt "$PILOT_DEBUG_MAX_LINES" ]; then
            # Keep last half of entries
            local keep_lines=$((PILOT_DEBUG_MAX_LINES / 2))
            tail -n "$keep_lines" "$PILOT_DEBUG_LOG" > "${PILOT_DEBUG_LOG}.tmp" 2>/dev/null
            mv "${PILOT_DEBUG_LOG}.tmp" "$PILOT_DEBUG_LOG" 2>/dev/null || true
        fi
    fi
}

# Check if debug mode is enabled
# Usage: if debug_enabled; then ...; fi
debug_enabled() {
    [ "${PILOT_DEBUG:-0}" = "1" ]
}

# Get debug log path
# Usage: log_path=$(debug_get_log_path)
debug_get_log_path() {
    echo "$PILOT_DEBUG_LOG"
}
