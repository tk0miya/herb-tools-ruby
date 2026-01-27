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

# Check if command starts with bin/ and the file exists
if [[ "$COMMAND" =~ ^bin/([^[:space:]]+) ]]; then
  BIN_FILE="${BASH_REMATCH[1]}"
  ABSOLUTE_BIN="${PROJECT_ROOT}/bin/${BIN_FILE}"

  if [ -f "$ABSOLUTE_BIN" ]; then
    NEW_COMMAND="${PROJECT_ROOT}/${COMMAND}"

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
fi

exit 0
