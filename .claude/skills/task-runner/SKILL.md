---
name: task-runner
description: "Pick and execute the next implementation task from docs/tasks/. Use this skill whenever the user wants to work on the next task, implement a specific task, or continue implementation work from the task list. Also use when the user mentions task numbers (e.g., 'task 2.31'), phase numbers (e.g., 'phase 3'), or says things like 'next task', 'continue working', or 'pick up where we left off'."
argument-hint: "[task-id or phase]"
allowed-tools: Read, Glob, Grep, Edit, Write, Bash, Task
---

# Task Runner

Execute implementation tasks defined in `docs/tasks/` for the herb-tools-ruby project.

## Scope: One Task Per Invocation

Execute exactly one task per invocation. Even if the user says "phase 3" or mentions multiple tasks, pick only the single next unchecked task and stop after completing it. Do not chain tasks, do not look ahead to the next task and start it, and do not batch multiple checkbox items into one run. After completing the single task, report results and wait for the user to invoke the skill again.

## Workflow

### 1. Identify the Target Task

If the user specified a task (e.g., "task 2.31", "phase 3"), find that task directly. Otherwise, follow this selection process:

1. Read `docs/tasks/README.md` to see which phases are active (marked 🚧) or planned (marked 📋)
2. Among active/planned phases, pick the one with the lowest phase number that still has unchecked items
3. Read that phase's task file
4. Find the first unchecked task (`- [ ]`) — this is the task to work on

The task files use markdown checkboxes:
- `- [ ]` = incomplete (work on these)
- `- [x]` = complete (skip these)

### 2. Understand the Task

Before writing any code, thoroughly read the task description including:
- **Location** — where to create/modify files
- **Interface** — the expected API and code structure
- **Test Cases** — expected test behavior
- **Verification** — how to confirm the task is done
- **Design Notes** — architectural context and rationale

Also check:
- Prerequisites and dependencies on other tasks
- Related design documents referenced in the task file
- Existing code in the target location (read before modifying)

Always use the `ts-reference-investigator` agent to investigate the original TypeScript implementation before writing any code. This project is a Ruby port of the TypeScript ecosystem, so understanding the original design decisions, edge case handling, and behavioral specifications is essential for maintaining compatibility. Even when the task description includes detailed interface specifications, the TypeScript source is the authoritative reference — check it to catch nuances the task description may not cover.

After investigating the TypeScript implementation, validate the task description against the original behavior. The TypeScript implementation is the source of truth for **tool behavior** (what the tool does, its inputs/outputs, user-facing semantics). Implementation-level differences due to language characteristics (TypeScript vs Ruby idioms, type systems, class hierarchies) are acceptable and expected — but the tool's observable behavior must match the original.

If you find a discrepancy where the task description asks for behavior that differs from the TypeScript implementation, **stop and ask the user** before proceeding. Report:
- What the task description says
- What the TypeScript implementation actually does
- Your recommendation on which to follow

Do not silently follow the task description when it contradicts the original behavior.

### 3. Implement the Task

Follow the project's coding conventions (see `docs/CODING_CONVENTIONS.md`):
- Ruby 3.3+ style, RuboCop compliant
- RBS inline type annotations (`@rbs`, `#:` comments)
- RSpec tests with factory_bot where applicable
- `Herb.parse` calls must include `track_whitespace: true`
- Sort `require_relative`, constant definitions, and gem declarations in ASCII order

Implementation order for each task:
1. Write the production code at the specified location
2. Write the spec file with comprehensive tests
3. Run the verification command specified in the task (typically `./bin/rspec` for the relevant gem)
4. Fix any failures until all tests pass

### 4. Verify with Lint Tools

Run the full lint and type-check suite in the gem directory:

```bash
cd <gem-dir> && ./bin/rake
```

This runs rspec, rubocop, and steep together. Fix all errors and warnings before proceeding. If steep or rubocop reports issues, correct them and re-run until clean.

### 5. Self-Review

After lint tools pass, spawn the `self-reviewer` agent to review the code you just wrote. Pass the list of changed files so the reviewer knows what to look at.

If the reviewer finds issues, fix them, then re-run the lint tools (step 4) to confirm nothing is broken. Repeat until the review passes.

### 6. Mark the Task Complete

After all verification passes:
1. Edit the task file to check off completed items (`- [ ]` → `- [x]`)
2. Update the task checklist at the top of the file if one exists
3. Update `docs/tasks/README.md` progress counters if applicable

### 7. Commit the Changes

Create a git commit with all changes:
- Stage the implementation files, spec files, and updated task markdown
- Use a descriptive commit message that references the task (e.g., "feat(herb-format): Task 3.1 - implement FormatIgnore module")
- Include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`

### 8. Report Results

After completing the task, provide a summary:
- Which task was completed
- What files were created or modified
- Test results (number of examples, pass/fail)
- Any issues encountered or notable decisions made
- What the next unchecked task is (so the user knows what's coming)

## Important Notes

- **One task only**: Execute exactly one task per invocation. Never continue to the next task, even if it seems small or related. Complete the full workflow (implement → lint → review → commit) for the single task, then stop and report.
- **Ask the user when blocked**: If a task cannot be executed for any reason, do not skip it or try to work around it silently. Stop and ask the user how to proceed. Common blocking situations include:
  - The task depends on prerequisites that aren't complete
  - The task description contradicts the TypeScript reference implementation
  - Required dependencies or infrastructure are missing
  - Tests fail persistently and you can't identify the root cause
  - The task description is ambiguous and the TypeScript source doesn't clarify it
