// SessionCard Component - Display session information

import React from "react"
import { Box, Text } from "ink"
import type { SessionState } from "../types"
import { formatDuration, getShortPath } from "../utils"

export interface SessionCardProps {
  session: SessionState
  showProgress?: boolean
  animated?: boolean
}

export function SessionCard({
  session,
  showProgress = true,
  animated = true,
}: SessionCardProps) {
  const now = Math.floor(Date.now() / 1000)
  const duration = now - session.startTime
  const durationStr = formatDuration(duration)

  const title = session.title || generateSessionTitle(session.workingDirectory)

  function generateSessionTitle(workingDir?: string): string {
    if (!workingDir) return "Active session"
    
    const projectName = workingDir.split("/").pop()
    if (projectName && projectName !== "~" && projectName !== "") {
      return `Working on ${projectName}`
    }
    return "Active session"
  }

  const metrics = session.metrics

  return (
    <Box
      flexDirection="column"
      borderStyle="round"
      borderColor="#334155"
      paddingX={1}
      paddingY={0}
      marginBottom={1}
    >
      {/* Session header */}
      <Box>
        <Text color={session.color}>● </Text>
        <Text color="#f8fafc" bold>
          {session.id.slice(0, 20)}
        </Text>
        <Text color="#94a3b8"> · </Text>
        <Text color="#e2e8f0">{durationStr}</Text>
      </Box>

      {/* Session title */}
      <Box marginLeft={2}>
        <Text color="#e2e8f0">{title}</Text>
      </Box>

      {/* Working directory */}
      {session.workingDirectory && (
        <Box marginLeft={2}>
          <Text color="#94a3b8">
            {getShortPath(session.workingDirectory)}
          </Text>
        </Box>
      )}

      {/* Identity access */}
      {session.identityAccess && session.identityAccess.length > 0 && (
        <Box marginLeft={2}>
          <Text color="#8b5cf6">◇ </Text>
          <Text color="#c4b5fd">
            {session.identityAccess.slice(0, 3).join(", ")}
            {session.identityAccess.length > 3 && ` +${String(session.identityAccess.length - 3)} more`}
          </Text>
        </Box>
      )}

      {/* Metrics row - show prompts, tools, hooks and commands */}
      {(metrics?.prompts || metrics?.tools || metrics?.hooks || session.commandCount > 1) && (
        <Box marginLeft={2} marginTop={0}>
          <Text color="#0ea5e9">◆ </Text>
          {metrics?.prompts && (
            <>
              <Text color="#e2e8f0">{String(metrics.prompts)} prompts</Text>
              {(metrics?.tools || metrics?.hooks || session.commandCount > 1) && <Text color="#94a3b8"> · </Text>}
            </>
          )}
          {metrics?.tools && (
            <>
              <Text color="#e2e8f0">{String(metrics.tools)} tool calls</Text>
              {(metrics?.hooks || session.commandCount > 1) && <Text color="#94a3b8"> · </Text>}
            </>
          )}
          {metrics?.hooks && (
            <>
              <Text color="#e2e8f0">{String(metrics.hooks)} hooks</Text>
              {session.commandCount > 1 && <Text color="#94a3b8"> · </Text>}
            </>
          )}
          {session.commandCount > 1 && (
            <Text color="#e2e8f0">{String(session.commandCount)} commands</Text>
          )}
        </Box>
      )}
    </Box>
  )
}
