# herb-format Design Document

Architectural design for the ERB template formatter.

## Overview

herb-format is a code formatter for ERB templates that provides a CLI interface compatible with the TypeScript version `@herb-tools/formatter`. This document describes the system architecture, component responsibilities, and public interfaces.

## Directory Structure

```
herb-format/
├── lib/
│   └── herb/
│       └── format/
│           ├── version.rb
│           ├── cli.rb
│           ├── runner.rb
│           ├── formatter.rb
│           ├── formatter_factory.rb
│           ├── format_ignore.rb
│           ├── context.rb
│           ├── format_result.rb
│           ├── aggregated_result.rb
│           ├── format_printer.rb
│           ├── format_helpers.rb
│           ├── element_analysis.rb
│           ├── element_analyzer.rb
│           └── errors.rb
├── exe/
│   └── herb-format
├── spec/
│   └── herb/
│       └── format/
│           ├── cli_spec.rb
│           ├── runner_spec.rb
│           ├── formatter_spec.rb
│           ├── format_ignore_spec.rb
│           ├── context_spec.rb
│           ├── format_result_spec.rb
│           └── format_printer_spec.rb
├── herb-format.gemspec
└── Gemfile

# Rewriter infrastructure (herb-rewriter gem):
herb-rewriter/
└── lib/
    └── herb/
        └── rewriter/
            ├── version.rb
            ├── ast_rewriter.rb
            ├── string_rewriter.rb
            ├── registry.rb
            ├── context.rb
            └── built_ins/
                └── tailwind_class_sorter.rb
```

## Class Design

### Module Structure

```
Herb::Format
├── CLI              # Command line interface
├── Runner           # Format execution orchestration
├── Formatter        # Core formatting implementation
├── FormatterFactory # Formatter instance creation (Factory Pattern)
├── FormatIgnore     # Ignore directive detection (AST-based)
├── Context          # Format execution context
├── FormatResult     # Format result for a single file
├── AggregatedResult # Aggregated result for multiple files
├── FormatPrinter    # AST formatting (extends Printer::Base)
├── FormatHelpers    # Constants and helper functions for formatting decisions
├── ElementAnalysis  # Data structure for element formatting decisions
├── ElementAnalyzer  # Analyzes HTMLElementNode to determine inline/block layout
└── Errors           # Custom exceptions

# Rewriter infrastructure lives in the herb-rewriter gem:
Herb::Rewriter
├── ASTRewriter      # Abstract base for pre-format AST-to-AST rewriters
├── StringRewriter   # Abstract base for post-format string-to-string rewriters
├── Registry         # Rewriter registration and lookup (Registry Pattern)
├── Context          # Rewrite execution context
└── BuiltIns
    └── TailwindClassSorter  # Sort Tailwind CSS classes
```

## Data Structures

### Herb::Format::FormatResult

Represents the formatting result for a single file.

```rbs
class Herb::Format::FormatResult
  attr_reader file_path: String
  attr_reader original: String
  attr_reader formatted: String
  attr_reader ignored: bool
  attr_reader error: StandardError?

  def initialize: (
    file_path: String,
    original: String,
    formatted: String,
    ?ignored: bool,
    ?error: StandardError?
  ) -> void

  def ignored?: () -> bool
  def error?: () -> bool
  def changed?: () -> bool
  def diff: () -> String?
  def to_h: () -> Hash[Symbol, untyped]
end
```

### Herb::Format::AggregatedResult

Aggregates results across multiple files.

```rbs
class Herb::Format::AggregatedResult
  attr_reader results: Array[FormatResult]

  def initialize: (Array[FormatResult] results) -> void

  def file_count: () -> Integer
  def changed_count: () -> Integer
  def ignored_count: () -> Integer
  def error_count: () -> Integer
  def all_formatted?: () -> bool
  def to_h: () -> Hash[Symbol, untyped]
end
```

## Component Details

### Herb::Format::CLI

**Responsibility:** Command-line interface orchestration.

**Exit Codes:**
- `EXIT_SUCCESS = 0` - All files formatted (or already formatted with `--check`)
- `EXIT_FORMAT_NEEDED = 1` - Files need formatting (with `--check`) or formatting error
- `EXIT_RUNTIME_ERROR = 2` - Configuration or runtime error

