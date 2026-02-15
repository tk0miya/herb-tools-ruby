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
│           ├── rewriter_registry.rb
│           ├── custom_rewriter_loader.rb
│           ├── errors.rb
│           └── rewriters/
│               ├── base.rb
│               ├── normalize_attributes.rb
│               ├── sort_attributes.rb
│               └── tailwind_class_sorter.rb
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
│           ├── format_printer_spec.rb
│           ├── rewriter_registry_spec.rb
│           └── rewriters/
│               └── ...
├── herb-format.gemspec
└── Gemfile
```

## Class Design

### Module Structure

```
Herb::Format
├── CLI                  # Command line interface
├── Runner               # Format execution orchestration
├── Formatter            # Core formatting implementation
├── FormatterFactory     # Formatter instance creation (Factory Pattern)
├── FormatIgnore         # Ignore directive detection (AST-based)
├── Context              # Format execution context
├── FormatResult         # Format result for a single file
├── AggregatedResult     # Aggregated result for multiple files
├── FormatPrinter        # AST formatting (extends Printer::Base)
├── RewriterRegistry     # Rewriter registration and lookup (Registry Pattern)
├── CustomRewriterLoader # Custom rewriter loading
├── Errors               # Custom exceptions
└── Rewriters            # Rewriter implementations
    ├── Base
    ├── NormalizeAttributes
    ├── SortAttributes
    └── TailwindClassSorter
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
  @rewriter_registry: RewriterRegistry
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
1. Setup: Load built-in and custom rewriters via RewriterRegistry
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
- `RewriterRegistry` - Rewriter management
- `CustomRewriterLoader` - Custom rewriter loading
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
  @rewriter_registry: RewriterRegistry

  attr_reader config: Herb::Config::FormatterConfig
  attr_reader rewriter_registry: RewriterRegistry

  def initialize: (
    Herb::Config::FormatterConfig config,
    RewriterRegistry rewriter_registry
  ) -> void

  def create: () -> Formatter

  private

  def build_pre_rewriters: () -> Array[Rewriters::Base]
  def build_post_rewriters: () -> Array[Rewriters::Base]
  def instantiate_rewriter: (singleton(Rewriters::Base) rewriter_class) -> Rewriters::Base
end
```

**Processing:**
1. Query RewriterRegistry for configured pre-rewriters
2. Query RewriterRegistry for configured post-rewriters
3. Instantiate each rewriter
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
2. Traverse AST via `document.visit(detector)`
3. For each `ERBContentNode`, check if it is an ERB comment (`<%#`)
4. If comment content (trimmed) equals `"herb:formatter ignore"`, set flag
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
  VOID_ELEMENTS: Array[String]
  PRESERVED_ELEMENTS: Array[String]

  attr_reader indent_width: Integer
  attr_reader max_line_length: Integer
  attr_reader format_context: Context

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

  # Visitor method overrides for each node type
  def visit_literal_node: ...
  def visit_html_text_node: ...
  def visit_whitespace_node: ...
  def visit_html_attribute_node: ...
  def visit_html_element_node: ...
  def visit_html_open_tag_node: ...
  def visit_html_close_tag_node: ...
  def visit_html_comment_node: ...
  def visit_html_doctype_node: ...
  def visit_erb_*_node: ...

  private

  def indent_string: (?Integer level) -> String
  def void_element?: (String tag_name) -> bool
  def preserved_element?: (String tag_name) -> bool
  def print_erb_tag: (Herb::AST::Node node) -> void
  def nodes_before_token: (Array[Herb::AST::Node] children, Herb::Token token) -> Array[Herb::AST::Node]
  def nodes_after_token: (Array[Herb::AST::Node] children, Herb::Token token) -> Array[Herb::AST::Node]
end
```

**Design Notes:**
- Inherits `Printer::Base` which provides `visit(node)`, `write(text)`, and `context` (PrintContext)
- PrintContext manages output accumulation, indent level, column tracking, and tag stack
- All AST node types have visitor methods; unoverridden nodes default to `visit_child_nodes`
- ERB node visitors are generated dynamically via `define_method`

**Formatting Rules (to be implemented):**
- **Indentation**: Uses spaces (configurable width), indents nested elements
- **Line Length**: Wraps long lines at max_line_length, wraps attributes to separate lines when exceeded
- **Attributes**: Single attribute on same line, multiple attributes with overflow get one per line
- **Whitespace**: Removes trailing whitespace, normalizes line endings (LF)
- **ERB Tags**: Consistent spacing inside ERB tags (`<%= %>` not `<%=  %>`)
- **Void Elements**: Omits closing slash (`<br>` not `<br/>`)
- **Preserved Content**: Does not reformat `<pre>`, `<code>`, `<script>`, `<style>` content

### Herb::Format::RewriterRegistry

**Responsibility:** Central registry for rewriter classes (Registry Pattern).

```rbs
class Herb::Format::RewriterRegistry
  @rewriters: Hash[String, singleton(Rewriters::Base)]

  def initialize: () -> void

  def register: (singleton(Rewriters::Base) rewriter_class) -> void
  def get: (String name) -> singleton(Rewriters::Base)?
  def registered?: (String name) -> bool
  def all: () -> Array[singleton(Rewriters::Base)]
  def rewriter_names: () -> Array[String]
  def load_builtin_rewriters: () -> void

  private

  def validate_rewriter_class: (singleton(Rewriters::Base) rewriter_class) -> bool
