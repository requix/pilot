// PILOT Dashboard State Types

export type AlgorithmPhase = 
  | "OBSERVE" | "THINK" | "PLAN" | "BUILD" 
  | "EXECUTE" | "VERIFY" | "LEARN" | "IDLE"

export type IdentityComponent =
  | "MISSION" | "GOALS" | "PROJECTS" | "BELIEFS" | "MODELS"
  | "STRATEGIES" | "NARRATIVES" | "LEARNED" | "CHALLENGES" | "IDEAS"

export interface SessionState {
  id: string
  color: string
  phase: AlgorithmPhase
  updated: number
  identityAccess?: IdentityComponent[]
  startTime: number
  commandCount: number
  workingDirectory?: string
  phaseHistory: { phase: AlgorithmPhase; timestamp: number }[]
  title?: string
}

export interface DashboardState {
  sessions: Record<string, SessionState>
  recentLearnings: Learning[]
  sessionHistory: SessionState[]
  learningStats: {
    totalCount: number
    categoryCounts: Record<string, number>
    recentRate: number // learnings per hour in last 24h
  }
}

export interface Learning {
  timestamp: number
  sessionId: string
  title: string
  category?: string
  tags?: string[]
}

export interface PhaseEvent {
  type: "phase"
  sessionId: string
  phase: AlgorithmPhase
  timestamp: number
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

export type DashboardEvent = PhaseEvent | LearningEvent | IdentityEvent
