# PILOT Dashboard - Complete Data Flow Investigation

**Date**: January 19, 2026
**Investigation**: Deep dive into kiro CLI → PILOT → Dashboard data flow

## Executive Summary

✅ **System is Working Correctly** - Data flows from kiro CLI hooks through PILOT libraries to the dashboard.

⚠️ **Issues Found**:
1. Phase highlighting persists indefinitely (FIXED: Added 30-second timeout)
2. Learning titles show generic "Learning captured" (ROOT CAUSE: Hook implementation)
3. No active sessions visible (EXPECTED: Sessions clean up on exit)

## Complete Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        KIRO CLI SYSTEM                           │
│                                                                  │
│  Claude Code Session Hooks:                                     │
│    ├─ agent-spawn.sh        (session start)                    │
│    ├─ user-prompt-submit.sh (phase detection)                  │
│    ├─ post-tool-use.sh      (tool tracking)                    │
│    └─ stop.sh               (learning capture + cleanup)       │
└──────────────────────┬──────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────────┐
│                    PILOT EMISSION LIBRARIES                      │
│                                                                  │
│  Location: src/packs/pilot-core/system/lib/                     │
│                                                                  │
│  dashboard-emitter.sh (primary):                                │
│    ├─ dashboard_emit_phase(PHASE, TITLE?)                      │
│    ├─ dashboard_emit_learning(TITLE, CATEGORY?, TAGS?)         │
│    ├─ dashboard_emit_identity(COMPONENT)                       │
│    └─ dashboard_cleanup()                                       │
│                                                                  │
│  dashboard-emit.sh (fallback):                                  │
│    ├─ emit_phase(PHASE)                                        │
│    ├─ emit_learning(TITLE)                                     │
│    └─ emit_identity(COMPONENT)                                 │
└──────────────────────┬──────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────────┐
│                     FILE SYSTEM STORAGE                          │
│                                                                  │
│  ~/.kiro/pilot/dashboard/                                       │
│    ├─ sessions/                                                 │
│    │   └─ pilot-{timestamp}-{pid}.json  (active sessions)      │
│    │      {                                                     │
│    │        "id": "pilot-1234567890-1234",                     │
│    │        "phase": "EXECUTE",                                │
│    │        "updated": 1234567890,                             │
│    │        "startTime": 1234567890,                           │
│    │        "commandCount": 5,                                 │
│    │        "workingDirectory": "/path/to/project"             │
│    │      }                                                     │
│    │                                                            │
│    └─ events.jsonl  (append-only event log)                    │
│        {"type":"phase","sessionId":"...","phase":"EXECUTE"...} │
│        {"type":"learning","sessionId":"...","title":"..."...}  │
│        {"type":"identity","sessionId":"...","component":"...}  │
└──────────────────────┬──────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────────┐
│                   DASHBOARD CONSUMPTION                          │
│                                                                  │
│  Location: src/dashboard-ink/src/state.ts                       │
│                                                                  │
│  StateManager (polls every 500ms):                              │
│    ├─ pollSessions()                                           │
│    │   └─ Reads all *.json files in sessions/                  │
│    ├─ pollEvents()                                             │
│    │   └─ Incrementally reads new lines from events.jsonl      │
│    └─ notify()                                                  │
│        └─ Triggers React re-render                             │
│                                                                  │
│  Location: src/dashboard-ink/src/App.tsx                        │
│                                                                  │
│  React Dashboard:                                               │
│    ├─ Active Sessions (from state.sessions)                    │
│    ├─ Algorithm Phases (from active sessions)                  │
│    ├─ Identity System (from state.identityAccess)              │
│    └─ Recent Learnings (from state.recentLearnings)            │
└─────────────────────────────────────────────────────────────────┘
```

## Detailed Component Analysis

### 1. Event Emission Hooks

#### **agent-spawn.sh** - Session Initialization
```bash
# Triggered when: New Claude Code session starts
# Location: src/packs/pilot-core/system/hooks/agent-spawn.sh

dashboard_emit_phase "OBSERVE"  # Initial phase

# Also creates:
# - ~/.kiro/pilot/metrics/session-{ID}.json
# - ~/.kiro/pilot/.cache/current-session-id
```

**Impact**: Every new session starts with OBSERVE phase highlighted.

#### **user-prompt-submit.sh** - Phase Detection
```bash
# Triggered when: User submits a prompt
# Location: src/packs/pilot-core/system/hooks/user-prompt-submit.sh

# Phase detection logic:
if [[ "$prompt" =~ (explain|understand|analyze|review|investigate) ]]; then
    PHASE="OBSERVE"
elif [[ "$prompt" =~ (think|consider|evaluate|approach) ]]; then
    PHASE="THINK"
elif [[ "$prompt" =~ (plan|design|architect|outline|strategy) ]]; then
    PHASE="PLAN"
elif [[ "$prompt" =~ (build|create|implement|write|add) ]]; then
    PHASE="EXECUTE"
elif [[ "$prompt" =~ (test|verify|check|validate|ensure) ]]; then
    PHASE="VERIFY"
elif [[ "$prompt" =~ (learn|capture|document|reflect) ]]; then
    PHASE="LEARN"
fi

dashboard_emit_phase "$PHASE"
```

**Impact**: Phase highlighting changes based on detected keywords in user prompts.

**Issue**: Once set, phase stays highlighted until:
1. Another phase is detected, OR
2. Session ends and file is removed

**Fix Applied**: Added 30-second timeout - phases auto-dim if session not updated recently.

#### **stop.sh** - Session Cleanup & Learning Capture
```bash
# Triggered when: Session ends (Ctrl+C, quit, error)
# Location: src/packs/pilot-core/system/hooks/stop.sh

# Learning detection (looks for 2+ indicators):
indicators=(
    "fixed" "solved" "resolved" "debugged" "corrected"
    "discovered" "found" "identified" "realized" "learned"
    "improved" "optimized" "enhanced" "refactored" "cleaned"
)

if [[ $indicator_count -ge 2 ]]; then
    dashboard_emit_learning "Learning captured"  # ⚠️ GENERIC TITLE
    emit_phase "LEARN"
fi

# Cleanup:
dashboard_cleanup  # Removes session file
```

**Issue Found**: `dashboard_emit_learning "Learning captured"` uses a hardcoded generic title!

**Root Cause**: The hook doesn't extract actual learning content, just detects that learning occurred.

**Recommendation**: Modify stop.sh to extract first sentence or key phrase from the learning content.

### 2. Session Lifecycle

```
Session Start (agent-spawn.sh):
    └─> Creates: ~/.kiro/pilot/dashboard/sessions/pilot-{timestamp}-{pid}.json
    └─> Emits: dashboard_emit_phase("OBSERVE")

Phase Transitions (user-prompt-submit.sh):
    └─> Updates: Session file with new phase
    └─> Emits: dashboard_emit_phase($DETECTED_PHASE)
    └─> Increments: commandCount in session file

Session End (stop.sh):
    └─> Emits: dashboard_emit_learning() if indicators found
    └─> Emits: emit_phase("LEARN")
    └─> Removes: Session file via dashboard_cleanup()
```

**Why No Active Sessions**:
- Sessions are removed when they end
- Dashboard only shows sessions with existing files
- This is **correct behavior** - ended sessions should not appear as "active"

### 3. Dashboard State Management

#### Polling Mechanism (state.ts)
```typescript
private async pollSessions() {
  const files = await readdir(SESSIONS_DIR)
  for (const file of files.filter(f => f.endsWith(".json"))) {
    const path = join(SESSIONS_DIR, file)
    const stats = await stat(path).catch(() => null)
    if (!stats) continue

    // Only remove sessions stale BEFORE dashboard started
    const staleThreshold = this.dashboardStartTime - 600000 // 10 min before start
    if (lastModified < staleThreshold) {
      // Move to history and remove file
    }

    // Check if file was modified since last poll
    if (mtime > lastMtime) {
      await this.loadSession(path)  // Re-read and update state
    }
  }
}
```

**Stale Session Handling**: Sessions older than 10 minutes before dashboard start are automatically cleaned up.

**Phase Highlighting Issue**: Before my fix, phases would stay highlighted as long as session file existed, even if not actively being updated.

**Fix**: Added time-based check in App.tsx:
```typescript
const PHASE_TIMEOUT = 30 // seconds
const isRecent = (now - session.updated) < PHASE_TIMEOUT
if (session.phase && session.phase !== "IDLE" && isRecent) {
  activePhases.add(session.phase)
}
```

Now phases auto-dim after 30 seconds of inactivity.

### 4. Learning Capture Flow

```
User Action (e.g., fixing bug, adding feature)
    ↓
Session ends (stop.sh triggered)
    ↓
Content analysis (scans for indicator keywords)
    ↓
If 2+ indicators found:
    ├─> dashboard_emit_learning("Learning captured")  # ⚠️ Generic
    └─> Creates: ~/.pilot/learnings/{timestamp}_learning.md
    ↓
Dashboard polls events.jsonl
    ↓
Displays: "✓ [general] Learning captured 5m ago"
```

**Issue**: Title is always "Learning captured" instead of actual content.

**Solution Options**:

1. **Option A - Fix in Hook** (Recommended):
   ```bash
   # In stop.sh, extract actual content:
   learning_title=$(grep -m 1 "^# " "$learning_file" | sed 's/^# //')
   if [[ -z "$learning_title" ]]; then
       learning_title=$(head -n 1 "$learning_file" | cut -c1-100)
   fi
   dashboard_emit_learning "$learning_title"
   ```

2. **Option B - Fix in Dashboard**:
   - Fallback: If title is "Learning captured", extract from learning file
   - Look in ~/.pilot/learnings/ for matching timestamp
   - Use first line or heading as title

3. **Option C - User Explicit Capture**:
   - Add manual capture command
   - Users describe learning when saving
   - Higher quality but requires user action

### 5. Identity System Tracking

```
Hook emits:
    dashboard_emit_identity("GOALS")  # When GOALS.md is accessed/updated

Dashboard tracks:
    state.identityAccess = {
      MISSION: 5,    // Accessed 5 times
      GOALS: 12,     // Accessed 12 times
      PROJECTS: 3    // Accessed 3 times
    }

Visualization:
    Active (accessed at least once): Highlighted
    Inactive (never accessed): Dim
```

**Current Issue**: Hook emission of identity events is sparse or not implemented.

**Finding**: Need to verify if identity-writer.sh or related hooks actually call `dashboard_emit_identity()`.

## Session ID Resolution

Multiple fallback mechanisms ensure session tracking:

```
Priority Order:
1. $PILOT_SESSION         (explicitly set)
2. $PILOT_SESSION_ID      (from agent-spawn)
3. $KIRO_SESSION_ID       (from kiro infrastructure)
4. ~/.kiro/pilot/.cache/current-session-id  (cached)
5. Generated: pilot-$(date +%s)-$$  (timestamp-pid)
```

This ensures every emission has a valid session ID even if environment variables aren't set.

## Files Involved

### Emission Layer
- `src/packs/pilot-core/system/lib/dashboard-emitter.sh` - Main emission library
- `src/packs/pilot-core/system/lib/dashboard-emit.sh` - Fallback library
- `src/dashboard-ink/bin/pilot-emit` - CLI tool (legacy reference)
- `src/dashboard-ink/bin/pilot-stream` - Bun/TypeScript implementation (legacy reference)

### Hook Layer
- `src/packs/pilot-core/system/hooks/agent-spawn.sh` - Session start
- `src/packs/pilot-core/system/hooks/user-prompt-submit.sh` - Phase detection
- `src/packs/pilot-core/system/hooks/post-tool-use.sh` - Tool tracking
- `src/packs/pilot-core/system/hooks/stop.sh` - Cleanup & learning

### Dashboard Layer
- `src/dashboard-ink/src/state.ts` - State management & polling
- `src/dashboard-ink/src/App.tsx` - React UI components
- `src/dashboard-ink/src/types.ts` - Type definitions

## Issues & Solutions

### ✅ Issue 1: Phase Highlighting Persists Too Long
**Problem**: Phases stay highlighted indefinitely once activated.
**Root Cause**: No timeout check - highlights based solely on session.phase existence.
**Solution**: Added 30-second inactivity timeout in App.tsx.
**Status**: FIXED

### ⚠️ Issue 2: Learning Titles Show "Learning captured"
**Problem**: All learnings display generic "Learning captured" instead of actual content.
**Root Cause**: stop.sh hook uses hardcoded string instead of extracting title.
**Solution**: Modify stop.sh to extract title from learning file or response text.
**Status**: REQUIRES HOOK UPDATE

### ✅ Issue 3: No Active Sessions Visible
**Problem**: Dashboard shows "No active sessions" most of the time.
**Root Cause**: Sessions are removed when they end (by design).
**Solution**: None needed - this is correct behavior. Consider adding "Recent Sessions" history.
**Status**: WORKING AS DESIGNED

### ⚠️ Issue 4: Identity System Not Showing Activity
**Problem**: Identity components rarely show as "active".
**Root Cause**: Hooks may not be emitting identity access events consistently.
**Solution**: Verify and enhance identity-writer.sh to emit events when files are read/written.
**Status**: NEEDS INVESTIGATION

## Recommendations

### Immediate (High Priority)
1. **Fix Learning Titles** - Update stop.sh to extract actual learning content
2. **Verify Identity Emission** - Ensure identity-writer.sh calls dashboard_emit_identity()
3. **Test Phase Timeout** - Validate 30-second timeout works correctly in practice

### Short Term (Next Sprint)
1. **Add Recent Sessions History** - Show last 5-10 sessions with completion status
2. **Enhanced Learning Capture** - Allow manual learning capture with custom titles
3. **Session Metrics** - Display prompts, tokens, success rate from metrics files

### Medium Term (Future Enhancement)
1. **Real-time Streaming** - Replace 500ms polling with Unix socket streaming (<10ms)
2. **Interactive Mode** - Click sessions to expand details
3. **Identity Growth Visualization** - Show file size, line count, last modified per component

## Testing Commands

### Manual Event Emission
```bash
# Source the emitter library
source ~/.kiro/pilot/lib/dashboard-emitter.sh

# Set session ID
export PILOT_SESSION="test-$(date +%s)"

# Emit phase changes
dashboard_emit_phase OBSERVE "Analyzing the problem"
sleep 2
dashboard_emit_phase EXECUTE "Implementing solution"
sleep 2
dashboard_emit_phase LEARN "Capturing insights"

# Emit learning
dashboard_emit_learning "Discovered caching pattern improves performance" performance optimization

# Emit identity access
dashboard_emit_identity GOALS
dashboard_emit_identity MISSION

# Cleanup (removes session file)
dashboard_cleanup
```

### Verify Data
```bash
# Check session files
ls -la ~/.kiro/pilot/dashboard/sessions/

# View recent events
tail -20 ~/.kiro/pilot/dashboard/events.jsonl

# Count events by type
grep -c '"type":"phase"' ~/.kiro/pilot/dashboard/events.jsonl
grep -c '"type":"learning"' ~/.kiro/pilot/dashboard/events.jsonl
grep -c '"type":"identity"' ~/.kiro/pilot/dashboard/events.jsonl
```

## Conclusion

The dashboard data flow is **well-architected and functioning correctly**. The issues identified are primarily in the hooks layer (generic learning titles) and presentation layer (phase timeout), not in the core architecture.

**Key Insights**:
1. ✅ Event emission system is robust with multiple fallback mechanisms
2. ✅ File-based storage is reliable and simple
3. ✅ Polling approach works well for current scale
4. ⚠️ Hooks need enhancement to emit more descriptive data
5. ✅ Dashboard consumption is efficient and correct

**Priority Fixes Applied**:
- [x] Phase highlighting timeout (30 seconds)
- [x] Phase box text overflow fixed (shortened labels)
- [x] Identity System redesign with file stats
- [x] Session Metrics integration (prompts, tools, success rate, cost)
- [x] Global Statistics (prompts/24h, estimated cost, success rate)
- [ ] Learning title extraction (requires hook modification)
- [ ] Identity emission verification (requires investigation)
