#!/usr/bin/env bash
# prompt-templates.sh - Prompt Templates for Adaptive Identity Capture
# Part of PILOT - Generates user-friendly prompts for identity updates
#
# Features:
# - Templates for each identity file type
# - Observation-based prompt generation
# - Terminal-friendly formatting
#
# Usage:
#   source prompt-templates.sh
#   prompt_generate_project "$project_data"
#   prompt_generate_goal "$goal_data"
#   prompt_format_for_terminal "$prompt"

# Dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for terminal output
PROMPT_COLOR_HEADER='\033[1;36m'    # Cyan bold
PROMPT_COLOR_QUESTION='\033[1;33m'  # Yellow bold
PROMPT_COLOR_HINT='\033[0;90m'      # Gray
PROMPT_COLOR_RESET='\033[0m'

# ============================================
# PROJECT PROMPTS
# ============================================

# Generate prompt for adding a project to identity
prompt_generate_project() {
    local project_name="$1"
    local session_count="$2"
    local total_time="${3:-0}"
    local working_dir="${4:-}"
    
    local time_formatted
    time_formatted=$(prompt_format_time "$total_time")
    
    cat << EOF
${PROMPT_COLOR_HEADER}📁 Project Detected${PROMPT_COLOR_RESET}

I've noticed you've been working on ${PROMPT_COLOR_QUESTION}${project_name}${PROMPT_COLOR_RESET} frequently.

${PROMPT_COLOR_HINT}Sessions: ${session_count} | Time: ${time_formatted}${PROMPT_COLOR_RESET}
${PROMPT_COLOR_HINT}Location: ${working_dir}${PROMPT_COLOR_RESET}

${PROMPT_COLOR_QUESTION}Would you like to add this to your PROJECTS.md?${PROMPT_COLOR_RESET}

This helps me:
• Remember context between sessions
• Suggest relevant past learnings
• Track time allocation

EOF
}

# ============================================
# GOAL PROMPTS
# ============================================

# Generate prompt for suggesting a goal
prompt_generate_goal() {
    local cluster_name="$1"
    local project_count="$2"
    local suggested_goal="$3"
    
    cat << EOF
${PROMPT_COLOR_HEADER}🎯 Goal Pattern Detected${PROMPT_COLOR_RESET}

You have ${PROMPT_COLOR_QUESTION}${project_count} related projects${PROMPT_COLOR_RESET} in the "${cluster_name}" area.

${PROMPT_COLOR_HINT}Suggested goal:${PROMPT_COLOR_RESET}
"${suggested_goal}"

${PROMPT_COLOR_QUESTION}Would you like to add this goal to your GOALS.md?${PROMPT_COLOR_RESET}

Goals help me:
• Understand your priorities
• Suggest relevant approaches
• Track progress over time

EOF
}

# ============================================
# CHALLENGE PROMPTS
# ============================================

# Generate prompt for documenting a challenge
prompt_generate_challenge() {
    local pattern="$1"
    local occurrence_count="$2"
    local contexts="$3"
    
    cat << EOF
${PROMPT_COLOR_HEADER}⚠️ Recurring Challenge${PROMPT_COLOR_RESET}

I've noticed you've encountered "${PROMPT_COLOR_QUESTION}${pattern}${PROMPT_COLOR_RESET}" ${occurrence_count} times.

${PROMPT_COLOR_HINT}Contexts: ${contexts}${PROMPT_COLOR_RESET}

${PROMPT_COLOR_QUESTION}Would you like to document this in CHALLENGES.md?${PROMPT_COLOR_RESET}

Documenting challenges helps:
• Track resolution progress
• Apply past solutions
• Identify patterns

EOF
}

# ============================================
# LEARNING PROMPTS
# ============================================

# Generate prompt for capturing a learning
prompt_generate_learning() {
    local topic="$1"
    local context="$2"
    local solution="${3:-}"
    
    cat << EOF
${PROMPT_COLOR_HEADER}💡 Learning Opportunity${PROMPT_COLOR_RESET}

You just solved: "${PROMPT_COLOR_QUESTION}${topic}${PROMPT_COLOR_RESET}"

${PROMPT_COLOR_HINT}Context: ${context}${PROMPT_COLOR_RESET}

${PROMPT_COLOR_QUESTION}Would you like to capture this in LEARNED.md?${PROMPT_COLOR_RESET}

Capturing learnings helps:
• Avoid repeating mistakes
• Build your knowledge base
• Share insights with future you

EOF
}

