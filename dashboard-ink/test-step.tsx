#!/usr/bin/env bun
// Step by step test

import React, { useState, useEffect } from "react"
import { render, Box, Text, useInput } from "ink"
import { StateManager } from "./src/state"
import type { DashboardState } from "./src/types"
import { Header, StatsCard, SectionHeader } from "./src/components"
import { formatDuration } from "./src/utils"

const stateManager = new StateManager()

function TestApp() {
  const [state, setState] = useState<DashboardState>({
    sessions: {},
    recentLearnings: [],
    sessionHistory: [],
    learningStats: { totalCount: 0, categoryCounts: {}, recentRate: 0 },
    identityAccess: {} as any,
    identityStats: {} as any,
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

  useEffect(() => {
    stateManager.init()
    stateManager.onChange(setState)
    return () => stateManager.cleanup()
  }, [])

  useInput((input, key) => {
    if (input === "q" || (key.ctrl && input === "c")) {
      process.exit(0)
    }
  })

  const sessions = Object.values(state.sessions)
  const uptimeStr = formatDuration(state.uptime)

  return (
    <Box flexDirection="column" padding={1}>
      <Text>Step 1: Basic text works</Text>
      
      <Text>Step 2: Sessions length: {String(sessions.length)}</Text>
      
      <Text>Step 3: History length: {String(state.sessionHistory.length)}</Text>
      
      <Text>Step 4: Learning count: {String(state.learningStats.totalCount)}</Text>
      
      <Text>Step 5: Uptime: {uptimeStr}</Text>
      
      <Text>Step 6: Testing Header component...</Text>
      <Header
        title="TEST HEADER"
        subtitle="Testing"
        actions={["q=quit"]}
      />
      
      <Text>Step 7: Testing StatsCard component...</Text>
      <StatsCard label="TEST" value={String(sessions.length)} color="#0ea5e9" />
      
      <Text>Step 8: Testing SectionHeader component...</Text>
      <SectionHeader
        title="Test Section"
        count={sessions.length}
        icon="›"
        color="#0ea5e9"
      />
    </Box>
  )
}

// Render the app
const { waitUntilExit } = render(<TestApp />)

waitUntilExit()
  .then(() => process.exit(0))
  .catch(error => {
    console.error("Test error:", error)
    process.exit(1)
  })