```rbs
class Herb::Format::CLI
  EXIT_SUCCESS: Integer
  EXIT_FORMAT_NEEDED: Integer
  EXIT_RUNTIME_ERROR: Integer

  @argv: Array[String]
  @stdout: IO
  @stderr: IO
  @stdin: IO
  @options: Hash[Symbol, untyped]

  attr_reader argv: Array[String]
  attr_reader stdout: IO
  attr_reader stderr: IO
  attr_reader stdin: IO

  def initialize: (
    ?Array[String] argv,
    ?stdout: IO,
    ?stderr: IO,
    ?stdin: IO
  ) -> void

  def run: () -> Integer

  private

  def parse_options: () -> Hash[Symbol, untyped]
  def handle_init: () -> Integer
  def handle_version: () -> Integer
  def handle_help: () -> Integer
  def handle_stdin: () -> Integer
  def load_config: () -> Herb::Config::FormatterConfig
  def determine_exit_code: (AggregatedResult result, bool check_mode) -> Integer
end
```

**Processing Flow:**
1. Parse command-line options
2. Handle special flags (--init, --version, --help)
3. Handle --stdin mode (read from stdin, output to stdout)
4. Load configuration via Herb::Config::Loader
5. Create and run Runner
6. Report results (diff output in check mode)
7. Determine exit code based on formatting results

**Command-Line Options:**
- `--init` - Generate default .herb.yml
- `--check` - Check if files are formatted without modifying them
- `--write` - Write formatted output back to files (default behavior)
- `--force` - Override inline ignore directives
- `--stdin` - Read from standard input (output to stdout)
- `--stdin-filepath PATH` - Path to use for configuration lookup when using stdin
- `--config PATH` - Custom configuration file path
- `--version` - Display version information
- `--help` - Display help message

### Herb::Format::Runner

**Responsibility:** Orchestrates the formatting process across multiple files.

```rbs
class Herb::Format::Runner
  @config: Herb::Config::FormatterConfig
  @check: bool
  @write: bool
  @force: bool
  @rewriter_registry: Herb::Rewriter::Registry
  @formatter: Formatter

  attr_reader config: Herb::Config::FormatterConfig
  attr_reader check: bool
  attr_reader write: bool
  attr_reader force: bool

  def initialize: (
    config: Herb::Config::FormatterConfig,
    ?check: bool,
    ?write: bool,
    ?force: bool
  ) -> void

  def run: (?Array[String] files) -> AggregatedResult

  private

  def setup_rewriters: () -> void
  def discover_files: (Array[String]? files) -> Array[String]
  def format_file: (String file_path) -> FormatResult
  def write_file: (FormatResult result) -> void
end
```

**Processing Flow:**
1. Setup: Initialize `Herb::Rewriter::Registry` (includes built-ins; auto-discovers custom rewriters on demand)
2. File Discovery: Use Herb::Core::FileDiscovery to find target files
3. Formatter Creation: Build Formatter instance via FormatterFactory
4. Per-File Processing:
   - Read source file
   - Execute formatting via Formatter
   - If write mode: update file
   - Collect results
5. Aggregation: Combine results into AggregatedResult

**Dependencies:**
- `Herb::Config::FormatterConfig` - Configuration
- `Herb::Rewriter::Registry` - Rewriter management (from herb-rewriter gem)
- `FormatterFactory` - Formatter instantiation
- `Herb::Core::FileDiscovery` - File discovery

### Herb::Format::Formatter

**Responsibility:** Core single-file formatting implementation.

```rbs
class Herb::Format::Formatter
  @pre_rewriters: Array[Rewriters::Base]
  @post_rewriters: Array[Rewriters::Base]
  @config: Herb::Config::FormatterConfig

  attr_reader pre_rewriters: Array[Rewriters::Base]
  attr_reader post_rewriters: Array[Rewriters::Base]
  attr_reader config: Herb::Config::FormatterConfig

  def initialize: (
    Array[Rewriters::Base] pre_rewriters,
    Array[Rewriters::Base] post_rewriters,
    Herb::Config::FormatterConfig config
  ) -> void

  def format: (String file_path, String source, ?force: bool) -> FormatResult

  private

  def apply_rewriters: (Herb::AST::Document ast, Array[Rewriters::Base] rewriters, Context context) -> Herb::AST::Document
end
```

