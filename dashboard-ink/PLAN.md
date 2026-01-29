# PILOT Dashboard (Ink) - Implementation Plan

**Project**: Dashboard migration from OpenTUI to Ink
**Timeline**: 2-3 days (16-24 hours)
**Goal**: Modern, stable, animated real-time dashboard

---

## Phase 1: Foundation (4-6 hours)

### Setup & Dependencies

**Priority**: Critical
**Time**: 1 hour

```bash
# Initialize project
cd src/dashboard-ink
bun init

# Install dependencies
bun add ink react
bun add -d @types/react typescript

# Dev tools
bun add -d @oclif/test ink-testing-library
```

**Deliverables**:
- ✅ `package.json` configured
- ✅ `tsconfig.json` setup
- ✅ Build scripts working
- ✅ Basic project structure

---

### Core State Management

**Priority**: Critical
**Time**: 2-3 hours

**Tasks**:
1. Port `state/StateManager.ts` from OpenTUI version
2. Implement `state/EventStream.ts` with Unix socket
3. Update `state/types.ts` with Ink-compatible types
4. Add fallback polling mechanism

**Files to Create**:
```
src/state/
├── StateManager.ts       # State management with event handling
├── EventStream.ts        # Unix socket + file polling
├── types.ts              # TypeScript interfaces
└── __tests__/
    ├── StateManager.test.ts
    └── EventStream.test.ts
```

**Key Features**:
- Event stream with automatic fallback
- Session lifecycle management
- Learning categorization
- Identity access tracking
- Persistent state loading

**Testing**:
```typescript
// StateManager.test.ts
describe('StateManager', () => {
  it('loads persisted sessions', async () => {
    await stateManager.init()
    expect(stateManager.getState().sessions).toBeDefined()
  })

  it('handles phase events', () => {
    stateManager.handleEvent({
      type: 'phase',
      sessionId: 'test-123',
      phase: 'EXECUTE',
      timestamp: Date.now()
    })

    const state = stateManager.getState()
    expect(state.sessions['test-123'].phase).toBe('EXECUTE')
  })
})
```

**Deliverables**:
- ✅ StateManager with event handling
- ✅ EventStream with socket + fallback
- ✅ All types defined
- ✅ Unit tests passing

---

### Utility Functions

**Priority**: High
**Time**: 1 hour

**Files to Create**:
```
src/utils/
├── colors.ts           # Color palette and helpers
├── formatters.ts       # Time, numbers, etc.
├── categories.ts       # Learning categorization
└── __tests__/
    └── formatters.test.ts
```

**`colors.ts`**:
```typescript
export const COLORS = {
  primary: '#00ff9f',
  glow: '#00ffff',
  success: '#98D8C8',
  warning: '#FFEAA7',
  error: '#FF6B6B',
  info: '#4ECDC4',
  muted: '#888888',
  dim: '#555555',
  bgDark: '#1a1a1a',
  border: '#2a2a2a',
} as const

export const PHASE_COLORS: Record<AlgorithmPhase, string> = {
  OBSERVE: '#4ECDC4',
  THINK: '#45B7D1',
  PLAN: '#96CEB4',
  BUILD: '#FFEAA7',
  EXECUTE: '#FF6B6B',
  VERIFY: '#DDA0DD',
  LEARN: '#98D8C8',
  IDLE: '#333333',
}

export const getCategoryColor = (category: string): string => {
  const colors: Record<string, string> = {
    terraform: '#DDA0DD',
    kubernetes: '#4ECDC4',
    git: '#FF6B6B',
    aws: '#FFEAA7',
    docker: '#45B7D1',
    bash: '#96CEB4',
    python: '#98D8C8',
    javascript: '#F7DC6F',
  }
  return colors[category] || COLORS.success
}
```

**`formatters.ts`**:
```typescript
export const formatDuration = (seconds: number): string => {
  if (seconds < 60) return `${seconds}s`

  const minutes = Math.floor(seconds / 60)
  const secs = seconds % 60

  if (minutes < 60) return `${minutes}m${secs}s`

  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60

  return `${hours}h${mins}m`
}

export const formatTimeAgo = (timestamp: number): string => {
  const seconds = Math.floor((Date.now() - timestamp * 1000) / 1000)
  const minutes = Math.floor(seconds / 60)

  if (minutes < 1) return 'now'
  if (minutes < 60) return `${minutes}m`

  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h`

  const days = Math.floor(hours / 24)
  return `${days}d`
}

