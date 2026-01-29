#!/usr/bin/env bun
// PILOT Dashboard - Entry Point

import React from "react"
import { render } from "ink"
import { App } from "./src/App"

// Render the app
const { waitUntilExit } = render(<App />)

// Handle exit
waitUntilExit()
  .then(() => {
    process.exit(0)
  })
  .catch(error => {
    console.error("Dashboard error:", error)
    process.exit(1)
  })