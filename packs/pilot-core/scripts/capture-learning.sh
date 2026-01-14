#!/usr/bin/env bash
# capture-learning.sh - Helper to capture learnings
# Usage: capture-learning.sh "Title" "Context" "Learning"

LEARNINGS_DIR="${HOME}/.pilot/learnings"
mkdir -p "$LEARNINGS_DIR"

TITLE="${1:-Untitled}"
CONTEXT="${2:-No context provided}"
LEARNING="${3:-No learning provided}"
DATE=$(date +%Y-%m-%d)
FILE="$LEARNINGS_DIR/$(date +%Y%m%d).md"

{
  echo ""
  echo "## $TITLE - $DATE"
  echo "**Context:** $CONTEXT"
  echo "**Learning:** $LEARNING"
  echo ""
} >> "$FILE"

echo "✅ Learning captured: $FILE"