export const formatNumber = (n: number): string => {
  if (n >= 1000000) return `${(n / 1000000).toFixed(1)}M`
  if (n >= 1000) return `${(n / 1000).toFixed(1)}K`
  return String(n)
}
```

**Deliverables**:
- ✅ Color utilities
- ✅ Formatters
- ✅ Category helpers
- ✅ Tests passing

---

## Phase 2: Core Components (6-8 hours)

### Basic Components

**Priority**: Critical
**Time**: 3-4 hours

**Order of Implementation**:

1. **ProgressBar** (30 min)
   - Simple, reusable
   - No dependencies
   - Good for learning Ink

2. **Sparkline** (30 min)
   - Standalone component
   - ASCII chart rendering
   - Tests easy to write

3. **SectionHeader** (30 min)
   - Simple layout
   - Accent styling
   - Reused everywhere

4. **CategoryBadge** (30 min)
   - Box with color
   - Text rendering
   - Color mapping

5. **Header** (1 hour)
   - Top-level component
   - Multiple text elements
   - Border styling

**Example: ProgressBar.tsx**:
```typescript
import React from 'react'
import { Box, Text } from 'ink'

interface ProgressBarProps {
  current: number
  max: number
  width?: number
  color?: string
  showLabel?: boolean
  filledChar?: string
  emptyChar?: string
}

export const ProgressBar: React.FC<ProgressBarProps> = ({
  current,
  max,
  width = 20,
  color = '#00ff9f',
  showLabel = false,
  filledChar = '█',
  emptyChar = '░',
}) => {
  const progress = Math.min(Math.max(current / max, 0), 1)
  const filledWidth = Math.floor(progress * width)
  const emptyWidth = width - filledWidth

  const bar = filledChar.repeat(filledWidth) + emptyChar.repeat(emptyWidth)
  const percentage = Math.round(progress * 100)

  return (
    <Box>
      <Text color={color}>{bar}</Text>
      {showLabel && <Text dimColor> {percentage}%</Text>}
    </Box>
  )
}
```

**Deliverables**:
- ✅ 5 basic components
- ✅ All with tests
- ✅ Storybook examples (optional)

---

### Complex Components

**Priority**: Critical
**Time**: 3-4 hours

**Order of Implementation**:

1. **PhaseBox** (1 hour)
   - Box with colors
   - Pulse animation
   - Border styles

2. **IdentityBox** (45 min)
   - Similar to PhaseBox
   - Access counter
   - Compact layout

3. **LearningItem** (1 hour)
   - Multi-element layout
   - Category badge integration
   - Time formatting

4. **SessionCard** (1.5 hours)
   - Most complex component
   - Multiple sub-elements
   - Progress bar integration
   - Color coordination

**Example: SessionCard.tsx**:
```typescript
import React, { useMemo } from 'react'
import { Box, Text } from 'ink'
import { ProgressBar } from './ProgressBar'
import { formatDuration } from '../utils/formatters'
import { PHASE_COLORS } from '../utils/colors'
import type { SessionState } from '../state/types'

interface SessionCardProps {
  session: SessionState
  showProgress?: boolean
}

