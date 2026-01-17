#!/usr/bin/env bash
# test-emit.sh - Test dashboard state emission
# Run this while dashboard is running to see updates

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../bin/pilot-emit" 2>/dev/null || {
    # Inline the emit functions if source fails
    DASHBOARD_DIR="$HOME/.kiro/pilot/dashboard"
    SESSIONS_DIR="$DASHBOARD_DIR/sessions"
    EVENTS_FILE="$DASHBOARD_DIR/events.jsonl"
    mkdir -p "$SESSIONS_DIR"
}

export PILOT_SESSION="test-session-$$"

echo "🧪 Testing dashboard emission..."
echo "   Session: $PILOT_SESSION"
echo ""

# Test phase emissions
for phase in OBSERVE THINK PLAN BUILD EXECUTE VERIFY LEARN; do
    echo "   Emitting phase: $phase"
    "$SCRIPT_DIR/../bin/pilot-emit" phase "$phase"
    sleep 1
done

# Test learning emission
echo ""
echo "   Emitting learning..."
"$SCRIPT_DIR/../bin/pilot-emit" learning "Test learning from emission script"

# Test identity emission
echo ""
echo "   Emitting identity access..."
for comp in MISSION GOALS PROJECTS; do
    "$SCRIPT_DIR/../bin/pilot-emit" identity "$comp"
    sleep 1
done

echo ""
echo "✅ Test complete. Check dashboard for updates."
echo ""
echo "State files:"
ls -la "$HOME/.kiro/pilot/dashboard/sessions/" 2>/dev/null || echo "   (no sessions yet)"
echo ""
echo "Recent events:"
tail -5 "$HOME/.kiro/pilot/dashboard/events.jsonl" 2>/dev/null || echo "   (no events yet)"