**Processing Flow:**
1. Parse ERB template into AST via `Herb.parse`
2. If parsing fails, return source unchanged
3. Check for ignore directive via `FormatIgnore.ignore?` (unless `--force`)
4. If ignored, return source unchanged
5. Create Context with source and configuration
6. Execute pre-rewriters (in order)
7. Apply formatting via `FormatPrinter.format(ast, format_context:)`
8. Execute post-rewriters (in order)
9. Return FormatResult with original and formatted content

**Design Note:** The ignore directive check happens after parsing, not before. This follows the TypeScript reference implementation where the AST is parsed first, then the Visitor pattern is used to detect `<%# herb:formatter ignore %>` comments in the AST. If the directive is found, the original source is returned unchanged without any formatting applied.

**Dependencies:**
- `FormatIgnore` - Detect ignore directives in AST
- `Herb.parse` - AST parsing (from herb gem)
- `Context` - Execution context
- `FormatPrinter` - AST formatting (extends Printer::Base)
- `Rewriters::Base` subclasses - Rewriter implementations

### Herb::Format::FormatterFactory

**Responsibility:** Creates configured Formatter instances (Factory Pattern).

```rbs
class Herb::Format::FormatterFactory
  @config: Herb::Config::FormatterConfig
  @rewriter_registry: Herb::Rewriter::Registry

  attr_reader config: Herb::Config::FormatterConfig
  attr_reader rewriter_registry: Herb::Rewriter::Registry

  def initialize: (
    Herb::Config::FormatterConfig config,
    Herb::Rewriter::Registry rewriter_registry
  ) -> void

  def create: () -> Formatter

  private

  def build_pre_rewriters: () -> Array[Herb::Rewriter::ASTRewriter]
  def build_post_rewriters: () -> Array[Herb::Rewriter::StringRewriter]
  def instantiate_rewriter: (String name) -> Herb::Rewriter::ASTRewriter?
end
```

**Processing:**
1. Query `Herb::Rewriter::Registry` for configured pre-rewriters (AST rewriters by name)
2. Query `Herb::Rewriter::Registry` for configured post-rewriters (String rewriters by name)
3. Instantiate each rewriter via `registry.resolve_ast_rewriter(name)` / `registry.resolve_string_rewriter(name)`
4. Create Formatter with rewriters

### Herb::Format::FormatIgnore

**Responsibility:** Detects `<%# herb:formatter ignore %>` directives in a parsed AST.

**Design Note:** The TypeScript reference implementation (`format-ignore.ts`) handles formatter directive detection within the formatter package itself. The Ruby implementation follows this same pattern, keeping the ignore detection logic self-contained in `FormatIgnore`.

```rbs
module Herb::Format::FormatIgnore
  FORMATTER_IGNORE_COMMENT: String  # "herb:formatter ignore"

  # Check if the AST contains a herb:formatter ignore directive.
  # Traverses ERB comment nodes looking for an exact match.
  def self.ignore?: (Herb::AST::Document document) -> bool

  # Check if a single node is a herb:formatter ignore comment.
  def self.ignore_comment?: (Herb::AST::Node node) -> bool

  private

  # Internal Visitor subclass that traverses the AST to detect
  # the ignore directive. Sets a flag when found.
  class IgnoreDetector
    include Herb::Visitor

    @ignore_directive_found: bool

    attr_reader ignore_directive_found: bool

    def initialize: () -> void
    def visit_erb_content_node: (Herb::AST::ERBContentNode node) -> void
  end
end
```

**Detection Algorithm:**
1. Create `IgnoreDetector` (a `Herb::Visitor` subclass)
2. Traverse AST via `document.accept(detector)`
3. For each `ERBContentNode`, check if it is an ERB comment (`<%#`)
4. If comment content (trimmed) equals `"herb:formatter ignore"`, set flag and stop traversal
5. Return flag value

### Herb::Format::Context

**Responsibility:** Provides contextual information during formatting and rewriting.

