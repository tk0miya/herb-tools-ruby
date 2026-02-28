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


#### 8. Syntax Highlighting and Additional CLI Options (Low Priority)

Implements the `herb-highlighter` gem (mirroring TypeScript's `@herb-tools/highlighter`),
then ports built-in themes and adds CLI options for theme selection and line formatting.

Tasks are ordered by dependency: the gem separation must come first, then themes, then CLI options.

> **TypeScript reference files:**
> - CLI parsing: `javascript/packages/linter/src/cli/argument-parser.ts`
> - Option flow: `javascript/packages/linter/src/cli.ts` → `output-manager.ts` → `formatters/detailed-formatter.ts`
> - Line wrapping/truncation logic: `javascript/packages/highlighter/src/line-wrapper.ts`
> - Syntax highlighting: `javascript/packages/highlighter/src/highlighter.ts`
> - Built-in themes: `javascript/packages/highlighter/src/themes.ts`

---

##### Step 0: Create `herb-highlighter` Gem

The TypeScript reference has `@herb-tools/highlighter` as a **standalone package** that the linter
depends on. The Ruby implementation will mirror this architecture with a dedicated `herb-highlighter`
gem. This step creates the gem from scratch (no prior implementation to port; start fresh).

**TypeScript package: `@herb-tools/highlighter`**
```
exports:
  Color utilities     — colorize(), severityColor(), NAMED_COLORS, hexToAnsi()
  Themes              — theme registry, built-in color schemes, custom theme loading
  SyntaxRenderer      — token-level ERB/HTML syntax colorization using Herb.lex()
  DiagnosticRenderer  — renders offense context (source lines + line numbers + caret)
  FileRenderer        — renders a full file with line numbers + highlighting
  Highlighter         — main orchestrator wiring the above together
  CLI                 — herb-highlight command (reads file, prints highlighted output)
```

**gem directory structure:**
```
herb-highlighter/
├── Gemfile
├── Gemfile.lock
├── Rakefile
├── Steepfile
├── herb-highlighter.gemspec
├── rbs_collection.lock.yaml
├── rbs_collection.yaml
├── bin/                            # Binstubs (rake, rbs, rbs-inline, rspec, rubocop, steep)
├── exe/
│   └── herb-highlight              # CLI entry point
├── lib/
│   └── herb/
│       ├── highlight.rb            # Top-level require (loads all sub-files in order)
│       └── highlight/
│           ├── version.rb
│           ├── color.rb
│           ├── themes.rb
│           ├── syntax_renderer.rb
│           ├── diagnostic_renderer.rb
│           ├── file_renderer.rb
│           ├── highlighter.rb
│           └── cli.rb
└── spec/
    ├── spec_helper.rb
    └── herb/
        └── highlight/
            ├── color_spec.rb
            ├── themes_spec.rb
            ├── syntax_renderer_spec.rb
            ├── diagnostic_renderer_spec.rb
            ├── file_renderer_spec.rb
            ├── highlighter_spec.rb
            └── cli_spec.rb
```

---

###### Step 0.1: Gem Scaffold

**Files to create** (no existing gem to reference directly; use `herb-printer` as template):

| File | Notes |
|------|-------|
| `herb-highlighter.gemspec` | `name: "herb-highlighter"`, runtime dep: `"herb"` only |
| `Gemfile` | Dev deps: `rspec`, `rubocop`, `rbs-inline`, `steep`, `rake`, `herb-highlighter` (path: ".") |
| `Rakefile` | Same as `herb-printer/Rakefile`: spec + rubocop + steep |
| `Steepfile` | Same pattern as other gems |
| `rbs_collection.yaml` | Same pattern as other gems |
| `lib/herb/highlight.rb` | `require_relative` all sub-files in ASCII order |
| `lib/herb/highlight/version.rb` | `VERSION = "0.1.0"` |
| `bin/` binstubs | Copy pattern from `herb-printer/bin/` |
| `exe/herb-highlight` | Shebang + `require "herb/highlight"` + `Herb::Highlight::CLI.start` |
| `spec/spec_helper.rb` | Same pattern as other gems |

**gemspec runtime dependency:**
```ruby
spec.add_dependency "herb"   # for Herb.lex()
```
No dependency on `herb-core`, `herb-config`, `herb-lint`, or `herb-printer`.

**`lib/herb/highlight.rb` load order** (each must be loadable without the others already loaded,
except for the stated dependencies):
```ruby
require_relative "highlight/version"
require_relative "highlight/color"       # no deps within gem
require_relative "highlight/themes"      # no deps within gem
require_relative "highlight/syntax_renderer"    # depends on: Color, Themes
require_relative "highlight/diagnostic_renderer" # depends on: Color, SyntaxRenderer
require_relative "highlight/file_renderer"       # depends on: Color, SyntaxRenderer
require_relative "highlight/highlighter"         # depends on: Themes, SyntaxRenderer, DiagnosticRenderer, FileRenderer
require_relative "highlight/cli"                 # depends on: Highlighter
```

**Verification:** `(cd herb-highlighter && ./bin/rspec)` should pass (0 examples, 0 failures).

**Implementation Tasks:**
- [x] Create `herb-highlighter/` directory structure
- [x] Write `herb-highlighter.gemspec` (runtime dep: `herb` only)
- [x] Write `Gemfile` (dev deps: rspec, rubocop, rbs-inline, steep, rake)
- [x] Write `Rakefile` (spec + rubocop + steep tasks, same as herb-printer)
- [x] Write `Steepfile` and `rbs_collection.yaml`
- [x] Create `bin/` binstubs (rake, rbs, rbs-inline, rspec, rubocop, steep)
- [x] Create `exe/herb-highlight` (shebang + require + `CLI.start`)
- [x] Create `lib/herb/highlight.rb` (require_relative in load order)
- [x] Create `lib/herb/highlight/version.rb` (`VERSION = "0.1.0"`)
- [x] Create `spec/spec_helper.rb`
- [x] Verify: `(cd herb-highlighter && ./bin/rspec)` passes with 0 examples
- [x] Add `herb-highlighter` job to `.github/workflows/ci.yml` (same pattern as other gems)

---

###### Step 0.2: `Herb::Highlight::Color`

**File:** `lib/herb/highlight/color.rb`

**Role:** ANSI color utilities. Converts hex/named colors to escape sequences, applies them to text.
Mirrors TypeScript `color.ts`. Is a **module** (no instances; all class-level methods/constants).

**Constants:**

```ruby
# All named ANSI colors accepted by themes (mirrors TypeScript color.ts `colors` object).
# Keys match the TypeScript names exactly (camelCase where TypeScript uses camelCase).
NAMED_COLORS = {
  "reset"         => "\e[0m",
  "bold"          => "\e[1m",
  "dim"           => "\e[2m",
  "black"         => "\e[30m",
  "red"           => "\e[31m",
  "green"         => "\e[32m",
  "yellow"        => "\e[33m",
  "blue"          => "\e[34m",
  "magenta"       => "\e[35m",
  "cyan"          => "\e[36m",
  "white"         => "\e[37m",
  "gray"          => "\e[90m",
  "brightRed"     => "\e[91m",
  "brightGreen"   => "\e[92m",
  "brightYellow"  => "\e[93m",
  "brightBlue"    => "\e[94m",
  "brightMagenta" => "\e[95m",
  "brightCyan"    => "\e[96m",
  "bgBlack"       => "\e[40m",
  "bgRed"         => "\e[41m",
  "bgGreen"       => "\e[42m",
  "bgYellow"      => "\e[43m",
  "bgBlue"        => "\e[44m",
  "bgMagenta"     => "\e[45m",
  "bgCyan"        => "\e[46m",
  "bgWhite"       => "\e[47m",
  "bgGray"        => "\e[100m",
}.freeze #: Hash[String, String]
```

**Public class methods:**

```ruby
# Converts a color value to an ANSI foreground escape sequence.
# Returns nil for unknown/unsupported color names.
#
# @rbs color: String -- hex "#RRGGBB" or named ANSI color
def self.ansi_code(color) #: String?
```
- Hex (`color.start_with?("#") && color.length == 7`): returns `"\e[38;2;#{r};#{g};#{b}m"` (24-bit true-color)
- Named: returns `NAMED_COLORS[color]` (nil if not found)

```ruby
# Converts a color value to an ANSI background escape sequence.
# Returns nil for unknown/unsupported color names.
#
# @rbs color: String
def self.background_ansi_code(color) #: String?
```
- Hex: returns `"\e[48;2;#{r};#{g};#{b}m"` (note 48 not 38)
- Named: looks up only bg* keys, OR accepts any named color key (caller decides)
  - Simplest: same lookup as `ansi_code` but replace `38` with `48` in the result

```ruby
# Applies ANSI foreground (and optional background) color to text.
# Respects the NO_COLOR environment variable: if ENV.key?("NO_COLOR"), returns text unchanged.
#
# @rbs text: String
# @rbs color: String -- hex or named color name
# @rbs background_color: String? -- optional background color (hex or named)
def self.colorize(text, color, background_color: nil) #: String
```
- If `ENV.key?("NO_COLOR")` → return `text` unchanged (regardless of value)
- If `ansi_code(color)` is nil → return `text` unchanged
- Format: `"#{background_escape}#{foreground_escape}#{text}\e[0m"`
  - `background_escape` is empty string when `background_color` is nil or unknown
  - Reset is always `"\e[0m"` (not `NAMED_COLORS["reset"]`, same value)

```ruby
# Maps a diagnostic severity string to a named color.
# Used by formatters to color severity labels and symbols.
#
# @rbs severity: String
def self.severity_color(severity) #: String
```
- `"error"` → `"brightRed"`
- `"warning"` → `"brightYellow"`
- `"info"` → `"cyan"`
- `"hint"` → `"gray"`
- anything else → `"brightYellow"`

**Design notes:**
- `Herb::Lint::ConsoleUtils#colorize` (which uses symbol keys `:red`, `:gray`) is a **separate**
  color system for UI chrome that stays in `herb-lint`. `Herb::Highlight::Color` uses string keys
  matching the TypeScript names and is for syntax highlighting only.
- No `bold:` or `dim:` keyword args — callers combine `"bold"` + foreground using the escape
  sequences directly, or pass `NAMED_COLORS["bold"]` as a prefix.

**Tests (`spec/herb/highlight/color_spec.rb`):**
- `.ansi_code` with hex → 24-bit escape
- `.ansi_code` with named → ANSI code
- `.ansi_code` with unknown name → nil
- `.colorize` with hex → includes `\e[38;2;…m`
- `.colorize` with named → includes correct escape
- `.colorize` with `NO_COLOR` set → plain text
- `.colorize` with background_color → includes `\e[48;2;…m` prefix
- `.severity_color` for each severity value

**Implementation Tasks:**
- [x] Create `lib/herb/highlight/color.rb`
- [x] Implement `NAMED_COLORS` constant (all 29 entries matching TypeScript `colors` object)
- [x] Implement `.ansi_code(color)` — hex → 24-bit `\e[38;2;R;G;Bm`; named → `NAMED_COLORS` lookup
- [x] Implement `.background_ansi_code(color)` — hex → `\e[48;2;R;G;Bm`; named → lookup
- [x] Implement `.colorize(text, color, background_color: nil)` with `NO_COLOR` env var support
- [x] Implement `.severity_color(severity)` mapping
- [x] Write `spec/herb/highlight/color_spec.rb`

---

###### Step 0.3: `Herb::Highlight::Themes`

**File:** `lib/herb/highlight/themes.rb`

**Role:** Theme registry — stores named token-color mappings and provides lookup/validation.
Also supports loading custom themes from JSON files. Mirrors TypeScript `themes.ts`.
Is a **module** (all class-level state and methods).

**ColorScheme keys** — the complete set of `TOKEN_*` strings and special keys that a theme can
define. All values are `String?` (hex `"#RRGGBB"`, named color, or nil = no color applied).

```
TOKEN_WHITESPACE            whitespace between tokens
TOKEN_NBSP                  non-breaking space
TOKEN_NEWLINE               newline character
TOKEN_IDENTIFIER            generic identifier (contextual: see SyntaxRenderer)
TOKEN_EQUALS                = in attribute assignment
TOKEN_QUOTE                 " or ' in attribute values
TOKEN_HTML_TAG_START        < (opening tags)
TOKEN_HTML_TAG_START_CLOSE  </ (closing tags)
TOKEN_HTML_TAG_END          > (end of tag)
TOKEN_HTML_TAG_SELF_CLOSE   /> (self-closing end)
TOKEN_HTML_DOCTYPE          <!DOCTYPE
TOKEN_HTML_COMMENT_START    <!-- (also used for content inside comments)
TOKEN_HTML_COMMENT_END      -->
TOKEN_ERB_START             <%, <%=, <%==, <%-
TOKEN_ERB_CONTENT           Ruby code inside ERB tags (identifiers/operators)
TOKEN_ERB_END               %>, -%>
TOKEN_ERB_COMMENT           <%# comment %>
TOKEN_ERROR                 tokenizer error tokens
TOKEN_EOF                   end of file
RUBY_KEYWORD                Ruby keywords inside TOKEN_ERB_CONTENT (special key, not a token type)
TOKEN_HTML_ATTRIBUTE_NAME   attribute name (e.g. class, href) — contextual from TOKEN_IDENTIFIER
TOKEN_HTML_ATTRIBUTE_VALUE  attribute value inside quotes — contextual from TOKEN_IDENTIFIER
```

**State:** Module-level `@registry = {}` (`Hash[String, Hash[String, String?]]`)

**Class methods:**

```ruby
# Registers a theme.
# @rbs name: String
# @rbs mapping: Hash[String, String?]
def self.register(name, mapping) #: void

# Returns the color mapping for a named theme, or nil if not registered.
# @rbs name: String
def self.find(name) #: Hash[String, String?]?

# Returns all registered theme names.
def self.names #: Array[String]

# Returns true if name is a registered theme.
# @rbs name: String
def self.valid?(name) #: bool

# Returns true if input looks like a file path rather than a theme name.
# Heuristic: contains "/" or "\" or ends with ".json"
# @rbs input: String
def self.custom?(input) #: bool

# Reads and parses a JSON theme file.
# Raises Errno::ENOENT if file not found, JSON::ParserError if invalid JSON.
# Returns the parsed hash (no validation of keys).
# @rbs path: String
def self.load_custom(path) #: Hash[String, String?]

# Resolves a theme name or file path to a color mapping.
# Returns nil if name is not registered (or raises if custom path fails).
# @rbs input: String
def self.resolve(input) #: Hash[String, String?]?
```

**`resolve` logic:**
```ruby
if custom?(input)
  load_custom(input)   # raises on error
else
  find(input)          # nil if not registered
end
```

**DEFAULT_THEME constant:**
```ruby
DEFAULT_THEME = "onedark" #: String
```
(The `onedark` theme colors are registered in Step 2, not here.)

**Tests (`spec/herb/highlight/themes_spec.rb`):**
- `.register` + `.find` roundtrip
- `.find` returns nil for unknown name
- `.names` returns registered names
- `.valid?` true/false
- `.custom?` with `/path/to/file.json`, `.\file.json`, `mytheme.json`, `"onedark"` (false)
- `.load_custom` with valid JSON file → hash
- `.load_custom` with missing file → raises `Errno::ENOENT`
- `.resolve` with registered name → hash
- `.resolve` with unregistered name → nil
- `.resolve` with file path → loads custom
- `DEFAULT_THEME == "onedark"`

**Implementation Tasks:**
- [x] Create `lib/herb/highlight/themes.rb`
- [x] Implement module-level `@registry` and `.register`, `.find`, `.names`, `.valid?`
- [x] Implement `.custom?(input)` (file path heuristic: contains `/`, `\`, or ends with `.json`)
- [x] Implement `.load_custom(path)` (reads and JSON-parses file; raises on error)
- [x] Implement `.resolve(input)` (dispatches to `.load_custom` or `.find`)
- [x] Define `DEFAULT_THEME = "onedark"` constant
- [x] Write `spec/herb/highlight/themes_spec.rb`

---

###### Step 0.4: `Herb::Highlight::SyntaxRenderer`

**File:** `lib/herb/highlight/syntax_renderer.rb`

**Role:** Token-level ERB/HTML syntax highlighting. Takes a single line of source text, tokenizes
it with `Herb.lex()`, and returns the same text with ANSI codes injected around each token.
Mirrors TypeScript `SyntaxRenderer`.

**Fallback:** Returns source unchanged (no ANSI codes) when:
- No theme was given (`theme_name: nil` and `theme: nil`)
- Theme name not found in registry
- `Herb.lex(source)` result has errors

**Interface:**

```ruby
# @rbs theme_name: String? -- looked up via Themes.find(); nil = plain text
# @rbs theme: Hash[String, String?]? -- pre-resolved theme (for testing; takes priority over theme_name)
def initialize(theme_name: nil, theme: nil) #: void

# Applies syntax highlighting to a single line of ERB/HTML source.
# @rbs source: String
def render(source) #: String
```

**Token-to-color logic:**

The renderer maintains a mutable state hash (state machine) as it walks tokens left-to-right.

State fields:
```
in_tag:                    bool   — currently inside an HTML tag (between < and >)
in_quotes:                 bool   — inside a quoted attribute value
quote_char:                String — the active quote character (" or ')
tag_name:                  String — first identifier seen after < (the element name)
is_closing_tag:            bool   — true after </
expecting_attribute_name:  bool
expecting_attribute_value: bool
in_comment:                bool   — inside <!-- ... -->
```

State transitions on each token type:

| Token type | State changes |
|------------|---------------|
| `TOKEN_HTML_TAG_START` | `in_tag=true`, `is_closing_tag=false`, clear attr flags |
| `TOKEN_HTML_TAG_START_CLOSE` | `in_tag=true`, `is_closing_tag=true`, clear attr flags |
| `TOKEN_HTML_TAG_END`, `TOKEN_HTML_TAG_SELF_CLOSE` | `in_tag=false`, `tag_name=""`, `is_closing_tag=false`, clear attr flags |
| `TOKEN_IDENTIFIER` (first in tag) | set `tag_name`, `expecting_attribute_name = !is_closing_tag` |
| `TOKEN_IDENTIFIER` (subsequent, expecting attr name) | `expecting_attribute_name=false`, `expecting_attribute_value=true` |
| `TOKEN_EQUALS` (in tag) | `expecting_attribute_value=true` |
| `TOKEN_QUOTE` (in tag, not in quotes) | `in_quotes=true`, `quote_char=token_text` |
| `TOKEN_QUOTE` (in tag, in quotes, matching char) | `in_quotes=false`, `quote_char=""`, `expecting_attribute_name=true`, `expecting_attribute_value=false` |
| `TOKEN_WHITESPACE` (in tag, not in quotes, tag_name known) | `expecting_attribute_name=true`, `expecting_attribute_value=false` |
| `TOKEN_HTML_COMMENT_START` | `in_comment=true` |
| `TOKEN_HTML_COMMENT_END` | `in_comment=false` |

Color selection per token (after state is updated):

```
in_comment && token NOT in [TOKEN_HTML_COMMENT_START, TOKEN_HTML_COMMENT_END,
                             TOKEN_ERB_START, TOKEN_ERB_CONTENT, TOKEN_ERB_END]
  → theme["TOKEN_HTML_COMMENT_START"]   (content inherits comment color)

TOKEN_HTML_TAG_START        → theme["TOKEN_HTML_TAG_START"]
TOKEN_HTML_TAG_START_CLOSE  → theme["TOKEN_HTML_TAG_START"]
TOKEN_HTML_TAG_END          → theme["TOKEN_HTML_TAG_END"]
TOKEN_HTML_TAG_SELF_CLOSE   → theme["TOKEN_HTML_TAG_END"]
TOKEN_HTML_DOCTYPE          → theme["TOKEN_HTML_DOCTYPE"]
TOKEN_HTML_COMMENT_START    → theme["TOKEN_HTML_COMMENT_START"]
TOKEN_HTML_COMMENT_END      → theme["TOKEN_HTML_COMMENT_END"]
TOKEN_ERB_START             → theme["TOKEN_ERB_START"]
TOKEN_ERB_CONTENT           → special: highlight_ruby_code (see below)
TOKEN_ERB_END               → theme["TOKEN_ERB_END"]
TOKEN_EQUALS                → theme["TOKEN_EQUALS"]
TOKEN_QUOTE (in tag)        → theme["TOKEN_QUOTE"]
TOKEN_IDENTIFIER:
  - if token_text == tag_name (tag element name)  → theme["TOKEN_HTML_TAG_START"]
  - if expecting_attribute_name                   → theme["TOKEN_HTML_ATTRIBUTE_NAME"]
  - if in_quotes                                  → theme["TOKEN_HTML_ATTRIBUTE_VALUE"]
  - otherwise                                     → nil (no color)
anything else               → nil (no color)
```

**`highlight_ruby_code(code)` method:**
Splits the ERB content string by word boundaries and colorizes Ruby keywords and identifiers:
- RUBY_KEYWORDS (see below) → `Color.colorize(word, theme["RUBY_KEYWORD"])` if color set
- Identifiers (match `/\A\w/`) → `Color.colorize(word, theme["TOKEN_ERB_CONTENT"] || theme["TOKEN_IDENTIFIER"])`
- Punctuation/operators → no color

```ruby
RUBY_KEYWORDS = %w[
  if unless else elsif end def class module return yield break next
  case when then while until for in do begin rescue ensure retry
  raise super self nil true false and or not
].freeze #: Array[String]
```

Split pattern: `code.split(/(\s+|[^\w\s]+)/)`  — preserves separators so rejoining reconstructs original.

**Color application:** uses `Color.colorize(text, color_value)` — do NOT inline ANSI escape building.

**Tests (`spec/herb/highlight/syntax_renderer_spec.rb`):**
- `render` with nil theme → returns source unchanged
- `render` with unregistered theme_name → returns source unchanged
- `render` with lex errors → returns source unchanged
- `render` strips ANSI: `rendered.gsub(/\e\[[^m]*m/, "")` equals original source
- HTML tag tokens colored (using test theme with known colors)
- ERB delimiters colored
- Ruby keywords inside ERB colored
- Attribute names use `TOKEN_HTML_ATTRIBUTE_NAME` (not hardcoded hex)
- Attribute values use `TOKEN_HTML_ATTRIBUTE_VALUE` (not hardcoded hex)
- Comment content inherits `TOKEN_HTML_COMMENT_START` color
- Hex colors produce `\e[38;2;R;G;Bm`
- Named colors produce correct ANSI codes

**Implementation Tasks:**
- [x] Create `lib/herb/highlight/syntax_renderer.rb`
- [x] Implement `initialize(theme_name: nil, theme: nil)` with theme resolution
- [x] Implement `render(source)` with `Herb.lex()` and plain-text fallback
- [x] Implement `initial_state` hash
- [x] Implement `update_state(state, token, token_text)` — all token type transitions
- [x] Implement `contextual_color(state, token, token_text)` — color selection logic
- [x] Implement `render_token(token, token_text, color)` — special-casing `TOKEN_ERB_CONTENT`
- [x] Define `RUBY_KEYWORDS` constant
- [x] Implement `highlight_ruby_code(code)` — keyword + identifier coloring via `Color.colorize`
- [x] Write `spec/herb/highlight/syntax_renderer_spec.rb`

---

###### Step 0.5: `Herb::Highlight::DiagnosticRenderer`

**File:** `lib/herb/highlight/diagnostic_renderer.rb`

**Role:** Renders source code context around a single offense. Shows N context lines before and
after the offense line, each prefixed with a formatted line number. Appends a caret (`^`) row
below the offense line pointing to the column. Mirrors TypeScript `DiagnosticRenderer`.

**This class does NOT render the offense header** (location, message, rule name). The header is
the formatter's responsibility (`DetailedFormatter`).

**Interface:**

```ruby
# @rbs syntax_renderer: SyntaxRenderer
# @rbs context_lines: Integer
# @rbs tty: bool -- when false, no ANSI codes are emitted
def initialize(syntax_renderer: SyntaxRenderer.new, context_lines: 2, tty: true) #: void

# @rbs source_lines: Array[String]
# @rbs line: Integer -- 1-based offense line number
# @rbs column: Integer -- 1-based offense column
# @rbs end_line: Integer? -- 1-based end line (nil = same as line)
# @rbs end_column: Integer? -- 1-based end column (nil = column + 1)
def render(source_lines, line:, column:, end_line: nil, end_column: nil) #: String
```

**Output format** (with `context_lines: 2`, offense at line 4, column 8, length 3):
```
  2 | <body>
  3 | <div>
  4 | <div class="foo">
     |        ^^^
  5 | </div>
```

**Line number formatting:**
- Line number width: `end_display_line.to_s.length` (right-justified)
  - `end_display_line = [source_lines.size, line + context_lines].min`
- Each rendered line: `"  #{line_num_str}#{separator}#{highlighted_content}\n"`
  - Context lines: `line_num_str = Color.colorize(num.to_s.rjust(width), "gray")`
    `separator = Color.colorize(" | ", "gray")`
  - Offense line: `line_num_str = Color.colorize(num.to_s.rjust(width), "brightRed")`
    `separator = Color.colorize(" | ", "brightRed")`
  - All ANSI disabled when `tty: false`
- Source content: `syntax_renderer.render(content)` (already handles its own tty check via theme)

**Caret row** (only for the offense line):
```
"  #{' ' * width} | #{' ' * [column - 1, 0].max}#{caret}\n"
```
- `caret = Color.colorize("^" * caret_length, "brightRed")`
- `caret_length`: if `end_line.nil? || end_line == line` → `[end_column - column + 1, 1].max`; else `1`
- No ANSI on caret when `tty: false`

**Tests (`spec/herb/highlight/diagnostic_renderer_spec.rb`):**
- Correct number of output lines (context + offense + caret)
- Line numbers are right-justified
- Offense line uses different color than context lines (check ANSI codes)
- Caret appears on the correct column
- Caret length for multi-column offense
- Caret length for single character offense
- `tty: false` → no ANSI codes in output
- Source content is syntax-highlighted (mock SyntaxRenderer for isolation)
- Handles offense at line 1 (no lines before)
- Handles offense at last line (no lines after)

**Implementation Tasks:**
- [x] Create `lib/herb/highlight/diagnostic_renderer.rb`
- [x] Implement `initialize(syntax_renderer:, context_lines: 2, tty: true)`
- [x] Implement `render(source_lines, line:, column:, end_line: nil, end_column: nil)`
  - [x] Context range calculation (clamp to source bounds)
  - [x] Line number width calculation
  - [x] Per-line rendering: context color vs. offense line color
  - [x] Caret row: column offset spacing + `^` * caret_length
- [x] Write `spec/herb/highlight/diagnostic_renderer_spec.rb`

---

###### Step 0.6: `Herb::Highlight::FileRenderer`

**File:** `lib/herb/highlight/file_renderer.rb`

**Role:** Renders a complete ERB/HTML source file with line numbers and syntax highlighting.
Used by the `herb-highlight` CLI to display a highlighted file. Mirrors TypeScript `FileRenderer`.

**Not used by `herb-lint`'s `DetailedFormatter`** (which uses `DiagnosticRenderer` instead).

**Interface:**

```ruby
# @rbs syntax_renderer: SyntaxRenderer
# @rbs tty: bool
def initialize(syntax_renderer: SyntaxRenderer.new, tty: true) #: void

# Renders all lines of source with sequential line numbers.
# @rbs source: String
# @rbs focus_line: Integer? -- 1-based line to render in red (nil = no focus)
def render(source, focus_line: nil) #: String
```

**Output format** (5-line file, no focus):
```
  1 | <html>
  2 | <body>
  3 | <div>hello</div>
  4 | </body>
  5 | </html>
```

**Line number formatting:**
- Width: total line count string width
- All lines: gray line numbers (unless focus_line)
- `focus_line`: red+bold line number and separator (same as `DiagnosticRenderer` offense line)
- Each line ends with `\n`

**Tests (`spec/herb/highlight/file_renderer_spec.rb`):**
- Output has correct number of lines
- Line numbers are sequential and right-justified
- Focus line uses different color
- `tty: false` → no ANSI codes
- Empty source → empty output (or `""`)
- Single-line source → 1 line output

**Implementation Tasks:**
- [x] Create `lib/herb/highlight/file_renderer.rb`
- [x] Implement `initialize(syntax_renderer:, tty: true)`
- [x] Implement `render(source, focus_line: nil)`
  - [x] Split source into lines
  - [x] Line number width calculation
  - [x] Per-line rendering with optional focus coloring
- [x] Write `spec/herb/highlight/file_renderer_spec.rb`

---

###### Step 0.7: `Herb::Highlight::Highlighter`

**File:** `lib/herb/highlight/highlighter.rb`

**Role:** Main orchestrator. Creates and wires together `SyntaxRenderer`, `DiagnosticRenderer`,
and `FileRenderer`. Provides a simple top-level API. Mirrors TypeScript `Highlighter`.

**Interface:**

```ruby
# @rbs theme_name: String? -- nil = plain text (no highlighting)
# @rbs context_lines: Integer
# @rbs tty: bool
def initialize(theme_name: nil, context_lines: 2, tty: true) #: void

# Renders a complete source file with line numbers and highlighting.
# @rbs source: String
# @rbs focus_line: Integer?
def highlight_source(source, focus_line: nil) #: String

# Renders source context for a single offense (used when embedding in other tools).
# @rbs source_lines: Array[String]
# @rbs line: Integer
# @rbs column: Integer
# @rbs end_line: Integer?
# @rbs end_column: Integer?
def render_diagnostic(source_lines, line:, column:, end_line: nil, end_column: nil) #: String
```

**Internal wiring:**
```ruby
@syntax_renderer     = SyntaxRenderer.new(theme_name: theme_name)
@file_renderer       = FileRenderer.new(syntax_renderer: @syntax_renderer, tty: tty)
@diagnostic_renderer = DiagnosticRenderer.new(
  syntax_renderer: @syntax_renderer,
  context_lines: context_lines,
  tty: tty
)
```

**Tests (`spec/herb/highlight/highlighter_spec.rb`):**
- `highlight_source` delegates to `FileRenderer#render`
- `render_diagnostic` delegates to `DiagnosticRenderer#render`
- With nil theme → plain text output from both methods
- With registered theme → ANSI codes in output

**Implementation Tasks:**
- [x] Create `lib/herb/highlight/highlighter.rb`
- [x] Implement `initialize(theme_name: nil, context_lines: 2, tty: true)` — wire all components
- [x] Implement `highlight_source(source, focus_line: nil)` — delegate to `FileRenderer#render`
- [x] Implement `render_diagnostic(source_lines, line:, column:, end_line: nil, end_column: nil)` — delegate to `DiagnosticRenderer#render`
- [x] Write `spec/herb/highlight/highlighter_spec.rb`

---

###### Step 0.8: `Herb::Highlight::CLI`

**File:** `lib/herb/highlight/cli.rb`
**Executable:** `exe/herb-highlight`

**Role:** The `herb-highlight` command. Reads an ERB file, applies syntax highlighting, writes to
stdout. Mirrors TypeScript's `herb-highlight` CLI. Mirrors option names from TypeScript CLI.

**`exe/herb-highlight` content:**
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "herb/highlight"
Herb::Highlight::CLI.start
```

**Interface:**

```ruby
# @rbs argv: Array[String]
def self.start(argv = ARGV) #: void
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--theme THEME` | String | `Themes::DEFAULT_THEME` | Built-in theme name or path to JSON file |
| `--focus LINE` | Integer | nil | 1-based line to focus/highlight |
| `--context-lines N` | Integer | 2 | Context lines around focus (only with --focus) |
| `--version` | flag | — | Print `herb-highlighter VERSION` and exit 0 |
| `--help` | flag | — | Print usage message and exit 0 |

**Positional argument:** `FILE` — path to ERB file to highlight (required unless `--version`/`--help`)

**Behavior:**
- Reads `FILE`, passes source to `Highlighter#highlight_source`
- TTY detection: `$stdout.tty?`
- When `--focus LINE` given: calls `Highlighter#highlight_source(source, focus_line: LINE.to_i)`
- When `--theme` is a file path (`Themes.custom?`) → resolved via `Themes.load_custom`
- Error conditions → stderr message + exit 1:
  - No file argument
  - File not found
  - Invalid JSON theme file

**Tests (`spec/herb/highlight/cli_spec.rb`):**
- `--version` → prints version, exits 0
- `--help` → prints usage, exits 0
- No arguments → exits 1
- File not found → exits 1 with error message on stderr
- Valid file → prints highlighted content to stdout
- `--theme onedark` → applies theme (test with a registered theme)
- `--focus 2` → highlights line 2

**Implementation Tasks:**
- [ ] Create `lib/herb/highlight/cli.rb`
- [ ] Implement `self.start(argv = ARGV)` with `OptionParser`
- [ ] Implement `--theme`, `--focus`, `--context-lines`, `--version`, `--help` options
- [ ] Implement file reading and error handling (no file → usage + exit 1; not found → stderr + exit 1)
- [ ] Make `exe/herb-highlight` executable (`chmod +x`)
- [ ] Write `spec/herb/highlight/cli_spec.rb`

---

##### Step 1: herb-lint Integration

**Prerequisites:** Step 0 complete (herb-highlighter gem published/path-available).

Wire `herb-lint` to use `herb-highlighter` instead of its embedded highlighting code.
**Start fresh** — remove current herb-lint highlighting implementation and rebuild the integration
using the herb-highlighter gem.

**What to DELETE from herb-lint:**

| File | Reason |
|------|--------|
| `lib/herb/lint/highlighter.rb` | Replaced by `Herb::Highlight::SyntaxRenderer` |
| `lib/herb/lint/themes.rb` | Replaced by `Herb::Highlight::Themes` |
| `sig/herb/lint/highlighter.rbs` | Signature for deleted class |
| `sig/herb/lint/themes.rbs` | Signature for deleted module |
| `spec/herb/lint/highlighter_spec.rb` | Tests moved to herb-highlighter |

**What to keep unchanged:**
- `lib/herb/lint/console_utils.rb` — still used for UI chrome colors (`:red`, `:gray` symbols)

**Files to update:**

`herb-lint.gemspec` — add runtime dependency:
```ruby
spec.add_dependency "herb-highlighter", "~> 0.1.0"
```

`lib/herb/lint.rb` — remove the two lines:
```ruby
require_relative "lint/highlighter"
require_relative "lint/themes"
```
(no new requires needed; `require "herb/highlight"` goes in `detailed_formatter.rb`)

`lib/herb/lint/formatter/detailed_formatter.rb`:
- Remove `require_relative "../highlighter"` at top; add `require "herb/highlight"`
- Add `theme_name: nil` keyword argument to `initialize`
- In `initialize`: replace `@highlighter` with `@diagnostic_renderer`:
  ```ruby
  @diagnostic_renderer = Herb::Highlight::DiagnosticRenderer.new(
    syntax_renderer: Herb::Highlight::SyntaxRenderer.new(theme_name:),
    context_lines: CONTEXT_LINES,
    tty: io.tty?
  )
  ```
- Replace `print_source_lines` body: delegate entirely to `@diagnostic_renderer`:
  ```ruby
  def print_source_lines(offense, source_lines)
    rendered = @diagnostic_renderer.render(
      source_lines,
      line: offense.line,
      column: offense.column,
      end_line: offense.location.end.line,
      end_column: offense.location.end.column
    )
    io.print(rendered)
  end
  ```
- Delete `print_source_line` and `print_column_indicator` private methods
  (that logic now lives in `DiagnosticRenderer`)

`sig/herb/lint/formatter/detailed_formatter.rbs`:
- Remove `@highlighter` type annotation
- Add `@diagnostic_renderer: Herb::Highlight::DiagnosticRenderer`

**Verification:**
```bash
(cd herb-lint && ./bin/rspec)      # all existing tests must pass
(cd herb-lint && ./bin/rubocop)    # no offenses
(cd herb-lint && ./bin/steep check) # no type errors
```

**Implementation Tasks:**
- [ ] Delete `lib/herb/lint/highlighter.rb` and related sig/spec files
- [ ] Delete `lib/herb/lint/themes.rb` and related sig file
- [ ] Add `herb-highlighter` dependency to `herb-lint.gemspec`
- [ ] Add `require "herb/highlight"` to `detailed_formatter.rb`; remove `require_relative "../highlighter"`
- [ ] Update `lib/herb/lint.rb` (remove the two require_relative lines)
- [ ] Add `theme_name: nil` to `DetailedFormatter#initialize`; wire `DiagnosticRenderer` with `SyntaxRenderer`
- [ ] Replace `print_source_lines` body with `@diagnostic_renderer.render(...)` delegation
- [ ] Delete `print_source_line` and `print_column_indicator` private methods
- [ ] Update RBS signature for `detailed_formatter.rbs` (`@diagnostic_renderer` type)
- [ ] Verify `herb-lint` test suite passes

---

##### Step 2: Port `onedark` Theme (default theme)

Ports the `onedark` theme as the first built-in theme and sets it as the default.
After this step, `DetailedFormatter` produces colored output by default.

**TypeScript Reference:**
- `javascript/packages/highlighter/src/themes.ts` — `onedark` color definitions
- `DEFAULT_THEME = "onedark"`

**Implementation Tasks (depends on Step 0):**
- [ ] Port `onedark` theme into `Herb::Highlight::Themes` using the private `register` method
  - Use `Themes.send(:register, "onedark", { ... })` at the bottom of `themes.rb` (or in a separate file loaded by `highlight.rb`)
  - Once registered, `Themes.required_keys` returns `onedark`'s keys, activating `load_custom` key validation
- [ ] Set `onedark` as the default theme in `DetailedFormatter`
- [ ] Write unit tests for `onedark` theme
  - [ ] Verify `Themes.valid?("onedark")` returns true
  - [ ] Verify `Themes.custom?("onedark")` returns false
  - [ ] Verify `load_custom` raises on a custom theme missing required keys (validation now active)

---

##### Step 3: Remaining Built-in Themes (`github-light`, `dracula`, `tokyo-night`, `simple`)

Ports the remaining four built-in themes using the structure established in Steps 0–2.
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
- Validate theme name against `Herb::Highlight::Themes.names` or check for file path existence
- Pass theme to `DetailedFormatter`, which passes it to `Herb::Highlight::SyntaxRenderer`

**TypeScript Reference:**
```typescript
// argument-parser.ts
const theme = values.theme || DEFAULT_THEME

// detailed-formatter.ts
this.highlighter = new Highlighter(this.theme)
```

**Implementation Tasks (depends on Steps 0–3):**
- [ ] Add `--theme THEME` CLI option
- [ ] Pass theme to `DetailedFormatter`
- [ ] Pass theme from `DetailedFormatter` to `Herb::Highlight::SyntaxRenderer`
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
