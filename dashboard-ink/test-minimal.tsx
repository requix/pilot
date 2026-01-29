#!/usr/bin/env bun
// Minimal test to isolate the issue

import React from "react"
import { render, Box, Text } from "ink"

function TestApp() {
  return (
    <Box flexDirection="column" padding={1}>
      <Text>Testing numeric values:</Text>
      <Text>Number 0: {String(0)}</Text>
      <Text>Number 1: {String(1)}</Text>
      <Text>Array length: {String([].length)}</Text>
    </Box>
  )
}

// Render the app
const { waitUntilExit } = render(<TestApp />)

// Handle exit
waitUntilExit()
  .then(() => {
    process.exit(0)
  })
  .catch(error => {
    console.error("Test error:", error)
    process.exit(1)
  })