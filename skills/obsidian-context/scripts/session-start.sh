#!/bin/bash
set -euo pipefail

VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian"
TODAY=$(date +%Y-%m-%d)

# Read stdin (hook input)
INPUT=$(cat)

# Skip on resume
SOURCE=$(echo "$INPUT" | jq -r '.source // empty' 2>/dev/null || true)
if [[ "$SOURCE" == "resume" ]]; then
  exit 0
fi

CONTEXT=""

# 1. Tasks
TASKS_FILE="$VAULT/tasks.md"
if [[ -f "$TASKS_FILE" ]]; then
  TASKS_CONTENT=$(cat "$TASKS_FILE" 2>/dev/null || true)
  if [[ -n "$TASKS_CONTENT" ]]; then
    CONTEXT="${CONTEXT}## Current Tasks
${TASKS_CONTENT}

"
  fi
fi

# 2. Today's daily note
DAILY_FILE="$VAULT/daily/${TODAY}.md"
if [[ -f "$DAILY_FILE" ]]; then
  DAILY_CONTENT=$(tail -50 "$DAILY_FILE" 2>/dev/null || true)
  if [[ -n "$DAILY_CONTENT" ]]; then
    CONTEXT="${CONTEXT}## Today's Note
${DAILY_CONTENT}

"
  fi
fi

# 3. Recent notes (file names only, last 3)
if [[ -d "$VAULT/note" ]]; then
  RECENT=$(ls -t "$VAULT/note/" 2>/dev/null | head -3 || true)
  if [[ -n "$RECENT" ]]; then
    CONTEXT="${CONTEXT}## Recent Notes
"
    while IFS= read -r f; do
      CONTEXT="${CONTEXT}- ${f}
"
    done <<< "$RECENT"
  fi
fi

# Output as hookSpecificOutput
if [[ -n "$CONTEXT" ]]; then
  jq -n --arg ctx "$CONTEXT" '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $ctx
    }
  }'
fi
