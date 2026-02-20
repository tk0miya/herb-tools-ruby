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
- [ ] Integrate syntax highlighting library (Rouge recommended)
  - [ ] Add Rouge dependency to gemspec
  - [ ] Implement theme loading/selection
  - [ ] Apply syntax highlighting to ERB code snippets
- [x] Implement code context display (±2 lines around violation)
  - [x] Extract relevant lines from source
  - [x] Format with line numbers
  - [x] Highlight the specific violation line
- [ ] Add top violated rules to summary
  - [ ] Track offense counts per rule in AggregatedResult
  - [ ] Display top 5 rules by count
  - [ ] Make count configurable
- [x] Make DetailedFormatter the **default** when `--format` is not specified
  - [x] Update CLI#create_formatter to use DetailedFormatter by default
  - [x] Update tests to expect DetailedFormatter output
- [ ] Add `--theme` CLI option for theme customization
- [ ] Add `--no-wrap-lines` CLI option
- [ ] Add `--truncate-lines` CLI option
- [x] Write unit tests for DetailedFormatter
- [x] Write integration tests via CLI

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
- [ ] Add `--force` CLI option
- [ ] Pass flag to Runner/Linter
- [ ] Override rule enabled/disabled configuration when flag is set
- [ ] Update CLI help text
- [ ] Write unit tests
- [ ] Write integration tests

#### 6. Timing Information Display

Display performance metrics in output.

**TypeScript Features:**
- Total execution time displayed by default
- Can be disabled with `--no-timing`
- Shown in summary section of DetailedFormatter

**Implementation Tasks:**
- [ ] Track start/end time in `Runner#run`
  - [ ] Record start time before file discovery
  - [ ] Record end time after all files processed
  - [ ] Calculate elapsed time
- [ ] Store timing in `AggregatedResult`
  - [ ] Add timing field (currently always null)
  - [ ] Populate from Runner
- [ ] Display timing in reporters
  - [ ] Add to SimpleFormatter summary
  - [ ] Add to DetailedFormatter summary
  - [ ] Include in JSON output (already has field)
- [ ] Add `--no-timing` CLI flag to disable display
  - [ ] Parse option
  - [ ] Pass to reporters
  - [ ] Update help text
- [ ] Write unit tests
- [ ] Write integration tests

### Phase 25.3: Low Priority

#### 7. Top Violated Rules Summary

Show most common violations in summary.

**Implementation Tasks:**
- [ ] Track offense counts per rule in `AggregatedResult`
  - [ ] Add method to group offenses by rule
  - [ ] Count offenses for each rule
- [ ] Add method to retrieve top N rules by count
  - [ ] Sort rules by offense count descending
  - [ ] Return top N (default: 5)
- [ ] Display in DetailedFormatter summary
  - [ ] Format as list with rule name and count
  - [ ] Only show if violations exist
- [ ] Make count configurable (optional)
- [ ] Write unit tests
- [ ] Write integration tests

#### 8. Additional CLI Options (Low Priority)

Remaining CLI options from TypeScript implementation:

**Implementation Tasks:**
- [ ] `--theme` option (requires DetailedFormatter)
  - [ ] Add CLI option
  - [ ] Pass to DetailedFormatter
  - [ ] Update help text
- [ ] `--no-wrap-lines` option (requires DetailedFormatter)
  - [ ] Add CLI option
  - [ ] Pass to DetailedFormatter
  - [ ] Disable line wrapping in output
  - [ ] Update help text
- [ ] `--truncate-lines` option (requires DetailedFormatter)
  - [ ] Add CLI option
  - [ ] Pass to DetailedFormatter
  - [ ] Enable line truncation in output
  - [ ] Update help text

## Non-Features (Do Not Implement)

The following features are mentioned in requirements/design documents but **do NOT exist** in the TypeScript reference implementation:

1. ❌ **Parallel Processing** - Not implemented in TypeScript
2. ❌ **Caching** - Not implemented in TypeScript

## Testing Requirements

- [x] Unit tests for all new classes/methods
  - [x] DetailedFormatter
  - [x] Custom rules system (Phase 22)
  - [ ] Config path resolution
  - [ ] Timing tracking
- [x] Integration tests via CLI
  - [ ] All new CLI options
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