# ============================================
# BELIEF PROMPTS
# ============================================

# Generate prompt for documenting a belief
prompt_generate_belief() {
    local belief="$1"
    local occurrence_count="$2"
    local domain="${3:-general}"
    
    cat << EOF
${PROMPT_COLOR_HEADER}💭 Belief Pattern${PROMPT_COLOR_RESET}

You've expressed this ${occurrence_count} times:
"${PROMPT_COLOR_QUESTION}${belief}${PROMPT_COLOR_RESET}"

${PROMPT_COLOR_HINT}Domain: ${domain}${PROMPT_COLOR_RESET}

${PROMPT_COLOR_QUESTION}Would you like to add this to BELIEFS.md?${PROMPT_COLOR_RESET}

Documenting beliefs helps me:
• Align suggestions with your values
• Understand your decision-making
• Provide consistent guidance

EOF
}

# ============================================
# STRATEGY PROMPTS
# ============================================

# Generate prompt for documenting a strategy
prompt_generate_strategy() {
    local strategy_name="$1"
    local usage_count="$2"
    local description="${3:-}"
    
    cat << EOF
${PROMPT_COLOR_HEADER}🎮 Strategy Detected${PROMPT_COLOR_RESET}

You've used this approach ${usage_count} times:
"${PROMPT_COLOR_QUESTION}${strategy_name}${PROMPT_COLOR_RESET}"

${PROMPT_COLOR_HINT}${description}${PROMPT_COLOR_RESET}

${PROMPT_COLOR_QUESTION}Would you like to document this in STRATEGIES.md?${PROMPT_COLOR_RESET}

Documenting strategies helps:
• Apply proven approaches
• Share your playbook
• Improve over time

EOF
}

# ============================================
# IDEA PROMPTS
# ============================================

# Generate prompt for capturing an idea
prompt_generate_idea() {
    local idea="$1"
    local context="${2:-}"
    
    cat << EOF
${PROMPT_COLOR_HEADER}✨ Idea Captured${PROMPT_COLOR_RESET}

You mentioned: "${PROMPT_COLOR_QUESTION}${idea}${PROMPT_COLOR_RESET}"

${PROMPT_COLOR_HINT}${context}${PROMPT_COLOR_RESET}

${PROMPT_COLOR_QUESTION}Would you like to save this to IDEAS.md?${PROMPT_COLOR_RESET}

Capturing ideas helps:
• Remember future possibilities
• Connect ideas to projects
• Track what inspires you

EOF
}

# ============================================
# MODEL PROMPTS
# ============================================

# Generate prompt for documenting a mental model
prompt_generate_model() {
    local model_name="$1"
    local usage_count="$2"
    local description="${3:-}"
    
    cat << EOF
${PROMPT_COLOR_HEADER}🧠 Mental Model${PROMPT_COLOR_RESET}

You've referenced "${PROMPT_COLOR_QUESTION}${model_name}${PROMPT_COLOR_RESET}" ${usage_count} times.

${PROMPT_COLOR_HINT}${description}${PROMPT_COLOR_RESET}

${PROMPT_COLOR_QUESTION}Would you like to add this to MODELS.md?${PROMPT_COLOR_RESET}

Documenting models helps:
• Apply frameworks consistently
• Share your thinking tools
• Suggest relevant models

EOF
}

# ============================================
# NARRATIVE PROMPTS
# ============================================

# Generate prompt for addressing a narrative
prompt_generate_narrative() {
    local narrative="$1"
    local narrative_type="$2"  # limiting, empowering, neutral
    local reframe="${3:-}"
    
    local type_label
    case "$narrative_type" in
        limiting) type_label="Limiting Narrative" ;;
        empowering) type_label="Empowering Narrative" ;;
        *) type_label="Self-Narrative" ;;
    esac
    
    cat << EOF
${PROMPT_COLOR_HEADER}📖 ${type_label}${PROMPT_COLOR_RESET}

