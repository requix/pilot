#!/usr/bin/env bash
# verify-hooks.sh - Verify PILOT hooks are capturing data correctly
# Part of PILOT

PILOT_HOME="${HOME}/.kiro/pilot"
HOT_MEMORY="${PILOT_HOME}/memory/hot"

echo "=== PILOT Hook Verification ==="
echo ""

# Check tool-usage.jsonl for non-unknown tools
echo "Tool names captured:"
if [ -f "$HOT_MEMORY/tool-usage.jsonl" ]; then
    total=$(wc -l < "$HOT_MEMORY/tool-usage.jsonl" | tr -d ' ')
    unknown=$(grep -c '"tool":"unknown"' "$HOT_MEMORY/tool-usage.jsonl" 2>/dev/null || echo 0)
    known=$((total - unknown))
    echo "  ✓ $known/$total entries have tool names ($unknown unknown)"
else
    echo "  - No tool usage data yet"
fi

# Check session IDs
echo ""
echo "Session IDs captured:"
if [ -f "$HOT_MEMORY/tool-usage.jsonl" ]; then
    unknown_sessions=$(grep -c '"session_id":"unknown"' "$HOT_MEMORY/tool-usage.jsonl" 2>/dev/null || echo 0)
    known_sessions=$((total - unknown_sessions))
    echo "  ✓ $known_sessions/$total entries have session IDs ($unknown_sessions unknown)"
else
    echo "  - No data yet"
fi

# Check current session ID
echo ""
echo "Current session ID:"
if [ -f "$PILOT_HOME/.cache/current-session-id" ]; then
    sid=$(cat "$PILOT_HOME/.cache/current-session-id")
    echo "  ✓ $sid"
else
    echo "  - Not set (run agent-spawn first)"
fi

# Check algorithm phases
echo ""
echo "Algorithm phases tracked:"
if [ -f "$HOT_MEMORY/algorithm-phases.jsonl" ]; then
    phases=$(wc -l < "$HOT_MEMORY/algorithm-phases.jsonl" | tr -d ' ')
    echo "  ✓ $phases phase entries"
else
    echo "  - No phase data yet"
fi

# Check jq availability
echo ""
echo "JSON parser:"
if command -v jq >/dev/null 2>&1; then
    echo "  ✓ jq available ($(jq --version))"
else
    echo "  ⚠ jq not installed - hooks will generate session IDs"
fi

echo ""
echo "=== Verification Complete ==="
