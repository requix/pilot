// PILOT Dashboard - Main App Component

import React, { useState, useEffect } from "react"
import { Box, Text, useInput } from "ink"
import { StateManager } from "./state"
import type { DashboardState, IdentityComponent, IdentityFileStats, GlobalMetrics } from "./types"
import {
  Header,
  StatsCard,
  SectionHeader,
  SessionCard,
} from "./components"
import { formatDuration } from "./utils"

const stateManager = new StateManager()

export function App() {
  const [state, setState] = useState<DashboardState>({
    sessions: {},
    recentLearnings: [],
    sessionHistory: [],
    learningStats: { totalCount: 0, categoryCounts: {}, recentRate: 0 },
    identityAccess: {} as Record<IdentityComponent, number>,
    identityStats: {} as Record<IdentityComponent, IdentityFileStats>,
    globalMetrics: {
      totalPrompts: 0,
      prompts24h: 0,
      totalTools: 0,
      totalSuccess: 0,
      totalFailures: 0,
      estimatedCost: 0,
      sessionCount: 0,
      successRate: 100,
    },
    uptime: 0,
    lastUpdate: Date.now(),
    connected: false,
  })

  const [, forceUpdate] = useState({})

  useEffect(() => {
    stateManager.init()
    stateManager.onChange(setState)

    // Update durations every second
    const timer = setInterval(() => {
      forceUpdate({})
    }, 1000)

    return () => {
      clearInterval(timer)
      stateManager.cleanup()
    }
  }, [])

  // Keyboard controls
  useInput((input, key) => {
    if (input === "q" || (key.ctrl && input === "c")) {
      process.exit(0)
    }

    if (input === "e") {
      // Export current state
      const exportData = {
        timestamp: new Date().toISOString(),
        sessions: Object.values(state.sessions),
        sessionHistory: state.sessionHistory,
        recentLearnings: state.recentLearnings,
        learningStats: state.learningStats,
        identityAccess: state.identityAccess,
        uptime: state.uptime,
      }

      const fs = require("fs")
      const path = require("path")
      const exportFile = path.join(
        process.cwd(),
        `pilot-dashboard-export-${Date.now()}.json`
      )

      try {
        fs.writeFileSync(exportFile, JSON.stringify(exportData, null, 2))
        // TODO: Show success message
      } catch (error) {
        // TODO: Show error message
      }
    }
  })

  const sessions = Object.values(state.sessions)
  const uptimeStr = formatDuration(state.uptime)

  return (
    <Box flexDirection="column" padding={1}>
      {/* Header */}
      <Header
        title="PILOT DASHBOARD v2.0"
        subtitle="Real-time session monitoring"
        actions={["q=quit", "e=export"]}
      />

      {/* Stats Overview */}
      <Box marginTop={1} gap={1}>
        <StatsCard label="ACTIVE" value={sessions.length} color="#0ea5e9" />
        <StatsCard label="HISTORY" value={state.sessionHistory.length} color="#38bdf8" />
        <StatsCard label="LEARNED" value={state.learningStats?.totalCount || 0} color="#10b981" />
        <StatsCard label="UPTIME" value={uptimeStr} color="#8b5cf6" />
      </Box>

      {/* Active Sessions */}
      <SectionHeader
        title="Active Sessions"
        count={sessions.length}
        icon="›"
        color="#0ea5e9"
      />

      {sessions.length === 0 ? (
        <Box marginLeft={2} marginTop={1}>
          <Text color="#94a3b8">No active sessions</Text>
        </Box>
      ) : (
        <Box flexDirection="column" marginTop={1}>
          {sessions.map(session => (
            <SessionCard
              key={session.id}
              session={session}
              showProgress={true}
              animated={true}
            />
          ))}
        </Box>
      )}

      {/* Recent Sessions */}
      {state.sessionHistory.length > 0 && (
        <>
          <SectionHeader
            title="Recent Sessions"
            count={state.sessionHistory.length}
            icon="○"
            color="#38bdf8"
          />
          <Box flexDirection="column" marginTop={1} marginLeft={2}>
            {state.sessionHistory.slice(0, 3).map(session => (
              <Box key={session.id}>
                <Text color="#94a3b8">○ </Text>
                <Text color="#e2e8f0">{session.id.slice(0, 20)} </Text>
              </Box>
            ))}
          </Box>
        </>
      )}

    </Box>
  )
}
