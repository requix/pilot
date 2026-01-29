# PILOT Dashboard - Ink Implementation Design

**Version**: 2.0
**TUI Library**: Ink (React-based, mature)
**Target**: Modern, animated, real-time dashboard with event streaming

---

## Design Philosophy

### Visual Language

**Modern TUI Aesthetics**:
- Gradient-like effects using color transitions
- Rounded/double borders for emphasis
- Animated elements (pulse, fade, slide)
- Clear visual hierarchy
- Rich typography (bold, dim, colors)
- Progress visualization
- Sparklines and mini-charts

**Color Palette**:
```
Primary:   #00ff9f  (Neon Green - accent/active)
Glow:      #00ffff  (Cyan - highlights)
Success:   #98D8C8  (Teal - learning)
Warning:   #FFEAA7  (Yellow - BUILD phase)
Error:     #FF6B6B  (Red - EXECUTE phase)
Info:      #4ECDC4  (Blue - OBSERVE phase)
Muted:     #888888  (Gray - secondary text)
Dim:       #555555  (Dark gray - inactive)
BG Dark:   #1a1a1a  (Background)
Border:    #2a2a2a  (Subtle borders)
```

### Layout Structure

```
┌─────────────────────────────────────────────────────────────────────────┐
│ ⚡ PILOT DASHBOARD v2.0                              (q=quit, e=export) │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────┬──────────────┬──────────────┬──────────────────────────┐
│  ACTIVE     │  LEARNINGS   │  RATE/24H    │  UPTIME                  │
│     3       │     142      │    8.5       │  2h 34m                  │
└─────────────┴──────────────┴──────────────┴──────────────────────────┘

▶ ACTIVE SESSIONS (3)

╭─────────────────────────────────────────────────────────────────────╮
│ ● pilot-1768768911-12345      [EXECUTE]    1h 23m                  │
│   Implementing solution                                             │
│   ~/Projects/pilot/src/dashboard-ink                               │
│   ████████████░░░░░░░ #42                                           │
╰─────────────────────────────────────────────────────────────────────╯

⚙ UNIVERSAL ALGORITHM

╭────────╮ ╭────────╮ ╭────────╮ ╭────────╮ ╭────────╮ ╭────────╮ ╭────────╮
│▶OBSERVE│ │ THINK  │ │  PLAN  │ │ BUILD  │ │EXECUTE │ │ VERIFY │ │ LEARN  │
╰────────╯ ╰────────╯ ╰────────╯ ╰────────╯ ╰────────╯ ╰────────╯ ╰────────╯
   (pulsing)                                  (active)

🧠 IDENTITY SYSTEM

╭─────────╮ ╭─────────╮ ╭─────────╮ ╭─────────╮ ╭─────────╮
│ MISSION │ │  GOALS  │ │PROJECTS │ │ BELIEFS │ │ MODELS  │
│   ·12   │ │   ·34   │ │   ·8    │ │         │ │         │
╰─────────╯ ╰─────────╯ ╰─────────╯ ╰─────────╯ ╰─────────╯

✨ RECENT LEARNINGS (142 total, 8.5/24h)

╭─────────────────────────────────────────────────────────────────────╮
│ ✓ [terraform] Discovered state locking pattern            • 2m ago │
│ ✓ [kubernetes] Fixed pod restart loop issue               • 15m    │
│ ✓ [git] Learned git stash --include-untracked            • 1h      │
│ ✓ [aws] S3 bucket versioning best practices              • 2h      │
│ ✓ [docker] Multi-stage builds reduce image size          • 3h      │
╰─────────────────────────────────────────────────────────────────────╯
```

---

## Component Architecture

### Core Components

#### 1. Header Component
**Purpose**: Dashboard title and controls

```tsx
<Header
  title="PILOT DASHBOARD v2.0"
  subtitle="Real-time session monitoring"
  actions={['q=quit', 'e=export', 'r=refresh']}
/>
```

