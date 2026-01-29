import { readFile, stat } from "fs/promises"
import { join } from "path"
import { homedir } from "os"

const HOT_DIR = join(homedir(), ".kiro", "pilot", "memory", "hot")
const SESSION_FILE = join(HOT_DIR, "current-session.jsonl")

export interface Session {
  id: string
  timestamp: number
  messages: Array<{ role: string; content: string; timestamp: number }>
  metrics?: { duration?: number; toolUses?: number; errors?: number }
}

export interface DashboardState {
  sessions: Record<string, Session>
  sessionHistory: Session[]
  isLoading: boolean
  error?: string
  startTime: number
  uptime: number
  recentLearnings: unknown[]
  learningStats: { totalCount: number; categoryCounts: Record<string, number>; recentRate: number }
  identityAccess: Record<string, number>
  identityStats: Record<string, unknown>
  globalMetrics: unknown
  lastUpdate: number
  connected: boolean
}

export class StateManager {
  private state: DashboardState = {
    sessions: {},
    sessionHistory: [],
    isLoading: false,
    startTime: Date.now(),
    uptime: 0,
    recentLearnings: [],
    learningStats: { totalCount: 0, categoryCounts: {}, recentRate: 0 },
    identityAccess: {},
    identityStats: {},
    globalMetrics: {},
    lastUpdate: Date.now(),
    connected: true
  }
  private listeners: Array<() => void> = []
  private lastMtime = 0

  subscribe(l: () => void) { this.listeners.push(l); return () => { const i = this.listeners.indexOf(l); if (i > -1) this.listeners.splice(i, 1) } }
  init() { return this.initialize() }
  onChange(cb: (s: DashboardState) => void) { this.listeners.push(() => cb(this.state)) }
  cleanup() { this.listeners = [] }
  getState() { return this.state }
  private notify() { this.state.uptime = (Date.now() - this.state.startTime) / 1000; this.listeners.forEach(l => l()) }

  async initialize() {
    this.state.isLoading = true
    this.notify()
    try {
      await this.loadFromJsonl()
      setInterval(() => { this.loadFromJsonl(); this.notify() }, 2000)
    } catch (e) {
      this.state.error = e instanceof Error ? e.message : "Unknown error"
    } finally {
      this.state.isLoading = false
      this.notify()
    }
  }

  private async loadFromJsonl() {
    try {
      const stats = await stat(SESSION_FILE)
      // Always reload on init (lastMtime starts at 0)
      if (this.lastMtime > 0 && stats.mtimeMs <= this.lastMtime) return
      this.lastMtime = stats.mtimeMs

      const content = await readFile(SESSION_FILE, "utf-8")
      const lines = content.trim().split("\n").filter(Boolean)
      const sessionsMap: Record<string, Session> = {}
      const now = Date.now()
      const activeThreshold = 30 * 60 * 1000 // 30 min

      for (const line of lines) {
        try {
          const entry = JSON.parse(line)
          const id = entry.session_id || "unknown"
          const ts = new Date(entry.timestamp).getTime()
          
          if (!sessionsMap[id]) {
            sessionsMap[id] = { id, timestamp: ts, messages: [] }
          }
          sessionsMap[id].messages.push({
            role: entry.type || "prompt",
            content: entry.prompt || "",
            timestamp: ts
          })
          if (ts > sessionsMap[id].timestamp) sessionsMap[id].timestamp = ts
        } catch { /* skip bad lines */ }
      }

      // Split into active vs history
      const active: Record<string, Session> = {}
      const history: Session[] = []
      
      for (const s of Object.values(sessionsMap)) {
        if (now - s.timestamp < activeThreshold) {
          active[s.id] = s
        } else {
          history.push(s)
        }
      }

      this.state.sessions = active
      this.state.sessionHistory = history.sort((a, b) => b.timestamp - a.timestamp).slice(0, 10)
      this.notify()
    } catch { /* file may not exist */ }
  }
}

export const stateManager = new StateManager()