# PILOT Dashboard

Real-time terminal visualization of PILOT system activity.

## Quick Start

```bash
cd src/dashboard

# Install dependencies (requires Bun and Zig)
bun install

# Run dashboard in a separate terminal
bun run start
```

Then use PILOT normally in another terminal - the dashboard will show activity.

## Features

- **Active Sessions**: Shows all running PILOT sessions with unique colors
- **Universal Algorithm**: 7 phase blocks (OBSERVE→THINK→PLAN→BUILD→EXECUTE→VERIFY→LEARN) that light up when active
- **Identity System**: 10 component blocks showing access patterns  
- **Learning Capture**: Flash effect when new learnings are captured

## Architecture

```
~/.kiro/pilot/dashboard/
├── sessions/           # Session state files (JSON)
│   └── pilot-123.json  # {"id":"...", "phase":"EXECUTE", "updated":...}
└── events.jsonl        # Append-only event log
```

## Integration

The dashboard is automatically integrated with PILOT hooks:

- `agent-spawn.sh` - Emits initial OBSERVE phase
- `user-prompt-submit.sh` - Emits phase changes based on prompt analysis
- `stop.sh` - Emits learning captures and cleans up session

### Manual Emission

You can also emit state manually from scripts:

```bash
# Source the emitter library
source ~/.kiro/pilot/lib/dashboard-emitter.sh

# Emit phase change
dashboard_emit_phase EXECUTE

# Emit learning capture
dashboard_emit_learning "Discovered caching pattern"

# Emit identity access
dashboard_emit_identity GOALS

# Cleanup on exit
dashboard_cleanup
```

Or use the standalone script:

```bash
# Set session ID (optional, auto-generated if not set)
export PILOT_SESSION="pilot-$(date +%s)-$$"

# Emit events
./bin/pilot-emit phase OBSERVE
./bin/pilot-emit learning "Discovered new pattern"
./bin/pilot-emit identity GOALS
```

## Installation

After installing PILOT, copy the dashboard emitter to the lib directory:

```bash
cp src/dashboard/../packs/pilot-core/system/lib/dashboard-emitter.sh ~/.kiro/pilot/lib/
```

Or run the PILOT installer which handles this automatically.

## Keyboard

- `q` or `Ctrl+C` - Quit dashboard

## Tech Stack

- [OpenTUI](https://opentui.com) - Terminal UI framework (React integration)
- [Bun](https://bun.sh) - Runtime
- TypeScript + React

## Requirements

- Bun >= 1.0
- Zig (for OpenTUI native code compilation)

## Development

```bash
# Type check (note: OpenTUI types are incomplete in v0.1.x)
bunx tsc --noEmit

# Run with debug console
DEBUG=1 bun run start
```
