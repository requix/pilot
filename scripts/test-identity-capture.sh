#!/usr/bin/env bash
# Test identity capture system

echo "Testing PILOT Identity Capture System..."

# Test conversation capture
echo "=== Testing conversation capture ==="
echo "I'm working on the PILOT dashboard project and learned that TypeScript is better than JavaScript for type safety" | ~/.kiro/pilot/hooks/post-conversation.sh

# Test tool usage capture  
echo "=== Testing tool usage capture ==="
~/.kiro/pilot/hooks/post-tool-use.sh "execute_bash" "terraform plan" "success"

# Run identity updater
echo "=== Running identity updater ==="
~/.kiro/pilot/scripts/update-identity.sh

# Show results
echo "=== Results ==="
echo "Auto-capture log:"
cat ~/.pilot/identity/.history/auto-capture.log 2>/dev/null || echo "No captures yet"

echo -e "\nTool patterns log:"
cat ~/.pilot/identity/.history/tool-patterns.log 2>/dev/null || echo "No tool patterns yet"

echo -e "\nUpdates log:"
cat ~/.pilot/identity/.history/updates.log 2>/dev/null || echo "No updates yet"

echo -e "\nHook activity log:"
cat ~/.pilot/identity/.history/hook-activity.log 2>/dev/null || echo "No hook activity yet"
