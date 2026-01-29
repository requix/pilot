#!/usr/bin/env bash
# Identity updater - processes captured signals into identity files
# Runs periodically to update identity from passive captures

PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
IDENTITY_DIR="${PILOT_DATA}/identity"
LEARNINGS_DIR="${PILOT_DATA}/learnings"

mkdir -p "$IDENTITY_DIR/.history"
mkdir -p "$LEARNINGS_DIR"

append_to_file() {
    local file="$1"
    local type="$2"
    local content="$3"
    local date_str=$(date +%Y-%m-%d)
    
    # Skip if already exists
    grep -Fq "$content" "$file" 2>/dev/null && return 0
    
    # Remove "no captures yet" placeholder if present
    sed -i '' '/No .* captured yet/d' "$file" 2>/dev/null || true
    
    # Append the capture
    echo "" >> "$file"
    echo "### $(date +%Y-%m-%d\ %H:%M)" >> "$file"
    echo "$content" >> "$file"
    
    return 1
}

process_captures() {
    local capture_log="${IDENTITY_DIR}/.history/auto-capture.log"
    local processed_log="${IDENTITY_DIR}/.history/processed.log"
    
    [[ ! -f "$capture_log" ]] && return 0
    
    local count=0
    while IFS= read -r line; do
        # Skip if already processed
        grep -Fq "$line" "$processed_log" 2>/dev/null && continue
        
        # Extract type and content
        if echo "$line" | grep -q "MISSION:"; then
            content=$(echo "$line" | sed 's/.*MISSION: //')
            append_to_file "${IDENTITY_DIR}/MISSION.md" "mission" "$content" && ((count++))
        elif echo "$line" | grep -q "GOAL:"; then
            content=$(echo "$line" | sed 's/.*GOAL: //')
            append_to_file "${IDENTITY_DIR}/GOALS.md" "goal" "$content" && ((count++))
        elif echo "$line" | grep -q "BELIEF:"; then
            content=$(echo "$line" | sed 's/.*BELIEF: //')
            append_to_file "${IDENTITY_DIR}/BELIEFS.md" "belief" "$content" && ((count++))
        elif echo "$line" | grep -q "CHALLENGE:"; then
            content=$(echo "$line" | sed 's/.*CHALLENGE: //')
            append_to_file "${IDENTITY_DIR}/CHALLENGES.md" "challenge" "$content" && ((count++))
        elif echo "$line" | grep -q "IDEA:"; then
            content=$(echo "$line" | sed 's/.*IDEA: //')
            append_to_file "${IDENTITY_DIR}/IDEAS.md" "idea" "$content" && ((count++))
        elif echo "$line" | grep -q "LEARNING:"; then
            content=$(echo "$line" | sed 's/.*LEARNING: //')
            today=$(date +%Y%m%d)
            learning_file="${LEARNINGS_DIR}/${today}.md"
            [[ ! -f "$learning_file" ]] && echo "# Learnings - $(date +%Y-%m-%d)" > "$learning_file"
            if ! grep -Fq "$content" "$learning_file" 2>/dev/null; then
                echo -e "\n## Auto-captured $(date +%H:%M)\n$content" >> "$learning_file"
                ((count++))
            fi
        elif echo "$line" | grep -q "PREFERENCE:"; then
            content=$(echo "$line" | sed 's/.*PREFERENCE: //')
            append_to_file "${IDENTITY_DIR}/PREFERENCES.md" "preference" "$content" && ((count++))
        elif echo "$line" | grep -q "STRATEGY:"; then
            content=$(echo "$line" | sed 's/.*STRATEGY: //')
            append_to_file "${IDENTITY_DIR}/STRATEGIES.md" "strategy" "$content" && ((count++))
        fi
        
        echo "$line" >> "$processed_log"
    done < "$capture_log"
    
    echo "$count"
}

processed=$(process_captures)
echo "$(date): Processed $processed identity signals" >> "${IDENTITY_DIR}/.history/updater.log"
