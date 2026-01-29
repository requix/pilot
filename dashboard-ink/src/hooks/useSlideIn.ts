// useSlideIn - Slide-in animation hook
// For TUI, this implements a fade-in effect with character reveal

import { useState, useEffect } from "react"

export function useSlideIn(
  delay: number = 0,
  duration: number = 300
): boolean {
  const [isVisible, setIsVisible] = useState(delay === 0)

  useEffect(() => {
    if (delay > 0) {
      const timer = setTimeout(() => {
        setIsVisible(true)
      }, delay)

      return () => clearTimeout(timer)
    }
  }, [delay])

  return isVisible
}

/**
 * Hook for revealing text character by character
 */
export function useRevealText(
  text: string,
  speed: number = 50
): string {
  const [revealedLength, setRevealedLength] = useState(0)

  useEffect(() => {
    setRevealedLength(0)

    if (text.length === 0) return

    const timer = setInterval(() => {
      setRevealedLength(prev => {
        if (prev >= text.length) {
          clearInterval(timer)
          return prev
        }
        return prev + 1
      })
    }, speed)

    return () => clearInterval(timer)
  }, [text, speed])

  return text.slice(0, revealedLength)
}