```rbs
class Herb::Format::Context
  @file_path: String
  @source: String
  @config: Herb::Config::FormatterConfig
  @source_lines: Array[String]?

  attr_reader file_path: String
  attr_reader source: String
  attr_reader config: Herb::Config::FormatterConfig

  def initialize: (
    file_path: String,
    source: String,
    config: Herb::Config::FormatterConfig
  ) -> void

  def indent_width: () -> Integer
  def max_line_length: () -> Integer
  def source_line: (Integer line) -> String
  def line_count: () -> Integer

  private

  def split_source_lines: () -> Array[String]
end
```

### Herb::Format::FormatPrinter

**Responsibility:** Core formatting logic - traverses AST and produces formatted output.

Extends `Herb::Printer::Base` (which extends `Herb::Visitor`) to leverage the standard visitor pattern with double-dispatch via `node.accept(self)`. This mirrors the TypeScript `FormatPrinter extends Printer extends Visitor` architecture.

```rbs
class Herb::Format::FormatPrinter < Herb::Printer::Base
  include FormatHelpers

  VOID_ELEMENTS: Array[String]
  PRESERVED_ELEMENTS: Array[String]

  attr_reader indent_width: Integer
  attr_reader max_line_length: Integer
  attr_reader format_context: Context
  attr_reader indent_level: Integer

  def self.format: (
    Herb::ParseResult | Herb::AST::Node input,
    format_context: Context,
    ?ignore_errors: bool
  ) -> String

  def initialize: (
    indent_width: Integer,
    max_line_length: Integer,
    format_context: Context
  ) -> void

  def formatted_output: () -> String

  # Capture output into a temporary buffer and return it
  def capture: () { () -> void } -> Array[String]

  # Visitor method overrides for each node type
  def visit_literal_node: (Herb::AST::LiteralNode node) -> void
  def visit_html_text_node: (Herb::AST::HTMLTextNode node) -> void
  def visit_whitespace_node: (Herb::AST::WhitespaceNode node) -> void
  def visit_html_element_node: (Herb::AST::HTMLElementNode node) -> void
  def visit_html_open_tag_node: (Herb::AST::HTMLOpenTagNode node) -> void
  def visit_html_close_tag_node: (Herb::AST::HTMLCloseTagNode node) -> void
  def visit_erb_content_node: (Herb::AST::ERBContentNode node) -> void
  def visit_erb_end_node: (Herb::AST::ERBEndNode node) -> void
  def visit_erb_if_node: (Herb::AST::ERBIfNode node) -> void
  def visit_erb_block_node: (Herb::AST::ERBBlockNode node) -> void
  def visit_erb_unless_node: (Herb::AST::ERBUnlessNode node) -> void
  def visit_erb_else_node: (Herb::AST::ERBElseNode node) -> void
  def visit_erb_case_node: (Herb::AST::ERBCaseNode node) -> void
  def visit_erb_when_node: (Herb::AST::ERBWhenNode node) -> void
  def visit_erb_case_match_node: (Herb::AST::ERBCaseMatchNode node) -> void
  def visit_erb_in_node: (Herb::AST::ERBInNode node) -> void
  def visit_erb_for_node: (Herb::AST::ERBForNode node) -> void
  def visit_erb_while_node: (Herb::AST::ERBWhileNode node) -> void
  def visit_erb_until_node: (Herb::AST::ERBUntilNode node) -> void

  private

  def current_element: () -> Herb::AST::HTMLElementNode?
  def current_tag_name: () -> String
  def indent: () -> String
  def push_with_indent: (String line) -> void
  def push_to_last_line: (String text) -> void
  def push: (String line) -> void
  def track_boundary: (Herb::AST::Node node) { () -> void } -> void
  def with_indent: () { () -> void } -> void
  def with_inline_mode: () { () -> void } -> void
  def visit_element_body: (Herb::AST::HTMLElementNode node) -> void
  def indent_string: (?Integer level) -> String
  def void_element?: (String tag_name) -> bool
  def preserved_element?: (String tag_name) -> bool
  def render_attributes_inline: (Herb::AST::HTMLOpenTagNode open_tag) -> String
  def render_multiline_attributes: (String tag_name, Array[Herb::AST::Node] children, bool is_void) -> void
  def render_attribute: (Herb::AST::HTMLAttributeNode attribute) -> String
  def render_class_attribute: (String name, String content, String open_quote, String close_quote) -> String
  def format_erb_content: (String content) -> String
  def reconstruct_erb_node: (Herb::AST::Node node, ?with_formatting: bool) -> String
  def print_erb_node: (Herb::AST::Node node) -> void
end
```

