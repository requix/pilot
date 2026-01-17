// @ts-nocheck
// PILOT Dashboard - React + OpenTUI
// Note: OpenTUI is in early development (v0.1.x), types are incomplete
import React, { useState, useEffect } from "react"
import { createRoot } from "@opentui/react"
import { createCliRenderer } from "@opentui/core"
import { StateManager } from "./state"
import type { AlgorithmPhase, IdentityComponent, DashboardState, DashboardEvent, SessionState, Learning } from "./types"

const PHASES: AlgorithmPhase[] = ["OBSERVE", "THINK", "PLAN", "BUILD", "EXECUTE", "VERIFY", "LEARN"]
const IDENTITY: IdentityComponent[] = ["MISSION", "GOALS", "PROJECTS", "BELIEFS", "MODELS", "STRATEGIES", "NARRATIVES", "LEARNED", "CHALLENGES", "IDEAS"]

const DIM = "#333333"

// Fixed colors for phases (so they're consistent)
const PHASE_COLORS: Record<AlgorithmPhase, string> = {
  OBSERVE: "#4ECDC4",
  THINK: "#45B7D1", 
  PLAN: "#96CEB4",
  BUILD: "#FFEAA7",
  EXECUTE: "#FF6B6B",
  VERIFY: "#DDA0DD",
  LEARN: "#98D8C8",
  IDLE: "#333333"
}

// Session colors (assigned round-robin)
const SESSION_COLORS = [
  "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", 
  "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F"
]

const stateManager = new StateManager()

function PhaseBox({ phase, active }: { phase: AlgorithmPhase; active: boolean }) {
  const bg = active ? PHASE_COLORS[phase] : DIM
  return (
    <box width={10} height={3} backgroundColor={bg} borderStyle="single" borderColor={bg}>
      <text fg={active ? "#000000" : "#666666"}>{phase.slice(0, 7)}</text>
    </box>
  )
}

function IdentityBox({ name, active }: { name: string; active: boolean }) {
  const bg = active ? "#4ECDC4" : DIM
  return (
    <box width={12} height={2} backgroundColor={bg} borderStyle="single" borderColor={bg}>
      <text fg={active ? "#000000" : "#666666"}>{name.slice(0, 10)}</text>
    </box>
  )
}

function SessionLine({ session, index }: { session: SessionState; index: number }) {
  const color = session.color || SESSION_COLORS[index % SESSION_COLORS.length]
  
  // Handle invalid or missing startTime
  const startTime = (session.startTime && session.startTime > 1000000000) ? session.startTime : Math.floor(Date.now() / 1000)
  const duration = Math.floor((Date.now() - (startTime * 1000)) / 1000)
  const durationStr = duration > 60 ? `${Math.floor(duration/60)}m${duration%60}s` : `${Math.max(0, duration)}s`
  
  // Generate session title based on phase and activity
  const sessionTitle = session.title || 
    (session.phase === 'OBSERVE' ? 'Analyzing problem' :
     session.phase === 'THINK' ? 'Exploring solutions' :
     session.phase === 'PLAN' ? 'Creating strategy' :
     session.phase === 'BUILD' ? 'Defining success' :
     session.phase === 'EXECUTE' ? 'Implementing solution' :
     session.phase === 'VERIFY' ? 'Testing results' :
     session.phase === 'LEARN' ? 'Capturing insights' : 'Active session')
  
  return (
    <box flexDirection="column">
      <box flexDirection="row">
        <text fg={color}>● </text>
        <text fg="#FFFFFF">{session.id} </text>
        <text fg={PHASE_COLORS[session.phase] || DIM}>[{session.phase}] </text>
        <text fg="#888888">{durationStr} </text>
        <text fg="#666666">#{session.commandCount || 0}</text>
      </box>
      <box flexDirection="row" marginLeft={2}>
        <text fg="#888888">({sessionTitle})</text>
        {session.workingDirectory && (
          <text fg="#555555"> in {session.workingDirectory.split('/').pop()}</text>
        )}
      </box>
    </box>
  )
}

function LearningLine({ learning }: { learning: Learning }) {
  const timeAgo = Math.floor((Date.now() - learning.timestamp * 1000) / 1000 / 60) // minutes ago
  const timeStr = timeAgo < 60 ? `${timeAgo}m` : `${Math.floor(timeAgo/60)}h`
  const categoryColor = learning.category === 'terraform' ? '#DDA0DD' :
                       learning.category === 'kubernetes' ? '#4ECDC4' :
                       learning.category === 'git' ? '#FF6B6B' :
                       learning.category === 'aws' ? '#FFEAA7' : '#98D8C8'
  
  return (
    <box flexDirection="row">
      <text fg="#98D8C8">✓ </text>
      <text fg={categoryColor}>[{learning.category || 'general'}] </text>
      <text fg="#FFFFFF">{learning.title.slice(0, 35)} </text>
      <text fg="#666666">{timeStr}</text>
    </box>
  )
}