export const SessionCard: React.FC<SessionCardProps> = ({
  session,
  showProgress = true,
}) => {
  const duration = useMemo(() => {
    const startTime =
      session.startTime && session.startTime > 1000000000
        ? session.startTime
        : Math.floor(Date.now() / 1000)
    return Math.floor((Date.now() - startTime * 1000) / 1000)
  }, [session.startTime])

  const title =
    session.title ||
    {
      OBSERVE: 'Analyzing problem',
      THINK: 'Exploring solutions',
      PLAN: 'Creating strategy',
      BUILD: 'Defining success',
      EXECUTE: 'Implementing solution',
      VERIFY: 'Testing results',
      LEARN: 'Capturing insights',
    }[session.phase] ||
    'Active session'

  const phaseColor = PHASE_COLORS[session.phase] || '#333333'

  return (
    <Box
      flexDirection="column"
      borderStyle="round"
      borderColor={session.color}
      paddingX={1}
      marginBottom={1}
    >
      <Box>
        <Text color={session.color}>● </Text>
        <Text>{session.id.slice(0, 20)} </Text>
        <Text color={phaseColor}>[{session.phase}] </Text>
        <Text dimColor>{formatDuration(duration)}</Text>
      </Box>

      <Box paddingLeft={2}>
        <Text dimColor>{title}</Text>
      </Box>

      {session.workingDirectory && (
        <Box paddingLeft={2}>
          <Text dimColor>
            {session.workingDirectory.split('/').slice(-2).join('/')}
          </Text>
        </Box>
      )}

      {showProgress && (
        <Box paddingLeft={2} marginTop={1}>
          <ProgressBar
            current={session.commandCount || 0}
            max={50}
            width={15}
            color="#666666"
          />
          <Text dimColor> #{session.commandCount || 0}</Text>
        </Box>
      )}
    </Box>
  )
}
```

**Deliverables**:
- ✅ 4 complex components
- ✅ Integration with basic components
- ✅ Animations working
- ✅ Tests passing

---

### Custom Hooks

**Priority**: High
**Time**: 1-2 hours

**Hooks to Implement**:

1. **usePulse** (15 min)
2. **useFlash** (15 min)
3. **useAnimatedValue** (30 min)
4. **useSlideIn** (15 min)
5. **useVirtualScroll** (45 min)

**Example: usePulse.ts**:
```typescript
import { useState, useEffect } from 'react'

export const usePulse = (interval = 1000): boolean => {
  const [pulse, setPulse] = useState(false)

  useEffect(() => {
    const timer = setInterval(() => {
      setPulse((p) => !p)
    }, interval)

    return () => clearInterval(timer)
  }, [interval])

  return pulse
}
```

**Deliverables**:
- ✅ All 5 hooks implemented
- ✅ Tests for each hook
- ✅ Documentation

---

## Phase 3: Integration (4-6 hours)

### Main App Component

**Priority**: Critical
**Time**: 2-3 hours

**File**: `src/App.tsx`

**Structure**:
```typescript
import React, { useState, useEffect } from 'react'
import { Box } from 'ink'
import { StateManager } from './state/StateManager'
import { Header } from './components/Header'
import { StatsPanel } from './components/StatsPanel'
import { SessionCard } from './components/SessionCard'
import { PhaseBox } from './components/PhaseBox'
import { usePulse, useFlash } from './hooks'
import type { DashboardState } from './state/types'

const PHASES = ['OBSERVE', 'THINK', 'PLAN', 'BUILD', 'EXECUTE', 'VERIFY', 'LEARN']
const IDENTITY = ['MISSION', 'GOALS', 'PROJECTS', 'BELIEFS', 'MODELS', 'STRATEGIES', 'NARRATIVES', 'LEARNED', 'CHALLENGES', 'IDEAS']

const stateManager = new StateManager()

