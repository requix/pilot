#!/usr/bin/env bash
# observation-init.sh - Initialize observation directories for Adaptive Identity Capture
# Part of PILOT - Fail-safe design (always exits 0)
#
# Creates and validates the observation directory structure at runtime.
# Hooks should call ensure_observation_dirs() to auto-create directories if missing.
#
# Usage:
#   source observation-init.sh
#   ensure_observation_dirs
#
# Directory Structure:
#   ~/.pilot/observations/
#   ├── projects.json       # Project detection state
#   ├── sessions.json       # Session time tracking
#   ├── patterns.json       # Detected patterns (all types)
#   ├── challenges.json     # Challenge tracking
#   ├── prompts.json        # Prompt history and acceptance rate
#   ├── cross-file.json     # Cross-file connection tracking
#   └── performance.json    # Performance metrics

# Base directories
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
IDENTITY_DIR="${PILOT_DATA}/identity"
IDENTITY_HISTORY_DIR="${IDENTITY_DIR}/.history"

# Observation files
PROJECTS_FILE="${OBSERVATIONS_DIR}/projects.json"
SESSIONS_FILE="${OBSERVATIONS_DIR}/sessions.json"
PATTERNS_FILE="${OBSERVATIONS_DIR}/patterns.json"
CHALLENGES_FILE="${OBSERVATIONS_DIR}/challenges.json"
PROMPTS_FILE="${OBSERVATIONS_DIR}/prompts.json"
CROSSFILE_FILE="${OBSERVATIONS_DIR}/cross-file.json"
PERFORMANCE_FILE="${OBSERVATIONS_DIR}/performance.json"

# Initialize empty JSON file with default structure
# Usage: init_json_file "/path/to/file.json" '{"key": "value"}'
init_json_file() {
    local file="$1"
    local default_content="${2:-{}}"
    
    if [[ ! -f "$file" ]]; then
        echo "$default_content" > "$file" 2>/dev/null || true
    fi
}

# Ensure all observation directories exist
# Returns 0 on success, 1 if directories couldn't be created (read-only filesystem)
ensure_observation_dirs() {
    local success=0
    
    # Create main directories
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || success=1
    mkdir -p "$IDENTITY_HISTORY_DIR" 2>/dev/null || success=1
    
    # Initialize observation files with default structures
    init_json_file "$PROJECTS_FILE" '{
  "projects": {},
  "lastUpdated": null
}'
    
    init_json_file "$SESSIONS_FILE" '{
  "sessions": [],
  "currentSession": null,
  "lastUpdated": null
}'
    
    init_json_file "$PATTERNS_FILE" '{
  "beliefs": {},
  "strategies": {},
  "ideas": {},
  "models": {},
  "narratives": {},
  "workingStyle": {},
  "lastUpdated": null
}'
    
    init_json_file "$CHALLENGES_FILE" '{
  "challenges": {},
  "resolved": [],
  "lastUpdated": null
}'
    
    init_json_file "$PROMPTS_FILE" '{
  "history": [],
  "stats": {
    "totalShown": 0,
    "totalAccepted": 0,
    "acceptanceRate": 0,
    "consecutiveDismissals": 0,
    "frequencyMultiplier": 1.0
  },
  "limits": {
    "sessionPrompts": 0,
    "weekStart": null,
    "weekPrompts": 0
  }
}'
    
    init_json_file "$CROSSFILE_FILE" '{
  "connections": [],
  "suggestions": [],
  "lastReview": null
}'
    
    init_json_file "$PERFORMANCE_FILE" '{
  "currentTier": "standard",
  "detectorMetrics": {},
  "disabledDetectors": [],
  "tierHistory": [],
  "lastUpdated": null
}'
    
    return $success
}

# Check if observation system is writable
# Returns 0 if writable, 1 if read-only
is_observation_writable() {
    local test_file="${OBSERVATIONS_DIR}/.write-test-$$"
    
    if touch "$test_file" 2>/dev/null; then
        rm -f "$test_file" 2>/dev/null
        return 0
    fi
    return 1
}

# Get observation directory path
get_observations_dir() {
    echo "$OBSERVATIONS_DIR"
}

# Get identity history directory path
get_identity_history_dir() {
    echo "$IDENTITY_HISTORY_DIR"
}

# Check if observation system is initialized
is_observation_initialized() {
    [[ -d "$OBSERVATIONS_DIR" ]] && [[ -f "$PROJECTS_FILE" ]]
}

# Reset observation state (for testing or user request)
# WARNING: This deletes all observation data!
reset_observation_state() {
    if [[ -d "$OBSERVATIONS_DIR" ]]; then
        rm -rf "$OBSERVATIONS_DIR" 2>/dev/null || true
    fi
    ensure_observation_dirs
}

# Get current timestamp in ISO format
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Export functions for use by other scripts
export -f ensure_observation_dirs
export -f is_observation_writable
export -f get_observations_dir
export -f get_identity_history_dir
export -f is_observation_initialized
export -f reset_observation_state
export -f get_timestamp
export -f init_json_file
