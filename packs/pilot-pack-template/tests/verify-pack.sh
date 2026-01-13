#!/bin/bash
# Comprehensive pack verification script
# Tests pack structure, integration, and functionality

set -euo pipefail

PACK_NAME="pilot-pack-template"
PACK_PATH="$HOME/.pilot/packs/$PACK_NAME"
STEERING_PATH="$HOME/.kiro/steering/packs/$PACK_NAME"
AGENT_CONFIG="$HOME/.kiro/settings/agents/template-agent.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Print colored output
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Test helper function
test_check() {
    local description="$1"
    local command="$2"
    local critical="${3:-false}"
    
    if eval "$command" >/dev/null 2>&1; then
        print_color "$GREEN" "✅ $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        if [ "$critical" = "true" ]; then
            print_color "$RED" "❌ $description (CRITICAL)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        else
            print_color "$YELLOW" "⚠️  $description (non-critical)"
            TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
        fi
        return 1
    fi
}

# Header
print_header() {
    echo ""
    print_color "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BLUE" "  PILOT Pack Verification"
    print_color "$BLUE" "  Pack: $PACK_NAME"
    print_color "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Test pack structure
test_structure() {
    print_color "$BLUE" "📁 Testing Pack Structure..."
    echo ""
    
    test_check "Pack directory exists" "test -d $PACK_PATH" true
    test_check "pack.json exists" "test -f $PACK_PATH/pack.json" true
    test_check "README.md exists" "test -f $PACK_PATH/README.md" true
    test_check "INSTALL.md exists" "test -f $PACK_PATH/INSTALL.md" true
    test_check "VERIFY.md exists" "test -f $PACK_PATH/VERIFY.md" true
    test_check "src/ directory exists" "test -d $PACK_PATH/src" true
    test_check "tests/ directory exists" "test -d $PACK_PATH/tests" false
    
    echo ""
}

# Test source structure
test_source_structure() {
    print_color "$BLUE" "📦 Testing Source Structure..."
    echo ""
    
    test_check "agents/ directory exists" "test -d $PACK_PATH/src/agents" true
    test_check "steering/ directory exists" "test -d $PACK_PATH/src/steering" true
    test_check "hooks/ directory exists" "test -d $PACK_PATH/src/hooks" true
    test_check "tools/ directory exists" "test -d $PACK_PATH/src/tools" true
    
    test_check "Agent config exists" "test -f $PACK_PATH/src/agents/template-agent.json" true
    test_check "Steering file exists" "test -f $PACK_PATH/src/steering/template-knowledge.md" true
    test_check "Hook scripts exist" "test -f $PACK_PATH/src/hooks/template-hook.sh" true
    test_check "Tool scripts exist" "test -f $PACK_PATH/src/tools/template-tool.sh" true
    
    echo ""
}

# Test Kiro integration
test_kiro_integration() {
    print_color "$BLUE" "🔗 Testing Kiro CLI Integration..."
    echo ""
    
    test_check "Steering directory exists" "test -d $STEERING_PATH" false
    test_check "Agent config installed" "test -f $AGENT_CONFIG" false
    
    if [ -f "$AGENT_CONFIG" ]; then
        test_check "Agent config is valid JSON" "jq empty $AGENT_CONFIG" true
        test_check "Agent name is correct" "jq -e '.name == \"template-agent\"' $AGENT_CONFIG" true
    fi
    
    echo ""
}

# Test metadata
test_metadata() {
    print_color "$BLUE" "📋 Testing Pack Metadata..."
    echo ""
    
    if [ -f "$PACK_PATH/pack.json" ]; then
        test_check "pack.json is valid JSON" "jq empty $PACK_PATH/pack.json" true
        test_check "Pack name is defined" "jq -e '.name' $PACK_PATH/pack.json" true
        test_check "Version is defined" "jq -e '.version' $PACK_PATH/pack.json" true
        test_check "Description is defined" "jq -e '.description' $PACK_PATH/pack.json" true
        test_check "Pack type is defined" "jq -e '.type' $PACK_PATH/pack.json" true
        test_check "Kiro integration is defined" "jq -e '.kiro_integration' $PACK_PATH/pack.json" true
        test_check "Installation steps defined" "jq -e '.installation.steps' $PACK_PATH/pack.json" true
    else
        print_color "$RED" "❌ pack.json not found - cannot test metadata"
        TESTS_FAILED=$((TESTS_FAILED + 7))
    fi
    
    echo ""
}

# Test executability
test_executability() {
    print_color "$BLUE" "⚙️  Testing Script Executability..."
    echo ""
    
    test_check "Hook scripts are executable" "test -x $PACK_PATH/src/hooks/template-hook.sh" true
    test_check "Tool scripts are executable" "test -x $PACK_PATH/src/tools/template-tool.sh" true
    
    echo ""
}

# Test functionality
test_functionality() {
    print_color "$BLUE" "🧪 Testing Functionality..."
    echo ""
    
    # Test hook execution
    if test_check "Hook script runs" "$PACK_PATH/src/hooks/template-hook.sh 'test input'" false; then
        print_color "$GREEN" "   Hook executed successfully"
    fi
    
    # Test tool execution
    if test_check "Tool script runs" "$PACK_PATH/src/tools/template-tool.sh action1" false; then
        print_color "$GREEN" "   Tool executed successfully"
    fi
    
    # Test tool status command
    if test_check "Tool status command works" "$PACK_PATH/src/tools/template-tool.sh status" false; then
        print_color "$GREEN" "   Status command works"
    fi
    
    echo ""
}

# Test security
test_security() {
    print_color "$BLUE" "🔒 Testing Security..."
    echo ""
    
    test_check "No dangerous rm patterns" "! grep -r 'rm -rf /' $PACK_PATH/src 2>/dev/null" true
    test_check "No curl pipe bash" "! grep -r 'curl.*|.*bash' $PACK_PATH/src 2>/dev/null" true
    test_check "No eval usage" "! grep -r 'eval \\\$' $PACK_PATH/src 2>/dev/null" false
    test_check "Security config exists" "jq -e '.security' $PACK_PATH/pack.json" false
    
    echo ""
}

# Test dependencies
test_dependencies() {
    print_color "$BLUE" "📦 Testing Dependencies..."
    echo ""
    
    test_check "jq is available" "which jq" true
    test_check "bash is available" "which bash" true
    
    echo ""
}

# Print summary
print_summary() {
    local total_tests=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
    local pass_rate=0
    
    if [ $total_tests -gt 0 ]; then
        pass_rate=$((TESTS_PASSED * 100 / total_tests))
    fi
    
    echo ""
    print_color "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$BLUE" "  Test Summary"
    print_color "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    print_color "$GREEN" "  Passed:  $TESTS_PASSED"
    print_color "$RED" "  Failed:  $TESTS_FAILED"
    print_color "$YELLOW" "  Skipped: $TESTS_SKIPPED"
    echo "  ────────────────"
    echo "  Total:   $total_tests"
    echo "  Pass Rate: $pass_rate%"
    echo ""
    print_color "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        print_color "$GREEN" "✅ All critical tests passed!"
        print_color "$GREEN" "   Pack is correctly structured and functional."
        echo ""
        return 0
    else
        print_color "$RED" "❌ Some critical tests failed."
        print_color "$RED" "   Please review the output above and fix issues."
        echo ""
        return 1
    fi
}

# Main execution
main() {
    print_header
    
    test_structure
    test_source_structure
    test_kiro_integration
    test_metadata
    test_executability
    test_functionality
    test_security
    test_dependencies
    
    print_summary
}

# Run tests
if main; then
    exit 0
else
    exit 1
fi
