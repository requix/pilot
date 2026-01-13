#!/usr/bin/env bash
# user-prompt-submit.sh - Process user prompts and detect algorithm phases
# Part of PILOT - Fail-safe design (always exits 0)

PILOT_HOME="${HOME}/.kiro/pilot"
HOT_MEMORY="${PILOT_HOME}/memory/hot"
CACHE_DIR="${PILOT_HOME}/.cache"

# Ensure directories exist
mkdir -p "$HOT_MEMORY" 2>/dev/null || true

# Get input JSON from STDIN (Kiro sends hook events via STDIN, not arguments)
input_json=$(cat 2>/dev/null || echo "{}")

# Get session ID (from input or persisted file)
get_session_id() {
    local json="$1"
    local sid=""
    if command -v jq >/dev/null 2>&1; then
        sid=$(echo "$json" | jq -r '.sessionId // .session_id // empty' 2>/dev/null) || true
    fi
    if [ -z "$sid" ] && [ -f "$CACHE_DIR/current-session-id" ]; then
        sid=$(cat "$CACHE_DIR/current-session-id" 2>/dev/null) || true
    fi
    echo "${sid:-unknown}"
}

# Get message from JSON
get_message() {
    local json="$1"
    local msg=""
    if command -v jq >/dev/null 2>&1; then
        msg=$(echo "$json" | jq -r '.message // .prompt // .content // empty' 2>/dev/null) || true
    fi
    echo "$msg"
}

# Detect algorithm phase from prompt
detect_phase() {
    local prompt="$1"
    local lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')
    
    case "$lower" in
        *"what is"*|*"show me"*|*"explain"*|*"describe"*|*"current state"*|*"understand"*)
            echo "OBSERVE" ;;
        *"how could"*|*"options"*|*"approaches"*|*"alternatives"*|*"ideas"*|*"think about"*)
            echo "THINK" ;;
        *"plan"*|*"strategy"*|*"steps"*|*"roadmap"*)
            echo "PLAN" ;;
        *"criteria"*|*"success"*|*"define"*|*"requirements"*|*"spec"*)
            echo "BUILD" ;;
        *"do it"*|*"implement"*|*"create"*|*"make"*|*"execute"*|*"run"*|*"fix"*|*"change"*|*"update"*|*"add"*|*"remove"*)
            echo "EXECUTE" ;;
        *"test"*|*"verify"*|*"check"*|*"validate"*|*"confirm"*|*"works"*)
            echo "VERIFY" ;;
        *"learned"*|*"takeaway"*|*"insight"*|*"summary"*|*"what worked"*)
            echo "LEARN" ;;
        *)
            echo "UNKNOWN" ;;
    esac
}

# Extract fields
SESSION_ID=$(get_session_id "$input_json")
USER_PROMPT=$(get_message "$input_json")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Exit if no message
[ -z "$USER_PROMPT" ] && exit 0

# Detect algorithm phase
PHASE=$(detect_phase "$USER_PROMPT")

# Escape prompt for JSON (truncate, escape quotes/newlines)
PROMPT_ESCAPED=$(echo "$USER_PROMPT" | head -c 200 | sed 's/\\/\\\\/g;s/"/\\"/g' | tr '\n' ' ')

# Log to session log
echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"prompt\",\"session_id\":\"$SESSION_ID\",\"phase\":\"$PHASE\",\"prompt\":\"$PROMPT_ESCAPED\"}" >> "$HOT_MEMORY/current-session.jsonl" 2>/dev/null || true

# Log algorithm phase
echo "{\"timestamp\":\"$TIMESTAMP\",\"session_id\":\"$SESSION_ID\",\"phase\":\"$PHASE\"}" >> "$HOT_MEMORY/algorithm-phases.jsonl" 2>/dev/null || true

# Silent hook
exit 0
