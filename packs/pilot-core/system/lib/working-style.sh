#!/usr/bin/env bash
# working-style.sh - Working Style Detection for Adaptive Identity Capture
# Part of PILOT - Detects user preferences from interaction patterns
#
# Features:
# - Response format preference detection
# - Timezone/productivity hours detection
# - Technology preference detection
# - Communication style detection
#
# Usage:
#   source working-style.sh
#   style_detect_preferences "$user_input"
#   style_get_productivity_hours
#   style_get_tech_preferences

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/json-helpers.sh" ]] && source "${SCRIPT_DIR}/json-helpers.sh"

# Directories and files
PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
OBSERVATIONS_DIR="${PILOT_DATA}/observations"
STYLE_FILE="${OBSERVATIONS_DIR}/working-style.json"

# Configuration
STYLE_DETECTION_THRESHOLD=5      # Occurrences before suggesting preference
PRODUCTIVITY_SAMPLE_SIZE=20      # Sessions to analyze for productivity hours

# ============================================
# INITIALIZATION
# ============================================

_style_ensure_file() {
    mkdir -p "$OBSERVATIONS_DIR" 2>/dev/null || true
    
    if [[ ! -f "$STYLE_FILE" ]]; then
        cat > "$STYLE_FILE" 2>/dev/null << 'EOF'
{
  "responseFormat": {
    "prefersBullets": 0,
    "prefersCode": 0,
    "prefersConcise": 0,
    "prefersDetailed": 0
  },
  "sessionTimes": [],
  "technologies": {},
  "communicationPatterns": {
    "directRequests": 0,
    "questionStyle": 0,
    "contextProvided": 0
  },
  "detectedPreferences": {},
  "lastUpdated": null
}
EOF
    fi
}

# ============================================
# RESPONSE FORMAT DETECTION
# ============================================

# Detect response format preferences from user input
style_detect_format_preference() {
    local input="$1"
    
    _style_ensure_file
    
    local detected=""
    
    # Check for bullet point preference
    if [[ "$input" =~ (list|bullet|points|enumerate) ]]; then
        json_increment "$STYLE_FILE" ".responseFormat.prefersBullets"
        detected="$detected bullets"
    fi
    
    # Check for code preference
    if [[ "$input" =~ (show.*code|example|snippet|implementation) ]]; then
        json_increment "$STYLE_FILE" ".responseFormat.prefersCode"
        detected="$detected code"
    fi
    
    # Check for concise preference
    if [[ "$input" =~ (brief|short|concise|quick|tldr|tl;dr) ]]; then
        json_increment "$STYLE_FILE" ".responseFormat.prefersConcise"
        detected="$detected concise"
    fi
    
    # Check for detailed preference
    if [[ "$input" =~ (detail|explain|elaborate|thorough|comprehensive) ]]; then
        json_increment "$STYLE_FILE" ".responseFormat.prefersDetailed"
        detected="$detected detailed"
    fi
    
    json_touch_file "$STYLE_FILE"
    echo "$detected"
}

# Get dominant format preference
style_get_format_preference() {
    _style_ensure_file
    
    local bullets code concise detailed
    bullets=$(json_read_file "$STYLE_FILE" ".responseFormat.prefersBullets")
    code=$(json_read_file "$STYLE_FILE" ".responseFormat.prefersCode")
    concise=$(json_read_file "$STYLE_FILE" ".responseFormat.prefersConcise")
    detailed=$(json_read_file "$STYLE_FILE" ".responseFormat.prefersDetailed")
    
    bullets=${bullets:-0}
    code=${code:-0}
    concise=${concise:-0}
    detailed=${detailed:-0}
    
    local max=$bullets
    local preference="bullets"
    
    [[ $code -gt $max ]] && { max=$code; preference="code"; }
    [[ $concise -gt $max ]] && { max=$concise; preference="concise"; }
    [[ $detailed -gt $max ]] && { max=$detailed; preference="detailed"; }
    
    if [[ $max -ge $STYLE_DETECTION_THRESHOLD ]]; then
        echo "{\"preference\": \"$preference\", \"confidence\": $max, \"threshold\": $STYLE_DETECTION_THRESHOLD}"
    else
        echo "{\"preference\": \"none\", \"confidence\": $max, \"threshold\": $STYLE_DETECTION_THRESHOLD}"
    fi
}

# ============================================
# PRODUCTIVITY HOURS DETECTION
# ============================================