**Features**:
- Double border with accent color
- Animated gradient effect
- Version display
- Keyboard shortcuts

**Props**:
```typescript
interface HeaderProps {
  title: string
  subtitle?: string
  actions?: string[]
  animate?: boolean
}
```

---

#### 2. StatsPanel Component
**Purpose**: Display key metrics

```tsx
<StatsPanel
  label="ACTIVE"
  value={sessions.length}
  trend={[1, 2, 3, 2, 3, 4, 3]}  // Sparkline data
  color="#00ff9f"
  icon="▶"
/>
```

**Features**:
- Large value display
- Optional sparkline chart
- Trend indicators (↑↓→)
- Color-coded by metric type
- Animated value changes

**Props**:
```typescript
interface StatsPanelProps {
  label: string
  value: number | string
  trend?: number[]
  color?: string
  icon?: string
  animate?: boolean
}
```

---

#### 3. SessionCard Component
**Purpose**: Rich session information display

```tsx
<SessionCard
  session={{
    id: "pilot-123",
    phase: "EXECUTE",
    color: "#FF6B6B",
    duration: 5400,
    commandCount: 42,
    title: "Implementing feature",
    workingDirectory: "/path/to/project"
  }}
  showProgress={true}
  animated={true}
/>
```

**Features**:
- Rounded border with session color
- Phase badge with color coding
- Duration timer (auto-updating)
- Progress bar visualization
- Working directory context
- Smooth animations on updates

**Layout**:
```
╭─────────────────────────────────────────────╮
│ ● pilot-123  [EXECUTE]  1h 30m              │
│   Implementing feature                      │
│   ~/path/to/project                         │
│   ████████████░░░░░░░ #42                   │
╰─────────────────────────────────────────────╯
```

**Props**:
```typescript
interface SessionCardProps {
  session: SessionState
  showProgress?: boolean
  animated?: boolean
  onClick?: () => void  // For future interactivity
}
```

---

#### 4. PhaseBox Component
**Purpose**: Algorithm phase visualization

```tsx
<PhaseBox
  phase="EXECUTE"
  active={true}
  pulse={true}
  count={2}  // Number of sessions in this phase
/>
```

**Features**:
- Color-coded by phase
- Pulsing animation when active
- Double border for active state
- Session count indicator
- Glow effect

**States**:
- **Inactive**: Dim background, single border
- **Active**: Phase color, double border
- **Pulsing**: Animated border transition

**Props**:
```typescript
interface PhaseBoxProps {
  phase: AlgorithmPhase
  active: boolean
  pulse?: boolean
  count?: number
}
```

---

#### 5. IdentityBox Component
**Purpose**: Identity component access tracking

```tsx
<IdentityBox
  name="GOALS"
  active={true}
  accessCount={34}
  lastAccessed={Date.now()}
/>
```

**Features**:
- Compact display
- Access counter
- Color indication when active
- Tooltip with last access time (future)

**Props**:
```typescript
interface IdentityBoxProps {
  name: IdentityComponent
  active: boolean
  accessCount?: number
  lastAccessed?: number
}
```

---

#### 6. LearningItem Component
**Purpose**: Learning entry display

```tsx
<LearningItem
  learning={{
    title: "Discovered caching pattern",
    category: "terraform",
    timestamp: 1768768911,
    tags: ["performance", "optimization"]
  }}
  showCategory={true}
  animated={true}
/>
```

**Features**:
- Category badge with semantic colors
- Time-ago display
- Tag visualization
- Truncated title with tooltip
- Flash animation on new entries

**Layout**:
```
✓ [terraform] Discovered caching pattern • 2m ago
```

**Props**:
```typescript
interface LearningItemProps {
  learning: Learning
  showCategory?: boolean
  showTags?: boolean
  animated?: boolean
}
```

---

#### 7. ProgressBar Component
**Purpose**: Visual progress indicator

```tsx
<ProgressBar
  current={42}
  max={100}
  width={20}
  color="#00ff9f"
  showLabel={true}
  animated={true}
/>
```

