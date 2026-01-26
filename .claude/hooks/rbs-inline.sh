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

# Function to find the gem directory containing the Ruby file
find_gem_dir() {
  local rb_file="$1"
  local dir="$rb_file"

  # Walk up the directory tree to find a directory with a .gemspec file
  while [[ "$dir" != "/" && "$dir" != "." ]]; do
    dir=$(dirname "$dir")
    # Check if any .gemspec file exists in this directory
    if compgen -G "$dir/*.gemspec" > /dev/null 2>&1; then
      echo "$dir"
      return 0
    fi
  done
  return 1
}

# Function to generate .rbs file for a Ruby file
generate_rbs() {
  local rb_file="$1"
  if [[ -f "$rb_file" ]]; then
    local gem_dir
    if gem_dir=$(find_gem_dir "$rb_file"); then
      # Run from gem directory with relative path for correct sig output
      local rel_path="${rb_file#$gem_dir/}"
      (cd "$gem_dir" && "$CLAUDE_PROJECT_DIR/bin/rbs-inline" --opt-out --output=sig "$rel_path" 2>/dev/null) || true
    fi
  fi
}

# Function to remove .rbs file corresponding to a Ruby file
remove_rbs() {
  local rb_file="$1"
  local gem_dir
  if gem_dir=$(find_gem_dir "$rb_file"); then
    # Convert lib/path/to/file.rb to sig/path/to/file.rbs
    local rel_path="${rb_file#$gem_dir/}"
    local rbs_file="${rel_path/lib\//sig\/}"
    rbs_file="${rbs_file%.rb}.rbs"
    local full_rbs_path="$gem_dir/$rbs_file"
    if [[ -f "$full_rbs_path" ]]; then
      rm -f "$full_rbs_path"
    fi
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
