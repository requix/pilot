# Dashboard Fixes and Enhancements

**Date**: January 19, 2026

## Issues Fixed

### 1. ✅ Command Count Removed
**Issue**: Every session showing "#1"
**Fix**: Removed progress bar and command count from SessionCard component
**File**: `src/components/SessionCard.tsx`

### 2. ✅ Phase Text Overflow
**Issue**: When phase is active, text becomes broken (e.g., "▶EXE C" split across lines)
**Root Cause**: Adding "▶" character caused text to exceed box width
**Fix**:
- Removed the arrow character from active phases
- Use border color pulsing to indicate activity instead
- Consistent phase labels that fit in 11-char width boxes
**File**: `src/components/PhaseBox.tsx`

### 3. ✅ Identity System Tracking
**Issue**: No identity activities shown despite events being emitted
**Root Cause**: Code was checking `session.identityAccess` array instead of global `state.identityAccess` counts
**Fix**: Changed to check global identity access counts from state
**File**: `src/App.tsx`

### 4. ⚠️ Recent Learnings Showing "Learning captured"
**Issue**: All learnings show generic "Learning captured" instead of actual content
**Root Cause**: PILOT hooks are emitting "Learning captured" placeholder instead of actual learning titles
**Status**: This is a PILOT hook issue, not a dashboard issue
**Location**: The hook that calls `dashboard_emit_learning()` needs to pass actual learning content
**Recommendation**: Update PILOT's learning capture hooks to emit descriptive titles

### 5. ✅ Categories Section Removed
**Issue**: Not useful for users
**Fix**: Removed entire Categories section from dashboard
**File**: `src/App.tsx`

## Enhancements Proposed

### Enhancement 1: Redesigned Identity System

**Current Problem**: Shows all 10 components always, even though user may not have defined all

**Proposed Solution**:
```
╭─ IDENTITY SYSTEM (8/10 defined) ─────────────────────╮
│                                                       │
│  ✓ MISSION      [53 lines]   ████░░░  Updated 2d    │
│  ✓ GOALS        [84 lines]   ██████░░ Updated 1h    │
│  ✓ PROJECTS     [138 lines]  ████████ Updated 30m   │
│  ✓ BELIEFS      [100 lines]  ██████░░ Updated 5d    │
│  ✓ MODELS       [93 lines]   ██████░░ Never accessed│
│  ✓ STRATEGIES   [159 lines]  ████████ Updated 2h    │
│  ✓ NARRATIVES   [123 lines]  ███████░ Updated 3d    │
│  ✓ LEARNED      [139 lines]  ████████ Updated 1d    │
│  ✓ CHALLENGES   [194 lines]  ████████ Updated 4h    │
│  ✓ IDEAS        [227 lines]  ████████ Updated 12h   │
│                                                       │
│  📈 Growth: +47 lines this week                      │
│  🔥 Most Active: IDEAS (12 accesses/week)            │
╰───────────────────────────────────────────────────────╯
```

**Features**:
- Only show components that exist and have content
- Show line count as growth indicator
- Show last modified time
- Show access frequency
- Summary stats: total defined, growth rate, most active

### Enhancement 2: Session Metrics

**Available Data** (from `~/.kiro/pilot/metrics/session-*.json`):
- `prompts`: Number of API calls (proxy for token usage)
- `tools`: Number of tool calls
- `success`/`failures`: Success rate
- `phases`: Phase distribution (e.g., "O:9 T:0 P:2 B:0 E:47 V:16 L:0")

**Proposed Addition to SessionCard**:
```
╭─────────────────────────────────────────────────────────╮
│ ● pilot-1768772675     [EXECUTE]    2h 15m             │
│   Implementing dashboard enhancements                   │
│   ~/Projects/pilot/src/dashboard-ink                    │
│                                                         │
│   📊 113 prompts  |  96 tools  |  100% success         │
│   💰 ~225k tokens (est. $0.68)                          │
╰─────────────────────────────────────────────────────────╯
```

**Implementation Required**:
1. Read metrics files from `~/.kiro/pilot/metrics/`
2. Match session ID to metrics file
3. Calculate estimated tokens (prompts × 2000 avg)
4. Calculate cost (tokens × $0.003/1k for Sonnet)

