#!/usr/bin/env bash
# model-detector.sh - Model detection for Adaptive Identity Capture
# Part of PILOT - Identifies mental frameworks and analogies the user references
#
# Features:
# - Framework/analogy detection
# - Known model recognition (Pareto, Conway's Law, etc.)
# - Usage counting (3+ threshold)
# - Model suggestion for problems
#
# Usage:
#   source model-detector.sh
#   model_detect "user input text"
#   model_get_suggestions
#   model_suggest_for_problem "problem context"

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
[[ -f "${LIB_DIR}/json-helpers.sh" ]] && source "${LIB_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
MODELS_FILE="${OBSERVATIONS_DIR}/models.json"
IDENTITY_DIR="${PILOT_DATA}/identity"
MODELS_MD="${IDENTITY_DIR}/MODELS.md"

# Configuration
MODEL_USAGE_THRESHOLD=3  # Uses before suggesting documentation

# Known models/frameworks with keywords
# Format: "model_name:keyword1,keyword2,keyword3"
KNOWN_MODELS=(
    "pareto:80/20,pareto,80-20,eighty twenty"
    "conways_law:conway,organization structure,team structure mirrors"
    "yagni:yagni,you aren't gonna need it,premature"
    "dry:dry,don't repeat yourself,duplication"
    "kiss:kiss,keep it simple,simplicity"
    "solid:solid,single responsibility,open closed,liskov,interface segregation,dependency inversion"
    "mvp:mvp,minimum viable,minimal viable"
    "technical_debt:technical debt,tech debt,shortcut"
    "rubber_duck:rubber duck,explain to,talk through"
    "occams_razor:occam,simplest explanation,simplest solution"
    "broken_windows:broken window,small issues lead"
    "boy_scout:boy scout,leave it better,clean as you go"
    "separation_of_concerns:separation of concerns,single purpose,one thing"
    "fail_fast:fail fast,early failure,quick feedback"
    "iterative:iterative,incremental,small steps"
)

# ============================================
# INITIALIZATION
# ============================================

_model_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$MODELS_FILE" ]]; then
        cat > "$MODELS_FILE" 2>/dev/null << 'EOF'
{
  "models": {},
  "detections": [],
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# MODEL ID GENERATION
# ============================================

# Generate a model ID from name
model_generate_id() {
    local name="$1"
    
    # Normalize (lowercase, replace spaces)
    local normalized
    normalized=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | head -c 50)
    
    # Generate hash
    local hash
    if command -v md5 >/dev/null 2>&1; then
        hash=$(echo -n "$normalized" | md5)
    elif command -v md5sum >/dev/null 2>&1; then
        hash=$(echo -n "$normalized" | md5sum | cut -d' ' -f1)
    else
        hash=$(echo -n "$normalized" | cksum | cut -d' ' -f1)
    fi
    
    echo "${hash:0:12}"
}

# ============================================
# MODEL DETECTION
# ============================================

# Detect model/framework references in user input
# Returns JSON with model candidate or empty if none found
model_detect() {
    local input="$1"
    
    _model_ensure_file
    
    local input_lower
    input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Check for known models
    for model_entry in "${KNOWN_MODELS[@]}"; do
        local model_name="${model_entry%%:*}"
        local keywords="${model_entry#*:}"
        
        # Check each keyword
        IFS=',' read -ra keyword_array <<< "$keywords"
        for keyword in "${keyword_array[@]}"; do
            if [[ "$input_lower" == *"$keyword"* ]]; then
                # Found a known model
                _model_record_usage "$model_name" "$input" "true"
                
                cat << EOF
{
  "name": "$model_name",
  "isKnownModel": true,
  "usageContext": "$input",
  "matchedKeyword": "$keyword",
  "timestamp": "$timestamp"
}
EOF
                return 0
            fi
        done
    done
    
    # Check for generic model/framework language
    local model_indicators=("like" "similar to" "analogy" "framework" "principle" "rule of" "law of" "pattern")
    for indicator in "${model_indicators[@]}"; do
        if [[ "$input_lower" == *"$indicator"* ]]; then
            # Might be a custom model/analogy
            _model_record_usage "custom_analogy" "$input" "false"
            
            cat << EOF
{
  "name": "custom_analogy",
  "isKnownModel": false,
  "usageContext": "$input",
  "matchedIndicator": "$indicator",
  "timestamp": "$timestamp"
}
EOF
            return 0
        fi
    done
    
    return 1
}

