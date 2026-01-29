// useAnimatedValue - Smooth value transition hook
// Animates from current value to target value over specified duration

import { useState, useEffect, useRef } from "react"

export function useAnimatedValue(
  targetValue: number,
  duration: number = 300
): number {
  const [currentValue, setCurrentValue] = useState(targetValue)
  const startValueRef = useRef(targetValue)
  const startTimeRef = useRef<number | null>(null)
  const frameRef = useRef<number | null>(null)

  useEffect(() => {
    startValueRef.current = currentValue
    startTimeRef.current = Date.now()

    const animate = () => {
      const now = Date.now()
      const elapsed = now - (startTimeRef.current || now)
      const progress = Math.min(elapsed / duration, 1)

      // Easing function (ease-out)
      const eased = 1 - Math.pow(1 - progress, 3)

      const newValue =
        startValueRef.current +
        (targetValue - startValueRef.current) * eased

      setCurrentValue(newValue)

      if (progress < 1) {
        frameRef.current = requestAnimationFrame(animate) as unknown as number
      }
    }

    // Start animation if value changed
    if (targetValue !== currentValue) {
      frameRef.current = requestAnimationFrame(animate) as unknown as number
    }

    return () => {
      if (frameRef.current !== null) {
        cancelAnimationFrame(frameRef.current)
      }
    }
  }, [targetValue, duration])

  return currentValue
}
