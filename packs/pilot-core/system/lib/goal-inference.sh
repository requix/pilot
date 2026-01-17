#!/usr/bin/env bash
# goal-inference.sh - Goal and Mission Inference for Adaptive Identity Capture
# Part of PILOT - Infers goals from project patterns and suggests mission
#
# Features:
# - Related project detection
# - Goal suggestion logic based on project clusters
# - Mission suggestion from goal patterns
#
# Usage:
#   source goal-inference.sh
#   goal_detect_related_projects
#   goal_suggest_from_projects
#   mission_suggest_from_goals

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/json-helpers.sh" ]] && source "${SCRIPT_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
IDENTITY_DIR="${PILOT_DATA}/identity"
PROJECTS_FILE="${OBSERVATIONS_DIR}/projects.json"
GOALS_FILE="${OBSERVATIONS_DIR}/goals.json"

# Configuration
GOAL_PROJECT_THRESHOLD=3         # Projects needed before suggesting a goal
GOAL_TIME_THRESHOLD=36000        # 10 hours total time before suggesting goal
MISSION_GOAL_THRESHOLD=3         # Goals needed before suggesting mission

# ============================================
# INITIALIZATION
# ============================================

_goal_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$GOALS_FILE" ]]; then
        cat > "$GOALS_FILE" 2>/dev/null << 'EOF'
{
  "inferredGoals": {},
  "projectClusters": {},
  "missionHints": [],
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# PROJECT CLUSTERING
# ============================================

# Detect related projects based on naming patterns and paths
goal_detect_related_projects() {
    _goal_ensure_file
    
    if [[ ! -f "$PROJECTS_FILE" ]]; then
        echo '{"clusters": {}}'
        return
    fi
    
    local clusters="{}"
    
    # Get all projects
    local project_ids
    project_ids=$(json_read_file "$PROJECTS_FILE" ".projects | keys[]" 2>/dev/null)
    
    # Group by common path prefixes
    declare -A path_groups
    
    for project_id in $project_ids; do
        [[ -z "$project_id" ]] && continue
        
        local working_dir
        working_dir=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".workingDir")
        
        [[ -z "$working_dir" ]] && continue
        
        # Extract parent directory as cluster key
        local parent_dir
        parent_dir=$(dirname "$working_dir")
        local cluster_name
        cluster_name=$(basename "$parent_dir")
        
        # Skip generic directories
        case "$cluster_name" in
            "Projects"|"projects"|"src"|"code"|"dev"|"~"|"$HOME")
                cluster_name=$(basename "$working_dir")
                ;;
        esac
        
        echo "{\"clusterId\": \"$cluster_name\", \"projectId\": \"$project_id\", \"workingDir\": \"$working_dir\"}"
    done
}

# Group projects into clusters
goal_cluster_projects() {
    _goal_ensure_file
    
    if [[ ! -f "$PROJECTS_FILE" ]]; then
        return
    fi
    
    local project_ids
    project_ids=$(json_read_file "$PROJECTS_FILE" ".projects | keys[]" 2>/dev/null)
    
    # Build clusters based on naming patterns
    declare -A clusters
    
    for project_id in $project_ids; do
        [[ -z "$project_id" ]] && continue
        
        local suggested_name working_dir total_time
        suggested_name=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".suggestedName")
        working_dir=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".workingDir")
        total_time=$(json_read_file "$PROJECTS_FILE" ".projects.\"$project_id\".totalTime")
        total_time=${total_time:-0}
        
        # Detect patterns in project names
        local cluster_key=""
        
        # Check for common prefixes (e.g., "pilot-core", "pilot-cli" -> "pilot")
        if [[ "$suggested_name" =~ ^([a-zA-Z]+)[-_] ]]; then
            cluster_key="${BASH_REMATCH[1]}"
        fi
        
        # Check for technology patterns
        case "$suggested_name" in
            *-api|*-service|*-backend)
                cluster_key="${cluster_key:-backend}"
                ;;
            *-ui|*-frontend|*-web|*-app)
                cluster_key="${cluster_key:-frontend}"
                ;;
            *-infra|*-terraform|*-cdk)
                cluster_key="${cluster_key:-infrastructure}"
                ;;
            *-test|*-e2e|*-spec)
                cluster_key="${cluster_key:-testing}"
                ;;
        esac
        
        # Default to parent directory
        if [[ -z "$cluster_key" ]]; then
            local parent
            parent=$(dirname "$working_dir")
            cluster_key=$(basename "$parent")
        fi
        
        # Store cluster data
        local cluster_data="{\"projectId\": \"$project_id\", \"name\": \"$suggested_name\", \"totalTime\": $total_time}"
        json_array_append "$GOALS_FILE" ".projectClusters.\"$cluster_key\"" "$cluster_data" 2>/dev/null || true
    done
    
    json_touch_file "$GOALS_FILE"
}

