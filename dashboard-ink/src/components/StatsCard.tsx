// StatsCard Component - Display metric with label

import React from "react"
import { Box, Text } from "ink"

export interface StatsCardProps {
  label: string
  value: string | number
  color?: string
  icon?: string
}

export function StatsCard({
  label,
  value,
  color = "#0ea5e9",
  icon,
}: StatsCardProps) {
  return (
    <Box
      flexDirection="column"
      borderStyle="round"
      borderColor="#334155"
      paddingX={1}
      minWidth={13}
    >
      <Text color="#94a3b8">{label}</Text>
      <Box>
        {icon && <Text color={color}>{icon} </Text>}
        <Text color={color} bold>
          {String(value)}
        </Text>
      </Box>
    </Box>
  )
}
