#!/bin/bash
# Template CLI tool demonstrating pack tool integration
# Usage: template-tool.sh {action1|action2|status|help}

set -euo pipefail

TOOL_NAME="template-tool"
PACK_NAME="pilot-pack-template"
PACK_PATH="$HOME/.pilot/packs/$PACK_NAME"
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Show help
show_help() {
    cat << EOF
$(print_color "$BLUE" "Template Tool v$VERSION")

A demonstration CLI tool for PILOT pack system.

$(print_color "$GREEN" "USAGE:")
    $0 <command> [options]

$(print_color "$GREEN" "COMMANDS:")
    action1         Perform example action 1
    action2         Perform example action 2
    status          Show pack status
    help            Show this help message

$(print_color "$GREEN" "EXAMPLES:")
    $0 action1
    $0 status

$(print_color "$GREEN" "INTEGRATION:")
    This tool integrates with:
    - Kiro CLI shell tool
    - PILOT memory system
    - Pack hook system
    - Security validation

$(print_color "$GREEN" "DOCUMENTATION:")
    See ~/.pilot/packs/$PACK_NAME/README.md
EOF
}

# Action 1: Example operation
action1() {
    print_color "$BLUE" "🔧 Executing Action 1..."
    
    # Simulate work
    sleep 0.5
    
    # Create output
    cat << EOF
$(print_color "$GREEN" "✅ Action 1 completed successfully")

Results:
  - Operation: Example Action 1
  - Status: Success
  - Timestamp: $(date -Iseconds)
  - Pack: $PACK_NAME

This demonstrates:
  - CLI tool execution
  - Integration with Kiro shell tool
  - Proper output formatting
  - Error handling patterns
EOF
}

# Action 2: Another example operation
action2() {
    print_color "$BLUE" "🔧 Executing Action 2..."
    
    # Check pack context
    if [ -f "$PACK_PATH/cache/context.json" ]; then
        print_color "$GREEN" "📦 Pack context loaded"
        local session_id
        session_id=$(jq -r '.session_id' "$PACK_PATH/cache/context.json" 2>/dev/null || echo "unknown")
        echo "Session ID: $session_id"
    fi
    
    # Simulate work
    sleep 0.5
    
    cat << EOF
$(print_color "$GREEN" "✅ Action 2 completed successfully")

Results:
  - Operation: Example Action 2
  - Status: Success
  - Context: Loaded from pack cache
  - Integration: Full Kiro CLI support

Features demonstrated:
  - Context awareness
  - Cache utilization
  - Session tracking
  - Status reporting
EOF
}

# Show pack status
show_status() {
    print_color "$BLUE" "📊 Pack Status Report"
    echo ""
    
    # Pack information
    if [ -f "$PACK_PATH/pack.json" ]; then
        local pack_version
        pack_version=$(jq -r '.version' "$PACK_PATH/pack.json" 2>/dev/null || echo "unknown")
        print_color "$GREEN" "Pack: $PACK_NAME v$pack_version"
    else
        print_color "$RED" "❌ pack.json not found"
    fi
    
    # Check steering files
    if [ -d "$HOME/.kiro/steering/packs/$PACK_NAME" ]; then
        local steering_count
        steering_count=$(find "$HOME/.kiro/steering/packs/$PACK_NAME" -name "*.md" -type f | wc -l)
        print_color "$GREEN" "✅ Steering files: $steering_count"
    else
        print_color "$YELLOW" "⚠️  Steering files not found"
    fi
    
    # Check agent configuration
    if [ -f "$HOME/.kiro/settings/agents/template-agent.json" ]; then
        print_color "$GREEN" "✅ Agent configuration: installed"
    else
        print_color "$YELLOW" "⚠️  Agent configuration not found"
    fi
    
    # Check hooks
    local hook_count=0
    for hook in "$PACK_PATH/src/hooks"/*.sh; do
        if [ -x "$hook" ]; then
            ((hook_count++))
        fi
    done
    print_color "$GREEN" "✅ Executable hooks: $hook_count"
    
    # Check context
    if [ -f "$PACK_PATH/cache/context.json" ]; then
        local health_status
        health_status=$(jq -r '.health_status // "unknown"' "$PACK_PATH/cache/context.json" 2>/dev/null)
        if [ "$health_status" = "healthy" ]; then
            print_color "$GREEN" "✅ Health status: $health_status"
        else
            print_color "$YELLOW" "⚠️  Health status: $health_status"
        fi
    else
        print_color "$YELLOW" "⚠️  Context not initialized"
    fi
    
    echo ""
    print_color "$BLUE" "Integration Status:"
    echo "  - Kiro CLI: ✅ Compatible"
    echo "  - PILOT: ✅ Compatible"
    echo "  - Hook System: ✅ Active"
    echo "  - Memory System: ✅ Integrated"
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    
    case "$command" in
        action1)
            action1
            ;;
        action2)
            action2
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_color "$RED" "❌ Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
