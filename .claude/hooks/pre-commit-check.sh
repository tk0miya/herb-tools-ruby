#!/bin/bash
#
# PreToolUse hook for running checks before git commit
#
# This script runs rake (spec, rubocop, steep) in gem directories
# that have staged changes before allowing git commit operations.
#

set -euo pipefail

# Read JSON input from stdin
input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only run for git commit commands via Bash tool
if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

# Check if it's a git commit/cherry-pick/merge/rebase command
if [[ ! "$command" =~ git[[:space:]]+(commit|cherry-pick|merge|rebase) ]]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 1

# Find gem directories that have staged changes
find_affected_gems() {
  local gems=()
  local seen=()

  # Get list of staged files
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    # Walk up the directory tree to find a directory with a .gemspec file
    local dir="$CLAUDE_PROJECT_DIR/$file"
    while [[ "$dir" != "$CLAUDE_PROJECT_DIR" && "$dir" != "/" ]]; do
      dir=$(dirname "$dir")
      if compgen -G "$dir/*.gemspec" > /dev/null 2>&1; then
        # Check if we've already seen this gem
        local already_seen=false
        for s in "${seen[@]:-}"; do
          if [[ "$s" == "$dir" ]]; then
            already_seen=true
            break
          fi
        done
        if [[ "$already_seen" == false ]]; then
          gems+=("$dir")
          seen+=("$dir")
        fi
        break
      fi
    done
  done < <(git diff --cached --name-only 2>/dev/null)

  printf '%s\n' "${gems[@]:-}"
}

# Get affected gems
mapfile -t affected_gems < <(find_affected_gems)

if [[ ${#affected_gems[@]} -eq 0 ]]; then
  # No gem directories affected, skip checks
  exit 0
fi

echo "Running pre-commit checks..." >&2

# Run rake in each affected gem directory
for gem_dir in "${affected_gems[@]}"; do
  gem_name=$(basename "$gem_dir")
  echo "Checking $gem_name..." >&2

  if ! (cd "$gem_dir" && "$CLAUDE_PROJECT_DIR/bin/rake") >&2; then
    echo "Error: rake checks failed in $gem_name" >&2
    exit 2
  fi
done

echo "All checks passed!" >&2
exit 0
