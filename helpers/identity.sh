#!/usr/bin/env bash
# identity.sh - Identity management for PILOT
# Part of PILOT - Personal Intelligence Layer for Optimized Tasks
# Location: src/helpers/identity.sh (consolidated from observation-init.sh + identity-writer.sh)
#
# Combines observation directory initialization with identity file management.
# Fail-safe design: always returns safe defaults on error.
#
# Usage:
#   source identity.sh
#   ensure_observation_dirs
#   identity_add_project "my-project" "Description" "/path" 40

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/json.sh" ]] && source "${SCRIPT_DIR}/json.sh"

# ============================================
# OBSERVATION INITIALIZATION (from observation-init.sh)
# ============================================

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
    local test_file="${OBSERVATIONS_DIR}/.write-test-$"
    
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

# ============================================
# IDENTITY WRITING (from identity-writer.sh)
# ============================================

# Directories (identity-specific)
HISTORY_DIR="${IDENTITY_DIR}/.history"

# Identity files
ID_PROJECTS_FILE="${IDENTITY_DIR}/PROJECTS.md"
GOALS_FILE="${IDENTITY_DIR}/GOALS.md"
MISSION_FILE="${IDENTITY_DIR}/MISSION.md"
BELIEFS_FILE="${IDENTITY_DIR}/BELIEFS.md"
ID_CHALLENGES_FILE="${IDENTITY_DIR}/CHALLENGES.md"
IDEAS_FILE="${IDENTITY_DIR}/IDEAS.md"
LEARNED_FILE="${IDENTITY_DIR}/LEARNED.md"
MODELS_FILE="${IDENTITY_DIR}/MODELS.md"
NARRATIVES_FILE="${IDENTITY_DIR}/NARRATIVES.md"
STRATEGIES_FILE="${IDENTITY_DIR}/STRATEGIES.md"
CONTEXT_FILE="${IDENTITY_DIR}/context.md"

# Ensure identity directories exist
_identity_ensure_dirs() {
    mkdir -p "$IDENTITY_DIR" "$HISTORY_DIR" 2>/dev/null || true
}

# Record a change to history
_identity_record_history() {
    local file="$1"
    local action="$2"
    local details="$3"
    
    _identity_ensure_dirs
    
    local timestamp filename history_file
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    filename=$(basename "$file")
    history_file="${HISTORY_DIR}/${filename%.md}-history.json"
    
    # Initialize history file if needed
    if [[ ! -f "$history_file" ]]; then
        echo '{"changes": []}' > "$history_file"
    fi
    
    # Add change record
    local change_record="{\"timestamp\": \"$timestamp\", \"action\": \"$action\", \"details\": \"$details\"}"
    json_array_append "$history_file" ".changes" "$change_record" 2>/dev/null || true
}

# Safe write with backup
_identity_safe_write() {
    local file="$1"
    local content="$2"
    
    _identity_ensure_dirs
    
    # Create backup if file exists
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.backup" 2>/dev/null || true
    fi
    
    # Write content
    if echo "$content" > "$file" 2>/dev/null; then
        return 0
    else
        # Restore backup on failure
        if [[ -f "${file}.backup" ]]; then
            mv "${file}.backup" "$file" 2>/dev/null || true
        fi
        return 1
    fi
}

# Append to file safely
_identity_safe_append() {
    local file="$1"
    local content="$2"
    
    _identity_ensure_dirs
    
    # Create backup
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.backup" 2>/dev/null || true
    fi
    
    # Append content
    if echo "$content" >> "$file" 2>/dev/null; then
        return 0
    else
        # Restore backup on failure
        if [[ -f "${file}.backup" ]]; then
            mv "${file}.backup" "$file" 2>/dev/null || true
        fi
        return 1
    fi
}


# ============================================
# PROJECTS.md
# ============================================

# Initialize PROJECTS.md if it doesn't exist
_identity_init_projects() {
    if [[ ! -f "$ID_PROJECTS_FILE" ]]; then
        _identity_safe_write "$ID_PROJECTS_FILE" "# Active Projects

---
*Total Allocation: 0%*
*Last Updated: $(date '+%Y-%m-%d')*
"
    fi
}

