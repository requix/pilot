#!/usr/bin/env bash
# analyze-identity-gaps.sh - Analyzes identity completeness
# Output: JSON with gaps and context for smart question generation

PILOT_DATA="${PILOT_DATA:-$HOME/.pilot}"
IDENTITY_DIR="${PILOT_DATA}/identity"

analyze_file() {
    local file="$1"
    local name="$2"
    
    [[ ! -f "$file" ]] && echo "missing" && return
    
    local lines=$(wc -l < "$file" | tr -d ' ')
    local has_content=$(grep -c "^###" "$file" 2>/dev/null || echo 0)
    
    if [[ $has_content -eq 0 ]] || grep -q "No .* captured yet" "$file" 2>/dev/null; then
        echo "empty"
    elif [[ $lines -lt 15 ]]; then
        echo "sparse"
    else
        echo "populated"
    fi
}

# Analyze each identity file
mission=$(analyze_file "${IDENTITY_DIR}/MISSION.md" "mission")
goals=$(analyze_file "${IDENTITY_DIR}/GOALS.md" "goals")
beliefs=$(analyze_file "${IDENTITY_DIR}/BELIEFS.md" "beliefs")
challenges=$(analyze_file "${IDENTITY_DIR}/CHALLENGES.md" "challenges")
strategies=$(analyze_file "${IDENTITY_DIR}/STRATEGIES.md" "strategies")
ideas=$(analyze_file "${IDENTITY_DIR}/IDEAS.md" "ideas")
preferences=$(analyze_file "${IDENTITY_DIR}/PREFERENCES.md" "preferences")
models=$(analyze_file "${IDENTITY_DIR}/MODELS.md" "models")
narratives=$(analyze_file "${IDENTITY_DIR}/NARRATIVES.md" "narratives")

# Build gaps array
gaps=""
[[ "$mission" != "populated" ]] && gaps="${gaps}\"mission\","
[[ "$goals" != "populated" ]] && gaps="${gaps}\"goals\","
[[ "$beliefs" != "populated" ]] && gaps="${gaps}\"beliefs\","
[[ "$challenges" != "populated" ]] && gaps="${gaps}\"challenges\","
[[ "$strategies" != "populated" ]] && gaps="${gaps}\"strategies\","
[[ "$ideas" != "populated" ]] && gaps="${gaps}\"ideas\","
[[ "$preferences" != "populated" ]] && gaps="${gaps}\"preferences\","
[[ "$models" != "populated" ]] && gaps="${gaps}\"models\","
[[ "$narratives" != "populated" ]] && gaps="${gaps}\"narratives\","

# Remove trailing comma
gaps="${gaps%,}"

# Get recent session topics from capture log
recent=""
if [[ -f "${IDENTITY_DIR}/.history/auto-capture.log" ]]; then
    recent=$(tail -5 "${IDENTITY_DIR}/.history/auto-capture.log" 2>/dev/null | grep -oE "(MISSION|GOAL|BELIEF|CHALLENGE|IDEA|LEARNING|PREFERENCE|STRATEGY):" | sort -u | tr '\n' ',' | sed 's/,$//')
fi

# Output JSON
cat << EOF
{
  "gaps": [${gaps}],
  "recentCaptures": "${recent}",
  "completeness": {
    "mission": "${mission}",
    "goals": "${goals}",
    "beliefs": "${beliefs}",
    "challenges": "${challenges}",
    "strategies": "${strategies}",
    "ideas": "${ideas}",
    "preferences": "${preferences}",
    "models": "${models}",
    "narratives": "${narratives}"
  },
  "analyzedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