**Design Notes:**
- Inherits `Printer::Base` which provides `visit(node)` and `write(text)`
- Includes `FormatHelpers` for all classification and analysis helper methods
- Uses `@lines` array (not PrintContext) for output accumulation; `formatted_output` joins them
- `@indent_level` and `@inline_mode` manage formatting context during traversal
- `@element_stack` tracks the current nesting path for open/close tag visitors
- `@element_formatting_analysis` caches `ElementAnalysis` results per element node
- `capture` enables pre-rendering elements to measure their length for inline/block decisions
- ERB control flow nodes (if/unless/case/for/while/until/block) use `visit_erb_if_node`-style dispatch

**Formatting Rules (to be implemented):**
- **Indentation**: Uses spaces (configurable width), indents nested elements
- **Line Length**: Wraps long lines at max_line_length, wraps attributes to separate lines when exceeded
- **Attributes**: Single attribute on same line, multiple attributes with overflow get one per line
- **Whitespace**: Removes trailing whitespace, normalizes line endings (LF)
- **ERB Tags**: Consistent spacing inside ERB tags (`<%= %>` not `<%=  %>`)
- **Void Elements**: Omits closing slash (`<br>` not `<br/>`)
- **Preserved Content**: Does not reformat `<pre>`, `<code>`, `<script>`, `<style>` content

### Herb::Format::FormatHelpers

**Responsibility:** Provides constants and helper functions used by `FormatPrinter` and `ElementAnalyzer` to classify nodes, analyze element content, and make formatting decisions. Included as a module (not instantiated).

```rbs
module Herb::Format::FormatHelpers
  # Constants
  INLINE_ELEMENTS: Set[String]             # 26 inline HTML elements
  CONTENT_PRESERVING_ELEMENTS: Set[String] # script, style, pre, textarea
  SPACEABLE_CONTAINERS: Set[String]        # div, section, article, etc.
  TOKEN_LIST_ATTRIBUTES: Set[String]       # class, data-controller, data-action
  FORMATTABLE_ATTRIBUTES: Hash[String, Array[String]]
  ASCII_WHITESPACE: Regexp

  # Node type detection
  def pure_whitespace_node?: (Herb::AST::Node node) -> bool
  def non_whitespace_node?: (Herb::AST::Node node) -> bool
  def inline_element?: (String tag_name) -> bool
  def content_preserving?: (String tag_name) -> bool
  def block_level_node?: (Herb::AST::Node node) -> bool
  def line_breaking_element?: (Herb::AST::Node node) -> bool
  def erb_node?: (Herb::AST::Node node) -> bool
  def erb_control_flow_node?: (Herb::AST::Node node) -> bool
  def herb_disable_comment?: (Herb::AST::Node node) -> bool

  # Sibling and child analysis
  def find_previous_meaningful_sibling: (Array[Herb::AST::Node] siblings, Integer current_index) -> Integer?
  def whitespace_between?: (Array[Herb::AST::Node] children, Integer start_index, Integer end_index) -> bool
  def filter_significant_children: (Array[Herb::AST::Node] body) -> Array[Herb::AST::Node]
  def count_adjacent_inline_elements: (Array[Herb::AST::Node] children) -> Integer

  # Content analysis
  def multiline_text_content?: (Array[Herb::AST::Node] children) -> bool
  def all_nested_elements_inline?: (Array[Herb::AST::Node] children) -> bool
  def mixed_text_and_inline_content?: (Array[Herb::AST::Node] children) -> bool
  def complex_erb_control_flow?: (Array[Herb::AST::Node] children) -> bool

  # Positioning and spacing
  def should_append_to_last_line?: (Herb::AST::Node child, Array[Herb::AST::Node] siblings, Integer index) -> bool
  def should_preserve_user_spacing?: (Herb::AST::Node child, Array[Herb::AST::Node] siblings, Integer index) -> bool

  # Text and punctuation
  def needs_space_between?: (String current_line, String word) -> bool
  def closing_punctuation?: (String word) -> bool
  def opening_punctuation?: (String word) -> bool
  def ends_with_erb_tag?: (String text) -> bool
  def starts_with_erb_tag?: (String text) -> bool

  # Attribute helpers
  def get_attribute_name: (Herb::AST::HTMLAttributeNode attribute) -> String
  def get_attribute_quotes: (Herb::AST::HTMLAttributeValueNode attribute_value) -> [String, String]
  def get_html_text_content: (Herb::AST::HTMLAttributeValueNode attribute_value) -> String
  def render_attribute_value_content: (Herb::AST::HTMLAttributeValueNode attribute_value) -> String

  # Utility
  def dedent: (String text) -> String
  def get_tag_name: (Herb::AST::HTMLElementNode element_node) -> String
end
```