# Add a project to PROJECTS.md
# Usage: identity_add_project "name" "description" "/path" allocation [related_goal]
identity_add_project() {
    local name="$1"
    local description="$2"
    local working_dir="$3"
    local allocation="${4:-0}"
    local related_goal="${5:-}"
    
    _identity_init_projects
    
    local added_date
    added_date=$(date '+%Y-%m-%d')
    
    # Build project entry
    local entry="
## $name
- **Path:** $working_dir
- **Description:** $description
- **Time Allocation:** ${allocation}%
- **Added:** $added_date"
    
    [[ -n "$related_goal" ]] && entry="$entry
- **Related Goal:** $related_goal"
    
    # Insert before the footer (--- line)
    local content
    content=$(cat "$ID_PROJECTS_FILE")
    
    # Remove old footer, add project, add new footer
    local new_content
    new_content=$(echo "$content" | sed '/^---$/,$d')
    new_content="$new_content
$entry

---
*Total Allocation: $(identity_get_total_allocation)%*
*Last Updated: $added_date*
"
    
    if _identity_safe_write "$ID_PROJECTS_FILE" "$new_content"; then
        _identity_record_history "$ID_PROJECTS_FILE" "add_project" "$name"
        return 0
    fi
    return 1
}

# Get total allocation from all projects
identity_get_total_allocation() {
    if [[ ! -f "$ID_PROJECTS_FILE" ]]; then
        echo "0"
        return
    fi
    
    local total=0
    while IFS= read -r line; do
        if [[ "$line" == *"Time Allocation:"* ]]; then
            local alloc
            alloc=$(echo "$line" | grep -oE '[0-9]+' | head -1)
            total=$((total + ${alloc:-0}))
        fi
    done < "$ID_PROJECTS_FILE"
    
    echo "$total"
}

# Check if project exists
identity_project_exists() {
    local name="$1"
    
    if [[ -f "$ID_PROJECTS_FILE" ]]; then
        grep -q "^## $name$" "$ID_PROJECTS_FILE"
    else
        return 1
    fi
}

# Archive a project (move to archived section)
identity_archive_project() {
    local name="$1"
    
    if [[ ! -f "$ID_PROJECTS_FILE" ]]; then
        return 1
    fi
    
    # This is a simplified implementation
    # In production, would move to "Archived Projects" section
    _identity_record_history "$ID_PROJECTS_FILE" "archive_project" "$name"
    return 0
}

# ============================================
# GOALS.md
# ============================================

# Initialize GOALS.md if it doesn't exist
_identity_init_goals() {
    if [[ ! -f "$GOALS_FILE" ]]; then
        _identity_safe_write "$GOALS_FILE" "# Goals

---
*Last Updated: $(date '+%Y-%m-%d')*
"
    fi
}

# Add a goal to GOALS.md
# Usage: identity_add_goal "name" "description" "project1,project2" "detected_pattern"
identity_add_goal() {
    local name="$1"
    local description="$2"
    local related_projects="$3"
    local detected_pattern="${4:-}"
    
    _identity_init_goals
    
    local added_date
    added_date=$(date '+%Y-%m-%d')
    
    # Build goal entry
    local entry="
## $name
- **Description:** $description
- **Related Projects:** $related_projects
- **Status:** Active"
    
    [[ -n "$detected_pattern" ]] && entry="$entry
- **Detected Pattern:** $detected_pattern"
    
    # Insert before footer
    local content
    content=$(cat "$GOALS_FILE")
    
    local new_content
    new_content=$(echo "$content" | sed '/^---$/,$d')
    new_content="$new_content
$entry

---
*Last Updated: $added_date*
"
    
    if _identity_safe_write "$GOALS_FILE" "$new_content"; then
        _identity_record_history "$GOALS_FILE" "add_goal" "$name"
        return 0
    fi
    return 1
}

# ============================================
# CHALLENGES.md
# ============================================

# Initialize CHALLENGES.md if it doesn't exist
_identity_init_challenges() {
    if [[ ! -f "$ID_CHALLENGES_FILE" ]]; then
        _identity_safe_write "$ID_CHALLENGES_FILE" "# Current Challenges

## Active Challenges

## Resolved Challenges

---
*Last Updated: $(date '+%Y-%m-%d')*
"
    fi
}