# ============================================
# GOAL SUGGESTION
# ============================================

# Suggest goals based on project clusters
goal_suggest_from_projects() {
    _goal_ensure_file
    goal_cluster_projects
    
    local suggestions="[]"
    
    # Get clusters
    local cluster_keys
    cluster_keys=$(json_read_file "$GOALS_FILE" ".projectClusters | keys[]" 2>/dev/null)
    
    for cluster_key in $cluster_keys; do
        [[ -z "$cluster_key" ]] && continue
        
        # Count projects in cluster
        local project_count
        project_count=$(json_array_length "$GOALS_FILE" ".projectClusters.\"$cluster_key\"")
        
        # Check if meets threshold
        if [[ $project_count -ge $GOAL_PROJECT_THRESHOLD ]]; then
            # Calculate total time across cluster
            local total_cluster_time=0
            local projects
            projects=$(json_read_file "$GOALS_FILE" ".projectClusters.\"$cluster_key\"")
            
            local times
            times=$(echo "$projects" | grep -o '"totalTime":[0-9]*' | cut -d: -f2)
            for t in $times; do
                total_cluster_time=$((total_cluster_time + t))
            done
            
            # Generate goal suggestion
            local goal_suggestion
            case "$cluster_key" in
                pilot|kiro)
                    goal_suggestion="Build an intelligent AI assistant system"
                    ;;
                backend|api|service)
                    goal_suggestion="Develop robust backend services"
                    ;;
                frontend|ui|web)
                    goal_suggestion="Create excellent user experiences"
                    ;;
                infrastructure|infra|terraform|cdk)
                    goal_suggestion="Build reliable cloud infrastructure"
                    ;;
                *)
                    goal_suggestion="Master $cluster_key development"
                    ;;
            esac
            
            echo "{\"cluster\": \"$cluster_key\", \"projectCount\": $project_count, \"totalTime\": $total_cluster_time, \"suggestedGoal\": \"$goal_suggestion\"}"
        fi
    done
}

# Check if goal should be suggested
goal_should_suggest() {
    local cluster_key="$1"
    
    _goal_ensure_file
    
    # Check if already suggested and accepted/declined
    local inferred_status
    inferred_status=$(json_read_file "$GOALS_FILE" ".inferredGoals.\"$cluster_key\".status")
    
    [[ "$inferred_status" == "accepted" ]] && return 1
    [[ "$inferred_status" == "declined" ]] && return 1
    
    # Check project count threshold
    local project_count
    project_count=$(json_array_length "$GOALS_FILE" ".projectClusters.\"$cluster_key\"")
    
    [[ $project_count -lt $GOAL_PROJECT_THRESHOLD ]] && return 1
    
    return 0
}

# Record goal suggestion response
goal_record_response() {
    local cluster_key="$1"
    local response="$2"  # accepted, declined
    local goal_text="${3:-}"
    
    _goal_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local goal_data="{
        \"cluster\": \"$cluster_key\",
        \"status\": \"$response\",
        \"goalText\": \"$goal_text\",
        \"respondedAt\": \"$timestamp\"
    }"
    
    json_set_nested "$GOALS_FILE" ".inferredGoals.\"$cluster_key\"" "$goal_data"
    json_touch_file "$GOALS_FILE"
}

# ============================================
# MISSION SUGGESTION
# ============================================

