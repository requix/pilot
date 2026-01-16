#!/usr/bin/env bash
# narrative-detector.sh - Narrative detection for Adaptive Identity Capture
# Part of PILOT - Identifies self-stories and identity patterns
#
# Features:
# - Self-limiting statement detection
# - Narrative classification (limiting/empowering/neutral)
# - Reframe suggestions
#
# Usage:
#   source narrative-detector.sh
#   narrative_detect "user input text"
#   narrative_classify "statement"
#   narrative_suggest_reframe "limiting statement"

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
[[ -f "${LIB_DIR}/json-helpers.sh" ]] && source "${LIB_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
NARRATIVES_FILE="${OBSERVATIONS_DIR}/narratives.json"
IDENTITY_DIR="${PILOT_DATA}/identity"
NARRATIVES_MD="${IDENTITY_DIR}/NARRATIVES.md"

# Configuration
NARRATIVE_OCCURRENCE_THRESHOLD=3  # Times before suggesting awareness

# Limiting narrative patterns
LIMITING_PATTERNS=(
    "i can't"
    "i'm not good at"
    "i always fail"
    "i never"
    "i'm bad at"
    "i don't understand"
    "i'm terrible at"
    "i'll never be able to"
    "i'm not smart enough"
    "i'm not experienced enough"
    "that's too hard for me"
    "i'm not a"
    "i suck at"
    "i hate"
    "i'm afraid of"
    "i'm scared to"
)

# Empowering narrative patterns
EMPOWERING_PATTERNS=(
    "i can"
    "i'm good at"
    "i enjoy"
    "i love"
    "i'm learning"
    "i'm getting better at"
    "i figured out"
    "i solved"
    "i understand"
    "i'm confident"
    "i'm capable"
    "i excel at"
)

# ============================================
# INITIALIZATION
# ============================================

_narrative_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$NARRATIVES_FILE" ]]; then
        cat > "$NARRATIVES_FILE" 2>/dev/null << 'EOF'
{
  "narratives": {},
  "detections": [],
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# NARRATIVE ID GENERATION
# ============================================

# Generate a narrative ID from statement
narrative_generate_id() {
    local statement="$1"
    
    # Normalize (lowercase, first 50 chars)
    local normalized
    normalized=$(echo "$statement" | tr '[:upper:]' '[:lower:]' | head -c 50)
    
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
# NARRATIVE DETECTION
# ============================================

# Detect self-limiting or self-defining statements
# Returns JSON with narrative candidate or empty if none found
narrative_detect() {
    local input="$1"
    
    _narrative_ensure_file
    
    local input_lower
    input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Check for limiting patterns
    for pattern in "${LIMITING_PATTERNS[@]}"; do
        if [[ "$input_lower" == *"$pattern"* ]]; then
            local classification="limiting"
            local reframe
            reframe=$(narrative_suggest_reframe "$input")
            
            _narrative_record "$input" "$classification" "$pattern"
            
            cat << EOF
{
  "statement": "$input",
  "classification": "$classification",
  "matchedPattern": "$pattern",
  "suggestedReframe": "$reframe",
  "timestamp": "$timestamp"
}
EOF
            return 0
        fi
    done
    
    # Check for empowering patterns
    for pattern in "${EMPOWERING_PATTERNS[@]}"; do
        if [[ "$input_lower" == *"$pattern"* ]]; then
            local classification="empowering"
            
            _narrative_record "$input" "$classification" "$pattern"
            
            cat << EOF
{
  "statement": "$input",
  "classification": "$classification",
  "matchedPattern": "$pattern",
  "timestamp": "$timestamp"
}
EOF
            return 0
        fi
    done
    
    return 1
}

# Internal: Record narrative
_narrative_record() {
    local statement="$1"
    local classification="$2"
    local pattern="$3"
    
    local narrative_id
    narrative_id=$(narrative_generate_id "$statement")
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Record detection
    local detection_record="{\"statement\": \"$statement\", \"classification\": \"$classification\", \"pattern\": \"$pattern\", \"timestamp\": \"$timestamp\"}"
    json_array_append "$NARRATIVES_FILE" ".detections" "$detection_record"
    
    # Trim to last 50 detections
    local detection_count
    detection_count=$(json_array_length "$NARRATIVES_FILE" ".detections")
    while [[ $detection_count -gt 50 ]]; do
        json_array_remove "$NARRATIVES_FILE" ".detections" 0
        detection_count=$((detection_count - 1))
    done
    
    # Get existing narrative data
    local existing
    existing=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\"")
    
    if [[ -z "$existing" ]] || [[ "$existing" == "null" ]]; then
        # Create new narrative entry
        local new_narrative="{
            \"narrativeId\": \"$narrative_id\",
            \"statement\": \"$statement\",
            \"classification\": \"$classification\",
            \"pattern\": \"$pattern\",
            \"occurrences\": 1,
            \"firstSeen\": \"$timestamp\",
            \"lastSeen\": \"$timestamp\",
            \"addressed\": false
        }"
        
        json_set_nested "$NARRATIVES_FILE" ".narratives.\"$narrative_id\"" "$new_narrative"
    else
        # Update existing
        local current_count
        current_count=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".occurrences")
        current_count=${current_count:-0}
        
        json_update_field "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".occurrences" "$((current_count + 1))"
        json_update_field "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".lastSeen" "\"$timestamp\""
    fi
    
    json_touch_file "$NARRATIVES_FILE"
}