### Enhancement 3: Global Statistics

**Add to Stats Overview**:
```
┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│ ACTIVE        │ │ PROMPTS/24H   │ │ EST. COST     │ │ SUCCESS RATE  │
│     2         │ │     847       │ │   $2.54       │ │   98.3%       │
└───────────────┘ └───────────────┘ └───────────────┘ └───────────────┘
```

### Enhancement 4: Phase Distribution Sparkline

**Add to each session**:
```
Phase History: O:█ T:░ P:█ B:░ E:████████ V:███ L:░
```

Shows relative time spent in each phase.

## Implementation Priority

### Phase 1: Critical Fixes (DONE)
- [x] Remove command count
- [x] Fix phase text overflow
- [x] Fix identity tracking
- [x] Remove categories

### Phase 2: Identity System Redesign (DONE)
- [x] Read identity file stats (size, modified time)
- [x] Track access frequency from events
- [x] Create new IdentityPanel component
- [x] Show only defined components with line counts
- [x] Add growth indicators (bars, timestamps)

### Phase 3: Session Metrics (DONE)
- [x] Create metrics reader utility
- [x] Match sessions to metrics files
- [x] Add metrics display to SessionCard (prompts, tools, success%, tokens, cost)
- [x] Add global metrics to stats overview

### Phase 4: Global Statistics (DONE)
- [x] Load metrics from all session files
- [x] Calculate prompts/24h
- [x] Token estimation
- [x] Cost calculation
- [x] Success rate tracking

## Technical Notes

### Reading Identity Stats

```typescript
// In src/state.ts
interface IdentityFileStats {
  component: IdentityComponent
  exists: boolean
  lines: number
  bytes: number
  lastModified: number
  accessCount: number
}

async function loadIdentityStats(): Promise<Record<IdentityComponent, IdentityFileStats>> {
  const identityDir = join(homedir(), ".kiro", "pilot", "identity")
  const stats: Record<string, IdentityFileStats> = {}

  for (const component of IDENTITY_COMPONENTS) {
    const filePath = join(identityDir, `${component}.md`)
    try {
      const stat = await statSync(filePath)
      const content = await readFileSync(filePath, 'utf-8')
      stats[component] = {
        component,
        exists: true,
        lines: content.split('\n').length,
        bytes: stat.size,
        lastModified: stat.mtimeMs,
        accessCount: 0 // Will be populated from events
      }
    } catch {
      stats[component] = {
        component,
        exists: false,
        lines: 0,
        bytes: 0,
        lastModified: 0,
        accessCount: 0
      }
    }
  }

  return stats
}
```

### Reading Session Metrics

```typescript
// In src/state.ts
interface SessionMetrics {
  sessionId: string
  prompts: number
  tools: number
  success: number
  failures: number
  phases: string
}

async function loadSessionMetrics(sessionId: string): Promise<SessionMetrics | null> {
  const metricsFile = join(homedir(), ".kiro", "pilot", "metrics", `session-${sessionId}.json`)
  try {
    const content = await readFile(metricsFile, 'utf-8')
    return JSON.parse(content).metrics
  } catch {
    return null
  }
}
```

## Questions for User

1. **Token Estimation**: Should we estimate tokens (prompts × 2000) or try to read actual token usage if available?

2. **Cost Calculation**: What pricing should we use? Sonnet 4.5 is $0.003/1k tokens. Should this be configurable?

3. **Identity System**:
   - Should we show ALL components with status indicators, or ONLY defined ones?
   - What's more valuable: line count, access frequency, or last modified time?

4. **Learning Titles**: Should we:
   - Fix this at the PILOT hook level?
   - Add a fallback that extracts first N characters from the learning content file?
   - Show session phase + timestamp if title is missing?

5. **Additional Metrics**: Any other data from kiro CLI that would be valuable to show?

## Next Steps

1. Await user feedback on proposed enhancements
2. Implement Identity System redesign
3. Add session metrics integration
4. Test with real PILOT sessions
5. Update documentation