end
```

**Built-in Rewriters:**
- `normalize-attributes` (pre) - Normalize attribute formatting
- `sort-attributes` (post) - Alphabetically sort attributes
- `tailwind-class-sorter` (post) - Sort Tailwind CSS classes

### Herb::Format::CustomRewriterLoader

**Responsibility:** Loads custom rewriter implementations from configured paths.

```rbs
class Herb::Format::CustomRewriterLoader
  DEFAULT_PATH: String  # ".herb/rewriters"

  @config: Herb::Config::FormatterConfig
  @registry: RewriterRegistry

  attr_reader config: Herb::Config::FormatterConfig
  attr_reader registry: RewriterRegistry

  def initialize: (
    Herb::Config::FormatterConfig config,
    RewriterRegistry registry
  ) -> void

  def load: () -> void

  private

  def load_rewriters_from: (String path) -> void
  def require_rewriter_file: (String file_path) -> void
  def auto_register_rewriters: () -> void
end
```

**Processing:**
1. Reads custom rewriter path (default: `.herb/rewriters/*.rb`)
2. Requires Ruby files containing rewriter classes
3. Auto-registers newly loaded rewriter classes with RewriterRegistry
4. Handles load errors gracefully

### Herb::Format::Rewriters::Base

**Responsibility:** Abstract base class defining the rewriter interface.

```rbs
# Abstract rewriter interface that all rewriters must implement
interface _Rewriter
  # Class methods (must override)
  def self.rewriter_name: () -> String
  def self.description: () -> String
  def self.phase: () -> Symbol

  # Instance interface
  def initialize: (?options: Hash[Symbol, untyped]) -> void
  def rewrite: (Herb::AST::Document ast, Context context) -> Herb::AST::Document
end

# Base class implementation providing common functionality
class Herb::Format::Rewriters::Base
  include _Rewriter

  attr_reader options: Hash[Symbol, untyped]

  def self.rewriter_name: () -> String
  def self.description: () -> String
  def self.phase: () -> Symbol  # :pre or :post

  def initialize: (?options: Hash[Symbol, untyped]) -> void
  def rewrite: (Herb::AST::Document ast, Context context) -> Herb::AST::Document

  private

  def traverse: (Herb::AST::Node node) { (Herb::AST::Node) -> Herb::AST::Node? } -> Herb::AST::Node
end
```

**Phase Values:**
- `:pre` - Runs before formatting rules (normalization)
- `:post` - Runs after formatting rules (final transformations)

## Rewriter Implementation Examples

### Example: Rewriters::NormalizeAttributes

**Purpose:** Normalize attribute formatting before main formatting pass.

**Interface:**
```rbs
class Herb::Format::Rewriters::NormalizeAttributes < Base
  def self.rewriter_name: () -> String  # "normalize-attributes"
  def self.description: () -> String
  def self.phase: () -> Symbol  # :pre

  def rewrite: (Herb::AST::Document ast, Context context) -> Herb::AST::Document

  private

  def normalize_attribute: (Herb::AST::HTMLAttributeNode node) -> void
end
```

**Responsibilities:**
- Convert single quotes to double quotes
- Normalize whitespace in attribute values
- Run in pre phase before formatting

### Example: Rewriters::SortAttributes

**Purpose:** Alphabetically sort HTML attributes.

**Interface:**
```rbs
class Herb::Format::Rewriters::SortAttributes < Base
  def self.rewriter_name: () -> String  # "sort-attributes"
  def self.description: () -> String
  def self.phase: () -> Symbol  # :post

  def rewrite: (Herb::AST::Document ast, Context context) -> Herb::AST::Document

  private

  def sort_element_attributes: (Herb::AST::HTMLElementNode node) -> void
  def attribute_sort_key: (Herb::AST::HTMLAttributeNode attr) -> String
end
```

**Responsibilities:**
- Sort attributes alphabetically by name
- Run in post phase after formatting

### Example: Rewriters::TailwindClassSorter

**Purpose:** Sort Tailwind CSS classes according to recommended order.

**Interface:**
```rbs
class Herb::Format::Rewriters::TailwindClassSorter < Base
  def self.rewriter_name: () -> String  # "tailwind-class-sorter"
  def self.description: () -> String
  def self.phase: () -> Symbol  # :post

  def rewrite: (Herb::AST::Document ast, Context context) -> Herb::AST::Document

  private

  def sort_class_attribute: (Herb::AST::HTMLAttributeNode attr) -> void
  def tailwind_sort_key: (String class_name) -> Integer
end
```

**Responsibilities:**
- Sort classes in `class` attributes according to Tailwind conventions
- Run in post phase after formatting

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
  │   ├── RewriterRegistry.load_builtin_rewriters
  │   └── CustomRewriterLoader.load
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
  │           ├── pre_rewriters.each { |r| r.rewrite(ast, context) }
  │           ├── FormatPrinter.format(ast, format_context:)
  │           ├── post_rewriters.each { |r| r.rewrite(ast, context) }
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
