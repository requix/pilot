# PILOT Dashboard - Observed Issues Report

**Date**: January 19, 2026
**Observer**: Kai (AI Assistant)
**Session**: Monitoring PILOT dashboard during active pilot sessions

---

## Summary Statistics

- **Total Phase Events**: 404
- **Total Learning Events**: 34
- **UNKNOWN Phase Events**: 72 (17.8% of all phase events)
- **Duplicate Events at Same Timestamp**: 50+ instances
- **Stale Session Files**: 6 (not cleaned up)

---

## Issue #1: Duplicate Event Emission

### Severity: HIGH
### Impact: Events appear twice in events.jsonl, causing incorrect counts

### Evidence
```
{"type":"phase","sessionId":"pilot-1768835254-909","phase":"EXECUTE","timestamp":1768835305}
{"type":"phase","sessionId":"pilot-1768835254-909","phase":"EXECUTE","timestamp":1768835306}
{"type":"phase","sessionId":"pilot-1768835254-909","phase":"UNKNOWN","timestamp":1768835468}
{"type":"phase","sessionId":"pilot-1768835254-909","phase":"UNKNOWN","timestamp":1768835468}
```

### Root Cause
Both `dashboard-emit.sh` AND `dashboard-emitter.sh` are sourced in hooks:
```bash
# user-prompt-submit.sh lines 23-24
[[ -f "${PILOT_HOME}/lib/dashboard-emit.sh" ]] && source "${PILOT_HOME}/lib/dashboard-emit.sh"
[[ -f "${PILOT_HOME}/lib/dashboard-emitter.sh" ]] && source "${PILOT_HOME}/lib/dashboard-emitter.sh"
```

Both libraries define `emit_phase()` function. When one is called, the other's definition may also execute or the hook calls both:
```bash
# agent-spawn.sh lines 90 and 183-184
type dashboard_emit_phase &>/dev/null && dashboard_emit_phase "OBSERVE"
...
if command -v emit_phase >/dev/null 2>&1; then
    emit_phase "OBSERVE" 2>/dev/null || true
```

### Recommendation
1. Consolidate into single emission library
2. Remove duplicate emit calls from hooks
3. Use only `dashboard_emit_*` functions consistently

---

## Issue #2: UNKNOWN Phase Emission

### Severity: MEDIUM
### Impact: 72 UNKNOWN phase events (17.8% of all phases)

### Evidence
```
{"type":"phase","sessionId":"pilot-1768835254-909","phase":"UNKNOWN","timestamp":1768835270}
{"type":"phase","sessionId":"pilot-1768835254-909","phase":"UNKNOWN","timestamp":1768835468}
{"type":"phase","sessionId":"pilot-1768835254-909","phase":"UNKNOWN","timestamp":1768835529}
```

### Root Cause
In `user-prompt-submit.sh`, the `detect_phase()` function returns "UNKNOWN" when no pattern matches:
```bash
# user-prompt-submit.sh detect_phase() function
case "$lower" in
    *"what is"*|... ) echo "OBSERVE" ;;
    ...
    *)
        echo "UNKNOWN" ;;  # <-- Default case
esac
```

However, `dashboard-emit.sh` has a different `detect_phase()` that defaults to "EXECUTE":
```bash
# dashboard-emit.sh detect_phase() function
else
    echo "EXECUTE"  # Default phase
fi
```

### Recommendation
1. Change default to "EXECUTE" (most common phase) instead of "UNKNOWN"
2. Or filter out "UNKNOWN" before emitting
3. Consolidate detect_phase logic into single location

---

## Issue #3: Generic Learning Titles

### Severity: MEDIUM
### Impact: All 34 learnings show "Learning captured" instead of actual content

### Evidence
```
{"type":"learning","sessionId":"pilot-1768814766-77425","title":"Learning captured","timestamp":1768815086}
{"type":"learning","sessionId":"pilot-1768814766-77425","title":"Learning captured","timestamp":1768815118}
{"type":"learning","sessionId":"pilot-1768835254-909","title":"Learning captured","timestamp":1768835480}
{"type":"learning","sessionId":"pilot-1768835254-909","title":"Learning captured","timestamp":1768835539}
```

### Root Cause
In `stop.sh`, learning is emitted with a variable that appears to be generic:
```bash
type dashboard_emit_learning &>/dev/null && dashboard_emit_learning "$LEARNING_SUMMARY"
```

The `$LEARNING_SUMMARY` variable is either:
- Not set to actual content
- Set to a hardcoded "Learning captured" string

### Recommendation
1. Extract title from learning content (first heading or summary)
2. Parse actual learning file for meaningful title
3. If no title available, use session context (project name, task type)

---

## Issue #4: Session Files Not Cleaned Up

### Severity: MEDIUM
### Impact: 6 stale session files remain, causing "active sessions" to show incorrectly

### Evidence
```
$ ls ~/.kiro/pilot/dashboard/sessions/
pilot-1768814766-77425.json  # Last updated: Jan 19 10:56
pilot-1768816644-84840.json  # Last updated: Jan 19 11:19
pilot-1768818031-89310.json  # Last updated: Jan 19 12:05
pilot-1768820861-97547.json  # Last updated: Jan 19 12:08
pilot-1768835254-909.json    # Last updated: Jan 19 16:13 (current)
pilot-1768835255-909.json    # Last updated: Jan 19 16:07 (ghost - never updated)
```

### Root Cause
1. `dashboard_cleanup()` only runs on clean exit via `stop.sh`
2. Crashed or killed sessions leave orphan files
3. Dashboard doesn't aggressively clean stale files during startup

