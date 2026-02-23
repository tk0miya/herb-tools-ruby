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

# Find gem directory for a given file path
find_gem_for_file() {
  local file="$1"
  local dir="$CLAUDE_PROJECT_DIR/$file"

  while [[ "$dir" != "$CLAUDE_PROJECT_DIR" && "$dir" != "/" ]]; do
    dir=$(dirname "$dir")
    if compgen -G "$dir/*.gemspec" > /dev/null 2>&1; then
      echo "$dir"
      return
    fi
  done
}

# Find gem directories that have changes (staged or unstaged)
# Uses git status to detect all modified files
find_affected_gems() {
  local gems=()
  local seen=()

  # Helper function to add a gem if not already seen
  add_gem() {
    local gem_dir="$1"
    [[ -z "$gem_dir" ]] && return

    for s in "${seen[@]:-}"; do
      if [[ "$s" == "$gem_dir" ]]; then
        return
      fi
    done
    gems+=("$gem_dir")
    seen+=("$gem_dir")
  }

  # Get all changed files from git status (both staged and unstaged)
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # git status --porcelain format: XY filename (filename starts at position 3)
    local file="${line:3}"
    [[ -z "$file" ]] && continue

    local gem_dir
    gem_dir=$(find_gem_for_file "$file")
    add_gem "$gem_dir"
  done < <(git status --porcelain 2>/dev/null)

  if [[ ${#gems[@]} -gt 0 ]]; then
    printf '%s\n' "${gems[@]}"
  fi
}

# Get affected gems
mapfile -t affected_gems < <(find_affected_gems)

if [[ ${#affected_gems[@]} -eq 0 ]]; then
  # No gem directories affected, skip checks
  exit 0
fi

echo "Running pre-commit checks..." >&2

# Check if gem dependencies are available (bundle check in the first affected gem)
# If not, skip checks and warn (can happen when network is restricted during setup)
first_gem="${affected_gems[0]}"
if [[ -n "$first_gem" ]]; then
  if ! (cd "$first_gem" && "$CLAUDE_PROJECT_DIR/bin/rake" --version > /dev/null 2>&1); then
    echo "Warning: gem dependencies unavailable (bundle setup failed). Skipping pre-commit checks." >&2
    echo "Run 'bundle install' in each gem directory when network access is available." >&2
    exit 0
  fi
fi

# Run rake in each affected gem directory
for gem_dir in "${affected_gems[@]}"; do
  [[ -z "$gem_dir" ]] && continue
  gem_name=$(basename "$gem_dir")
  echo "Checking $gem_name..." >&2

  if ! (cd "$gem_dir" && "$CLAUDE_PROJECT_DIR/bin/rake") >&2; then
    echo "Error: rake checks failed in $gem_name" >&2
    exit 2
  fi
done

echo "All checks passed!" >&2
exit 0
