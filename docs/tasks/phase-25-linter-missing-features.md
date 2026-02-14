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
- [ ] Create `Herb::Lint::Formatter::DetailedFormatter` class
- [ ] Integrate syntax highlighting library (Rouge recommended)
  - [ ] Add Rouge dependency to gemspec
  - [ ] Implement theme loading/selection
  - [ ] Apply syntax highlighting to ERB code snippets
- [ ] Implement code context display (±2 lines around violation)
  - [ ] Extract relevant lines from source
  - [ ] Format with line numbers
  - [ ] Highlight the specific violation line
- [ ] Add top violated rules to summary
  - [ ] Track offense counts per rule in AggregatedResult
  - [ ] Display top 5 rules by count
  - [ ] Make count configurable
- [ ] Make DetailedFormatter the **default** when `--format` is not specified
  - [ ] Update CLI#create_reporter to use DetailedFormatter by default
  - [ ] Update tests to expect DetailedFormatter output
- [ ] Add `--theme` CLI option for theme customization
- [ ] Add `--no-wrap-lines` CLI option
- [ ] Add `--truncate-lines` CLI option
- [ ] Write unit tests for DetailedFormatter
- [ ] Write integration tests via CLI

#### 2. CustomRuleLoader (.herb/rules/ Support)

The TypeScript implementation automatically loads custom rules from `.herb/rules/**/*.mjs` without requiring explicit configuration.

**TypeScript Features:**
- Glob pattern-based rule discovery: `.herb/rules/**/*.mjs`
- Automatic validation of rule structure
- Error handling for duplicate rule names
- Warning messages for invalid rules
- CLI flag `--no-custom-rules` to skip loading

**Current Ruby Status:**
- ❌ CustomRuleLoader **not implemented**
- Design document exists (`herb-lint-design.md`) but not implemented
- `RuleRegistry` exists and can register rules, but no automatic loading

**Implementation Tasks:**
- [ ] Create `Herb::Lint::CustomRuleLoader` class
  - [ ] Implement glob-based rule discovery (`.herb/rules/**/*.rb`)
  - [ ] Load Ruby files using `require` or `load`
  - [ ] Capture loaded rule classes
- [ ] Add rule validation
  - [ ] Validate rule classes inherit from `Herb::Lint::Rules::Base`
  - [ ] Validate required class methods exist (`rule_name`, `description`, etc.)
  - [ ] Handle invalid rules gracefully with warning messages
- [ ] Add duplicate rule name detection
  - [ ] Check against existing built-in rules
  - [ ] Check against other custom rules
  - [ ] Warn user about duplicates
- [ ] Integrate with `RuleRegistry`
  - [ ] Auto-register discovered rules
  - [ ] Maintain separation between built-in and custom rules
- [ ] Update `Runner` to call `CustomRuleLoader` during initialization
  - [ ] Load custom rules before creating Linter
  - [ ] Pass custom rules to RuleRegistry
- [ ] Add `--no-custom-rules` CLI flag
  - [ ] Skip CustomRuleLoader when flag is present
  - [ ] Update CLI help text
- [ ] Write unit tests for CustomRuleLoader
  - [ ] Test rule discovery
  - [ ] Test validation logic
  - [ ] Test duplicate detection
  - [ ] Test error handling
- [ ] Write integration tests
  - [ ] Create sample custom rules in test fixtures
  - [ ] Verify custom rules are loaded and executed
  - [ ] Verify `--no-custom-rules` flag works

#### 3. --init Command (Configuration File Generation)

TypeScript implementation provides `--init` to generate a default `.herb.yml` configuration file.

**TypeScript Behavior:**
- Creates `.herb.yml` in current directory
- Populates with sensible defaults
- Exits after generation (does not run linting)
- Error if file already exists

**Implementation Tasks:**
- [ ] Create default `.herb.yml` template
  - [ ] Include commonly-used linter rules with recommended severity
  - [ ] Include file patterns (include/exclude)
  - [ ] Add helpful comments explaining each section
- [ ] Add `--init` CLI option
  - [ ] Parse option in CLI
  - [ ] Call initialization handler
  - [ ] Exit with status 0 after generation
- [ ] Implement initialization logic
  - [ ] Check if `.herb.yml` already exists
  - [ ] Prevent overwriting (or prompt for confirmation)
  - [ ] Write template to `.herb.yml`
  - [ ] Display success message
- [ ] Update CLI help text
- [ ] Write unit tests
  - [ ] Test file generation
  - [ ] Test overwrite prevention
  - [ ] Test exit code
- [ ] Write integration tests via CLI

#### 4. --config-file / -c Option (Configuration File Path)

TypeScript implementation supports specifying a custom configuration file path.

**TypeScript Behavior:**
- `--config-file path/to/config.yml` loads the specified file
- Absolute or relative paths supported
- Upward directory search is **disabled** when `--config-file` is used
- Error if specified file does not exist

**Implementation Tasks:**
- [ ] Add `--config-file PATH` option to CLI
- [ ] Add `-c PATH` short form
- [ ] Modify `Herb::Config::Loader.load` to accept optional path parameter
  - [ ] When path provided, load from that path only
  - [ ] Disable upward directory search when path is provided
  - [ ] Return error if specified file does not exist
- [ ] Update CLI to pass config path to Loader
- [ ] Update CLI help text
- [ ] Write unit tests for Loader path resolution
- [ ] Write integration tests via CLI
  - [ ] Test with absolute path
  - [ ] Test with relative path
  - [ ] Test error when file does not exist

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
3. ❌ **General Plugin System** - TypeScript has "Rewriter System" but this is for the **formatter**, not the linter

## Testing Requirements

- [ ] Unit tests for all new classes/methods
  - [ ] DetailedFormatter
  - [ ] CustomRuleLoader
  - [ ] Config path resolution
  - [ ] Timing tracking
- [ ] Integration tests via CLI
  - [ ] All new CLI options
  - [ ] Default format selection
  - [ ] Custom rule loading
  - [ ] Config file generation
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
  - [ ] Add CustomRuleLoader design
  - [ ] Update component diagrams
- [ ] Update `README.md`
  - [ ] Add examples with new CLI options
  - [ ] Show DetailedFormatter output
  - [ ] Document custom rule creation
- [ ] Create custom rule guide
  - [ ] Document rule base class
  - [ ] Provide example custom rules
  - [ ] Explain `.herb/rules/` directory structure

## Acceptance Criteria

- [ ] All high-priority features implemented and tested
- [ ] DetailedFormatter is the default output format
- [ ] CustomRuleLoader automatically loads rules from `.herb/rules/`
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
