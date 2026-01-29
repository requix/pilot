// IdentityBox Component - Display identity component

import React from "react"
import { Box, Text } from "ink"
import type { IdentityComponent } from "../types"

export interface IdentityBoxProps {
  name: IdentityComponent
  active: boolean
  accessCount?: number
}

export function IdentityBox({ name, active, accessCount }: IdentityBoxProps) {
  const color = active ? "#4ECDC4" : "#2a2a2a"

  return (
    <Box
      width={13}
      height={3}
      borderStyle="round"
      borderColor={color}
      paddingX={1}
      flexDirection="column"
      justifyContent="center"
      alignItems="center"
    >
      <Text color={active ? "#4ECDC4" : "#555555"} bold={active}>
        {name === "STRATEGIES" ? "STRATEGY" : name === "NARRATIVES" ? "NARRATIVE" : name === "CHALLENGES" ? "CHALLENGE" : name}
      </Text>
      {accessCount !== undefined && accessCount > 0 && (
        <Text color="#888888" dimColor>
          ·{accessCount}
        </Text>
      )}
    </Box>
  )
}