# Internal: Record model usage
_model_record_usage() {
    local model_name="$1"
    local context="$2"
    local is_known="$3"
    
    local model_id
    model_id=$(model_generate_id "$model_name")
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Record detection
    local detection_record="{\"model\": \"$model_name\", \"context\": \"$context\", \"isKnown\": $is_known, \"timestamp\": \"$timestamp\"}"
    json_array_append "$MODELS_FILE" ".detections" "$detection_record"
    
    # Trim to last 50 detections
    local detection_count
    detection_count=$(json_array_length "$MODELS_FILE" ".detections")
    while [[ $detection_count -gt 50 ]]; do
        json_array_remove "$MODELS_FILE" ".detections" 0
        detection_count=$((detection_count - 1))
    done
    
    # Get existing model data
    local existing
    existing=$(json_read_file "$MODELS_FILE" ".models.\"$model_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
        # Create new model entry
        local new_model="{
            \"modelId\": \"$model_id\",
            \"name\": \"$model_name\",
            \"isKnownModel\": $is_known,
            \"usageCount\": 1,
            \"contexts\": [\"$context\"],
            \"firstSeen\": \"$timestamp\",
            \"lastSeen\": \"$timestamp\",
            \"documented\": false
        }"
        
        json_set_nested "$MODELS_FILE" ".models.\"$model_id\"" "$new_model"
    else
        # Update existing
        local current_count
        current_count=$(json_read_file "$MODELS_FILE" ".models.\"$model_id\".usageCount")
        current_count=${current_count:-0}
        
        json_update_field "$MODELS_FILE" ".models.\"$model_id\".usageCount" "$((current_count + 1))"
        json_update_field "$MODELS_FILE" ".models.\"$model_id\".lastSeen" "\"$timestamp\""
        
        # Add context (keep last 5)
        json_array_append "$MODELS_FILE" ".models.\"$model_id\".contexts" "\"$context\""
        
        local context_count
        context_count=$(json_array_length "$MODELS_FILE" ".models.\"$model_id\".contexts")
        while [[ $context_count -gt 5 ]]; do
            json_array_remove "$MODELS_FILE" ".models.\"$model_id\".contexts" 0
            context_count=$((context_count - 1))
        done
    fi
    
    json_touch_file "$MODELS_FILE"
}

# ============================================
# SUGGESTION LOGIC
# ============================================

# Get models that meet suggestion threshold
model_get_suggestions() {
    _model_ensure_file
    
    # Get all model IDs
    local model_ids
    model_ids=$(json_read_file "$MODELS_FILE" ".models | keys[]" 2>/dev/null)
    
    for model_id in $model_ids; do
        [[ -z "$model_id" ]] && continue
        
        local usage_count documented
        usage_count=$(json_read_file "$MODELS_FILE" ".models.\"$model_id\".usageCount")
        documented=$(json_read_file "$MODELS_FILE" ".models.\"$model_id\".documented")
        
        usage_count=${usage_count:-0}
        
        # Skip if already documented
        [[ "$documented" == "true" ]] && continue
        
        # Skip if below threshold
        [[ $usage_count -lt $MODEL_USAGE_THRESHOLD ]] && continue
        
        # Get model details
        local name is_known
        name=$(json_read_file "$MODELS_FILE" ".models.\"$model_id\".name")
        is_known=$(json_read_file "$MODELS_FILE" ".models.\"$model_id\".isKnownModel")
        
        echo "{\"modelId\": \"$model_id\", \"name\": \"$name\", \"usageCount\": $usage_count, \"isKnownModel\": $is_known}"
    done
}

# ============================================
# MODEL SUGGESTION FOR PROBLEMS
# ============================================

