#!/usr/bin/env bash
# cross-file-intelligence.sh - Cross-File Intelligence for Adaptive Identity Capture
# Part of PILOT - Connects insights across identity files
#
# Features:
# - Challenge-to-learning suggestion
# - Strategy-to-belief suggestion
# - Project-to-goal suggestion
# - Idea-to-project suggestion
# - Identity review generation
#
# Usage:
#   source cross-file-intelligence.sh
#   crossfile_on_challenge_resolved "challenge_id"
#   crossfile_on_strategy_success "strategy_id" 5
#   crossfile_on_project_theme_detected "proj1 proj2 proj3"
#   crossfile_generate_review

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/json-helpers.sh" ]] && source "${SCRIPT_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
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

# ============================================
# INITIALIZATION
# ============================================

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

# ============================================
# CHALLENGE-TO-LEARNING
# ============================================

# Suggest learning extraction when challenge is resolved
crossfile_on_challenge_resolved() {
    local challenge_id="$1"
    
    _crossfile_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Get challenge info from challenges.json
    local challenges_file="${OBSERVATIONS_DIR}/challenges.json"
    if [[ ! -f "$challenges_file" ]]; then
        return 1
    fi
    
    local pattern
    pattern=$(json_read_file "$challenges_file" ".challenges.\"$challenge_id\".pattern")
    
    if [[ -z "$pattern" ]] || [[ "$pattern" == "null" ]]; then
        return 1
    fi
    
    # Create learning suggestion
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
    
    # Return the suggestion
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

# ============================================
# STRATEGY-TO-BELIEF
# ============================================

# Suggest belief when strategy consistently works
crossfile_on_strategy_success() {
    local strategy_id="$1"
    local success_count="${2:-0}"
    
    _crossfile_ensure_file
    
    # Only suggest after 5+ successes
    if [[ $success_count -lt 5 ]]; then
        return 1
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Get strategy info
    local strategies_file="${OBSERVATIONS_DIR}/strategies.json"
    if [[ ! -f "$strategies_file" ]]; then
        return 1
    fi
    
    local problem_type
    problem_type=$(json_read_file "$strategies_file" ".strategies.\"$strategy_id\".problemType")
    
    if [[ -z "$problem_type" ]] || [[ "$problem_type" == "null" ]]; then
        return 1
    fi
    
    # Create belief suggestion
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

# ============================================
# PROJECT-TO-GOAL
# ============================================

# Suggest goal when projects share theme
crossfile_on_project_theme_detected() {
    local project_ids="$1"  # Space-separated list
    local theme="${2:-}"
    
    _crossfile_ensure_file
    
    # Count projects
    local project_count
    project_count=$(echo "$project_ids" | wc -w | tr -d ' ')
    
    # Only suggest after 3+ related projects
    if [[ $project_count -lt 3 ]]; then
        return 1
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Create goal suggestion
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

# ============================================
# IDEA-TO-PROJECT
# ============================================

# Suggest project creation when idea becomes active work
crossfile_on_idea_becomes_work() {
    local idea_id="$1"
    local work_context="${2:-}"
    
    _crossfile_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Get idea info
    local ideas_file="${OBSERVATIONS_DIR}/ideas.json"
    if [[ ! -f "$ideas_file" ]]; then
        return 1
    fi
    
    local idea
    idea=$(json_read_file "$ideas_file" ".ideas.\"$idea_id\".idea")
    
    if [[ -z "$idea" ]] || [[ "$idea" == "null" ]]; then
        return 1
    fi
    
    # Create project suggestion
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

# ============================================
# IDENTITY REVIEW
# ============================================

# Generate periodic identity review
crossfile_generate_review() {
    _crossfile_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local now_epoch
    now_epoch=$(date +%s)
    
    local stale_projects=""
    local resolved_challenges=""
    local stale_ideas=""
    local suggested_connections=""
    
    # Check for stale projects (30+ days inactive)
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
    
    # Check for resolved challenges
    local challenges_file="${OBSERVATIONS_DIR}/challenges.json"
    if [[ -f "$challenges_file" ]]; then
        local challenge_ids
        challenge_ids=$(json_read_file "$challenges_file" ".challenges | keys[]" 2>/dev/null)
        
        for challenge_id in $challenge_ids; do
            [[ -z "$challenge_id" ]] && continue
            
            local status last_seen
            status=$(json_read_file "$challenges_file" ".challenges.\"$challenge_id\".status")
            
            if [[ "$status" == "resolved" ]]; then
                local pattern
                pattern=$(json_read_file "$challenges_file" ".challenges.\"$challenge_id\".pattern")
                resolved_challenges+="$pattern, "
            fi
        done
    fi
    
    # Check for stale ideas (90+ days in backlog)
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
    
    # Get pending suggestions
    local pending_count
    pending_count=$(json_read_file "$CROSSFILE_FILE" '.suggestions | map(select(.status == "pending")) | length' 2>/dev/null)
    pending_count=${pending_count:-0}
    
    # Update last review timestamp
    json_update_field "$CROSSFILE_FILE" ".lastReview" "\"$timestamp\""
    json_touch_file "$CROSSFILE_FILE"
    
    # Return review
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

# ============================================
# SUGGESTION MANAGEMENT
# ============================================

# Get pending suggestions
crossfile_get_pending_suggestions() {
    _crossfile_ensure_file
    
    json_read_file "$CROSSFILE_FILE" '.suggestions | map(select(.status == "pending"))'
}

# Mark suggestion as acted upon
crossfile_mark_suggestion_acted() {
    local index="$1"
    
    _crossfile_ensure_file
    
    json_update_field "$CROSSFILE_FILE" ".suggestions[$index].status" "\"acted\""
    json_touch_file "$CROSSFILE_FILE"
}

# Mark suggestion as dismissed
crossfile_mark_suggestion_dismissed() {
    local index="$1"
    
    _crossfile_ensure_file
    
    json_update_field "$CROSSFILE_FILE" ".suggestions[$index].status" "\"dismissed\""
    json_touch_file "$CROSSFILE_FILE"
}

# Record a connection between files
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

# Get connections for an item
crossfile_get_connections() {
    local file="$1"
    local item="$2"
    
    _crossfile_ensure_file
    
    json_read_file "$CROSSFILE_FILE" ".connections | map(select(.sourceFile == \"$file\" and .sourceItem == \"$item\") or select(.targetFile == \"$file\" and .targetItem == \"$item\"))"
}

# ============================================
# EXPORTS
# ============================================

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
