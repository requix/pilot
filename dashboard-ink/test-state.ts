#!/usr/bin/env bun
// Quick test of state loading

import { StateManager } from "./src/state"

const sm = new StateManager()
await sm.init()

const state = sm.getState()
console.log("Sessions:", Object.keys(state.sessions).length)
console.log("History:", state.sessionHistory.length)
console.log("Uptime:", state.uptime)

if (Object.keys(state.sessions).length > 0) {
  console.log("Active session IDs:", Object.keys(state.sessions))
}

process.exit(0)
