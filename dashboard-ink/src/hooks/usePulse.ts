// usePulse - Pulsing animation hook
// Returns true/false at regular intervals for pulsing effects

import { useState, useEffect } from "react"

export function usePulse(interval: number = 1000): boolean {
  const [isPulsing, setIsPulsing] = useState(false)

  useEffect(() => {
    const timer = setInterval(() => {
      setIsPulsing(prev => !prev)
    }, interval)

    return () => clearInterval(timer)
  }, [interval])

  return isPulsing
}
