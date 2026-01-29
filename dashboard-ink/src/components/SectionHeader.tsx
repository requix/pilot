// SectionHeader Component - Section dividers with style

import React from "react"
import { Box, Text } from "ink"

export interface SectionHeaderProps {
  title: string
  count?: number
  icon?: string
  color?: string
}

export function SectionHeader({
  title,
  count,
  icon = "›",
  color = "#0ea5e9",
}: SectionHeaderProps) {
  return (
    <Box marginTop={1}>
      <Text color={color}>
        {icon}{" "}
      </Text>
      <Text color={color} bold>
        {title}
      </Text>
      {count !== undefined && (
        <Text color="#94a3b8"> · {String(count)}</Text>
      )}
    </Box>
  )
}
