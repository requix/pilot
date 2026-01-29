// ProgressBar Component - Visual progress indicator

import React from "react"
import { Text } from "ink"
import { generateProgressBar } from "../utils"

export interface ProgressBarProps {
  current: number
  max: number
  width?: number
  color?: string
  showLabel?: boolean
  animated?: boolean
  filledChar?: string
  emptyChar?: string
}

export function ProgressBar({
  current,
  max,
  width = 20,
  color = "#00ff9f",
  showLabel = true,
  filledChar = "█",
  emptyChar = "░",
}: ProgressBarProps) {
  const bar = generateProgressBar(current, max, width, filledChar, emptyChar)
  const percentage = Math.min(Math.round((current / max) * 100), 100)

  return (
    <Text color={color}>
      {bar}
      {showLabel && <Text> {percentage}%</Text>}
    </Text>
  )
}