# Record session time for productivity analysis
style_record_session_time() {
    local hour="${1:-$(date +%H)}"
    local day_of_week="${2:-$(date +%u)}"
    
    _style_ensure_file
    
    local session_data="{\"hour\": $hour, \"dayOfWeek\": $day_of_week, \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}"
    
    json_array_append "$STYLE_FILE" ".sessionTimes" "$session_data"
    
    # Trim to sample size
    local count
    count=$(json_array_length "$STYLE_FILE" ".sessionTimes")
    
    while [[ $count -gt $PRODUCTIVITY_SAMPLE_SIZE ]]; do
        json_array_remove "$STYLE_FILE" ".sessionTimes" "0"
        ((count--))
    done
    
    json_touch_file "$STYLE_FILE"
}

# Analyze productivity hours
style_get_productivity_hours() {
    _style_ensure_file
    
    local sessions
    sessions=$(json_read_file "$STYLE_FILE" ".sessionTimes")
    
    if [[ -z "$sessions" ]] || [[ "$sessions" == "null" ]]; then
        echo '{"peakHours": [], "peakDays": [], "sampleSize": 0}'
        return
    fi
    
    # Count hours
    declare -A hour_counts
    declare -A day_counts
    
    local hours
    hours=$(echo "$sessions" | grep -o '"hour":[0-9]*' | cut -d: -f2)
    
    for h in $hours; do
        hour_counts[$h]=$((${hour_counts[$h]:-0} + 1))
    done
    
    local days
    days=$(echo "$sessions" | grep -o '"dayOfWeek":[0-9]*' | cut -d: -f2)
    
    for d in $days; do
        day_counts[$d]=$((${day_counts[$d]:-0} + 1))
    done
    
    # Find peak hours (top 3)
    local peak_hours=""
    local sorted_hours
    sorted_hours=$(for h in "${!hour_counts[@]}"; do echo "${hour_counts[$h]} $h"; done | sort -rn | head -3)
    
    while read -r count hour; do
        [[ -n "$hour" ]] && peak_hours="$peak_hours $hour"
    done <<< "$sorted_hours"
    
    # Find peak days
    local peak_days=""
    local sorted_days
    sorted_days=$(for d in "${!day_counts[@]}"; do echo "${day_counts[$d]} $d"; done | sort -rn | head -3)
    
    while read -r count day; do
        [[ -n "$day" ]] && peak_days="$peak_days $day"
    done <<< "$sorted_days"
    
    local sample_size
    sample_size=$(json_array_length "$STYLE_FILE" ".sessionTimes")
    
    cat << EOF
{
  "peakHours": [${peak_hours// /, }],
  "peakDays": [${peak_days// /, }],
  "sampleSize": $sample_size
}
EOF
}

# ============================================
# TECHNOLOGY PREFERENCE DETECTION
# ============================================

# Detect technology from user input
style_detect_technology() {
    local input="$1"
    
    _style_ensure_file
    
    local detected=""
    
    # Programming languages
    local languages="typescript javascript python go rust java kotlin swift ruby php"
    for lang in $languages; do
        if echo "$input" | grep -qi "\b$lang\b"; then
            json_increment "$STYLE_FILE" ".technologies.\"$lang\""
            detected="$detected $lang"
        fi
    done
    
    # Frameworks
    local frameworks="react vue angular nextjs express fastapi django flask terraform cdk"
    for fw in $frameworks; do
        if echo "$input" | grep -qi "\b$fw\b"; then
            json_increment "$STYLE_FILE" ".technologies.\"$fw\""
            detected="$detected $fw"
        fi
    done
    
    # Cloud providers
    if echo "$input" | grep -qi "\baws\b\|amazon"; then
        json_increment "$STYLE_FILE" ".technologies.\"aws\""
        detected="$detected aws"
    fi
    if echo "$input" | grep -qi "\bgcp\b\|google cloud"; then
        json_increment "$STYLE_FILE" ".technologies.\"gcp\""
        detected="$detected gcp"
    fi
    if echo "$input" | grep -qi "\bazure\b"; then
        json_increment "$STYLE_FILE" ".technologies.\"azure\""
        detected="$detected azure"
    fi
    
    json_touch_file "$STYLE_FILE"
    echo "$detected"
}

# Get top technology preferences
style_get_tech_preferences() {
    _style_ensure_file
    
    local techs
    techs=$(json_read_file "$STYLE_FILE" ".technologies")
    
    if [[ -z "$techs" ]] || [[ "$techs" == "null" ]] || [[ "$techs" == "{}" ]]; then
        echo '{"topTechnologies": [], "totalMentions": 0}'
        return
    fi
    
    # Parse and sort technologies
    local sorted_techs
    sorted_techs=$(echo "$techs" | grep -o '"[^"]*":[0-9]*' | while read -r line; do
        local tech count
        tech=$(echo "$line" | cut -d'"' -f2)
        count=$(echo "$line" | cut -d: -f2)
        echo "$count $tech"
    done | sort -rn | head -5)
    
    local top_techs=""
    local total=0
    
    while read -r count tech; do
        [[ -n "$tech" ]] && {
            top_techs="$top_techs{\"name\": \"$tech\", \"mentions\": $count},"
            total=$((total + count))
        }
    done <<< "$sorted_techs"
    
    # Remove trailing comma
    top_techs="${top_techs%,}"
    
    cat << EOF
{
  "topTechnologies": [$top_techs],
  "totalMentions": $total
}
EOF
}

# ============================================
# COMMUNICATION STYLE DETECTION
# ============================================

# Detect communication patterns
style_detect_communication() {
    local input="$1"
    
    _style_ensure_file
    
    local detected=""
    
    # Direct requests (imperative)
    if [[ "$input" =~ ^(Create|Build|Fix|Update|Delete|Show|List|Run|Deploy) ]]; then
        json_increment "$STYLE_FILE" ".communicationPatterns.directRequests"
        detected="$detected direct"
    fi
    
    # Question style
    if [[ "$input" =~ \? ]] || [[ "$input" =~ ^(How|What|Why|When|Where|Can|Could|Would|Should) ]]; then
        json_increment "$STYLE_FILE" ".communicationPatterns.questionStyle"
        detected="$detected question"
    fi
    
    # Context provided
    if [[ ${#input} -gt 100 ]] || [[ "$input" =~ (because|since|context|background) ]]; then
        json_increment "$STYLE_FILE" ".communicationPatterns.contextProvided"
        detected="$detected contextual"
    fi
    
    json_touch_file "$STYLE_FILE"
    echo "$detected"
}

# Get communication style summary
style_get_communication_style() {
    _style_ensure_file
    
    local direct question contextual
    direct=$(json_read_file "$STYLE_FILE" ".communicationPatterns.directRequests")
    question=$(json_read_file "$STYLE_FILE" ".communicationPatterns.questionStyle")
    contextual=$(json_read_file "$STYLE_FILE" ".communicationPatterns.contextProvided")
    
    direct=${direct:-0}
    question=${question:-0}
    contextual=${contextual:-0}
    
    local total=$((direct + question))
    local style="balanced"
    
    if [[ $total -gt 0 ]]; then
        local direct_ratio=$((direct * 100 / total))
        if [[ $direct_ratio -gt 70 ]]; then
            style="directive"
        elif [[ $direct_ratio -lt 30 ]]; then
            style="inquisitive"
        fi
    fi
    
    cat << EOF
{
  "style": "$style",
  "directRequests": $direct,
  "questions": $question,
  "contextual": $contextual
}
EOF
}

# ============================================
# PREFERENCE SUGGESTIONS
# ============================================

# Get all detected preferences for suggestion
style_get_suggestions() {
    _style_ensure_file
    
    local suggestions="[]"
    
    # Check format preference
    local format_pref
    format_pref=$(style_get_format_preference)
    local format_type
    format_type=$(echo "$format_pref" | grep -o '"preference":"[^"]*"' | cut -d'"' -f4)
    
    if [[ "$format_type" != "none" ]]; then
        local confidence
        confidence=$(echo "$format_pref" | grep -o '"confidence":[0-9]*' | cut -d: -f2)
        echo "{\"type\": \"format\", \"preference\": \"$format_type\", \"confidence\": $confidence}"
    fi
    
    # Check tech preferences
    local tech_pref
    tech_pref=$(style_get_tech_preferences)
    local total_mentions
    total_mentions=$(echo "$tech_pref" | grep -o '"totalMentions":[0-9]*' | cut -d: -f2)
    
    if [[ $total_mentions -ge $STYLE_DETECTION_THRESHOLD ]]; then
        echo "{\"type\": \"technology\", \"data\": $tech_pref}"
    fi
    
    # Check communication style
    local comm_style
    comm_style=$(style_get_communication_style)
    local style_type
    style_type=$(echo "$comm_style" | grep -o '"style":"[^"]*"' | cut -d'"' -f4)
    
    if [[ "$style_type" != "balanced" ]]; then
        echo "{\"type\": \"communication\", \"style\": \"$style_type\"}"
    fi
}

# ============================================
# MAIN DETECTION FUNCTION
# ============================================

# Run all detections on user input
style_analyze_input() {
    local input="$1"
    
    _style_ensure_file
    
    # Run all detectors
    style_detect_format_preference "$input" >/dev/null
    style_detect_technology "$input" >/dev/null
    style_detect_communication "$input" >/dev/null
    
    # Record session time
    style_record_session_time
    
    json_touch_file "$STYLE_FILE"
}

# ============================================
# EXPORTS
# ============================================

export -f style_detect_format_preference
export -f style_get_format_preference
export -f style_record_session_time
export -f style_get_productivity_hours
export -f style_detect_technology
export -f style_get_tech_preferences
export -f style_detect_communication
export -f style_get_communication_style
export -f style_get_suggestions
export -f style_analyze_input
