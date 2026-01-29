# PILOT Dashboard - Ink Implementation

**Version 2.0** - Modern, real-time TUI dashboard for monitoring PILOT sessions, learnings, and the Universal Algorithm.

Built with [Ink](https://github.com/vadimdemedes/ink) - a mature React-based terminal UI library.

## Features

- **Real-time Session Monitoring**: Track active PILOT sessions with live updates
- **Universal Algorithm Visualization**: See which phases are active across all sessions
- **Identity System Tracking**: Monitor which identity components are being accessed
- **Learning Capture**: Display recent learnings with category classification
- **Statistics Dashboard**: View learning rates, session counts, and uptime
- **Modern TUI Aesthetics**: Rounded borders, color coding, animations
- **Keyboard Controls**: Simple, intuitive interface

## Quick Start

### Installation

```bash
cd src/dashboard-ink
bun install
```

### Run Dashboard

```bash
bun run start
```

Or for development with hot reload:

```bash
bun run dev
```

### Build Executable

```bash
bun run build
```

This creates a standalone `pilot-dashboard` executable.

## Architecture

### Data Flow

```
CLI/Hooks → ~/.kiro/pilot/dashboard/
              ├── sessions/*.json (active sessions)
              └── events.jsonl (event log)
                    ↓
              Dashboard (polls every 500ms)
                    ↓
              React Components → Terminal Display
```

### Components

**Foundation:**
- `types.ts` - TypeScript type definitions
- `state.ts` - State management and file polling
- `utils.ts` - Utility functions (formatting, progress bars, sparklines)

**Hooks:**
- `usePulse` - Pulsing animation for active phases
- `useFlash` - Flash effect for new learnings
- `useAnimatedValue` - Smooth value transitions
- `useSlideIn` - Slide-in animations

**UI Components:**
- `Header` - Dashboard title and controls
- `StatsCard` - Metric display cards
- `SessionCard` - Active session information
- `PhaseBox` - Algorithm phase visualization
- `IdentityBox` - Identity component display
- `LearningItem` - Learning entry display
- `CategoryBadge` - Category classification
- `ProgressBar` - Visual progress indicator
- `Sparkline` - Mini trend charts
- `SectionHeader` - Section dividers

### State Management

The `StateManager` class handles:
- Loading session data from `~/.kiro/pilot/dashboard/sessions/*.json`
- Loading event log from `~/.kiro/pilot/dashboard/events.jsonl`
- Polling for updates every 500ms
- Notifying React components of state changes
- Tracking uptime and connection status

## Usage

### Keyboard Controls

- `q` - Quit dashboard
- `e` - Export current state to JSON
- `Ctrl+C` - Force quit

### Data Sources

The dashboard reads data from:

1. **Session Files**: `~/.kiro/pilot/dashboard/sessions/pilot-*.json`
   - Created by PILOT hooks during execution
   - Contains session state, phase, working directory, etc.

2. **Event Log**: `~/.kiro/pilot/dashboard/events.jsonl`
   - Append-only log of events (learnings, phase changes, identity access)
   - Used for historical data and statistics

### Event Emission

Events are emitted from PILOT hooks using `dashboard-emitter.sh`:

```bash
source ~/.kiro/pilot/lib/dashboard-emitter.sh

# Emit phase change
dashboard_emit_phase EXECUTE "Implementing feature"

# Emit learning
dashboard_emit_learning "Discovered useful pattern" architecture

# Emit identity access
dashboard_emit_identity GOALS

# Cleanup on session end
dashboard_cleanup
```

## Development

### Project Structure

```
dashboard-ink/
├── index.tsx           # Entry point
├── package.json        # Dependencies and scripts
├── src/
│   ├── App.tsx         # Main app component
│   ├── types.ts        # Type definitions
│   ├── state.ts        # State management
│   ├── utils.ts        # Utility functions
│   ├── components/     # UI components
│   │   ├── Header.tsx
│   │   ├── SessionCard.tsx
│   │   ├── PhaseBox.tsx
│   │   └── ...
│   └── hooks/          # Custom hooks
│       ├── usePulse.ts
│       ├── useFlash.ts
│       └── ...
├── docs/
│   ├── DESIGN.md       # Component specifications
│   └── PLAN.md         # Implementation plan
└── README.md           # This file
```

### Adding New Components

1. Create component in `src/components/`
2. Export from `src/components/index.ts`
3. Import and use in `src/App.tsx`

### Customization

**Colors**: Edit `COLORS` and `PHASE_COLORS` in `src/types.ts`

**Polling Interval**: Change `POLL_INTERVAL` in `src/state.ts` (default: 500ms)

**Category Detection**: Update `detectCategory()` in `src/utils.ts`

## Comparison with OpenTUI Version

### Why Ink?

The original dashboard was built with OpenTUI v0.1.73, which proved unstable:
- Frequent segmentation faults
- Limited prop support
- Crashes with modern components
- Early development (v0.1.x)

**Ink advantages:**
- Mature and stable (no crashes)
- Full prop support (justifyContent, alignItems, etc.)
- Rich component ecosystem
- Active development and community
- Better documentation

### Migration Effort

This Ink implementation took approximately 16 hours to complete:
- Phase 1 (Foundation): 4 hours
- Phase 2 (Components): 8 hours
- Phase 3 (Integration): 3 hours
- Phase 4 (Testing & Polish): 1 hour

### Future Enhancements

Planned improvements:
- [ ] Event streaming via Unix domain sockets (<10ms latency)
- [ ] Interactive mode (click sessions for details)
- [ ] Learning filtering and search
- [ ] Phase transition graphs
- [ ] Multi-instance support (remote PILOT instances)
- [ ] Configuration file support

## Troubleshooting

### Dashboard not showing sessions

1. Check that `~/.kiro/pilot/dashboard/sessions/` exists
2. Verify session files are being created by PILOT hooks
3. Check file permissions

### No learnings displayed

1. Verify `~/.kiro/pilot/dashboard/events.jsonl` exists
2. Check that events are being written correctly
3. Review category detection logic

### Performance issues

- Reduce polling interval in `state.ts` (increase from 500ms)
- Limit number of displayed items in `App.tsx`
- Consider implementing virtual scrolling for large lists

## Testing

Run the test suite:

```bash
bun test
```

Test with mock data:

```bash
# In one terminal, start dashboard
bun run start

# In another terminal, emit test events
source ~/.kiro/pilot/lib/dashboard-emitter.sh
export PILOT_SESSION="test-$(date +%s)"
dashboard_emit_phase EXECUTE "Testing dashboard"
dashboard_emit_learning "Dashboard looks great!" testing
```

## License

Part of the PILOT project.

## Credits

Built with:
- [Ink](https://github.com/vadimdemedes/ink) by Vadim Demedes
- [React](https://react.dev/)
- [Bun](https://bun.com) runtime

---

**Status**: ✅ Production Ready

The dashboard is fully functional and ready for use. All core features are implemented and tested.