# Check if a problem could benefit from a documented model
model_suggest_for_problem() {
    local problem_context="$1"
    
    local context_lower
    context_lower=$(echo "$problem_context" | tr '[:upper:]' '[:lower:]')
    
    # Check documented models in MODELS.md
    if [[ -f "$MODELS_MD" ]]; then
        # Look for "When to Use" sections that match the problem
        local keywords
        keywords=$(echo "$context_lower" | tr -cs '[:alnum:]' ' ')
        
        for keyword in $keywords; do
            [[ ${#keyword} -lt 4 ]] && continue
            
            if grep -qi "$keyword" "$MODELS_MD" 2>/dev/null; then
                # Found a potential match - extract the model name
                local model_header
                model_header=$(grep -B10 -i "$keyword" "$MODELS_MD" 2>/dev/null | grep "^## " | tail -1)
                
                if [[ -n "$model_header" ]]; then
                    local model_name="${model_header#\#\# }"
                    echo "{\"name\": \"$model_name\", \"matchedKeyword\": \"$keyword\", \"source\": \"documented\"}"
                    return 0
                fi
            fi
        done
    fi
    
    # Check known models for problem keywords
    for model_entry in "${KNOWN_MODELS[@]}"; do
        local model_name="${model_entry%%:*}"
        local keywords="${model_entry#*:}"
        
        # Problem-specific suggestions
        case "$model_name" in
            "pareto")
                if [[ "$context_lower" == *"priorit"* ]] || [[ "$context_lower" == *"focus"* ]] || [[ "$context_lower" == *"important"* ]]; then
                    echo "{\"name\": \"Pareto Principle (80/20)\", \"suggestion\": \"Focus on the 20% that delivers 80% of value\", \"source\": \"known\"}"
                    return 0
                fi
                ;;
            "rubber_duck")
                if [[ "$context_lower" == *"stuck"* ]] || [[ "$context_lower" == *"debug"* ]] || [[ "$context_lower" == *"understand"* ]]; then
                    echo "{\"name\": \"Rubber Duck Debugging\", \"suggestion\": \"Try explaining the problem out loud\", \"source\": \"known\"}"
                    return 0
                fi
                ;;
            "yagni")
                if [[ "$context_lower" == *"future"* ]] || [[ "$context_lower" == *"might need"* ]] || [[ "$context_lower" == *"just in case"* ]]; then
                    echo "{\"name\": \"YAGNI\", \"suggestion\": \"You Aren't Gonna Need It - build only what's needed now\", \"source\": \"known\"}"
                    return 0
                fi
                ;;
            "mvp")
                if [[ "$context_lower" == *"scope"* ]] || [[ "$context_lower" == *"feature"* ]] || [[ "$context_lower" == *"launch"* ]]; then
                    echo "{\"name\": \"MVP\", \"suggestion\": \"Start with minimum viable product\", \"source\": \"known\"}"
                    return 0
                fi
                ;;
        esac
    done
    
    return 1
}

# ============================================
# STATUS MANAGEMENT
# ============================================

# Mark model as documented
model_mark_documented() {
    local model_id="$1"
    
    _model_ensure_file
    
    json_update_field "$MODELS_FILE" ".models.\"$model_id\".documented" "true"
    json_touch_file "$MODELS_FILE"
}

# ============================================
# UTILITY FUNCTIONS
# ============================================

# Get model info by ID
model_get_info() {
    local model_id="$1"
    
    _model_ensure_file
    
    json_read_file "$MODELS_FILE" ".models.\"$model_id\""
}

# Check if model exists
model_exists() {
    local model_id="$1"
    
    _model_ensure_file
    
    local existing
    existing=$(json_read_file "$MODELS_FILE" ".models.\"$model_id\"")
    
    [[ -n "$existing" ]] && [[ "$existing" != "null" ]]
}

# Get all known model names
model_get_known_models() {
    for model_entry in "${KNOWN_MODELS[@]}"; do
        local model_name="${model_entry%%:*}"
        echo "$model_name"
    done
}

# ============================================
# EXPORTS
# ============================================

export -f model_generate_id
export -f model_detect
export -f model_get_suggestions
export -f model_suggest_for_problem
export -f model_mark_documented
export -f model_get_info
export -f model_exists
export -f model_get_known_models