### Herb::Format::ElementAnalysis

**Responsibility:** Immutable data structure holding the three formatting decisions for an `HTMLElementNode`. Created by `ElementAnalyzer#analyze`.

```rbs
class Herb::Format::ElementAnalysis < Data
  attr_reader open_tag_inline: bool          # Render open tag on one line (no attribute wrapping)?
  attr_reader element_content_inline: bool   # Render element body inline (no newlines)?
  attr_reader close_tag_inline: bool         # Append close tag to same line as last content?

  def fully_inline?: () -> bool   # true when all three fields are true
  def block_format?: () -> bool   # true when element_content_inline is false
end
```

**Combinations:**
- `{ true, true, true }` — Fully inline: `<p>text</p>`
- `{ false, false, false }` — Block with multiline attributes: open tag wraps, body indented, close tag on own line
- `{ true, false, false }` — Block content: `<div>\n  ...\n</div>`

### Herb::Format::ElementAnalyzer

**Responsibility:** Analyzes a single `HTMLElementNode` and returns an `ElementAnalysis` with the three formatting decisions. Uses `FormatPrinter#capture` internally to pre-render elements for length measurement.

```rbs
class Herb::Format::ElementAnalyzer
  include FormatHelpers

  def initialize: (
    FormatPrinter printer,
    Integer max_line_length,
    Integer indent_width
  ) -> void

  def analyze: (Herb::AST::HTMLElementNode element) -> ElementAnalysis

  private

  def should_render_open_tag_inline?: (Herb::AST::HTMLElementNode element) -> bool
  def should_render_element_content_inline?: (Herb::AST::HTMLElementNode element, bool open_tag_inline) -> bool
  def should_render_close_tag_inline?: (Herb::AST::HTMLElementNode element, bool element_content_inline) -> bool
  def inline_node?: (Herb::AST::Node node) -> bool
  def should_render_inline?: (Herb::AST::HTMLElementNode element) -> bool
  def has_multiline_attributes?: (Herb::AST::HTMLOpenTagNode open_tag) -> bool
end
```

**Analysis Logic:**
1. Content-preserving elements (`<pre>`, `<script>`, etc.) → all `false`
2. Void elements → `open_tag_inline` from line-length check, others `true`
3. Other elements:
   - `open_tag_inline`: false if conditional context, complex ERB, or exceeds `max_line_length`
   - `element_content_inline`: false unless open tag is inline and all children are inline nodes
   - `close_tag_inline`: mirrors `element_content_inline`

### Herb::Rewriter::Registry

> **Note:** The rewriter registry lives in the `herb-rewriter` gem, not `herb-format`.
> This follows the TypeScript package boundary where `@herb-tools/rewriter` is a separate package.

**Responsibility:** Central registry for rewriter classes (Registry Pattern).

```rbs
class Herb::Rewriter::Registry
  BUILTIN_AST_REWRITERS: Array[singleton(ASTRewriter)]
  BUILTIN_STRING_REWRITERS: Array[singleton(StringRewriter)]

  def initialize: () -> void

  def register: (singleton(ASTRewriter) | singleton(StringRewriter) klass) -> void
  def registered?: (String name) -> bool
  def resolve_ast_rewriter: (String name) -> singleton(ASTRewriter)?
  def resolve_string_rewriter: (String name) -> singleton(StringRewriter)?
end
```

**Built-in Rewriters:**

| Rewriter | Type | Description |
|----------|------|-------------|
| `tailwind-class-sorter` | ASTRewriter (pre) | Sort Tailwind CSS classes |

