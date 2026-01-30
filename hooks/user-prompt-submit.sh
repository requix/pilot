#!/usr/bin/env bash
# user-prompt-submit.sh - Self-learning: Pattern detection and context loading
# Part of PILOT - Fail-safe design (always exits 0)

# PILOT directories
# PILOT directories - everything in ~/.pilot/
PILOT_HOME="${HOME}/.pilot"
LEARNINGS_DIR="${PILOT_HOME}/learnings"
PATTERNS_DIR="${PILOT_HOME}/patterns"
LOGS_DIR="${PILOT_HOME}/logs"
HOT_MEMORY="${PILOT_HOME}/memory/hot"
CACHE_DIR="${PILOT_HOME}/.cache"
OBSERVATIONS_DIR="${PILOT_HOME}/observations"

# Ensure directories exist
mkdir -p "$HOT_MEMORY" "$PATTERNS_DIR" "$LOGS_DIR" "$OBSERVATIONS_DIR" 2>/dev/null || true

# Source helper libraries (fail-safe)
[[ -f "${PILOT_HOME}/system/lib/json-helpers.sh" ]] && source "${PILOT_HOME}/system/lib/json-helpers.sh" 2>/dev/null || true
[[ -f "${PILOT_HOME}/system/lib/performance-manager.sh" ]] && source "${PILOT_HOME}/system/lib/performance-manager.sh" 2>/dev/null || true
[[ -f "${PILOT_HOME}/system/lib/capture-controller.sh" ]] && source "${PILOT_HOME}/system/lib/capture-controller.sh" 2>/dev/null || true
[[ -f "${PILOT_HOME}/system/lib/silent-capture.sh" ]] && source "${PILOT_HOME}/system/lib/silent-capture.sh" 2>/dev/null || true
# Use only dashboard-emitter.sh (consolidated emitter library)
[[ -f "${PILOT_HOME}/system/lib/dashboard-emitter.sh" ]] && source "${PILOT_HOME}/system/lib/dashboard-emitter.sh" 2>/dev/null || true

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
        *"what is"*|*"show me"*|*"explain"*|*"describe"*|*"current state"*|*"understand"*|*"observe"*|*"check status"*|*"examine"*)
            echo "OBSERVE" ;;
        *"how could"*|*"options"*|*"approaches"*|*"alternatives"*|*"ideas"*|*"think about"*|*"consider"*|*"brainstorm"*)
            echo "THINK" ;;
        *"plan"*|*"strategy"*|*"steps"*|*"roadmap"*|*"sequence"*|*"order"*)
            echo "PLAN" ;;
        *"criteria"*|*"success"*|*"define"*|*"requirements"*|*"spec"*|*"should"*|*"must"*|*"test plan"*|*"what success looks like"*|*"how will we know"*|*"acceptance criteria"*)
            echo "BUILD" ;;
        *"do it"*|*"implement"*|*"create"*|*"make"*|*"execute"*|*"run"*|*"fix"*|*"change"*|*"update"*|*"add"*|*"remove"*|*"build"*|*"deploy"*)
            echo "EXECUTE" ;;
        *"test"*|*"verify"*|*"check"*|*"validate"*|*"confirm"*|*"works"*|*"does it work"*|*"is it working"*|*"did it work"*|*"result"*|*"output"*)
            echo "VERIFY" ;;
        *"learned"*|*"takeaway"*|*"insight"*|*"summary"*|*"what worked"*|*"lesson"*|*"conclusion"*)
            echo "LEARN" ;;
        *)
            echo "EXECUTE" ;;
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

# Emit phase to dashboard (if emitter is available)
type dashboard_emit_phase &>/dev/null && dashboard_emit_phase "$PHASE"

# Escape prompt for JSON (truncate, escape quotes/newlines)
PROMPT_ESCAPED=$(echo "$USER_PROMPT" | head -c 200 | sed 's/\\/\\\\/g;s/"/\\"/g' | tr '\n' ' ')

# Log to session log
echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"prompt\",\"session_id\":\"$SESSION_ID\",\"phase\":\"$PHASE\",\"prompt\":\"$PROMPT_ESCAPED\"}" >> "$HOT_MEMORY/current-session.jsonl" 2>/dev/null || true

# Log algorithm phase
echo "{\"timestamp\":\"$TIMESTAMP\",\"session_id\":\"$SESSION_ID\",\"phase\":\"$PHASE\"}" >> "$HOT_MEMORY/algorithm-phases.jsonl" 2>/dev/null || true

# ============================================
# ADAPTIVE IDENTITY CAPTURE: Run detectors based on tier
# ============================================

# Get current tier (default to standard)
CURRENT_TIER=$(perf_get_tier 2>/dev/null || echo "standard")
DETECTOR_OUTPUT=""