export const App: React.FC = () => {
  const [state, setState] = useState<DashboardState>(stateManager.getState())
  const [, forceUpdate] = useState({})

  const pulse = usePulse(1000)
  const { flash, trigger: triggerFlash } = useFlash(800)

  useEffect(() => {
    stateManager.init()

    stateManager.onChange(setState)

    stateManager.onEvent((event) => {
      if (event.type === 'learning') {
        triggerFlash()
      }
    })

    // Update timer for durations
    const timer = setInterval(() => {
      forceUpdate({})
    }, 1000)

    return () => {
      clearInterval(timer)
    }
  }, [])

  const sessions = Object.values(state.sessions)
  const activePhases = new Set(
    sessions
      .filter((s) => s.phase !== 'IDLE')
      .map((s) => s.phase)
  )

  return (
    <Box flexDirection="column" padding={1}>
      <Header
        title="PILOT DASHBOARD v2.0"
        subtitle="Real-time session monitoring"
      />

      {/* Stats Overview */}
      <Box marginTop={1}>
        <StatsPanel label="ACTIVE" value={sessions.length} />
        <StatsPanel
          label="LEARNINGS"
          value={state.learningStats.totalCount}
        />
        <StatsPanel
          label="RATE/24H"
          value={state.learningStats.recentRate.toFixed(1)}
        />
      </Box>

      {/* Sessions */}
      <SectionHeader title="ACTIVE SESSIONS" count={sessions.length} />
      <Box flexDirection="column">
        {sessions.map((session) => (
          <SessionCard key={session.id} session={session} />
        ))}
      </Box>

      {/* Algorithm Phases */}
      <SectionHeader title="UNIVERSAL ALGORITHM" />
      <Box>
        {PHASES.map((phase) => (
          <PhaseBox
            key={phase}
            phase={phase}
            active={activePhases.has(phase)}
            pulse={pulse && activePhases.has(phase)}
          />
        ))}
      </Box>

      {/* ... more sections ... */}
    </Box>
  )
}
```

**Tasks**:
1. Implement main layout
2. Wire up state management
3. Add all sections
4. Implement keyboard controls
5. Add error boundaries

**Deliverables**:
- ✅ Complete App component
- ✅ All sections integrated
- ✅ State updates working
- ✅ Keyboard controls

---

### Entry Point

**Priority**: Critical
**Time**: 30 min

**File**: `src/index.tsx`

```typescript
#!/usr/bin/env node
import React from 'react'
import { render } from 'ink'
import { App } from './App'

// Handle uncaught errors
process.on('uncaughtException', (error) => {
  console.error('Fatal error:', error)
  process.exit(1)
})

process.on('unhandledRejection', (error) => {
  console.error('Unhandled promise rejection:', error)
  process.exit(1)
})

// Render app
const { waitUntilExit } = render(<App />)

// Wait for exit
waitUntilExit().catch((error) => {
  console.error('Error:', error)
  process.exit(1)
})
```

**Deliverables**:
- ✅ CLI entry point
- ✅ Error handling
- ✅ Executable script

---

### CLI Wrapper

**Priority**: Medium
**Time**: 30 min

**File**: `bin/pilot-dashboard`

```bash
#!/usr/bin/env bash
# PILOT Dashboard (Ink version)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_DIR="$(dirname "$SCRIPT_DIR")"

cd "$DASHBOARD_DIR"

# Check if built
if [ ! -d "dist" ]; then
    echo "Building dashboard..."
    bun run build
fi

# Run dashboard
exec bun run dist/index.js "$@"
```

**Deliverables**:
- ✅ Shell wrapper
- ✅ Build check
- ✅ Error messages

---

### Testing Suite

**Priority**: High
**Time**: 2-3 hours

**Test Categories**:

1. **Unit Tests** (1 hour)
   - All components
   - All hooks
   - Utilities

2. **Integration Tests** (1 hour)
   - State management
   - Event handling
   - Component interaction

3. **Snapshot Tests** (30 min)
   - Visual regression
   - Layout consistency

4. **E2E Tests** (30 min)
   - Full dashboard flow
   - Event emission
   - Cleanup

**Example Integration Test**:
```typescript
import { render } from 'ink-testing-library'
import { App } from '../App'
import { StateManager } from '../state/StateManager'

describe('Dashboard Integration', () => {
  it('displays new session when event received', async () => {
    const { lastFrame, rerender } = render(<App />)

    // Emit session event
    const stateManager = StateManager.getInstance()
    await stateManager.handleEvent({
      type: 'phase',
      sessionId: 'test-123',
      phase: 'EXECUTE',
      timestamp: Date.now(),
    })

    rerender(<App />)

    expect(lastFrame()).toContain('test-123')
    expect(lastFrame()).toContain('EXECUTE')
  })

  it('shows flash animation on learning', async () => {
    const { lastFrame, rerender } = render(<App />)

    const stateManager = StateManager.getInstance()
    await stateManager.handleEvent({
      type: 'learning',
      sessionId: 'test-123',
      title: 'Test learning',
      timestamp: Date.now(),
    })

    rerender(<App />)

    // Should show flash state
    expect(lastFrame()).toContain('Test learning')
  })
})
```

**Deliverables**:
- ✅ 80%+ code coverage
- ✅ All tests passing
- ✅ CI/CD ready

---

## Phase 4: Polish & Documentation (2-4 hours)

### Configuration System

**Priority**: Medium
**Time**: 1 hour

**File**: `src/config/index.ts`

```typescript
import { readFile, writeFile } from 'fs/promises'
import { join } from 'path'
import { homedir } from 'os'

