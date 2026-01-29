// IdentityPanel Component - Enhanced Identity System Display

import React from "react"
import { Box, Text } from "ink"
import type { IdentityComponent, IdentityFileStats } from "../types"

export interface IdentityPanelProps {
  stats: Record<IdentityComponent, IdentityFileStats>
  accessCounts: Record<IdentityComponent, number>
}

function formatTimeAgo(timestamp: number): string {
  if (!timestamp) return "never"
  const seconds = Math.floor((Date.now() - timestamp) / 1000)
  if (seconds < 60) return "now"
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m`
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h`
  return `${Math.floor(seconds / 86400)}d`
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes}b`
  return `${(bytes / 1024).toFixed(1)}k`
}

// Short names that fit in display
const SHORT_NAMES: Record<IdentityComponent, string> = {
  MISSION: "MISSION",
  GOALS: "GOALS",
  PROJECTS: "PROJECTS",
  BELIEFS: "BELIEFS",
  MODELS: "MODELS",
  STRATEGIES: "STRATEGY",
  NARRATIVES: "NARRTVE",
  LEARNED: "LEARNED",
  CHALLENGES: "CHALLNG",
  IDEAS: "IDEAS",
}

interface IdentityRowProps {
  stat: IdentityFileStats
  accessCount: number
}

function IdentityRow({ stat, accessCount }: IdentityRowProps) {
  const name = SHORT_NAMES[stat.component]
  const isActive = accessCount > 0
  const color = isActive ? "#4ECDC4" : stat.exists ? "#666666" : "#333333"

  return (
    <Box>
      <Text color={stat.exists ? "#98D8C8" : "#444444"}>{stat.exists ? "\u2713" : "\u2717"} </Text>
      <Text color={color} bold={isActive}>{name.padEnd(9)}</Text>
      <Text color="#666666"> {formatTimeAgo(stat.lastModified).padStart(4)}</Text>
      {accessCount > 0 && <Text color="#888888"> x{accessCount}</Text>}
    </Box>
  )
}

export function IdentityPanel({ stats, accessCounts }: IdentityPanelProps) {
  const components = Object.values(stats)
  const existingCount = components.filter(s => s.exists).length
  const totalAccess = Object.values(accessCounts).reduce((sum, c) => sum + (c || 0), 0)

  // Find most recently modified
  const sortedByModified = [...components].filter(s => s.exists).sort((a, b) => b.lastModified - a.lastModified)
  const mostRecent = sortedByModified[0]

  return (
    <Box flexDirection="column" borderStyle="round" borderColor="#2a2a2a" paddingX={1}>
      {/* Header */}
      <Box marginBottom={1}>
        <Text color="#4ECDC4" bold>IDENTITY SYSTEM </Text>
        <Text color="#666666">({existingCount}/10 defined)</Text>
      </Box>

      {/* Two columns of identity components */}
      <Box flexDirection="row" gap={2}>
        <Box flexDirection="column">
          {components.slice(0, 5).map(stat => (
            <IdentityRow key={stat.component} stat={stat} accessCount={accessCounts[stat.component] || 0} />
          ))}
        </Box>
        <Box flexDirection="column">
          {components.slice(5).map(stat => (
            <IdentityRow key={stat.component} stat={stat} accessCount={accessCounts[stat.component] || 0} />
          ))}
        </Box>
      </Box>

      {/* Summary */}
      <Box marginTop={1} gap={2}>
        {mostRecent && <Text color="#666666">{"\u231B"} Latest: {SHORT_NAMES[mostRecent.component]} ({formatTimeAgo(mostRecent.lastModified)})</Text>}
        {totalAccess > 0 && <Text color="#666666">{"\u26A1"} {totalAccess} accesses this session</Text>}
      </Box>
    </Box>
  )
}
