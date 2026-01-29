// CategoryBadge Component - Display category badge

import React from "react"
import { Box, Text } from "ink"
import { getCategoryColor } from "../utils"

export interface CategoryBadgeProps {
  category: string
  count?: number
}

export function CategoryBadge({ category, count }: CategoryBadgeProps) {
  const color = getCategoryColor(category)

  return (
    <Box
      borderStyle="single"
      borderColor="#2a2a2a"
      paddingX={1}
      minWidth={12}
    >
      <Text color={color}>{category}</Text>
      {count !== undefined && (
        <Text color="#888888"> {count}</Text>
      )}
    </Box>
  )
}