# Suggest mission based on accepted goals
mission_suggest_from_goals() {
    _goal_ensure_file
    
    # Count accepted goals
    local accepted_goals=0
    local goal_themes=""
    
    local goal_keys
    goal_keys=$(json_read_file "$GOALS_FILE" ".inferredGoals | keys[]" 2>/dev/null)
    
    for goal_key in $goal_keys; do
        [[ -z "$goal_key" ]] && continue
        
        local goal_status
        goal_status=$(json_read_file "$GOALS_FILE" ".inferredGoals.\"$goal_key\".status")
        
        if [[ "$goal_status" == "accepted" ]]; then
            ((accepted_goals++))
            goal_themes="$goal_themes $goal_key"
        fi
    done
    
    # Check threshold
    if [[ $accepted_goals -lt $MISSION_GOAL_THRESHOLD ]]; then
        echo '{"shouldSuggest": false, "reason": "insufficient_goals", "acceptedGoals": '"$accepted_goals"'}'
        return
    fi
    
    # Generate mission suggestion based on themes
    local mission_suggestion=""
    
    if [[ "$goal_themes" =~ (pilot|ai|assistant|agent) ]]; then
        mission_suggestion="Advance the state of AI-assisted development"
    elif [[ "$goal_themes" =~ (infrastructure|cloud|devops) ]]; then
        mission_suggestion="Build reliable, scalable systems that empower teams"
    elif [[ "$goal_themes" =~ (frontend|ui|ux|user) ]]; then
        mission_suggestion="Create delightful experiences that solve real problems"
    else
        mission_suggestion="Build impactful software that makes a difference"
    fi
    
    cat << EOF
{
  "shouldSuggest": true,
  "acceptedGoals": $accepted_goals,
  "themes": "$goal_themes",
  "suggestedMission": "$mission_suggestion"
}
EOF
}

# Record mission hint from user input
mission_record_hint() {
    local hint="$1"
    local source="${2:-user_input}"
    
    _goal_ensure_file
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local hint_data="{\"hint\": \"$hint\", \"source\": \"$source\", \"timestamp\": \"$timestamp\"}"
    
    json_array_append "$GOALS_FILE" ".missionHints" "$hint_data"
    json_touch_file "$GOALS_FILE"
}

# ============================================
# ANALYSIS FUNCTIONS
# ============================================

# Analyze user input for goal/mission hints
goal_analyze_input() {
    local input="$1"
    
    local hints=""
    
    # Check for goal-related phrases
    if [[ "$input" =~ (want to|trying to|goal is|aim to|working toward) ]]; then
        hints="goal_hint"
    fi
    
    # Check for mission-related phrases
    if [[ "$input" =~ (my mission|purpose is|believe in|passionate about|life's work) ]]; then
        hints="$hints mission_hint"
    fi
    
    # Check for project relationship hints
    if [[ "$input" =~ (related to|part of|connects to|builds on) ]]; then
        hints="$hints relationship_hint"
    fi
    
    echo "$hints"
}

# Get goal inference status
goal_get_status() {
    _goal_ensure_file
    
    local cluster_count goal_count mission_ready
    
    cluster_count=$(json_read_file "$GOALS_FILE" ".projectClusters | keys | length" 2>/dev/null || echo 0)
    goal_count=$(json_read_file "$GOALS_FILE" ".inferredGoals | keys | length" 2>/dev/null || echo 0)
    
    local accepted_goals=0
    local goal_keys
    goal_keys=$(json_read_file "$GOALS_FILE" ".inferredGoals | keys[]" 2>/dev/null)
    
    for goal_key in $goal_keys; do
        local goal_status
        goal_status=$(json_read_file "$GOALS_FILE" ".inferredGoals.\"$goal_key\".status")
        [[ "$goal_status" == "accepted" ]] && ((accepted_goals++))
    done
    
    mission_ready="false"
    [[ $accepted_goals -ge $MISSION_GOAL_THRESHOLD ]] && mission_ready="true"
    
    cat << EOF
{
  "clusterCount": $cluster_count,
  "inferredGoalCount": $goal_count,
  "acceptedGoalCount": $accepted_goals,
  "missionReady": $mission_ready
}
EOF
}

# ============================================
# EXPORTS
# ============================================

export -f goal_detect_related_projects
export -f goal_cluster_projects
export -f goal_suggest_from_projects
export -f goal_should_suggest
export -f goal_record_response
export -f mission_suggest_from_goals
export -f mission_record_hint
export -f goal_analyze_input
export -f goal_get_status