const CONFIG_PATH = join(homedir(), '.kiro', 'pilot', 'dashboard-config.json')

const DEFAULT_CONFIG = {
  theme: {
    primaryColor: '#00ff9f',
    accentColor: '#00ffff',
    backgroundColor: '#1a1a1a',
  },
  animations: {
    enabled: true,
    pulseInterval: 1000,
    flashDuration: 800,
  },
  display: {
    maxSessions: 10,
    maxLearnings: 5,
    showHistory: true,
    showCategories: true,
  },
  streaming: {
    enabled: true,
    fallbackToPolling: true,
    pollingInterval: 500,
  },
}

export class Config {
  private static config: typeof DEFAULT_CONFIG

  static async load() {
    try {
      const data = await readFile(CONFIG_PATH, 'utf-8')
      this.config = { ...DEFAULT_CONFIG, ...JSON.parse(data) }
    } catch {
      this.config = DEFAULT_CONFIG
    }
  }

  static async save() {
    await writeFile(CONFIG_PATH, JSON.stringify(this.config, null, 2))
  }

  static get<K extends keyof typeof DEFAULT_CONFIG>(
    key: K
  ): typeof DEFAULT_CONFIG[K] {
    return this.config[key]
  }

  static set<K extends keyof typeof DEFAULT_CONFIG>(
    key: K,
    value: typeof DEFAULT_CONFIG[K]
  ) {
    this.config[key] = value
  }
}
```

**Deliverables**:
- ✅ Config loading/saving
- ✅ Default values
- ✅ Type safety

---

### Documentation

**Priority**: High
**Time**: 2 hours

**Files to Create**:

1. **README.md** (45 min)
   - Installation
   - Quick start
   - Features
   - Configuration
   - Troubleshooting

2. **MIGRATION.md** (45 min)
   - Migration from OpenTUI
   - Breaking changes
   - Feature comparison

3. **API.md** (30 min)
   - Component APIs
   - Hook APIs
   - Configuration options

**README Structure**:
```markdown
# PILOT Dashboard (Ink)

Modern, animated real-time dashboard for PILOT system activity.

## Features
- Real-time session monitoring
- Event streaming (instant updates)
- Modern TUI aesthetics
- Smooth animations
- Learning categorization
- Identity tracking

## Installation
...

## Usage
...