**Features**:
- Filled/empty character visualization
- Percentage label
- Color customization
- Smooth animation
- Optional gradient effect

**Visual**:
```
████████████░░░░░░░░ 42%
```

**Props**:
```typescript
interface ProgressBarProps {
  current: number
  max: number
  width?: number
  color?: string
  showLabel?: boolean
  animated?: boolean
  filledChar?: string
  emptyChar?: string
}
```

---

#### 8. Sparkline Component
**Purpose**: Mini-chart for trend visualization

```tsx
<Sparkline
  data={[1, 3, 2, 5, 4, 7, 6, 8]}
  width={20}
  color="#00ff9f"
/>
```

**Features**:
- ASCII bar chart
- Auto-scaling
- Color coding
- Compact display

**Visual**:
```
▁▃▂▅▄▇▆█
```

**Props**:
```typescript
interface SparklineProps {
  data: number[]
  width?: number
  color?: string
}
```

---

#### 9. SectionHeader Component
**Purpose**: Section dividers with style

```tsx
<SectionHeader
  title="ACTIVE SESSIONS"
  count={3}
  icon="▶"
  color="#00ff9f"
/>
```

**Features**:
- Icon prefix
- Count indicator
- Accent line
- Color customization

**Visual**:
```
▶ ACTIVE SESSIONS (3) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Props**:
```typescript
interface SectionHeaderProps {
  title: string
  count?: number
  icon?: string
  color?: string
}
```

---

#### 10. CategoryBadge Component
**Purpose**: Learning category display

```tsx
<CategoryBadge
  category="terraform"
  count={12}
  compact={false}
/>
```

**Features**:
- Semantic color mapping
- Compact/full modes
- Count indicator
- Rounded borders

**Visual**:
```
╭────────────╮
│ terraform  │
│    12      │
╰────────────╯
```

**Props**:
```typescript
interface CategoryBadgeProps {
  category: string
  count?: number
  compact?: boolean
  color?: string
}
```

---

## Animation System

### 1. Pulse Animation
**Use**: Active phases, new learnings

```typescript
const usePulse = (interval = 1000) => {
  const [pulse, setPulse] = useState(false)

  useEffect(() => {
    const timer = setInterval(() => {
      setPulse(p => !p)
    }, interval)
    return () => clearInterval(timer)
  }, [interval])

  return pulse
}
```

**Effect**: Border style toggles between single/double

---

### 2. Flash Animation
**Use**: New learning captures

```typescript
const useFlash = (duration = 800) => {
  const [flash, setFlash] = useState(false)

  const trigger = useCallback(() => {
    setFlash(true)
    setTimeout(() => setFlash(false), duration)
  }, [duration])

  return { flash, trigger }
}
```

**Effect**: Background color bright → dim transition

---

### 3. Count Animation
**Use**: Value changes in stats

```typescript
const useAnimatedValue = (value: number, duration = 500) => {
  const [displayValue, setDisplayValue] = useState(value)

  useEffect(() => {
    // Smooth transition from current to new value
    const steps = 10
    const increment = (value - displayValue) / steps
    let step = 0

    const timer = setInterval(() => {
      if (step++ < steps) {
        setDisplayValue(v => v + increment)
      } else {
        setDisplayValue(value)
        clearInterval(timer)
      }
    }, duration / steps)

    return () => clearInterval(timer)
  }, [value])

  return Math.round(displayValue)
}
```

---

### 4. Slide-In Animation
**Use**: New sessions appearing

```typescript
const useSlideIn = (show: boolean, delay = 200) => {
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    if (show) {
      setTimeout(() => setVisible(true), delay)
    } else {
      setVisible(false)
    }
  }, [show, delay])

  return visible
}
```

---

## Event Streaming Architecture

### Unix Domain Socket

**Path**: `~/.kiro/pilot/dashboard/events.sock`

**Protocol**:
```typescript
interface EventMessage {
  type: 'phase' | 'learning' | 'identity' | 'heartbeat'
  sessionId: string
  timestamp: number
  data: any
}

