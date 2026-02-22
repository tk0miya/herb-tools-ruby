# Phase 25: herb-lint Missing Features Implementation

This task tracks the implementation of features that exist in the TypeScript reference implementation but are missing in the Ruby implementation.

**Status**: Not Started
**Priority**: Medium
**Estimated Effort**: 3-5 days
**Dependencies**: Phase 24 complete

## Overview

After reviewing the TypeScript implementation (https://github.com/marcoroth/herb), several features exist in the original that are not yet implemented in the Ruby version.

## Implementation Checklist

### Phase 25.1: High Priority (Required for Feature Parity)

#### 1. DetailedFormatter (Default Output Format)

The TypeScript implementation has a `DetailedFormatter` that is the **default** output format. The Ruby implementation currently uses `SimpleFormatter` as the default.

**Features of TypeScript DetailedFormatter:**
- Syntax highlighting with configurable themes
- Contextual code snippets showing the violation
- Line wrapping for long lines
- Line truncation option
- `[Correctable]` marker for fixable violations
- Summary statistics with top violated rules

**Current Ruby Status:**
- ✅ SimpleFormatter implemented
- ✅ JsonFormatter implemented
- ✅ GithubFormatter implemented
- ❌ DetailedFormatter **not implemented**

**Implementation Tasks:**
- [x] Create `Herb::Lint::Formatter::DetailedFormatter` class
- [x] Implement code context display (±2 lines around violation)
  - [x] Extract relevant lines from source
  - [x] Format with line numbers
  - [x] Highlight the specific violation line
- [x] Add top violated rules to summary — see Task 7 for details
- [x] Make DetailedFormatter the **default** when `--format` is not specified
  - [x] Update CLI#create_formatter to use DetailedFormatter by default
  - [x] Update tests to expect DetailedFormatter output
- [x] Write unit tests for DetailedFormatter
- [x] Write integration tests via CLI

> **Note:** `--theme`, `--no-wrap-lines`, and `--truncate-lines` are tracked in Task 8.

#### 2. Custom Rules System (Replaces CustomRuleLoader)

> **Note:** This feature is tracked in [Phase 22: Custom Rule Loading](phase-22-custom-rule-loading.md). Removed from Phase 25 to avoid duplication.

#### 3. --init Command (Configuration File Generation)

TypeScript implementation provides `--init` to generate a default `.herb.yml` configuration file.

**TypeScript Behavior:**
- Creates `.herb.yml` in current directory
- Populates with sensible defaults
- Exits after generation (does not run linting)
- Error if file already exists

**Implementation Tasks:**
- [x] Create default `.herb.yml` template
  - [x] Include commonly-used linter rules with recommended severity
  - [x] Include file patterns (include/exclude)
  - [x] Add helpful comments explaining each section
- [x] Add `--init` CLI option
  - [x] Parse option in CLI
  - [x] Call initialization handler
  - [x] Exit with status 0 after generation
- [x] Implement initialization logic
  - [x] Check if `.herb.yml` already exists
  - [x] Prevent overwriting (or prompt for confirmation)
  - [x] Write template to `.herb.yml`
  - [x] Display success message
- [x] Update CLI help text
- [x] Write unit tests
  - [x] Test file generation
  - [x] Test overwrite prevention
  - [x] Test exit code
- [x] Write integration tests via CLI

#### 4. --config-file / -c Option (Configuration File Path)

TypeScript implementation supports specifying a custom configuration file path.

**TypeScript Behavior:**
- `--config-file path/to/config.yml` loads the specified file
- Absolute or relative paths supported
- Upward directory search is **disabled** when `--config-file` is used
- Error if specified file does not exist

**Implementation Tasks:**
- [x] Add `--config-file PATH` option to CLI
- [x] Add `-c PATH` short form
- [x] Modify `Herb::Config::Loader.load` to accept optional path parameter
  - [x] When path provided, load from that path only
  - [x] Disable upward directory search when path is provided
  - [x] Return error if specified file does not exist
- [x] Update CLI to pass config path to Loader
- [x] Update CLI help text
- [x] Write unit tests for Loader path resolution
- [x] Write integration tests via CLI
  - [x] Test with absolute path
  - [x] Test with relative path
  - [x] Test error when file does not exist

### Phase 25.2: Medium Priority

#### 5. --force Option

Force execution of disabled rules.

**Implementation Tasks:**
- [x] Add `--force` CLI option
- [x] Pass flag to Runner/Linter
- [x] Override rule enabled/disabled configuration when flag is set
- [x] Update CLI help text
- [x] Write unit tests
- [x] Write integration tests

#### 6. Timing Information Display

Display performance metrics in output.

**TypeScript Features:**
- Total execution time displayed by default
- Can be disabled with `--no-timing`
- Shown in summary section of DetailedFormatter

**Implementation Tasks:**
- [x] Track start/end time in `Runner#run`
  - [x] Record start time before file discovery
  - [x] Record end time after all files processed
  - [x] Calculate elapsed time
- [x] Store timing in `AggregatedResult`
  - [x] Add timing field (currently always null)
  - [x] Populate from Runner
- [x] Display timing in reporters
  - [x] Add to SimpleFormatter summary
  - [x] Add to DetailedFormatter summary
  - [x] Include in JSON output (already has field)
- [x] Add `--no-timing` CLI flag to disable display
  - [x] Parse option
  - [x] Pass to reporters
  - [x] Update help text
- [x] Write unit tests
- [x] Write integration tests

### Phase 25.3: Low Priority

#### 7. Top Violated Rules Summary

Show most common violations in summary.

**Implementation Tasks:**
- [x] Track offense counts per rule in `AggregatedResult`
  - [x] Add method to group offenses by rule
  - [x] Count offenses for each rule
- [x] Add method to retrieve top N rules by count
  - [x] Sort rules by offense count descending
  - [x] Return top N (default: 5)
- [x] Display in DetailedFormatter summary
  - [x] Format as list with rule name and count
  - [x] Only show if violations exist
- [x] Write unit tests
- [x] Write integration tests

##### Investigation: Is "Make count configurable" needed?

Check the TypeScript reference implementation to determine whether configuring the top-rules display count is an actual feature.

**Tasks:**
- [ ] Check `javascript/packages/linter/src/cli/argument-parser.ts` for a `--top-rules` or similar option
- [ ] Check `javascript/packages/linter/src/formatters/detailed-formatter.ts` for any configurable count
- [ ] If the feature exists in TypeScript: add a proper implementation task to this section
- [ ] If the feature does not exist: delete this investigation step

#### 8. Syntax Highlighting and Additional CLI Options (Low Priority)

Implements syntax highlighting via Rouge and three related CLI options.
Tasks are ordered by dependency: Rouge integration must be completed before `--theme` can work,
and line wrapping must be implemented before `--no-wrap-lines` can work.

> **TypeScript reference files:**
> - CLI parsing: `javascript/packages/linter/src/cli/argument-parser.ts`
> - Option flow: `javascript/packages/linter/src/cli.ts` → `output-manager.ts` → `formatters/detailed-formatter.ts`
> - Line wrapping/truncation logic: `javascript/packages/highlighter/src/line-wrapper.ts`
> - Syntax highlighting: `javascript/packages/highlighter/src/highlighter.ts`
> - Built-in themes: `javascript/packages/highlighter/src/themes.ts`

---

##### Step 1: Rouge Infrastructure (no theme yet)

Sets up the Rouge highlighting infrastructure without any theme.
The `Highlighter` class is wired into `DetailedFormatter` but produces no colorization until a theme is added in Step 2.

**TypeScript Specification:**
- Uses the `@herb-tools/highlighter` package which wraps a custom syntax renderer
- Themes define token colors for HTML tags, keywords, identifiers, operators, etc.
- Theme is passed to `Highlighter` constructor and applied to HTML/ERB/Ruby token colorization

**Ruby Implementation Notes:**
- Use the `rouge` gem as the highlighting library
- Define a `Herb::Lint::Highlighter` class wrapping Rouge; accept theme name as an argument
- Define the theme storage structure (`Herb::Lint::Themes` module or similar) so Step 2 can fill it in
- Integrate into `DetailedFormatter#print_source_lines` (no-op colorization until a theme exists)

**Implementation Tasks:**
- [ ] Add `rouge` gem dependency to `herb-lint.gemspec`
- [ ] Create `Herb::Lint::Highlighter` class
  - [ ] Accept theme name as constructor argument
  - [ ] Apply Rouge lexer for ERB source code
  - [ ] Look up token color mapping from theme; output plain text if theme is unknown
- [ ] Define theme storage structure (`Herb::Lint::Themes` module or similar)
- [ ] Integrate highlighter into `DetailedFormatter#print_source_lines`
- [ ] Write unit tests for `Highlighter` (no theme / fallback behavior)

---

##### Step 2: Port `onedark` Theme (default theme)

Ports the `onedark` theme as the first built-in theme and sets it as the default.
After this step, `DetailedFormatter` produces colored output by default.

**TypeScript Reference:**
- `javascript/packages/highlighter/src/themes.ts` — `onedark` color definitions
- `DEFAULT_THEME = "onedark"`

**Implementation Tasks (depends on Step 1):**
- [ ] Port `onedark` theme (token color mapping) into `Herb::Lint::Themes`
- [ ] Set `onedark` as the default theme in `Herb::Lint::Highlighter`
- [ ] Write unit tests for `onedark` theme

---

##### Step 3: Remaining Built-in Themes (`github-light`, `dracula`, `tokyo-night`, `simple`)

Ports the remaining four built-in themes using the structure established in Steps 1–2.
Each theme is a straightforward token color mapping following the same pattern.

**TypeScript Reference:**
- `javascript/packages/highlighter/src/themes.ts` contains all color definitions

**Implementation Tasks (depends on Step 2):**
- [ ] Port `github-light` theme
- [ ] Port `dracula` theme
- [ ] Port `tokyo-night` theme
- [ ] Port `simple` theme
- [ ] Write unit tests for each ported theme

---

##### Step 4: `--theme THEME`

**TypeScript Specification:**
- `--theme NAME` selects a built-in theme by name
- `--theme /path/to/file.json` loads a custom theme from a JSON file
- Uses `DEFAULT_THEME` constant when `--theme` is not specified
- Invalid theme name/path causes an error

**Ruby Implementation Notes:**
- Validate theme name against built-in theme list or check for file path existence
- Pass theme to `DetailedFormatter`, which passes it to `Herb::Lint::Highlighter`

**TypeScript Reference:**
```typescript
// argument-parser.ts
const theme = values.theme || DEFAULT_THEME

// detailed-formatter.ts
this.highlighter = new Highlighter(this.theme)
```

**Implementation Tasks (depends on Steps 1–3):**
- [ ] Add `--theme THEME` CLI option
- [ ] Pass theme to `DetailedFormatter`
- [ ] Pass theme from `DetailedFormatter` to `Herb::Lint::Highlighter`
- [ ] Validate theme name (built-in list) or file path existence; exit with `EXIT_RUNTIME_ERROR` on invalid input
- [ ] Update help text listing available built-in themes
- [ ] Write unit tests

---

##### Step 5: Line Wrapping Implementation

Implements the line wrapping logic in `DetailedFormatter`.
`--no-wrap-lines` (Step 6) is simply the flag that disables it and comes after.

**TypeScript Specification:**
- Default: line wrapping **enabled** (`wrapLines = true`)
- Wrap point priority order (see `wrapLine()` in `line-wrapper.ts`):
  1. Whitespace/tabs (within 40 characters of max width)
  2. Punctuation `>`, `,`, `;` (within 30 characters of max width)
  3. Any character except `=` and quotes (within 10 characters of max width)
- Continuation lines preserve the same indentation as the original line
- ANSI color codes are preserved during wrapping

**Ruby Implementation Notes:**
- Use `IO#winsize` to get terminal width; fall back to 80 if not a TTY
- Strip ANSI codes when measuring line length for wrap point calculation
- Reapply ANSI codes on continuation lines

**Implementation Tasks:**
- [ ] Implement line wrapping in `DetailedFormatter#print_source_line`
  - [ ] Get terminal width via `IO#winsize` (fallback to 80)
  - [ ] Find wrap point: whitespace → punctuation → any character (with priority distances)
  - [ ] Preserve indentation on continuation lines
  - [ ] Preserve ANSI color codes across wrapped lines
- [ ] Write unit tests for line wrapping behavior

---

##### Step 6: `--no-wrap-lines`

Adds the CLI option to disable the line wrapping implemented in Step 5.

**TypeScript Specification:**
- `--no-wrap-lines` sets `wrapLines = false` (wrapping disabled)
- Mutual exclusivity with `--truncate-lines`:

```typescript
// argument-parser.ts
let wrapLines = !values["no-wrap-lines"]

// --truncate-lines automatically disables wrapping
if (values["truncate-lines"]) {
  truncateLines = true
  wrapLines = false
}

// Using both flags together is an error
if (!values["no-wrap-lines"] && values["truncate-lines"]) {
  console.error("Error: Line wrapping and --truncate-lines cannot be used together...")
  process.exit(1)
}
```

**Ruby Implementation Notes:**
- When used together with `--truncate-lines`, print an error to stderr and exit with `EXIT_RUNTIME_ERROR`

**Implementation Tasks (depends on Step 5):**
- [ ] Add `--no-wrap-lines` CLI option to disable wrapping
- [ ] Detect `--no-wrap-lines` + `--truncate-lines` combination in CLI and exit with `EXIT_RUNTIME_ERROR`
- [ ] Update help text
- [ ] Write unit tests for `--no-wrap-lines` (wrapping disabled, mutual exclusivity error)

---

##### Step 7: `--truncate-lines`

**TypeScript Specification:**
- Default: truncation **disabled** (`truncateLines = false`)
- Truncation width = actual terminal width (not a fixed value)
- Uses the single-character ellipsis `…` (U+2026, HORIZONTAL ELLIPSIS), not `...`
- Automatically sets `wrapLines = false` when specified
- ANSI color codes are preserved during truncation (via `extractPortionWithAnsi()`)
- Truncation logic differs between the offense line (diagnostic target) and surrounding context lines

```typescript
// argument-parser.ts
let truncateLines = false
if (values["truncate-lines"]) {
  truncateLines = true
  wrapLines = false  // automatically disable wrapping
}
```

**Ruby Implementation Notes:**
- Use `IO#winsize` for terminal width; fall back to 80 if not a TTY
- Use `…` (U+2026) as the ellipsis character, not `...`
- Measure line length after stripping ANSI escape sequences
- Automatically set `wrap_lines = false` when `truncate_lines = true`
- Exit with `EXIT_RUNTIME_ERROR` when used together with `--no-wrap-lines`

**Implementation Tasks:**
- [ ] Add `--truncate-lines` CLI option
- [ ] In CLI, automatically set `wrap_lines = false` when `--truncate-lines` is specified
- [ ] Implement truncation in `DetailedFormatter`
  - [ ] Get terminal width via `IO#winsize` (fallback to 80)
  - [ ] Strip ANSI codes when measuring line length
  - [ ] Use `…` (U+2026) as ellipsis character
  - [ ] Preserve ANSI color codes in the retained portion of the line
- [ ] Detect `--no-wrap-lines` + `--truncate-lines` combination in CLI and exit with `EXIT_RUNTIME_ERROR`
- [ ] Update help text
- [ ] Write unit tests (truncation at terminal width, ANSI preservation, ellipsis character)

## Non-Features (Do Not Implement)

The following features are mentioned in requirements/design documents but **do NOT exist** in the TypeScript reference implementation:

1. ❌ **Parallel Processing** - Not implemented in TypeScript
2. ❌ **Caching** - Not implemented in TypeScript

## Testing Requirements

- [x] Unit tests for all new classes/methods
  - [x] DetailedFormatter
  - [x] Custom rules system (Phase 22)
  - [x] Config path resolution
  - [x] Timing tracking
- [x] Integration tests via CLI
  - [ ] `--theme` option (accepts option, runs normally)
  - [ ] `--no-wrap-lines` option (accepts option, runs normally)
  - [ ] `--truncate-lines` option (accepts option, runs normally)
  - [ ] `--no-wrap-lines` + `--truncate-lines` 同時指定でエラー終了
  - [x] Default format selection
  - [x] Custom rules loading (Phase 22)
  - [x] Config file generation
- [ ] Update existing CLI specs
  - [ ] Verify new options appear in help
  - [ ] Verify exit codes
- [ ] Ensure TypeScript parity in behavior
  - [ ] Compare output formats
  - [ ] Compare error messages
  - [ ] Compare default configurations

## Documentation Updates

- [ ] Update `docs/requirements/herb-lint.md`
  - [ ] Mark implemented features as complete
  - [ ] Update CLI options table
  - [ ] Update output format examples
- [ ] Update `docs/design/herb-lint-design.md`
  - [ ] Add DetailedFormatter design
  - [x] Update custom rules system design (Phase 22)
  - [ ] Update component diagrams
- [ ] Update `README.md`
  - [ ] Add examples with new CLI options
  - [ ] Show DetailedFormatter output
  - [ ] Document plugin system usage

## Acceptance Criteria

- [ ] All high-priority features implemented and tested
- [x] DetailedFormatter is the default output format
- [x] Custom rules system loads rules from `linter.custom_rules` (Phase 22)
- [ ] --init generates a working `.herb.yml` configuration
- [ ] --config-file allows specifying custom configuration path
- [ ] CLI help text updated with new options
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Requirements/design documents aligned with TypeScript reference

## Related Documents

- [herb-lint Requirements](../requirements/herb-lint.md)
- [herb-lint Design](../design/herb-lint-design.md)
- [TypeScript Reference Implementation](https://github.com/marcoroth/herb)
