// PILOT Dashboard - Utility Functions

import type { Learning } from "./types"

/**
 * Format duration in seconds to human-readable string
 */
export function formatDuration(seconds: number): string {
  if (seconds < 60) {
    return `${Math.max(0, Math.floor(seconds))}s`
  }

  const minutes = Math.floor(seconds / 60)
  const remainingSeconds = seconds % 60

  if (minutes < 60) {
    return `${minutes}m${Math.floor(remainingSeconds)}s`
  }

  const hours = Math.floor(minutes / 60)
  const remainingMinutes = minutes % 60

  return `${hours}h ${remainingMinutes}m`
}

/**
 * Format timestamp as "X ago" string
 */
export function formatTimeAgo(timestamp: number): string {
  const now = Math.floor(Date.now() / 1000)
  const diff = now - timestamp

  if (diff < 60) {
    return `${diff}s ago`
  }

  const minutes = Math.floor(diff / 60)
  if (minutes < 60) {
    return `${minutes}m ago`
  }

  const hours = Math.floor(minutes / 60)
  if (hours < 24) {
    return `${hours}h ago`
  }

  const days = Math.floor(hours / 24)
  return `${days}d ago`
}

/**
 * Generate progress bar using block characters
 */
export function generateProgressBar(
  current: number,
  max: number,
  width: number = 20,
  filledChar: string = "█",
  emptyChar: string = "░"
): string {
  const percentage = Math.min(Math.max(current / max, 0), 1)
  const filled = Math.floor(percentage * width)
  const empty = width - filled

  return filledChar.repeat(filled) + emptyChar.repeat(empty)
}

/**
 * Generate sparkline using block characters
 */
export function generateSparkline(data: number[]): string {
  if (data.length === 0) return ""

  const chars = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
  const min = Math.min(...data)
  const max = Math.max(...data)
  const range = max - min

  if (range === 0) {
    return chars[0].repeat(data.length)
  }

  return data
    .map(value => {
      const normalized = (value - min) / range
      const index = Math.min(Math.floor(normalized * chars.length), chars.length - 1)
      return chars[index]
    })
    .join("")
}

/**
 * Detect category from learning title
 */
export function detectCategory(title: string, tags?: string[]): string {
  const lowerTitle = title.toLowerCase()

  // Check tags first
  if (tags && tags.length > 0) {
    return tags[0]
  }

  // Detect from content
  const categories = {
    terraform: ["terraform", "tf", "hcl", "tfstate"],
    kubernetes: ["kubernetes", "k8s", "kubectl", "pod", "deployment", "namespace"],
    docker: ["docker", "dockerfile", "container", "image"],
    git: ["git", "commit", "branch", "merge", "rebase", "stash"],
    aws: ["aws", "s3", "ec2", "lambda", "cloudformation"],
    azure: ["azure", "az"],
    gcp: ["gcp", "google cloud"],
    typescript: ["typescript", "ts", "type"],
    javascript: ["javascript", "js", "node"],
    python: ["python", "py", "pip"],
    bash: ["bash", "shell", "sh"],
    sql: ["sql", "postgres", "mysql", "database"],
    api: ["api", "rest", "graphql", "endpoint"],
    security: ["security", "auth", "oauth", "jwt", "encryption"],
    testing: ["test", "testing", "jest", "mocha"],
    ci: ["ci", "cd", "github actions", "jenkins", "pipeline"],
  }

  for (const [category, keywords] of Object.entries(categories)) {
    if (keywords.some(keyword => lowerTitle.includes(keyword))) {
      return category
    }
  }

  return "general"
}

/**
 * Truncate string with ellipsis
 */
export function truncate(str: string, maxLength: number): string {
  if (str.length <= maxLength) return str
  return str.slice(0, maxLength - 3) + "..."
}

/**
 * Get short directory path (last 2 segments)
 */
export function getShortPath(path: string, segments: number = 2): string {
  const parts = path.split("/").filter(Boolean)
  if (parts.length <= segments) return path
  return ".../" + parts.slice(-segments).join("/")
}

/**
 * Calculate learning rate (per 24h) from recent learnings
 */
export function calculateLearningRate(learnings: Learning[]): number {
  const now = Date.now()
  const oneDayAgo = now - 24 * 60 * 60 * 1000

  const recentCount = learnings.filter(
    l => l.timestamp * 1000 >= oneDayAgo
  ).length

  return recentCount
}

/**
 * Group learnings by category
 */
export function groupLearningsByCategory(
  learnings: Learning[]
): Record<string, number> {
  return learnings.reduce((acc, learning) => {
    const category = learning.category || "general"
    acc[category] = (acc[category] || 0) + 1
    return acc
  }, {} as Record<string, number>)
}

/**
 * Validate timestamp (must be Unix timestamp in seconds, reasonable range)
 */
export function validateTimestamp(timestamp: number): number {
  // Must be > 2020-01-01 and < 2050-01-01
  if (timestamp < 1577836800 || timestamp > 2524608000) {
    return Math.floor(Date.now() / 1000)
  }
  return timestamp
}

/**
 * Get color for category
 */
export function getCategoryColor(category: string): string {
  const colorMap: Record<string, string> = {
    terraform: "#DDA0DD",
    kubernetes: "#4ECDC4",
    docker: "#45B7D1",
    git: "#FF6B6B",
    aws: "#FFEAA7",
    azure: "#00ffff",
    gcp: "#96CEB4",
    typescript: "#45B7D1",
    javascript: "#FFEAA7",
    python: "#4ECDC4",
    bash: "#888888",
    sql: "#DDA0DD",
    api: "#00ff9f",
    security: "#FF6B6B",
    testing: "#98D8C8",
    ci: "#F7DC6F",
    general: "#888888",
  }

  return colorMap[category] || "#888888"
}