// Sent as newline-delimited JSON
```

**Client → Server**:
```
{"type":"phase","sessionId":"pilot-123","phase":"EXECUTE","timestamp":1768768911}\n
{"type":"learning","sessionId":"pilot-123","title":"...","timestamp":1768768911}\n
```

**Server → Client** (broadcast):
```
{"type":"heartbeat","timestamp":1768768911}\n
```

### Fallback Strategy

```typescript
class EventStream {
  private socket: Socket | null = null
  private fallbackTimer: NodeJS.Timer | null = null

  async connect() {
    try {
      // Try socket first
      this.socket = await this.connectSocket()
      this.startHeartbeat()
    } catch {
      // Fallback to file polling
      this.startFilePolling()
    }
  }

  private startFilePolling() {
    this.fallbackTimer = setInterval(async () => {
      const events = await this.pollEventFile()
      events.forEach(e => this.handleEvent(e))
    }, 500)
  }
}
```

---

## State Management

### Global State

```typescript
interface DashboardState {
  // Sessions
  sessions: Record<string, SessionState>
  sessionHistory: SessionState[]

  // Learnings
  recentLearnings: Learning[]
  learningStats: LearningStats

  // Identity
  identityAccess: Record<IdentityComponent, number>

  // Meta
  uptime: number
  lastUpdate: number
  connected: boolean  // Socket connection status
}
```

### State Updates

```typescript
class StateManager {
  private state: DashboardState
  private listeners: Set<(state: DashboardState) => void>
  private eventStream: EventStream

  async init() {
    // Load persisted state
    await this.loadPersistedState()

    // Connect event stream
    await this.eventStream.connect()

    // Listen for events
    this.eventStream.on('event', this.handleEvent)

    // Start timers
    this.startUptimeTimer()
    this.startSessionCleanup()
  }

  private handleEvent(event: DashboardEvent) {
    switch (event.type) {
      case 'phase':
        this.updateSessionPhase(event)
        break
      case 'learning':
        this.addLearning(event)
        this.triggerFlash()
        break
      case 'identity':
        this.trackIdentityAccess(event)
        break
    }

    this.notify()
  }

  private notify() {
    this.listeners.forEach(fn => fn(this.state))
  }
}
```

---

## Performance Optimizations

### 1. Memoization

```typescript
const SessionCard = React.memo(({ session }) => {
  // Only re-render when session data changes
  return <SessionCardImpl session={session} />
}, (prev, next) => {
  return prev.session.updated === next.session.updated
})
```

### 2. Virtual Scrolling

For large learning lists:

```typescript
import { useVirtualScroll } from './hooks/useVirtualScroll'