### Recommendation
1. Add startup cleanup for files older than 1 hour
2. Add periodic cleanup check (every 5 minutes)
3. Track session heartbeat and clean files without recent heartbeat

---

## Issue #5: Ghost Session Files (Same PID, Different Timestamps)

### Severity: LOW
### Impact: Duplicate sessions appear for same process

### Evidence
```
pilot-1768835254-909.json  - Active, updating
pilot-1768835255-909.json  - Ghost, never updated after creation
```

Both have PID `909` but timestamps 1 second apart.

### Root Cause
1. `dashboard-emit.sh` uses: `pilot-$(date +%s)-$$` for session ID
2. `dashboard-emitter.sh` uses cached file: `current-session-id`
3. If timestamp changes between calls, different session IDs are generated

### Recommendation
1. Use consistent session ID source
2. Prefer cached session ID over generated
3. Generate session ID once at session start and reuse

---

## Issue #6: Session Files Missing Data

### Severity: LOW
### Impact: Dashboard shows minimal session info

### Evidence
Current session file format:
```json
{"id":"pilot-1768835254-909","phase":"LEARN","updated":1768835607}
```

Expected format (from `dashboard-emitter.sh`):
```json
{
  "id":"pilot-1768835254-909",
  "phase":"LEARN",
  "updated":1768835607,
  "startTime":1768835254,
  "commandCount":1,
  "workingDirectory":"/path/to/project"
}
```

### Root Cause
The simpler `emit_phase()` from `dashboard-emit.sh` overwrites the enhanced data:
```bash
# dashboard-emit.sh emit_phase() - minimal format
cat > "$SESSIONS_DIR/${session_id}.json" << EOF
{"id":"$session_id","phase":"$phase","updated":$timestamp}
EOF
```

vs

```bash
# dashboard-emitter.sh dashboard_emit_phase() - enhanced format
cat > "${SESSIONS_DIR}/${session_id}.json" << EOF
{"id":"${session_id}","phase":"${phase}","updated":${timestamp},"startTime":${start_time},"commandCount":1,"workingDirectory":"${cwd}"}
EOF
```

### Recommendation
1. Use only `dashboard-emitter.sh` (enhanced format)
2. Remove `dashboard-emit.sh` or deprecate it
3. Add increment logic for commandCount

---

## Issue #7: No Session History After Cleanup

### Severity: LOW
### Impact: User cannot see past sessions, only active ones

### Current Behavior
- Sessions are deleted when they end
- No archive/history maintained
- Dashboard only shows active sessions

### Evidence
Metrics files exist but are separate from dashboard:
```
~/.kiro/pilot/metrics/session-pilot-1768835254-909.json
```

Session summaries archived to:
```
~/.kiro/pilot/memory/cold/sessions/2026-01-19/summary-16-13-26.md
```

### Recommendation
1. Move ended sessions to `history/` instead of deleting
2. Show "Recent Sessions" section on dashboard
3. Link to metrics and summary files

---

## Issue #8: Identity Events Not Being Emitted

### Severity: LOW
### Impact: Identity System panel shows no activity

### Evidence
```bash
$ grep '"type":"identity"' ~/.kiro/pilot/dashboard/events.jsonl | wc -l
0
```

Zero identity events in the entire events log.

### Root Cause
No hooks currently call `dashboard_emit_identity()` or `emit_identity()`.

### Recommendation
1. Add identity emission to identity-writer.sh
2. Track when MISSION.md, GOALS.md, etc. are read/modified
3. Emit identity access events from relevant hooks

---

## Files Involved

### Hook Files (need modification)
- `~/.kiro/hooks/pilot/agent-spawn.sh` - Lines 90, 183-184 (duplicate emit)
- `~/.kiro/hooks/pilot/user-prompt-submit.sh` - Lines 23-24 (dual source), detect_phase
- `~/.kiro/hooks/pilot/stop.sh` - Learning emission

### Library Files (need consolidation)
- `~/.kiro/pilot/lib/dashboard-emit.sh` - Simple emission (should deprecate)
- `~/.kiro/pilot/lib/dashboard-emitter.sh` - Enhanced emission (should keep)

### Dashboard Files (no changes needed)
- `src/dashboard-ink/src/state.ts` - Already handles polling correctly
- `src/dashboard-ink/src/App.tsx` - Already has 30-second phase timeout

---

## Priority Order for Fixes

1. **HIGH**: Remove duplicate event emission (#1)
2. **MEDIUM**: Fix UNKNOWN phase default (#2)
3. **MEDIUM**: Extract actual learning titles (#3)
4. **MEDIUM**: Add session cleanup logic (#4)
5. **LOW**: Fix ghost sessions (#5)
6. **LOW**: Use enhanced session format (#6)
7. **LOW**: Add session history (#7)
8. **LOW**: Add identity emission (#8)

---

## Verification Commands

```bash
# Count duplicate events (same timestamp)
awk -F'"timestamp":' '{print $2}' ~/.kiro/pilot/dashboard/events.jsonl | \
  cut -d'}' -f1 | sort | uniq -c | sort -rn | head -20

# Count UNKNOWN phases
grep '"phase":"UNKNOWN"' ~/.kiro/pilot/dashboard/events.jsonl | wc -l

# List stale sessions
ls -la ~/.kiro/pilot/dashboard/sessions/

# Check learning titles
grep '"type":"learning"' ~/.kiro/pilot/dashboard/events.jsonl | tail -10

# Check session file contents
for f in ~/.kiro/pilot/dashboard/sessions/*.json; do echo "=== $f ==="; cat "$f"; done
```

---

*Report generated by PILOT Dashboard investigation session*