function Dashboard() {
  const [state, setState] = useState<DashboardState>({ 
    sessions: {}, 
    recentLearnings: [], 
    sessionHistory: [],
    learningStats: { totalCount: 0, categoryCounts: {}, recentRate: 0 }
  })
  const [flash, setFlash] = useState(false)
  const [, forceUpdate] = useState({})

  useEffect(() => {
    stateManager.init()
    stateManager.onChange(setState)
    stateManager.onEvent((e: DashboardEvent) => {
      if (e.type === "learning") {
        setFlash(true)
        setTimeout(() => setFlash(false), 500)
      }
    })

    // Update durations every second and auto-export for testing
    const timer = setInterval(() => {
      forceUpdate({})
      
      // Auto-export every 10 seconds for testing (only if DEBUG env var is set)
      if (process.env.DEBUG && Math.floor(Date.now() / 1000) % 10 === 0) {
        const currentState = stateManager.getState()
        const exportData = {
          timestamp: new Date().toISOString(),
          sessions: Object.values(currentState.sessions),
          sessionHistory: currentState.sessionHistory,
          recentLearnings: currentState.recentLearnings,
          learningStats: currentState.learningStats
        }
        const fs = require('fs')
        const path = require('path')
        const exportFile = path.join(__dirname, '..', 'dashboard-state.json')
        try {
          fs.writeFileSync(exportFile, JSON.stringify(exportData, null, 2))
        } catch {}
      }
    }, 1000)

    return () => clearInterval(timer)
  }, [])

  const sessions: SessionState[] = Object.values(state.sessions)
  
  // Build set of active phases from all sessions
  const activePhases = new Set<AlgorithmPhase>()
  sessions.forEach((s) => {
    if (s.phase && s.phase !== "IDLE") {
      activePhases.add(s.phase)
    }
  })
  
  const activeIdentity = new Set(sessions.flatMap((s) => s.identityAccess || []))

  return (
    <box flexDirection="column" padding={1}>
      <text fg="#FFFFFF">⚡ PILOT DASHBOARD  (press q to quit, e to export)</text>

      <text fg="#888888" marginTop={1}>SESSIONS ({sessions.length})</text>
      {sessions.length === 0 ? (
        <text fg={DIM}>No active sessions</text>
      ) : (
        <box flexDirection="column">
          {sessions.map((s, i) => (
            <SessionLine key={s.id} session={s} index={i} />
          ))}
        </box>
      )}

      {state.sessionHistory.length > 0 && (
        <>
          <text fg="#888888" marginTop={1}>RECENT SESSIONS ({state.sessionHistory.length})</text>
          <box flexDirection="column">
            {state.sessionHistory.slice(0, 3).map((s, i) => (
              <box key={s.id} flexDirection="row">
                <text fg="#555555">○ </text>
                <text fg="#888888">{s.id.slice(0, 15)} </text>
                <text fg="#666666">[{s.phase}] </text>
                <text fg="#444444">#{s.commandCount || 0}</text>
              </box>
            ))}
          </box>
        </>
      )}

      <text fg="#888888" marginTop={1}>UNIVERSAL ALGORITHM</text>
      <box flexDirection="row" gap={1}>
        {PHASES.map((phase) => (
          <PhaseBox
            key={phase}
            phase={phase}
            active={activePhases.has(phase)}
          />
        ))}
      </box>

      <text fg="#888888" marginTop={1}>IDENTITY SYSTEM</text>
      <box flexDirection="column" gap={0}>
        <box flexDirection="row" gap={1}>
          {IDENTITY.slice(0, 5).map((comp) => (
            <IdentityBox key={comp} name={comp} active={activeIdentity.has(comp)} />
          ))}
        </box>
        <box flexDirection="row" gap={1}>
          {IDENTITY.slice(5).map((comp) => (
            <IdentityBox key={comp} name={comp} active={activeIdentity.has(comp)} />
          ))}
        </box>
      </box>

      <text fg="#888888" marginTop={1}>LEARNINGS ({state.learningStats.totalCount} total, {state.learningStats.recentRate}/24h)</text>
      <box
        width={75}
        height={6}
        backgroundColor={flash ? "#98D8C8" : DIM}
        borderStyle="single"
        borderColor={flash ? "#FFFFFF" : DIM}
      >
        {state.recentLearnings.length === 0 ? (
          <text fg="#666666">Waiting for learnings...</text>
        ) : (
          <box flexDirection="column">
            {state.recentLearnings.slice(0, 4).map((l, i) => (
              <LearningLine key={i} learning={l} />
            ))}
          </box>
        )}
      </box>

      {Object.keys(state.learningStats.categoryCounts).length > 0 && (
        <>
          <text fg="#888888" marginTop={1}>CATEGORIES</text>
          <box flexDirection="row" gap={1}>
            {Object.entries(state.learningStats.categoryCounts)
              .sort(([,a], [,b]) => b - a)
              .slice(0, 6)
              .map(([cat, count]) => (
                <box key={cat} width={12} height={2} backgroundColor="#333333" borderStyle="single">
                  <text fg="#FFFFFF">{cat} {count}</text>
                </box>
              ))}
          </box>
        </>
      )}
    </box>
  )
}

// Handle quit and export
process.stdin.setRawMode?.(true)
process.stdin.on("data", (data) => {
  const key = data.toString()
  if (key === "q" || key === "\x03") process.exit(0)
  if (key === "e") {
    // Export current state to readable location for testing
    const state = stateManager.getState()
    const exportData = {
      timestamp: new Date().toISOString(),
      sessions: Object.values(state.sessions),
      sessionHistory: state.sessionHistory,
      recentLearnings: state.recentLearnings,
      learningStats: state.learningStats
    }
    const fs = require('fs')
    const path = require('path')
    
    // Save to dashboard directory for easy access
    const exportFile = path.join(__dirname, '..', 'dashboard-state.json')
    fs.writeFileSync(exportFile, JSON.stringify(exportData, null, 2))
    console.log(`\nExported to ${exportFile}`)
    setTimeout(() => process.exit(0), 1000)
  }
})

// Start the app
async function main() {
  const renderer = await createCliRenderer()
  const root = createRoot(renderer)
  root.render(<Dashboard />)
  renderer.start()
}

main().catch(console.error)