### Herb::Rewriter::Registry (custom rewriter loading)

> **Note:** Custom rewriter loading is handled by `Herb::Rewriter::Registry` in the
> `herb-rewriter` gem via auto-discovery. When `resolve_ast_rewriter(name)` or
> `resolve_string_rewriter(name)` is called with an unregistered name, the registry
> attempts to `require` the name and auto-discovers newly loaded subclasses via `ObjectSpace`.

**Processing:**
1. `Registry#resolve_ast_rewriter(name)` is called with a rewriter name or file path
2. If not already registered, attempt `require name`
3. After require, scan `ObjectSpace` for new `ASTRewriter` or `StringRewriter` subclasses
4. Register discovered classes and return the matching one

### Herb::Rewriter::ASTRewriter and StringRewriter

> **Note:** Rewriter base classes live in the `herb-rewriter` gem.

**Herb::Rewriter::ASTRewriter** — Abstract base for pre-format rewriters.

```rbs
class Herb::Rewriter::ASTRewriter
  attr_reader options: Hash[Symbol, untyped]

  def self.rewriter_name: () -> String
  def self.description: () -> String

  def initialize: (?options: Hash[Symbol, untyped]) -> void
  def rewrite: (Herb::AST::DocumentNode ast, untyped context) -> Herb::AST::DocumentNode

  private

  def traverse: (Herb::AST::Node node) { (Herb::AST::Node) -> Herb::AST::Node? } -> Herb::AST::Node
end
```

**Herb::Rewriter::StringRewriter** — Abstract base for post-format rewriters.

```rbs
class Herb::Rewriter::StringRewriter
  def self.rewriter_name: () -> String
  def self.description: () -> String

  def rewrite: (String formatted, Herb::Rewriter::Context context) -> String
end
```

**Processing phases:**
- `ASTRewriter` — runs before FormatPrinter (AST → AST transformation)
- `StringRewriter` — runs after FormatPrinter (String → String transformation)

## Rewriter Implementation Examples

### Example: Herb::Rewriter::BuiltIns::TailwindClassSorter

> **Note:** Built-in rewriters are in the `herb-rewriter` gem under `Herb::Rewriter::BuiltIns`.

**Purpose:** Sort Tailwind CSS classes according to recommended order.

**Interface:**
```rbs
class Herb::Rewriter::BuiltIns::TailwindClassSorter < Herb::Rewriter::ASTRewriter
  def self.rewriter_name: () -> String  # "tailwind-class-sorter"
  def self.description: () -> String

  def rewrite: (Herb::AST::DocumentNode ast, untyped context) -> Herb::AST::DocumentNode

  private

  def sort_class_attribute: (Herb::AST::HTMLAttributeNode attr) -> void
  def tailwind_sort_key: (String class_name) -> Integer
end
```

**Responsibilities:**
- Sort classes in `class` attributes according to Tailwind conventions
- Run in the pre phase (before FormatPrinter) as an ASTRewriter

## Processing Flow

```
CLI#run
  │
  ├── parse_options
  │
  ├── (--stdin mode)
  │   ├── Read from stdin
  │   ├── Formatter#format
  │   └── Output to stdout
  │
  ├── Config.load (herb-config)
  │
  ├── Runner.new(config)
  │   └── Herb::Rewriter::Registry.new  (built-ins pre-registered; custom auto-discovered on demand)
  │
  ├── Runner#run(files)
  │   ├── FileDiscovery.discover (herb-core)
  │   │
  │   └── files.each do |file|
  │       ├── File.read(file)
  │       │
  │       └── Formatter#format(file, source)
  │           ├── Herb.parse(source) (herb gem)
  │           ├── (parse failed?) return source unchanged
  │           ├── FormatIgnore.ignore?(ast) (unless --force)
  │           ├── (ignored?) return source unchanged
  │           ├── Context.new
  │           ├── [pre-rewriters: ASTRewriter[]] ast = r.rewrite(ast, context) for each
  │           ├── FormatPrinter.format(ast, format_context:)  ← AST/string boundary
  │           ├── [post-rewriters: StringRewriter[]] formatted = r.rewrite(formatted, context) for each
  │           └── return FormatResult
  │
  ├── (--write mode) Write files
  │
  ├── (--check mode) Show diffs
  │
  ├── AggregatedResult.new(results)
  │
  └── Exit Code
```