# ============================================
# CLASSIFICATION
# ============================================

# Classify a narrative statement
narrative_classify() {
    local statement="$1"
    
    local statement_lower
    statement_lower=$(echo "$statement" | tr '[:upper:]' '[:lower:]')
    
    # Check limiting patterns
    for pattern in "${LIMITING_PATTERNS[@]}"; do
        if [[ "$statement_lower" == *"$pattern"* ]]; then
            echo "limiting"
            return 0
        fi
    done
    
    # Check empowering patterns
    for pattern in "${EMPOWERING_PATTERNS[@]}"; do
        if [[ "$statement_lower" == *"$pattern"* ]]; then
            echo "empowering"
            return 0
        fi
    done
    
    echo "neutral"
}

# ============================================
# REFRAME SUGGESTIONS
# ============================================

# Suggest reframing for limiting narratives
narrative_suggest_reframe() {
    local statement="$1"
    
    local statement_lower
    statement_lower=$(echo "$statement" | tr '[:upper:]' '[:lower:]')
    
    # Pattern-specific reframes
    if [[ "$statement_lower" == *"i can't"* ]]; then
        echo "I'm learning to... / I haven't yet..."
    elif [[ "$statement_lower" == *"i'm not good at"* ]]; then
        echo "I'm developing skills in... / I'm improving at..."
    elif [[ "$statement_lower" == *"i always fail"* ]]; then
        echo "I'm learning from each attempt... / Each try teaches me..."
    elif [[ "$statement_lower" == *"i never"* ]]; then
        echo "I haven't yet... / I'm working toward..."
    elif [[ "$statement_lower" == *"i'm bad at"* ]]; then
        echo "I'm still learning... / This is a growth area for me..."
    elif [[ "$statement_lower" == *"i don't understand"* ]]; then
        echo "I'm working to understand... / I need more context on..."
    elif [[ "$statement_lower" == *"i'm terrible at"* ]]; then
        echo "I'm developing... / This is challenging and I'm growing..."
    elif [[ "$statement_lower" == *"i'll never be able to"* ]]; then
        echo "With practice, I can... / I'm on the path to..."
    elif [[ "$statement_lower" == *"i'm not smart enough"* ]]; then
        echo "I can learn this... / Intelligence grows with effort..."
    elif [[ "$statement_lower" == *"i'm not experienced enough"* ]]; then
        echo "I'm building experience... / Every expert was once a beginner..."
    elif [[ "$statement_lower" == *"that's too hard"* ]]; then
        echo "This is challenging and achievable... / I can break this down..."
    elif [[ "$statement_lower" == *"i suck at"* ]]; then
        echo "I'm developing skills in... / This is a growth opportunity..."
    elif [[ "$statement_lower" == *"i hate"* ]]; then
        echo "I find this challenging... / I'm working on my relationship with..."
    elif [[ "$statement_lower" == *"i'm afraid"* ]] || [[ "$statement_lower" == *"i'm scared"* ]]; then
        echo "I'm cautious about... / I'm building confidence in..."
    else
        echo "Consider: What would a growth mindset version of this be?"
    fi
}

