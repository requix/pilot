// State manager - watches files for PILOT session state changes
// Uses polling for reliability (fs.watch is unreliable on macOS)

import { readdir, readFile, mkdir, stat } from "fs/promises"
import { join } from "path"
import { homedir } from "os"
import type { SessionState, DashboardState, DashboardEvent, Learning } from "./types"

const DASHBOARD_DIR = join(homedir(), ".kiro", "pilot", "dashboard")
const SESSIONS_DIR = join(DASHBOARD_DIR, "sessions")
const EVENTS_FILE = join(DASHBOARD_DIR, "events.jsonl")

const POLL_INTERVAL = 500 // ms

// Session colors (assigned round-robin)
const COLORS = [
  "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", 
  "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F"
]

export class StateManager {
  private state: DashboardState = { 
    sessions: {}, 
    recentLearnings: [], 
    sessionHistory: [],
    learningStats: { totalCount: 0, categoryCounts: {}, recentRate: 0 }
  }
  private colorIndex = 0
  private listeners: ((state: DashboardState) => void)[] = []
  private eventListeners: ((event: DashboardEvent) => void)[] = []
  private lastEventLine = 0
  private sessionMtimes: Map<string, number> = new Map()
  private allLearnings: Learning[] = []
  private dashboardStartTime = Date.now()

  async init() {
    await mkdir(SESSIONS_DIR, { recursive: true })
    await this.loadSessions()
    await this.loadEvents()
    
    // Start polling
    setInterval(() => this.poll(), POLL_INTERVAL)
  }

  getState(): DashboardState {
    return this.state
  }

  onChange(fn: (state: DashboardState) => void) {
    this.listeners.push(fn)
    // Immediately call with current state
    fn(this.state)
  }

  onEvent(fn: (event: DashboardEvent) => void) {
    this.eventListeners.push(fn)
  }

  private notify() {
    // Create new object reference to trigger React re-render
    this.state = { ...this.state, sessions: { ...this.state.sessions } }
    this.listeners.forEach(fn => fn(this.state))
  }

  private notifyEvent(event: DashboardEvent) {
    this.eventListeners.forEach(fn => fn(event))
  }

  private async poll() {
    await this.pollSessions()
    await this.pollEvents()
  }

  private async pollSessions() {
    try {
      const files = await readdir(SESSIONS_DIR)
      const currentIds = new Set<string>()
      const now = Date.now()
      
      for (const file of files.filter(f => f.endsWith(".json"))) {
        const path = join(SESSIONS_DIR, file)
        const stats = await stat(path).catch(() => null)
        if (!stats) continue
        
        // Only remove sessions that were stale BEFORE dashboard started
        // This prevents cleaning up active sessions when dashboard restarts
        const lastModified = stats.mtimeMs
        const staleThreshold = this.dashboardStartTime - 600000 // 10 minutes before dashboard start
        if (lastModified < staleThreshold) {
          // Move to history before removing file
          const id = file.replace(".json", "")
          if (this.state.sessions[id]) {
            this.state.sessionHistory = [this.state.sessions[id], ...this.state.sessionHistory].slice(0, 10)
            delete this.state.sessions[id]
          }
          // Remove stale file
          try {
            const fs = await import('fs')
            fs.unlinkSync(path)
          } catch {}
          continue
        }
        
        const mtime = stats.mtimeMs
        const lastMtime = this.sessionMtimes.get(file) || 0
        
        if (mtime > lastMtime) {
          this.sessionMtimes.set(file, mtime)
          await this.loadSession(path)
        }
        
        // Track which sessions still exist
        const id = file.replace(".json", "")
        currentIds.add(id)
      }
      
      // Remove sessions whose files were deleted
      let changed = false
      for (const id of Object.keys(this.state.sessions)) {
        if (!currentIds.has(id)) {
          // Move to history before removing
          const session = this.state.sessions[id]
          if (session) {
            this.state.sessionHistory = [session, ...this.state.sessionHistory].slice(0, 10)
          }
          delete this.state.sessions[id]
          changed = true
        }
      }
      if (changed) this.notify()
      
    } catch { /* dir may not exist yet */ }
  }

  private async loadSessions() {
    try {
      const files = await readdir(SESSIONS_DIR)
      for (const file of files.filter(f => f.endsWith(".json"))) {
        const path = join(SESSIONS_DIR, file)
        const stats = await stat(path).catch(() => null)
        if (stats) {
          this.sessionMtimes.set(file, stats.mtimeMs)
          await this.loadSession(path)
        }
      }
    } catch { /* dir may not exist yet */ }
  }

