#!/usr/bin/env bash
# project-detector.sh - Project detection for Adaptive Identity Capture
# Part of PILOT - Identifies when users are working on distinct projects
#
# Features:
# - Directory-to-project-id hashing
# - Session counting per project
# - Suggestion threshold logic (2+ sessions)
# - Decline cooldown (7 days)
#
# Usage:
#   source project-detector.sh
#   project_detect "/path/to/project"
#   project_record_session "$project_id" 3600
#   project_get_suggestions

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
[[ -f "${LIB_DIR}/json-helpers.sh" ]] && source "${LIB_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
PROJECTS_FILE="${OBSERVATIONS_DIR}/projects.json"

# Configuration
PROJECT_SESSION_THRESHOLD=2      # Sessions before suggesting
PROJECT_DECLINE_COOLDOWN_DAYS=7  # Days before re-suggesting after decline

# ============================================
# INITIALIZATION
# ============================================

_project_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$PROJECTS_FILE" ]]; then
        cat > "$PROJECTS_FILE" 2>/dev/null << 'EOF'
{
  "projects": {},
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# PROJECT ID GENERATION
# ============================================

# Generate a consistent project ID from a directory path
# Uses MD5 hash of normalized path for consistency
project_generate_id() {
    local dir="$1"
    
    # Normalize path (resolve symlinks, remove trailing slash)
    local normalized
    normalized=$(cd "$dir" 2>/dev/null && pwd -P) || normalized="$dir"
    normalized="${normalized%/}"
    
    # Generate hash (use md5 on macOS, md5sum on Linux)
    local hash
    if command -v md5 >/dev/null 2>&1; then
        hash=$(echo -n "$normalized" | md5)
    elif command -v md5sum >/dev/null 2>&1; then
        hash=$(echo -n "$normalized" | md5sum | cut -d' ' -f1)
    else
        # Fallback: use simple hash
        hash=$(echo -n "$normalized" | cksum | cut -d' ' -f1)
    fi
    
    # Return first 12 characters
    echo "${hash:0:12}"
}

# Extract suggested project name from directory path
project_suggest_name() {
    local dir="$1"
    
    # Get the last component of the path
    local name
    name=$(basename "$dir")
    
    # Clean up common patterns
    name="${name#.}"  # Remove leading dot
    
    echo "$name"
}

# ============================================
# PROJECT DETECTION
# ============================================

# Detect project from working directory
# Returns JSON with project info
project_detect() {
    local working_dir="$1"
    
    _project_ensure_file
    
    local project_id suggested_name
    project_id=$(project_generate_id "$working_dir")
    suggested_name=$(project_suggest_name "$working_dir")
    
    # Check if project exists
    local existing
    existing=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\"")
    
    local is_new="true"
    local session_count=0
    local last_seen=""
    
    if [[ -n "$existing" ]] && [[ "$existing" != "null" ]]; then
        is_new="false"
        session_count=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".sessionCount")
        last_seen=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".lastSeen")
        session_count=${session_count:-0}
    fi
    
    # Return detection result as JSON
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

# ============================================
# SESSION RECORDING
# ============================================

# Record a session for a project
project_record_session() {
    local project_id="$1"
    local duration="${2:-0}"
    local working_dir="${3:-}"
    
    _project_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Get existing project data
    local existing
    existing=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
        # Create new project entry
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
        
        json_set_nested "$PROJECTS_FILE" ".projects.\"$project_id\"" "$new_project"
    else
        # Update existing project
        local current_count current_time
        current_count=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".sessionCount")
        current_time=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".totalTime")
        
        current_count=${current_count:-0}
        current_time=${current_time:-0}
        
        # Add session to array
        local session_record="{\"start\": \"$timestamp\", \"duration\": $duration}"
        json_array_append "$PROJECTS_FILE" ".projects.\"$project_id\".sessions" "$session_record"
        
        # Update counts
        json_update_field "$PROJECTS_FILE" ".projects.\"$project_id\".sessionCount" "$((current_count + 1))"
        json_update_field "$PROJECTS_FILE" ".projects.\"$project_id\".totalTime" "$((current_time + duration))"
        json_update_field "$PROJECTS_FILE" ".projects.\"$project_id\".lastSeen" "\"$timestamp\""
    fi
    
    json_touch_file "$PROJECTS_FILE"
}