# Add a challenge
identity_add_challenge() {
    local name="$1"
    local description="$2"
    local impact="$3"
    local attempted_solutions="${4:-}"
    
    _identity_init_challenges
    
    local added_date
    added_date=$(date '+%Y-%m-%d')
    
    # Build entry in temp file to handle multi-line
    local temp_entry
    temp_entry=$(mktemp)
    
    cat > "$temp_entry" << EOF

### $name
- **Description:** $description
- **Impact:** $impact
- **First Seen:** $added_date
- **Status:** Active
EOF
    
    [[ -n "$attempted_solutions" ]] && echo "- **Attempted Solutions:** $attempted_solutions" >> "$temp_entry"
    
    # Read current content and insert entry
    local temp_output
    temp_output=$(mktemp)
    
    local inserted=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        echo "$line" >> "$temp_output"
        if [[ "$line" == "## Active Challenges" ]] && [[ $inserted -eq 0 ]]; then
            cat "$temp_entry" >> "$temp_output"
            inserted=1
        fi
    done < "$ID_CHALLENGES_FILE"
    
    rm -f "$temp_entry"
    
    # Update last updated using perl for portability
    perl -i -pe "s/\*Last Updated:.*\*/\*Last Updated: $added_date\*/" "$temp_output" 2>/dev/null || true
    
    if _identity_safe_write "$ID_CHALLENGES_FILE" "$(cat "$temp_output")"; then
        rm -f "$temp_output"
        _identity_record_history "$ID_CHALLENGES_FILE" "add_challenge" "$name"
        return 0
    fi
    rm -f "$temp_output"
    return 1
}

# ============================================
# LEARNED.md
# ============================================

# Initialize LEARNED.md if it doesn't exist
_identity_init_learned() {
    if [[ ! -f "$LEARNED_FILE" ]]; then
        _identity_safe_write "$LEARNED_FILE" "# Lessons Learned

---
*Last Updated: $(date '+%Y-%m-%d')*
"
    fi
}

# Add a learning
identity_add_learning() {
    local lesson="$1"
    local context="$2"
    local cost="${3:-}"
    local when_to_apply="${4:-}"
    
    _identity_init_learned
    
    local added_date
    added_date=$(date '+%Y-%m-%d')
    
    local entry="
## $lesson
- **Context:** $context
- **Learned:** $added_date"
    
    [[ -n "$cost" ]] && entry="$entry
- **Cost of Learning:** $cost"
    
    [[ -n "$when_to_apply" ]] && entry="$entry
- **When to Apply:** $when_to_apply"
    
    # Insert before footer
    local content
    content=$(cat "$LEARNED_FILE")
    
    local new_content
    new_content=$(echo "$content" | sed '/^---$/,$d')
    new_content="$new_content
$entry

---
*Last Updated: $added_date*
"
    
    if _identity_safe_write "$LEARNED_FILE" "$new_content"; then
        _identity_record_history "$LEARNED_FILE" "add_learning" "$lesson"
        return 0
    fi
    return 1
}


# ============================================
# BELIEFS.md
# ============================================

_identity_init_beliefs() {
    if [[ ! -f "$BELIEFS_FILE" ]]; then
        _identity_safe_write "$BELIEFS_FILE" "# Core Beliefs

---
*Last Updated: $(date '+%Y-%m-%d')*
"
    fi
}

identity_add_belief() {
    local belief="$1"
    local domain="$2"
    local supporting_evidence="${3:-}"
    
    _identity_init_beliefs
    
    local added_date
    added_date=$(date '+%Y-%m-%d')
    
    local entry="
## $belief
- **Domain:** $domain
- **Added:** $added_date"
    
    [[ -n "$supporting_evidence" ]] && entry="$entry
- **Supporting Evidence:** $supporting_evidence"
    
    local content
    content=$(cat "$BELIEFS_FILE")
    
    local new_content
    new_content=$(echo "$content" | sed '/^---$/,$d')
    new_content="$new_content
$entry

---
*Last Updated: $added_date*
"
    
    if _identity_safe_write "$BELIEFS_FILE" "$new_content"; then
        _identity_record_history "$BELIEFS_FILE" "add_belief" "$belief"
        return 0
    fi
    return 1
}

# ============================================
# STRATEGIES.md
# ============================================

_identity_init_strategies() {
    if [[ ! -f "$STRATEGIES_FILE" ]]; then
        _identity_safe_write "$STRATEGIES_FILE" "# Problem-Solving Strategies

---
*Last Updated: $(date '+%Y-%m-%d')*
"
    fi
}

identity_add_strategy() {
    local name="$1"
    local problem_type="$2"
    local steps="$3"
    local when_it_works="${4:-}"
    local when_it_doesnt="${5:-}"
    
    _identity_init_strategies
    
    local added_date
    added_date=$(date '+%Y-%m-%d')
    
    local entry="
## $name
- **Problem Type:** $problem_type
- **Steps:** $steps
- **Added:** $added_date"
    
    [[ -n "$when_it_works" ]] && entry="$entry
- **When It Works:** $when_it_works"
    
    [[ -n "$when_it_doesnt" ]] && entry="$entry
- **When It Doesn't Work:** $when_it_doesnt"
    
    local content
    content=$(cat "$STRATEGIES_FILE")
    
    local new_content
    new_content=$(echo "$content" | sed '/^---$/,$d')
    new_content="$new_content
$entry

---
*Last Updated: $added_date*
"
    
    if _identity_safe_write "$STRATEGIES_FILE" "$new_content"; then
        _identity_record_history "$STRATEGIES_FILE" "add_strategy" "$name"
        return 0
    fi
    return 1
}