You said: "${PROMPT_COLOR_QUESTION}${narrative}${PROMPT_COLOR_RESET}"

EOF

    if [[ "$narrative_type" == "limiting" ]] && [[ -n "$reframe" ]]; then
        cat << EOF
${PROMPT_COLOR_HINT}Consider reframing: "${reframe}"${PROMPT_COLOR_RESET}

EOF
    fi
    
    cat << EOF
${PROMPT_COLOR_QUESTION}Would you like to explore this in NARRATIVES.md?${PROMPT_COLOR_RESET}

Understanding narratives helps:
• Recognize self-limiting patterns
• Reinforce empowering stories
• Grow intentionally

EOF
}

# ============================================
# WORKING STYLE PROMPTS
# ============================================

# Generate prompt for updating working style
prompt_generate_style() {
    local preference_type="$1"
    local preference_value="$2"
    local confidence="$3"
    
    local description
    case "$preference_type" in
        format)
            description="You seem to prefer ${preference_value} responses"
            ;;
        technology)
            description="Your top technologies: ${preference_value}"
            ;;
        communication)
            description="Your communication style: ${preference_value}"
            ;;
        *)
            description="Detected preference: ${preference_value}"
            ;;
    esac
    
    cat << EOF
${PROMPT_COLOR_HEADER}⚙️ Working Style${PROMPT_COLOR_RESET}

${description}

${PROMPT_COLOR_HINT}Confidence: ${confidence} observations${PROMPT_COLOR_RESET}

${PROMPT_COLOR_QUESTION}Would you like to update your context.md?${PROMPT_COLOR_RESET}

Updating preferences helps me:
• Tailor responses to your style
• Use your preferred technologies
• Communicate more effectively

EOF
}

# ============================================
# MISSION PROMPTS
# ============================================

# Generate prompt for suggesting a mission
prompt_generate_mission() {
    local suggested_mission="$1"
    local goal_count="$2"
    local themes="$3"
    
    cat << EOF
${PROMPT_COLOR_HEADER}🌟 Mission Suggestion${PROMPT_COLOR_RESET}

Based on your ${goal_count} goals around "${themes}", I suggest:

"${PROMPT_COLOR_QUESTION}${suggested_mission}${PROMPT_COLOR_RESET}"

${PROMPT_COLOR_QUESTION}Would you like to add this to MISSION.md?${PROMPT_COLOR_RESET}

A mission statement helps:
• Guide long-term decisions
• Align projects with purpose
• Stay motivated

EOF
}

# ============================================
# UTILITY FUNCTIONS
# ============================================

# Format time in seconds to human-readable
prompt_format_time() {
    local seconds="$1"
    
    if [[ $seconds -lt 60 ]]; then
        echo "${seconds}s"
    elif [[ $seconds -lt 3600 ]]; then
        echo "$((seconds / 60))m"
    else
        local hours=$((seconds / 3600))
        local mins=$(((seconds % 3600) / 60))
        echo "${hours}h ${mins}m"
    fi
}

# Strip ANSI colors for non-terminal output
prompt_strip_colors() {
    local text="$1"
    echo "$text" | sed 's/\x1b\[[0-9;]*m//g'
}

# Format prompt for terminal width
prompt_format_for_terminal() {
    local prompt="$1"
    local width="${2:-80}"
    
    # Simple word wrap (basic implementation)
    echo "$prompt" | fold -s -w "$width"
}

# Generate accept/decline options
prompt_generate_options() {
    cat << EOF

${PROMPT_COLOR_HINT}[y] Yes, add it  [n] No, skip  [l] Later  [?] More info${PROMPT_COLOR_RESET}
EOF
}

# ============================================
# EXPORTS
# ============================================

export -f prompt_generate_project
export -f prompt_generate_goal
export -f prompt_generate_challenge
export -f prompt_generate_learning
export -f prompt_generate_belief
export -f prompt_generate_strategy
export -f prompt_generate_idea
export -f prompt_generate_model
export -f prompt_generate_narrative
export -f prompt_generate_style
export -f prompt_generate_mission
export -f prompt_format_time
export -f prompt_strip_colors
export -f prompt_format_for_terminal
export -f prompt_generate_options