# ============================================
# SUGGESTION LOGIC
# ============================================

# Get limiting narratives that occur frequently
narrative_get_limiting() {
    _narrative_ensure_file
    
    # Get all narrative IDs
    local narrative_ids
    narrative_ids=$(json_read_file "$NARRATIVES_FILE" ".narratives | keys[]" 2>/dev/null)
    
    for narrative_id in $narrative_ids; do
        [[ -z "$narrative_id" ]] && continue
        
        local classification occurrences addressed
        classification=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".classification")
        occurrences=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".occurrences")
        addressed=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".addressed")
        
        occurrences=${occurrences:-0}
        
        # Only return limiting narratives
        [[ "$classification" != "limiting" ]] && continue
        
        # Skip if already addressed
        [[ "$addressed" == "true" ]] && continue
        
        # Skip if below threshold
        [[ $occurrences -lt $NARRATIVE_OCCURRENCE_THRESHOLD ]] && continue
        
        # Get narrative details
        local statement pattern
        statement=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".statement")
        pattern=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".pattern")
        
        local reframe
        reframe=$(narrative_suggest_reframe "$statement")
        
        echo "{\"narrativeId\": \"$narrative_id\", \"statement\": \"$statement\", \"pattern\": \"$pattern\", \"occurrences\": $occurrences, \"suggestedReframe\": \"$reframe\"}"
    done
}

# Get empowering narratives (for positive reinforcement)
narrative_get_empowering() {
    _narrative_ensure_file
    
    local narrative_ids
    narrative_ids=$(json_read_file "$NARRATIVES_FILE" ".narratives | keys[]" 2>/dev/null)
    
    for narrative_id in $narrative_ids; do
        [[ -z "$narrative_id" ]] && continue
        
        local classification occurrences
        classification=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".classification")
        occurrences=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".occurrences")
        
        occurrences=${occurrences:-0}
        
        # Only return empowering narratives
        [[ "$classification" != "empowering" ]] && continue
        
        local statement
        statement=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".statement")
        
        echo "{\"narrativeId\": \"$narrative_id\", \"statement\": \"$statement\", \"occurrences\": $occurrences}"
    done
}

# ============================================
# STATUS MANAGEMENT
# ============================================

# Mark narrative as addressed
narrative_mark_addressed() {
    local narrative_id="$1"
    
    _narrative_ensure_file
    
    json_update_field "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".addressed" "true"
    json_touch_file "$NARRATIVES_FILE"
}

# ============================================
# UTILITY FUNCTIONS
# ============================================

# Get narrative info by ID
narrative_get_info() {
    local narrative_id="$1"
    
    _narrative_ensure_file
    
    json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\""
}

# Check if narrative exists
narrative_exists() {
    local narrative_id="$1"
    
    _narrative_ensure_file
    
    local existing
    existing=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\"")
    
    [[ -n "$existing" ]] && [[ "$existing" != "null" ]]
}

# Get narrative statistics
narrative_get_stats() {
    _narrative_ensure_file
    
    local limiting_count=0
    local empowering_count=0
    local neutral_count=0
    
    local narrative_ids
    narrative_ids=$(json_read_file "$NARRATIVES_FILE" ".narratives | keys[]" 2>/dev/null)
    
    for narrative_id in $narrative_ids; do
        [[ -z "$narrative_id" ]] && continue
        
        local classification
        classification=$(json_read_file "$NARRATIVES_FILE" ".narratives.\"$narrative_id\".classification")
        
        case "$classification" in
            "limiting") limiting_count=$((limiting_count + 1)) ;;
            "empowering") empowering_count=$((empowering_count + 1)) ;;
            *) neutral_count=$((neutral_count + 1)) ;;
        esac
    done
    
    echo "{\"limiting\": $limiting_count, \"empowering\": $empowering_count, \"neutral\": $neutral_count}"
}

# ============================================
# EXPORTS
# ============================================

export -f narrative_generate_id
export -f narrative_detect
export -f narrative_classify
export -f narrative_suggest_reframe
export -f narrative_get_limiting
export -f narrative_get_empowering
export -f narrative_mark_addressed
export -f narrative_get_info
export -f narrative_exists
export -f narrative_get_stats
