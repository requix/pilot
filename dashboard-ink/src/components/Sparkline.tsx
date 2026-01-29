// Sparkline Component - Mini-chart for trend visualization

import React from "react"
import { Text } from "ink"
import { generateSparkline } from "../utils"

export interface SparklineProps {
  data: number[]
  width?: number
  color?: string
}

export function Sparkline({
  data,
  color = "#00ff9f",
}: SparklineProps) {
  const chart = generateSparkline(data)

  return <Text color={color}>{chart}</Text>
}