const LearningList = ({ learnings }) => {
  const { visibleItems, scrollProps } = useVirtualScroll({
    items: learnings,
    itemHeight: 1,
    viewportHeight: 10
  })

  return (
    <Box {...scrollProps}>
      {visibleItems.map(learning => (
        <LearningItem key={learning.timestamp} learning={learning} />
      ))}
    </Box>
  )
}
```

### 3. Debounced Updates

```typescript
const useDebouncedState = (value: any, delay = 100) => {
  const [debouncedValue, setDebouncedValue] = useState(value)

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => clearTimeout(timer)
  }, [value, delay])

  return debouncedValue
}
```

---

## Keyboard Controls

```typescript
const KeyboardHandler = () => {
  useInput((input, key) => {
    // Quit
    if (input === 'q' || key.ctrl && input === 'c') {
      process.exit(0)
    }

    // Export
    if (input === 'e') {
      exportState()
    }

    // Refresh
    if (input === 'r') {
      refreshState()
    }

    // Toggle animations
    if (input === 'a') {
      toggleAnimations()
    }

    // Future: Navigation
    if (key.upArrow) navigateUp()
    if (key.downArrow) navigateDown()
    if (key.return) selectItem()
  })

  return null
}
```

---

## File Structure

```
src/dashboard-ink/
├── src/
│   ├── index.tsx              # Main entry point
│   ├── App.tsx                # Root component
│   ├── components/
│   │   ├── Header.tsx
│   │   ├── StatsPanel.tsx
│   │   ├── SessionCard.tsx
│   │   ├── PhaseBox.tsx
│   │   ├── IdentityBox.tsx
│   │   ├── LearningItem.tsx
│   │   ├── ProgressBar.tsx
│   │   ├── Sparkline.tsx
│   │   ├── SectionHeader.tsx
│   │   └── CategoryBadge.tsx
│   ├── hooks/
│   │   ├── usePulse.ts
│   │   ├── useFlash.ts
│   │   ├── useAnimatedValue.ts
│   │   ├── useSlideIn.ts
│   │   └── useVirtualScroll.ts
│   ├── state/
│   │   ├── StateManager.ts
│   │   ├── EventStream.ts
│   │   └── types.ts
│   └── utils/
│       ├── colors.ts
│       ├── formatters.ts
│       └── categories.ts
├── bin/
│   └── pilot-dashboard       # CLI wrapper
├── docs/
│   ├── DESIGN.md            # This file
│   └── MIGRATION.md         # Migration guide
├── package.json
├── tsconfig.json
└── README.md
```

---

## Testing Strategy

### Unit Tests
```typescript
describe('SessionCard', () => {
  it('displays session information', () => {
    const { lastFrame } = render(
      <SessionCard session={mockSession} />
    )

    expect(lastFrame()).toContain('pilot-123')
    expect(lastFrame()).toContain('[EXECUTE]')
  })

  it('shows progress bar', () => {
    const { lastFrame } = render(
      <SessionCard session={mockSession} showProgress />
    )

    expect(lastFrame()).toMatch(/█+░+/)
  })
})
```

### Integration Tests
```typescript
describe('Dashboard', () => {
  it('updates when new session added', async () => {
    const { rerender, lastFrame } = render(<App />)

    // Emit session event
    await stateManager.addSession(newSession)

    rerender(<App />)
    expect(lastFrame()).toContain('pilot-new')
  })
})
```

---

## Accessibility

### Screen Reader Support
- Text descriptions for all visual elements
- Semantic structure
- Keyboard navigation

### Color Blindness
- High contrast mode
- Pattern indicators (not just color)
- Configurable color schemes

---

## Configuration

### User Config File
**Path**: `~/.kiro/pilot/dashboard-config.json`

```json
{
  "theme": {
    "primaryColor": "#00ff9f",
    "accentColor": "#00ffff",
    "backgroundColor": "#1a1a1a"
  },
  "animations": {
    "enabled": true,
    "pulseInterval": 1000,
    "flashDuration": 800
  },
  "display": {
    "maxSessions": 10,
    "maxLearnings": 5,
    "showHistory": true,
    "showCategories": true
  },
  "streaming": {
    "enabled": true,
    "fallbackToPolling": true,
    "pollingInterval": 500
  }
}
```

---

## Future Enhancements

### Phase 1 (MVP)
- ✅ All core components
- ✅ Basic animations
- ✅ Event streaming with fallback
- ✅ Session monitoring
- ✅ Learning display

### Phase 2 (Enhanced)
- 🔲 Interactive mode (click sessions)
- 🔲 Search/filter learnings
- 🔲 Export formats (JSON, CSV, HTML)
- 🔲 Session replay from logs
- 🔲 Multi-instance support

### Phase 3 (Advanced)
- 🔲 Historical analytics
- 🔲 Learning database with tags
- 🔲 Custom phase workflows
- 🔲 Plugin system
- 🔲 Web dashboard (same data source)

---

This design provides a comprehensive foundation for a modern, animated, real-time PILOT dashboard using Ink. All components are specified with clear props, behaviors, and visual examples.