# Run detectors based on tier (with performance tracking)
run_detector() {
    local detector_name="$1"
    local detector_func="$2"
    local start_time end_time duration
    
    start_time=$(date +%s%3N 2>/dev/null || date +%s)
    
    # Run detector (capture output)
    local result
    result=$($detector_func "$USER_PROMPT" 2>/dev/null) || true
    
    end_time=$(date +%s%3N 2>/dev/null || date +%s)
    duration=$((end_time - start_time))
    
    # Record performance
    perf_record "$detector_name" "$duration" 2>/dev/null || true
    
    # Return result if any
    [[ -n "$result" ]] && echo "$result"
}

# Minimal tier: Project + Challenge detectors
if [[ "$CURRENT_TIER" == "minimal" ]] || [[ "$CURRENT_TIER" == "standard" ]] || [[ "$CURRENT_TIER" == "full" ]]; then
    # Challenge detection (look for error/blocker patterns)
    if [[ -f "${PILOT_HOME}/system/detectors/challenge-detector.sh" ]]; then
        source "${PILOT_HOME}/system/detectors/challenge-detector.sh" 2>/dev/null || true
        
        # Check for debugging context
        if capture_detect_debugging "$USER_PROMPT" 2>/dev/null; then
            # Extract challenge type from prompt
            CHALLENGE_TYPE=$(echo "$USER_PROMPT" | head -c 100 | tr -d '\n')
            challenge_record_blocker "$CHALLENGE_TYPE" "$USER_PROMPT" 2>/dev/null || true
        fi
    fi
fi

# Standard tier: Add Learning, Strategy, Idea, Belief detectors
if [[ "$CURRENT_TIER" == "standard" ]] || [[ "$CURRENT_TIER" == "full" ]]; then
    # Idea detection
    if [[ -f "${PILOT_HOME}/system/detectors/idea-capturer.sh" ]]; then
        source "${PILOT_HOME}/system/detectors/idea-capturer.sh" 2>/dev/null || true
        IDEA_RESULT=$(idea_detect "$USER_PROMPT" 2>/dev/null) || true
        if [[ -n "$IDEA_RESULT" ]]; then
            DETECTOR_OUTPUT="$DETECTOR_OUTPUT
💡 Idea detected - consider adding to IDEAS.md"
        fi
    fi
fi

# Full tier: Add Model, Narrative detectors
if [[ "$CURRENT_TIER" == "full" ]]; then
    # Model detection
    if [[ -f "${PILOT_HOME}/system/detectors/model-detector.sh" ]]; then
        source "${PILOT_HOME}/system/detectors/model-detector.sh" 2>/dev/null || true
        MODEL_RESULT=$(model_detect "$USER_PROMPT" 2>/dev/null) || true
    fi
    
    # Narrative detection
    if [[ -f "${PILOT_HOME}/system/detectors/narrative-detector.sh" ]]; then
        source "${PILOT_HOME}/system/detectors/narrative-detector.sh" 2>/dev/null || true
        NARRATIVE_RESULT=$(narrative_detect "$USER_PROMPT" 2>/dev/null) || true
        
        # If limiting narrative detected, suggest reframe
        if echo "$NARRATIVE_RESULT" | grep -q '"classification": "limiting"' 2>/dev/null; then
            REFRAME=$(echo "$NARRATIVE_RESULT" | grep -o '"suggestedReframe": "[^"]*"' | sed 's/.*": "//;s/"$//')
            [[ -n "$REFRAME" ]] && DETECTOR_OUTPUT="$DETECTOR_OUTPUT
🔄 Consider reframing: $REFRAME"
        fi
    fi
fi

# Add detector output to context if any
[[ -n "$DETECTOR_OUTPUT" ]] && OUTPUT_CONTEXT="$OUTPUT_CONTEXT$DETECTOR_OUTPUT"

# ============================================
# SELF-LEARNING: Pattern detection
# ============================================

NORMALIZED=$(normalize_text "$USER_PROMPT")
PROMPT_HASH=$(generate_hash "$NORMALIZED")
PATTERNS_LOG="$PATTERNS_DIR/questions.log"
OUTPUT_CONTEXT=""

# Check for repeated patterns
if [ -f "$PATTERNS_LOG" ]; then
    REPEAT_COUNT=$(grep -c "^$PROMPT_HASH|" "$PATTERNS_LOG" 2>/dev/null | head -1 || echo "0")
    REPEAT_COUNT=${REPEAT_COUNT:-0}
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

# ============================================
# SILENT IDENTITY AUTO-CAPTURE
# ============================================

# Run silent capture on the prompt (non-blocking, fail-safe)
if type capture_from_prompt &>/dev/null; then
    capture_from_prompt "$USER_PROMPT" 2>/dev/null || true
fi

exit 0
