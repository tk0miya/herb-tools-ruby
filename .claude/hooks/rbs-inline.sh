#!/bin/bash
#
# PostToolUse hook for rbs-inline type generation
#
# This script automatically generates .rbs files when .rb files in lib/ are modified.
# It handles:
# - Edit/Write tool: Regenerates .rbs for modified Ruby files
# - Bash tool: Handles mv/git mv of Ruby files, updating .rbs accordingly
#

set -euo pipefail

# Read JSON input from stdin
input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Function to generate .rbs file for a Ruby file
generate_rbs() {
  local rb_file="$1"
  if [[ -f "$rb_file" ]]; then
    bundle exec rbs-inline --output "$CLAUDE_PROJECT_DIR/sig" "$rb_file" 2>/dev/null || true
  fi
}

# Function to remove .rbs file corresponding to a Ruby file
remove_rbs() {
  local rb_file="$1"
  # Convert lib/path/to/file.rb to sig/path/to/file.rbs
  local rbs_file="${rb_file/lib\//sig/}"
  rbs_file="${rbs_file%.rb}.rbs"
  local full_rbs_path="$CLAUDE_PROJECT_DIR/$rbs_file"
  if [[ -f "$full_rbs_path" ]]; then
    rm -f "$full_rbs_path"
  fi
}

# Handle Edit and Write tools
if [[ "$tool_name" == "Edit" || "$tool_name" == "Write" ]]; then
  if [[ -n "$file_path" && "$file_path" == */lib/*.rb ]]; then
    generate_rbs "$file_path"
  fi
fi

# Handle Bash tool (mv and git mv commands)
if [[ "$tool_name" == "Bash" && -n "$command" ]]; then
  # Check for mv or git mv commands
  if [[ "$command" =~ (^|[[:space:]])(mv|git\ mv)[[:space:]] ]]; then
    # Extract source and destination from the command
    # This is a simplified parser; complex cases may need adjustment

    # Try to extract paths (handles basic "mv source dest" and "git mv source dest")
    if [[ "$command" =~ (mv|git\ mv)[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+) ]]; then
      src="${BASH_REMATCH[2]}"
      dest="${BASH_REMATCH[3]}"

      # Handle Ruby files
      if [[ "$src" == *.rb ]]; then
        # Remove old .rbs file
        if [[ "$src" == lib/* || "$src" == */lib/* ]]; then
          remove_rbs "$src"
        fi

        # Generate new .rbs file if destination is in lib/
        if [[ "$dest" == lib/* || "$dest" == */lib/* ]]; then
          if [[ -f "$CLAUDE_PROJECT_DIR/$dest" ]]; then
            generate_rbs "$CLAUDE_PROJECT_DIR/$dest"
          elif [[ -f "$dest" ]]; then
            generate_rbs "$dest"
          fi
        fi
      fi
    fi
  fi
fi
