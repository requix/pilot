// LearningItem Component - Display learning entry

import React from "react"
import { Box, Text } from "ink"
import type { Learning } from "../types"
import { formatTimeAgo, truncate, getCategoryColor } from "../utils"

export interface LearningItemProps {
  learning: Learning
  maxTitleLength?: number
}

export function LearningItem({
  learning,
  maxTitleLength = 50,
}: LearningItemProps) {
  const timeAgo = formatTimeAgo(learning.timestamp)
  const categoryColor = getCategoryColor(learning.category || "general")
  const title = truncate(learning.title, maxTitleLength)

  return (
    <Box>
      <Text color="#98D8C8">✓ </Text>
      <Text color={categoryColor}>[{learning.category || "general"}] </Text>
      <Text color="#FFFFFF">{title} </Text>
      <Text color="#666666">{timeAgo}</Text>
    </Box>
  )
}
