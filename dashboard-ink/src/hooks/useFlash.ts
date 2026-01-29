// useFlash - Flash effect hook
// Returns [isFlashing, trigger] where trigger() activates a flash

import { useState, useEffect, useRef } from "react"

export function useFlash(duration: number = 800): [boolean, () => void] {
  const [isFlashing, setIsFlashing] = useState(false)
  const timerRef = useRef<Timer | null>(null)

  const trigger = () => {
    // Clear any existing timer
    if (timerRef.current) {
      clearTimeout(timerRef.current)
    }

    setIsFlashing(true)
    timerRef.current = setTimeout(() => {
      setIsFlashing(false)
      timerRef.current = null
    }, duration)
  }

  useEffect(() => {
    return () => {
      if (timerRef.current) {
        clearTimeout(timerRef.current)
      }
    }
  }, [])

  return [isFlashing, trigger]
}
