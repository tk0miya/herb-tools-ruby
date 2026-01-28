#!/bin/bash
# Rewrite relative bin/ paths to absolute paths

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Rewrite bin/ paths to absolute paths
# Handles: "bin/rake", "cd foo && bin/rake", "cd foo; bin/rake"
NEW_COMMAND="$COMMAND"
MODIFIED=false

# Pattern: command starts with bin/
if [[ "$COMMAND" =~ ^bin/([^[:space:]]+) ]]; then
  BIN_FILE="${BASH_REMATCH[1]}"
  if [ -f "${PROJECT_ROOT}/bin/${BIN_FILE}" ]; then
    NEW_COMMAND="${PROJECT_ROOT}/bin/${BIN_FILE}${COMMAND#bin/${BIN_FILE}}"
    MODIFIED=true
  fi
fi

# Pattern: && bin/ or ; bin/ (after cd or other commands)
if [[ "$COMMAND" =~ (.*[&\;][[:space:]]*)bin/([^[:space:]]+)(.*) ]]; then
  PREFIX="${BASH_REMATCH[1]}"
  BIN_FILE="${BASH_REMATCH[2]}"
  SUFFIX="${BASH_REMATCH[3]}"
  if [ -f "${PROJECT_ROOT}/bin/${BIN_FILE}" ]; then
    NEW_COMMAND="${PREFIX}${PROJECT_ROOT}/bin/${BIN_FILE}${SUFFIX}"
    MODIFIED=true
  fi
fi

if [ "$MODIFIED" = true ]; then
  # Output JSON with updatedInput
  jq -n --arg cmd "$NEW_COMMAND" '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "updatedInput": {
        "command": $cmd
      }
    }
  }'
fi

exit 0