## Inline Directives

The formatter supports a single inline directive, detected by `Herb::Format::FormatIgnore` via AST traversal:

| Directive | Description |
|-----------|-------------|
| `<%# herb:formatter ignore %>` | Ignore entire file |

**File-level Ignore:**
```erb
<%# herb:formatter ignore %>
<!-- Rest of file is not formatted -->
```

When the ignore directive is found anywhere in the file, the entire file's original source is returned unchanged. No rewriters or formatting engine run.

**Note:** The formatter only supports file-level ignore. This matches the TypeScript reference implementation. Range-based ignore (`off`/`on`) is not supported.

## Error Handling

### Custom Exceptions

```ruby
module Herb
  module Format
    module Errors
      class Error < StandardError; end

      class ConfigurationError < Error; end
      class ParseError < Error; end
      class RewriterError < Error; end
      class FileNotFoundError < Error; end
    end
  end
end
```

### Exit Code Convention

| Code | Meaning | Used When |
|------|---------|-----------|
| 0 | Success | Files formatted successfully, or all files already formatted (check mode) |
| 1 | Format needed | Files need formatting (check mode) or formatting error |
| 2 | Runtime error | Configuration errors, file I/O errors, parser failures |

## Testing Strategy

### Unit Tests - FormatPrinter

**Focus:** Core formatting logic in isolation

**Test Structure:**
- Parse sample ERB into AST using `Herb.parse`
- Create FormatPrinter with test configuration (via format_context)
- Execute `FormatPrinter.format` class method
- Verify formatted output

**Key Test Cases:**
- Indentation normalization
- Attribute wrapping at line length
- ERB tag spacing normalization
- Void element formatting
- Preserved content (`<pre>`, `<code>`) not modified
- Whitespace normalization

### Unit Tests - Rewriters

**Focus:** Individual rewriter logic in isolation

**Test Structure:**
- Parse sample ERB into AST using `Herb.parse`
- Create mock Context with test configuration
- Execute rewriter's `rewrite` method
- Verify AST transformation

**Key Test Cases:**
- Rewriter name and phase are correct
- AST is correctly transformed
- Non-relevant nodes are unchanged
- Options affect behavior appropriately

### Unit Tests - FormatIgnore

**Focus:** Ignore directive detection logic

**Test Structure:**
- Parse sample ERB into AST using `Herb.parse`
- Execute `FormatIgnore.ignore?` on the AST
- Verify detection result

**Key Test Cases:**
- File with `<%# herb:formatter ignore %>` returns true
- File without directive returns false
- Directive with extra whitespace (e.g., `<%#  herb:formatter ignore  %>`) handled correctly
- Directive not at the beginning of file still detected
- Non-ignore comments (e.g., `<%# herb:formatter something %>`) do not trigger

### Integration Tests - Runner

**Focus:** End-to-end formatting workflow

**Test Structure:**
- Create temporary test files
- Configure formatter with specific rewriters
- Execute Runner.run
- Verify AggregatedResult and file contents

**Key Test Cases:**
- Multiple files are processed correctly
- File discovery respects include/exclude patterns
- File with `herb:formatter ignore` directive is skipped
- `--force` overrides ignore directive
- Write mode updates files
- Check mode does not modify files
- Error handling for parse failures

### Integration Tests - CLI

**Focus:** Command-line interface behavior

**Test Structure:**
- Invoke CLI with test arguments and I/O streams
- Verify exit codes
- Verify output (formatted content, diffs)

**Key Test Cases:**
- Exit codes match formatting results
- Check mode shows diff output
- Stdin mode reads from stdin and outputs to stdout
- Write mode modifies files
- Force option overrides ignore directives
- Configuration loading works

## Related Documents

- [Overall Architecture](./architecture.md)
- [herb-config Design](./herb-config-design.md)
- [herb-core Design](./herb-core-design.md)
- [herb-lint Design](./herb-lint-design.md)
- [Requirements: herb-format](../requirements/herb-format.md)
- [herb-rewriter gem](../../herb-rewriter/) - Rewriter base classes and registry
