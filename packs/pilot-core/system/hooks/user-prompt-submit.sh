#!/usr/bin/env bash
# user-prompt-submit.sh - Self-learning: Pattern detection and context loading
# Part of PILOT - Fail-safe design (always exits 0)

# PILOT directories
PILOT_DIR="${PILOT_DIR:-$HOME/.pilot}"
PILOT_HOME="${HOME}/.kiro/pilot"
LEARNINGS_DIR="${PILOT_DIR}/learnings"
PATTERNS_DIR="${PILOT_DIR}/patterns"
LOGS_DIR="${PILOT_DIR}/logs"
HOT_MEMORY="${PILOT_HOME}/memory/hot"
CACHE_DIR="${PILOT_HOME}/.cache"

# Ensure directories exist
mkdir -p "$HOT_MEMORY" "$PATTERNS_DIR" "$LOGS_DIR" 2>/dev/null || true

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

# Normalize text for pattern matching (lowercase, remove punctuation, collapse spaces)
normalize_text() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]' | tr -s ' ' | head -c 200
}

# Generate hash for pattern detection
generate_hash() {
    echo "$1" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "nohash"
}

# Search learnings for relevant context
search_learnings() {
    local query="$1"
    local results=""
    
    [ ! -d "$LEARNINGS_DIR" ] && return
    
    # Extract key words (3+ chars, not common words)
    local keywords=$(echo "$query" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alpha:]' '\n' | \
        grep -vE '^(the|and|for|are|but|not|you|all|can|had|her|was|one|our|out|has|his|how|its|may|new|now|old|see|way|who|did|get|let|put|say|she|too|use|what|when|where|which|why|will|with|would|about|after|also|back|been|being|both|came|come|could|each|even|find|first|from|give|going|good|great|have|here|into|just|know|last|like|little|long|look|made|make|many|more|most|much|must|name|never|next|only|other|over|part|people|place|right|same|should|show|small|some|still|such|take|than|that|them|then|there|these|they|thing|think|this|those|through|time|under|very|want|well|were|what|when|where|which|while|work|year|your)$' | \
        head -5)
    
    [ -z "$keywords" ] && return
    
    # Search in learning files
    for keyword in $keywords; do
        local found=$(grep -l -i "$keyword" "$LEARNINGS_DIR"/*_learning.md 2>/dev/null | head -2)
        for f in $found; do
            [ -z "$results" ] && results="$f" || results="$results $f"
        done
    done
    
    # Return unique files
    echo "$results" | tr ' ' '\n' | sort -u | head -3
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

# ============================================
# SELF-LEARNING: Pattern detection
# ============================================

NORMALIZED=$(normalize_text "$USER_PROMPT")
PROMPT_HASH=$(generate_hash "$NORMALIZED")
PATTERNS_LOG="$PATTERNS_DIR/questions.log"
OUTPUT_CONTEXT=""

# Check for repeated patterns
if [ -f "$PATTERNS_LOG" ]; then
    REPEAT_COUNT=$(grep -c "^$PROMPT_HASH|" "$PATTERNS_LOG" 2>/dev/null || echo "0")
    if [ "$REPEAT_COUNT" -ge 2 ]; then
        OUTPUT_CONTEXT="$OUTPUT_CONTEXT
💡 You've asked similar questions $REPEAT_COUNT times before.
Consider adding the answer to your knowledge base for future reference."
    fi
fi

# Log current pattern
echo "$PROMPT_HASH|$TIMESTAMP|$NORMALIZED" >> "$PATTERNS_LOG" 2>/dev/null || true

# Keep patterns log from growing too large (last 1000 entries)
if [ -f "$PATTERNS_LOG" ] && [ $(wc -l < "$PATTERNS_LOG" 2>/dev/null || echo 0) -gt 1000 ]; then
    tail -500 "$PATTERNS_LOG" > "$PATTERNS_LOG.tmp" 2>/dev/null && mv "$PATTERNS_LOG.tmp" "$PATTERNS_LOG" 2>/dev/null || true
fi

# ============================================
# SELF-LEARNING: Search for relevant learnings
# ============================================

RELEVANT_FILES=$(search_learnings "$USER_PROMPT")
if [ -n "$RELEVANT_FILES" ]; then
    RELEVANT_CONTEXT=""
    for f in $RELEVANT_FILES; do
        if [ -f "$f" ]; then
            # Extract summary from learning file
            SUMMARY=$(grep -A1 "^## Summary" "$f" 2>/dev/null | tail -1 | head -c 150)
            [ -n "$SUMMARY" ] && RELEVANT_CONTEXT="$RELEVANT_CONTEXT
- $SUMMARY..."
        fi
    done
    
    if [ -n "$RELEVANT_CONTEXT" ]; then
        OUTPUT_CONTEXT="$OUTPUT_CONTEXT

## Relevant Past Learnings
$RELEVANT_CONTEXT"
    fi
fi

# Output context if we have any
if [ -n "$OUTPUT_CONTEXT" ]; then
    echo "<pilot-context>$OUTPUT_CONTEXT
</pilot-context>"
fi

exit 0
