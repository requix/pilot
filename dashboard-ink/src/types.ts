// PILOT Dashboard - Ink Implementation
// Type Definitions

export type IdentityComponent =
  | "MISSION" | "GOALS" | "PROJECTS" | "BELIEFS" | "MODELS"
  | "STRATEGIES" | "NARRATIVES" | "LEARNED" | "CHALLENGES" | "IDEAS"

export const IDENTITY_COMPONENTS: IdentityComponent[] = [
  "MISSION", "GOALS", "PROJECTS", "BELIEFS", "MODELS",
  "STRATEGIES", "NARRATIVES", "LEARNED", "CHALLENGES", "IDEAS"
]

export interface IdentityFileStats {
  component: IdentityComponent
  exists: boolean
  lines: number
  bytes: number
  lastModified: number
  accessCount: number
}

export interface SessionMetrics {
  sessionId: string
  prompts: number
  tools: number
  success: number
  failures: number
  hooks?: number
  endedAt?: string
  status?: string
}

export interface SessionState {
  id: string
  color: string
  updated: number
  identityAccess?: IdentityComponent[]
  startTime: number
  commandCount: number
  workingDirectory?: string
  title?: string
  metrics?: SessionMetrics
}

export interface Learning {
  timestamp: number
  sessionId: string
  title: string
  category?: string
  tags?: string[]
}

export interface LearningStats {
  totalCount: number
  categoryCounts: Record<string, number>
  recentRate: number // learnings per hour in last 24h
}

export interface GlobalMetrics {
  totalPrompts: number
  prompts24h: number
  totalTools: number
  totalSuccess: number
  totalFailures: number
  estimatedCost: number  // USD
  sessionCount: number
  successRate: number    // percentage
}

export interface DashboardState {
  // Sessions
  sessions: Record<string, SessionState>
  sessionHistory: SessionState[]

  // Learnings
  recentLearnings: Learning[]
  learningStats: LearningStats

  // Identity tracking
  identityAccess: Record<IdentityComponent, number>
  identityStats: Record<IdentityComponent, IdentityFileStats>

  // Global metrics
  globalMetrics: GlobalMetrics

  // Meta
  uptime: number
  lastUpdate: number
  connected: boolean  // Socket/streaming connection status
}

export interface LearningEvent {
  type: "learning"
  sessionId: string
  title: string
  timestamp: number
  category?: string
  tags?: string[]
}

export interface IdentityEvent {
  type: "identity"
  sessionId: string
  component: IdentityComponent
  timestamp: number
}

export interface CleanupEvent {
  type: "cleanup"
  sessionId: string
  timestamp: number
}

export type DashboardEvent = LearningEvent | IdentityEvent | CleanupEvent

// Color system - Light pastel purple theme
export const COLORS = {
  primary: "#ddd6fe",    // Light lavender
  glow: "#ede9fe",       // Very light lavender
  success: "#bbf7d0",    // Light green
  warning: "#fde68a",    // Light amber
  error: "#fecaca",      // Light red
  info: "#c7d2fe",       // Light indigo
  muted: "#a1a1aa",      // Light gray
  dim: "#71717a",        // Medium gray
  bgDark: "#0f0f1a",     // Deep purple-black
  border: "#5b21b6",     // Purple border
} as const

// Session colors (assigned round-robin) - Light pastels
export const SESSION_COLORS = [
  "#ddd6fe", "#c7d2fe", "#bfdbfe", "#a5f3fc",
  "#e9d5ff", "#f5d0fe", "#fbcfe8", "#fde68a"
]