## Configuration
...
```

**Deliverables**:
- ✅ Complete README
- ✅ Migration guide
- ✅ API documentation

---

### Performance Optimization

**Priority**: Medium
**Time**: 1 hour

**Tasks**:

1. **Memoization** (20 min)
   - Wrap components with React.memo
   - Optimize re-render triggers

2. **Virtual Scrolling** (30 min)
   - Implement for long lists
   - Only render visible items

3. **Debouncing** (10 min)
   - Debounce state updates
   - Throttle animations

**Deliverables**:
- ✅ Optimized components
- ✅ Virtual scrolling working
- ✅ Performance tests

---

## Phase 5: Deployment & Testing (2-3 hours)

### Build System

**Priority**: Critical
**Time**: 30 min

**package.json scripts**:
```json
{
  "scripts": {
    "dev": "tsx watch src/index.tsx",
    "build": "tsc && chmod +x dist/index.js",
    "start": "bun run dist/index.js",
    "test": "bun test",
    "test:watch": "bun test --watch",
    "lint": "eslint src --ext .ts,.tsx",
    "format": "prettier --write \"src/**/*.{ts,tsx}\"",
    "typecheck": "tsc --noEmit"
  }
}
```

**Deliverables**:
- ✅ Build script
- ✅ Dev mode
- ✅ Type checking

---

### Integration Testing

**Priority**: High
**Time**: 1-2 hours

**Test Scenarios**:

1. **Fresh Install** (15 min)
   - No existing data
   - First run experience

2. **With Existing Data** (15 min)
   - Load persisted sessions
   - Event history

3. **Event Streaming** (30 min)
   - Socket connection
   - Fallback to polling
   - Reconnection

4. **Error Handling** (30 min)
   - Malformed events
   - Socket errors
   - File permissions

**Deliverables**:
- ✅ All scenarios tested
- ✅ Edge cases covered
- ✅ Error messages clear

---

### User Acceptance Testing

**Priority**: High
**Time**: 1 hour

**Test with Real Data**:

1. Start dashboard
2. Run PILOT session
3. Emit various events
4. Verify all features work
5. Check performance

**Checklist**:
- [ ] Dashboard starts without errors
- [ ] Sessions appear in real-time
- [ ] Phases update correctly
- [ ] Learnings display properly
- [ ] Animations are smooth
- [ ] Keyboard controls work
- [ ] Export function works
- [ ] No memory leaks
- [ ] CPU usage reasonable

**Deliverables**:
- ✅ UAT checklist complete
- ✅ All issues fixed
- ✅ Production ready

---

## Rollout Plan

### Week 1: Development
- **Day 1**: Phase 1 (Foundation)
- **Day 2**: Phase 2 (Components)
- **Day 3**: Phase 3 (Integration)

### Week 2: Polish
- **Day 4**: Phase 4 (Polish & Docs)
- **Day 5**: Phase 5 (Testing & Deployment)

### Migration Strategy

1. **Parallel Development**
   - Keep OpenTUI version running
   - Develop Ink version in parallel
   - Test both side-by-side

2. **Soft Launch**
   - Deploy to `bin/pilot-dashboard-ink`
   - Invite testing feedback
   - Iterate on issues

3. **Full Migration**
   - Replace `bin/pilot-dashboard`
   - Deprecate OpenTUI version
   - Update documentation

---

## Success Criteria

### Functional
- ✅ All features from OpenTUI version
- ✅ Event streaming with <10ms latency
- ✅ Smooth animations (no jank)
- ✅ Stable (no crashes)

### Performance
- ✅ <50ms render time
- ✅ <10MB memory usage
- ✅ <1% CPU usage when idle

### Quality
- ✅ 80%+ test coverage
- ✅ Zero TypeScript errors
- ✅ Clean linter output
- ✅ Complete documentation

---

## Risk Mitigation

### Technical Risks

**Risk**: Ink performance issues
- **Mitigation**: Benchmark early, optimize components
- **Fallback**: Virtual scrolling, memoization

**Risk**: Socket connection unreliable
- **Mitigation**: Automatic fallback to file polling
- **Fallback**: File-only mode as last resort

**Risk**: Animation jank
- **Mitigation**: Use requestAnimationFrame equivalent
- **Fallback**: Disable animations option

### Timeline Risks

**Risk**: Scope creep
- **Mitigation**: Stick to MVP features
- **Fallback**: Push enhancements to Phase 2

**Risk**: Unexpected bugs
- **Mitigation**: Comprehensive testing
- **Fallback**: Keep OpenTUI version as backup

---

## Post-Launch

### Monitoring (Week 3+)

- Gather user feedback
- Monitor for crashes
- Track performance metrics
- Collect feature requests

### Iteration (Week 4+)

- Fix reported bugs
- Add requested features
- Performance tuning
- Documentation updates

### Future Enhancements

- Interactive mode
- Search/filter
- Custom themes
- Plugin system
- Web dashboard

---

## Resource Estimate

**Total Time**: 16-24 hours over 3-5 days

**Breakdown**:
- Phase 1: 4-6 hours (Foundation)
- Phase 2: 6-8 hours (Components)
- Phase 3: 4-6 hours (Integration)
- Phase 4: 2-4 hours (Polish)
- Phase 5: 2-3 hours (Testing)

**Team**: 1 developer (you or contributor)

**Timeline**: Can be compressed to 2 days if focused, or spread over a week with other work.

---

This plan provides a clear path from zero to production-ready Ink dashboard with all modern features, comprehensive testing, and proper documentation.