# ============================================
# IDEAS.md
# ============================================

_identity_init_ideas() {
    if [[ ! -f "$IDEAS_FILE" ]]; then
        _identity_safe_write "$IDEAS_FILE" "# Ideas & Future Possibilities

## Backlog

## Researching

## On Hold

---
*Last Updated: $(date '+%Y-%m-%d')*
"
    fi
}

identity_add_idea() {
    local name="$1"
    local why_interesting="$2"
    local potential_impact="${3:-}"
    local next_step="${4:-}"
    local status="${5:-Backlog}"
    
    _identity_init_ideas
    
    local added_date
    added_date=$(date '+%Y-%m-%d')
    
    # Build entry in temp file
    local temp_entry
    temp_entry=$(mktemp)
    
    cat > "$temp_entry" << EOF

### $name
- **Why Interesting:** $why_interesting
- **Added:** $added_date
EOF
    
    [[ -n "$potential_impact" ]] && echo "- **Potential Impact:** $potential_impact" >> "$temp_entry"
    [[ -n "$next_step" ]] && echo "- **Next Step:** $next_step" >> "$temp_entry"
    
    # Read current content and insert entry
    local temp_output
    temp_output=$(mktemp)
    
    local inserted=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        echo "$line" >> "$temp_output"
        if [[ "$line" == "## $status" ]] && [[ $inserted -eq 0 ]]; then
            cat "$temp_entry" >> "$temp_output"
            inserted=1
        fi
    done < "$IDEAS_FILE"
    
    rm -f "$temp_entry"
    
    # Update last updated using perl for portability
    perl -i -pe "s/\*Last Updated:.*\*/\*Last Updated: $added_date\*/" "$temp_output" 2>/dev/null || true
    
    if _identity_safe_write "$IDEAS_FILE" "$(cat "$temp_output")"; then
        rm -f "$temp_output"
        _identity_record_history "$IDEAS_FILE" "add_idea" "$name"
        return 0
    fi
    rm -f "$temp_output"
    return 1
}

# ============================================
# MODELS.md
# ============================================

_identity_init_models() {
    if [[ ! -f "$MODELS_FILE" ]]; then
        _identity_safe_write "$MODELS_FILE" "# Mental Models

---
*Last Updated: $(date '+%Y-%m-%d')*
"
    fi
}

identity_add_model() {
    local name="$1"
    local what_it_is="$2"
    local when_to_use="$3"
    local example="${4:-}"
    
    _identity_init_models
    
    local added_date
    added_date=$(date '+%Y-%m-%d')
    
    local entry="
## $name
- **What It Is:** $what_it_is
- **When to Use:** $when_to_use
- **Added:** $added_date"
    
    [[ -n "$example" ]] && entry="$entry
- **Example:** $example"
    
    local content
    content=$(cat "$MODELS_FILE")
    
    local new_content
    new_content=$(echo "$content" | sed '/^---$/,$d')
    new_content="$new_content
$entry

---
*Last Updated: $added_date*
"
    
    if _identity_safe_write "$MODELS_FILE" "$new_content"; then
        _identity_record_history "$MODELS_FILE" "add_model" "$name"
        return 0
    fi
    return 1
}

# ============================================
# NARRATIVES.md
# ============================================

_identity_init_narratives() {
    if [[ ! -f "$NARRATIVES_FILE" ]]; then
        _identity_safe_write "$NARRATIVES_FILE" "# Self-Narratives

## Limiting Narratives

## Empowering Narratives

---
*Last Updated: $(date '+%Y-%m-%d')*
"
    fi
}

