#!/usr/bin/env bash
# install-dashboard-integration.sh - Deploy dashboard integration to PILOT

PILOT_HOME="$HOME/.kiro/pilot"
SRC_DIR="/Users/vol/Projects/pilot/src/packs/pilot-core"

echo "🔧 Installing PILOT dashboard integration..."

# Copy dashboard emission library
echo "   📦 Installing dashboard emission library..."
cp "$SRC_DIR/system/lib/dashboard-emit.sh" "$PILOT_HOME/lib/" 2>/dev/null || {
    echo "   ❌ Failed to copy dashboard-emit.sh"
    exit 1
}

# Copy updated hooks
echo "   🔗 Installing updated hooks..."
for hook in agent-spawn.sh user-prompt-submit.sh post-tool-use.sh stop.sh; do
    if cp "$SRC_DIR/system/hooks/$hook" "$HOME/.kiro/hooks/pilot/" 2>/dev/null; then
        chmod +x "$HOME/.kiro/hooks/pilot/$hook"
        echo "   ✓ Updated $hook"
    else
        echo "   ❌ Failed to update $hook"
    fi
done

# Ensure dashboard directories exist
mkdir -p "$PILOT_HOME/dashboard/sessions" 2>/dev/null || true

echo "✅ Dashboard integration installed successfully!"
echo ""
echo "Next steps:"
echo "1. Restart your PILOT session to activate integration"
echo "2. Dashboard will now show real-time phase updates"
echo "3. Learning captures will appear in dashboard events"