# ============================================
# SUGGESTION LOGIC
# ============================================

# Get projects that meet suggestion threshold
project_get_suggestions() {
    _project_ensure_file
    
    local now_epoch
    now_epoch=$(date +%s)
    
    local suggestions="[]"
    
    # Get all project IDs
    local project_ids
    project_ids=$(json_read_file "$PROJECTS_FILE" ".projects | keys[]" 2>/dev/null)
    
    for project_id in $project_ids; do
        # Skip if empty
        [[ -z "$project_id" ]] && continue
        
        local status session_count declined_until
        status=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".status")
        session_count=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".sessionCount")
        declined_until=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".declinedUntil")
        
        session_count=${session_count:-0}
        
        # Skip if already added to identity
        [[ "$status" == "added" ]] && continue
        
        # Skip if below threshold
        [[ $session_count -lt $PROJECT_SESSION_THRESHOLD ]] && continue
        
        # Check decline cooldown
        if [[ -n "$declined_until" ]] && [[ "$declined_until" != "null" ]]; then
            local declined_epoch
            if [[ "$(uname)" == "Darwin" ]]; then
                declined_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$declined_until" +%s 2>/dev/null || echo 0)
            else
                declined_epoch=$(date -d "$declined_until" +%s 2>/dev/null || echo 0)
            fi
            
            [[ $now_epoch -lt $declined_epoch ]] && continue
        fi
        
        # Get project details for suggestion
        local suggested_name working_dir total_time
        suggested_name=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".suggestedName")
        working_dir=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".workingDir")
        total_time=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".totalTime")
        
        echo "{\"projectId\": \"$project_id\", \"suggestedName\": \"$suggested_name\", \"workingDir\": \"$working_dir\", \"sessionCount\": $session_count, \"totalTime\": ${total_time:-0}}"
    done
}

# Check if a specific project should be suggested
project_should_suggest() {
    local project_id="$1"
    
    _project_ensure_file
    
    local status session_count declined_until
    status=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".status")
    session_count=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".sessionCount")
    declined_until=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".declinedUntil")
    
    session_count=${session_count:-0}
    
    # Already added
    [[ "$status" == "added" ]] && return 1
    
    # Below threshold
    [[ $session_count -lt $PROJECT_SESSION_THRESHOLD ]] && return 1
    
    # Check decline cooldown
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

# ============================================
# DECLINE HANDLING
# ============================================

# Mark a project as declined (starts cooldown)
project_decline() {
    local project_id="$1"
    
    _project_ensure_file
    
    # Calculate cooldown end date
    local declined_until
    if [[ "$(uname)" == "Darwin" ]]; then
        declined_until=$(date -u -v+${PROJECT_DECLINE_COOLDOWN_DAYS}d +"%Y-%m-%dT%H:%M:%SZ")
    else
        declined_until=$(date -u -d "+${PROJECT_DECLINE_COOLDOWN_DAYS} days" +"%Y-%m-%dT%H:%M:%SZ")
    fi
    
    json_update_field "$PROJECTS_FILE" ".projects.\"$project_id\".declinedUntil" "\"$declined_until\""
    json_update_field "$PROJECTS_FILE" ".projects.\"$project_id\".status" "\"declined\""
    json_touch_file "$PROJECTS_FILE"
}

# Mark a project as added to identity
project_mark_added() {
    local project_id="$1"
    
    _project_ensure_file
    
    json_update_field "$PROJECTS_FILE" ".projects.\"$project_id\".status" "\"added\""
    json_update_field "$PROJECTS_FILE" ".projects.\"$project_id\".declinedUntil" "null"
    json_touch_file "$PROJECTS_FILE"
}

# ============================================
# UTILITY FUNCTIONS
# ============================================

# Get project info by ID
project_get_info() {
    local project_id="$1"
    
    _project_ensure_file
    
    json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\""
}

# Check if project exists
project_exists() {
    local project_id="$1"
    
    _project_ensure_file
    
    local existing
    existing=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\"")
    
    [[ -n "$existing" ]] && [[ "$existing" != "null" ]]
}

# Get session count for project
project_get_session_count() {
    local project_id="$1"
    
    _project_ensure_file
    
    local count
    count=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".sessionCount")
    echo "${count:-0}"
}

# ============================================
# EXPORTS
# ============================================

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