identity_add_narrative() {
    local statement="$1"
    local classification="$2"  # limiting or empowering
    local evidence="${3:-}"
    local impact="${4:-}"
    local reframe="${5:-}"
    
    _identity_init_narratives
    
    local added_date
    added_date=$(date '+%Y-%m-%d')
    
    local section="Limiting Narratives"
    [[ "$classification" == "empowering" ]] && section="Empowering Narratives"
    
    # Build entry in temp file
    local temp_entry
    temp_entry=$(mktemp)
    
    cat > "$temp_entry" << EOF

### "$statement"
- **Classification:** $classification
- **Added:** $added_date
EOF
    
    [[ -n "$evidence" ]] && echo "- **Evidence:** $evidence" >> "$temp_entry"
    [[ -n "$impact" ]] && echo "- **Impact:** $impact" >> "$temp_entry"
    [[ -n "$reframe" ]] && echo "- **Suggested Reframe:** $reframe" >> "$temp_entry"
    
    # Read current content and insert entry
    local temp_output
    temp_output=$(mktemp)
    
    local inserted=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        echo "$line" >> "$temp_output"
        if [[ "$line" == "## $section" ]] && [[ $inserted -eq 0 ]]; then
            cat "$temp_entry" >> "$temp_output"
            inserted=1
        fi
    done < "$NARRATIVES_FILE"
    
    rm -f "$temp_entry"
    
    # Update last updated using perl for portability
    perl -i -pe "s/\*Last Updated:.*\*/\*Last Updated: $added_date\*/" "$temp_output" 2>/dev/null || true
    
    if _identity_safe_write "$NARRATIVES_FILE" "$(cat "$temp_output")"; then
        rm -f "$temp_output"
        _identity_record_history "$NARRATIVES_FILE" "add_narrative" "$statement"
        return 0
    fi
    rm -f "$temp_output"
    return 1
}

# ============================================
# MISSION.md
# ============================================

identity_set_mission() {
    local mission="$1"
    
    _identity_ensure_dirs
    
    local added_date
    added_date=$(date '+%Y-%m-%d')
    
    local content="# Mission Statement

$mission

---
*Last Updated: $added_date*
"
    
    if _identity_safe_write "$MISSION_FILE" "$content"; then
        _identity_record_history "$MISSION_FILE" "set_mission" "updated"
        return 0
    fi
    return 1
}

# ============================================
# context.md (Preferences)
# ============================================

identity_update_preference() {
    local key="$1"
    local value="$2"
    
    _identity_ensure_dirs
    
    # Initialize context.md if needed
    if [[ ! -f "$CONTEXT_FILE" ]]; then
        _identity_safe_write "$CONTEXT_FILE" "# User Context

## Preferences

---
*Last Updated: $(date '+%Y-%m-%d')*
"
    fi
    
    local added_date
    added_date=$(date '+%Y-%m-%d')
    
    # Check if preference already exists
    if grep -q "^- \*\*$key:\*\*" "$CONTEXT_FILE" 2>/dev/null; then
        # Update existing
        local content
        content=$(cat "$CONTEXT_FILE")
        local new_content
        new_content=$(echo "$content" | sed "s/^- \*\*$key:\*\*.*/- \*\*$key:\*\* $value/")
        new_content=$(echo "$new_content" | sed "s/\*Last Updated:.*\*/\*Last Updated: $added_date\*/")
        _identity_safe_write "$CONTEXT_FILE" "$new_content"
    else
        # Add new preference after "## Preferences" using temp file approach
        local temp_output
        temp_output=$(mktemp)
        
        local inserted=0
        while IFS= read -r line || [[ -n "$line" ]]; do
            echo "$line" >> "$temp_output"
            if [[ "$line" == "## Preferences" ]] && [[ $inserted -eq 0 ]]; then
                echo "- **$key:** $value" >> "$temp_output"
                inserted=1
            fi
        done < "$CONTEXT_FILE"
        
        # Update last updated using perl for portability
        perl -i -pe "s/\*Last Updated:.*\*/\*Last Updated: $added_date\*/" "$temp_output" 2>/dev/null || true
        
        _identity_safe_write "$CONTEXT_FILE" "$(cat "$temp_output")"
        rm -f "$temp_output"
    fi
    
    _identity_record_history "$CONTEXT_FILE" "update_preference" "$key=$value"
}

# ============================================
# EXPORTS
# ============================================

# Observation exports
export -f ensure_observation_dirs
export -f is_observation_writable
export -f get_observations_dir
export -f get_identity_history_dir
export -f is_observation_initialized
export -f reset_observation_state
export -f get_timestamp
export -f init_json_file

# Identity exports
export -f identity_add_project
export -f identity_get_total_allocation
export -f identity_project_exists
export -f identity_archive_project
export -f identity_add_goal
export -f identity_add_challenge
export -f identity_add_learning
export -f identity_add_belief
export -f identity_add_strategy
export -f identity_add_idea
export -f identity_add_model
export -f identity_add_narrative
export -f identity_set_mission
export -f identity_update_preference
