// Header Component - Dashboard title and controls

import React from "react"
import { Box, Text } from "ink"

// Robotic Ghost Pilot - Professional mascot v4
function RoboticGhostPilot() {
  return (
    <Box flexDirection="column" marginRight={2}>
      <Text><Text color="#0ea5e9">{"  ▲"}</Text><Text color="#38bdf8">{"▲▲"}</Text><Text color="#0ea5e9">{"▲"}</Text></Text>
      <Text><Text color="#0ea5e9">{"  ▌"}</Text><Text color="#ffffff">{"◎"}</Text><Text color="#f59e0b">{"◆"}</Text><Text color="#ffffff">{"◎"}</Text><Text color="#0ea5e9">{"▐"}</Text></Text>
      <Text><Text color="#0ea5e9">{"  ▼"}</Text><Text color="#38bdf8">{"▼"}</Text><Text color="#ffffff">{"▬"}</Text><Text color="#38bdf8">{"▼"}</Text><Text color="#0ea5e9">{"▼"}</Text></Text>
    </Box>
  )
}

export interface HeaderProps {
  title: string
  subtitle?: string
  actions?: string[]
}

export function Header({
  title,
  subtitle,
  actions = ["q=quit", "e=export"],
}: HeaderProps) {
  return (
    <Box flexDirection="column" borderStyle="round" borderColor="#0ea5e9" paddingX={2} paddingY={0}>
      <Box justifyContent="space-between" alignItems="center">
        <Box alignItems="center">
          <RoboticGhostPilot />
          <Box flexDirection="column">
            <Text color="#f8fafc" bold>{title}</Text>
            {subtitle && <Text color="#94a3b8">{subtitle}</Text>}
          </Box>
        </Box>
        <Text color="#94a3b8">
          {actions.join("  ·  ")}
        </Text>
      </Box>
    </Box>
  )
}