  private async loadSession(path: string) {
    try {
      const content = await readFile(path, "utf-8")
      const data = JSON.parse(content)
      const id = data.id
      
      // Get file modification time as fallback start time
      const stats = await stat(path).catch(() => null)
      const fileStartTime = stats ? Math.floor(stats.birthtimeMs / 1000) : Math.floor(Date.now() / 1000)
      
      // Preserve existing session data or set defaults
      const existingSession = this.state.sessions[id]
      
      if (!existingSession) {
        // New session
        data.color = COLORS[this.colorIndex++ % COLORS.length]
        // Use valid startTime from data, or file creation time, or current time
        data.startTime = (data.startTime && data.startTime > 1000000000) ? data.startTime : fileStartTime
        data.commandCount = data.commandCount || 1
        data.phaseHistory = data.phaseHistory || []
      } else {
        // Existing session - preserve critical data
        data.color = existingSession.color
        // Keep existing startTime if valid, otherwise use file time
        data.startTime = (existingSession.startTime && existingSession.startTime > 1000000000) ? 
                        existingSession.startTime : fileStartTime
        // Use the command count from the file (which should be incremented by emitter)
        data.commandCount = data.commandCount || existingSession.commandCount || 1
        data.phaseHistory = existingSession.phaseHistory || []
        
        // Track phase changes
        if (existingSession.phase && existingSession.phase !== data.phase) {
          data.phaseHistory.push({ phase: data.phase, timestamp: Date.now() })
          data.phaseHistory = data.phaseHistory.slice(-20)
        }
      }
      
      this.state.sessions[id] = data
      this.notify()
    } catch { /* ignore parse errors */ }
  }

  private async pollEvents() {
    try {
      const content = await readFile(EVENTS_FILE, "utf-8").catch(() => "")
      if (!content) return
      
      const lines = content.trim().split("\n")
      
      // Only process new lines
      if (lines.length > this.lastEventLine) {
        const newLines = lines.slice(this.lastEventLine)
        this.lastEventLine = lines.length
        
        for (const line of newLines) {
          try {
            const event = JSON.parse(line) as DashboardEvent
            this.handleEvent(event)
          } catch { /* skip bad lines */ }
        }
      }
    } catch { /* file may not exist */ }
  }

  private async loadEvents() {
    try {
      const content = await readFile(EVENTS_FILE, "utf-8").catch(() => "")
      if (!content) return
      
      const lines = content.trim().split("\n")
      this.lastEventLine = lines.length
      
      // Load all learnings for stats
      this.allLearnings = []
      for (const line of lines) {
        try {
          const event = JSON.parse(line) as DashboardEvent
          if (event.type === "learning") {
            const learning: Learning = {
              timestamp: event.timestamp,
              sessionId: event.sessionId,
              title: event.title,
              category: event.category || this.extractCategory(event.title),
              tags: event.tags || this.extractTags(event.title)
            }
            this.allLearnings.push(learning)
          }
        } catch { /* skip */ }
      }
      
      // Update recent learnings and stats
      this.state.recentLearnings = this.allLearnings.slice(-10)
      this.updateLearningStats()
    } catch { /* file may not exist */ }
  }

  private handleEvent(event: DashboardEvent) {
    if (event.type === "learning") {
      const learning: Learning = {
        timestamp: event.timestamp,
        sessionId: event.sessionId,
        title: event.title,
        category: event.category || this.extractCategory(event.title),
        tags: event.tags || this.extractTags(event.title)
      }
      this.allLearnings.push(learning)
      this.state.recentLearnings = [learning, ...this.state.recentLearnings].slice(0, 10)
      this.updateLearningStats()
      this.notify()
    }
    this.notifyEvent(event)
  }

  private extractCategory(title: string): string {
    const lower = title.toLowerCase()
    if (lower.includes('terraform') || lower.includes('tf ')) return 'terraform'
    if (lower.includes('kubernetes') || lower.includes('k8s')) return 'kubernetes'
    if (lower.includes('git ') || lower.includes('stash') || lower.includes('commit')) return 'git'
    if (lower.includes('aws') || lower.includes('cloud') || lower.includes('s3') || lower.includes('ec2')) return 'aws'
    if (lower.includes('docker') || lower.includes('container')) return 'docker'
    if (lower.includes('bash') || lower.includes('shell') || lower.includes('script')) return 'bash'
    if (lower.includes('database') || lower.includes('sql') || lower.includes('postgres') || lower.includes('mysql')) return 'database'
    if (lower.includes('python') || lower.includes('py ')) return 'python'
    if (lower.includes('javascript') || lower.includes('js ') || lower.includes('node')) return 'javascript'
    if (lower.includes('react') || lower.includes('vue') || lower.includes('angular')) return 'frontend'
    return 'general'
  }

  private extractTags(title: string): string[] {
    const tags: string[] = []
    const lower = title.toLowerCase()
    if (lower.includes('error') || lower.includes('fix')) tags.push('troubleshooting')
    if (lower.includes('performance') || lower.includes('optimize')) tags.push('performance')
    if (lower.includes('security')) tags.push('security')
    if (lower.includes('config')) tags.push('configuration')
    return tags
  }

  private updateLearningStats() {
    const now = Date.now()
    const last24h = now - (24 * 60 * 60 * 1000)
    
    // Count categories
    const categoryCounts: Record<string, number> = {}
    let recent24hCount = 0
    
    for (const learning of this.allLearnings) {
      const category = learning.category || 'general'
      categoryCounts[category] = (categoryCounts[category] || 0) + 1
      
      if (learning.timestamp * 1000 > last24h) {
        recent24hCount++
      }
    }
    
    this.state.learningStats = {
      totalCount: this.allLearnings.length,
      categoryCounts,
      recentRate: Math.round(recent24hCount * 10) / 10 // learnings per 24h
    }
  }
}
