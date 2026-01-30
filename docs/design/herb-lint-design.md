# herb-lint Design Document

Architectural design for the ERB template static analysis tool.

## Overview

herb-lint is a static analysis tool for ERB templates that provides a CLI interface compatible with the TypeScript version `@herb-tools/linter`. This document describes the system architecture, component responsibilities, and public interfaces.

## Directory Structure

```
herb-lint/
├── lib/
│   └── herb/
│       └── lint/
│           ├── version.rb
│           ├── cli.rb
│           ├── runner.rb
│           ├── linter.rb
│           ├── linter_factory.rb
│           ├── context.rb
│           ├── offense.rb
│           ├── lint_result.rb
│           ├── aggregated_result.rb
│           ├── rule_registry.rb
│           ├── custom_rule_loader.rb
│           ├── fixer.rb
│           ├── errors.rb
│           ├── reporter/
│           │   ├── base_reporter.rb
│           │   ├── detailed_reporter.rb
│           │   ├── simple_reporter.rb
│           │   ├── json_reporter.rb
│           │   └── github_reporter.rb
│           └── rules/
│               ├── base.rb
│               ├── visitor_rule.rb
│               ├── node_helpers.rb
│               ├── html_attribute_double_quotes.rb
│               ├── html_iframe_has_title.rb
│               ├── html_img_require_alt.rb
│               ├── html_no_duplicate_attributes.rb
│               ├── html_no_duplicate_ids.rb
│               ├── html_no_positive_tab_index.rb
│               ├── html_no_self_closing.rb
│               ├── html_tag_name_lowercase.rb
│               └── ...
├── exe/
│   └── herb-lint
├── spec/
│   └── herb/
│       └── lint/
│           ├── cli_spec.rb
│           ├── runner_spec.rb
│           ├── linter_spec.rb
│           ├── context_spec.rb
│           ├── offense_spec.rb
│           ├── rule_registry_spec.rb
│           ├── reporter/
│           │   └── ...
│           └── rules/
│               └── ...
├── herb-lint.gemspec
└── Gemfile
```

## Class Design

### Module Structure

```
Herb::Lint
├── CLI              # Command line interface
├── Runner           # Lint execution orchestration
├── Linter           # Core linting implementation
├── LinterFactory    # Linter instance creation (Factory Pattern)
├── Context          # Lint execution context
├── Offense          # Offense representation
├── LintResult       # Lint result for a single file
├── AggregatedResult # Aggregated result for multiple files
├── RuleRegistry     # Rule registration and lookup (Registry Pattern)
├── CustomRuleLoader # Custom rule loading
├── Fixer            # Automatic fix application
├── Errors           # Custom exceptions
├── Reporter         # Output formatter
│   ├── BaseReporter
│   ├── DetailedReporter
│   ├── SimpleReporter
│   ├── JsonReporter
│   └── GithubReporter
└── Rules            # Rule implementations
    ├── Base
    ├── VisitorRule
    ├── Erb::*
    └── Html::*
```

## Data Structures

### Herb::Lint::Offense

Represents a single linting violation.

```rbs
class Herb::Lint::Offense
  attr_reader rule_name: String
  attr_reader message: String
  attr_reader severity: Symbol
  attr_reader location: Herb::Location
  attr_reader node: Herb::AST::Node?
  attr_reader fixable: bool
  attr_reader fix: Proc?

  def initialize: (
    rule_name: String,
    message: String,
    severity: Symbol,
    location: Herb::Location,
    ?node: Herb::AST::Node?,
    ?fixable: bool,
    ?fix: Proc?
  ) -> void

  def line: () -> Integer
  def column: () -> Integer
  def end_line: () -> Integer
  def end_column: () -> Integer
  def fixable?: () -> bool
  def to_h: () -> Hash[Symbol, untyped]
end
```

### Herb::Lint::LintResult

Represents the linting result for a single file.

```rbs
class Herb::Lint::LintResult
  attr_reader file_path: String
  attr_reader offenses: Array[Offense]
  attr_reader source: String
  attr_reader ignored: bool

  def initialize: (
    file_path: String,
    offenses: Array[Offense],
    source: String,
    ?ignored: bool
  ) -> void

  def ignored?: () -> bool
  def error_count: () -> Integer
  def warning_count: () -> Integer
  def fixable_count: () -> Integer
  def to_h: () -> Hash[Symbol, untyped]
end
```

### Herb::Lint::AggregatedResult

Aggregates results across multiple files.

```rbs
class Herb::Lint::AggregatedResult
  attr_reader results: Array[LintResult]

  def initialize: (Array[LintResult] results) -> void

  def all_offenses: () -> Array[Offense]
  def file_count: () -> Integer
  def files_with_offenses_count: () -> Integer
  def offense_count: () -> Integer
  def error_count: () -> Integer
  def warning_count: () -> Integer
  def fixable_count: () -> Integer
  def has_offenses_at_or_above?: (Symbol level) -> bool
  def to_h: () -> Hash[Symbol, untyped]
end
```

## Component Details

### Herb::Lint::CLI

**Responsibility:** Command-line interface orchestration.

**Exit Codes:**
- `EXIT_SUCCESS = 0` - No offenses found
- `EXIT_LINT_ERROR = 1` - Offenses detected
- `EXIT_RUNTIME_ERROR = 2` - Configuration or runtime error

```rbs
class Herb::Lint::CLI
  EXIT_SUCCESS: Integer
  EXIT_LINT_ERROR: Integer
  EXIT_RUNTIME_ERROR: Integer

  @argv: Array[String]
  @stdout: IO
  @stderr: IO
  @options: Hash[Symbol, untyped]

  attr_reader argv: Array[String]
  attr_reader stdout: IO
  attr_reader stderr: IO

  def initialize: (
    ?Array[String] argv,
    ?stdout: IO,
    ?stderr: IO
  ) -> void

  def run: () -> Integer

  private

  def parse_options: () -> Hash[Symbol, untyped]
  def handle_init: () -> Integer
  def handle_version: () -> Integer
  def handle_help: () -> Integer
  def load_config: () -> Herb::Config::LinterConfig
  def create_reporter: (String format, bool github) -> Reporter::BaseReporter
  def determine_exit_code: (AggregatedResult result, Symbol fail_level) -> Integer
end
```

**Processing Flow:**
1. Parse command-line options
2. Handle special flags (--init, --version, --help)
3. Load configuration via Herb::Config::Loader
4. Create and run Runner
5. Format output via Reporter
6. Determine exit code based on fail-level threshold

**Command-Line Options:**
- `--init` - Generate default .herb.yml
- `--fix` - Apply safe automatic fixes
- `--fix-unsafely` - Apply potentially unsafe fixes
- `--format TYPE` - Output format (detailed, simple, json)
- `--github` - GitHub Actions annotation format
- `--fail-level LEVEL` - Minimum severity to trigger failure (error, warning, info, hint)
- `--config PATH` - Custom configuration file path
- `--version` - Display version information
- `--help` - Display help message

### Herb::Lint::Runner

**Responsibility:** Orchestrates the linting process across multiple files.

```rbs
class Herb::Lint::Runner
  @config: Herb::Config::LinterConfig
  @fix: bool
  @fix_unsafely: bool
  @rule_registry: RuleRegistry
  @linter: Linter

  attr_reader config: Herb::Config::LinterConfig
  attr_reader fix: bool
  attr_reader fix_unsafely: bool

  def initialize: (
    config: Herb::Config::LinterConfig,
    ?fix: bool,
    ?fix_unsafely: bool
  ) -> void

  def run: (?Array[String] files) -> AggregatedResult

  private

  def setup_rules: () -> void
  def discover_files: (Array[String]? files) -> Array[String]
  def lint_file: (String file_path) -> LintResult
  def apply_fixes: (LintResult result) -> void
end
```

**Processing Flow:**
1. Setup: Load built-in and custom rules via RuleRegistry
2. File Discovery: Use Herb::Core::FileDiscovery to find target files
3. Linter Creation: Build Linter instance via LinterFactory
4. Per-File Processing:
   - Read source file
   - Execute linting via Linter
   - Apply fixes if requested and available
   - Handle errors gracefully
5. Aggregation: Combine results into AggregatedResult

**Dependencies:**
- `Herb::Config::LinterConfig` - Configuration
- `RuleRegistry` - Rule management
- `CustomRuleLoader` - Custom rule loading
- `LinterFactory` - Linter instantiation
- `Herb::Core::FileDiscovery` - File discovery
- `Fixer` - Auto-fix application

### Herb::Lint::Linter

**Responsibility:** Core single-file linting implementation.

```rbs
class Herb::Lint::Linter
  @rules: Array[Rules::Base]
  @config: Herb::Config::LinterConfig

  attr_reader rules: Array[Rules::Base]
  attr_reader config: Herb::Config::LinterConfig

  def initialize: (
    Array[Rules::Base] rules,
    Herb::Config::LinterConfig config
  ) -> void

  def lint: (String file_path, String source) -> LintResult

  private

  def parse_directives: (String source) -> Herb::Core::DirectiveParser
  def should_ignore_file?: (Herb::Core::DirectiveParser directives) -> bool
  def filter_by_directives: (Array[Offense] offenses, Herb::Core::DirectiveParser directives) -> Array[Offense]
end
```

**Processing Flow:**
1. Parse inline directives (herb-lint-disable comments)
2. Check for file-level ignore directive
3. Parse ERB template into AST via `Herb.parse`
4. Create Context with source and configuration
5. Execute each enabled rule against the AST
6. Filter offenses based on inline disable directives
7. Return LintResult with offenses

**Dependencies:**
- `Herb::Core::DirectiveParser` - Parse inline directives
- `Herb::Core::DisableTracker` - Track disabled rules
- `Herb.parse` - AST parsing (from herb gem)
- `Context` - Execution context
- `Rules::Base` subclasses - Rule implementations

### Herb::Lint::LinterFactory

**Responsibility:** Creates configured Linter instances (Factory Pattern).

```rbs
class Herb::Lint::LinterFactory
  @config: Herb::Config::LinterConfig
  @rule_registry: RuleRegistry

  attr_reader config: Herb::Config::LinterConfig
  attr_reader rule_registry: RuleRegistry

  def initialize: (
    Herb::Config::LinterConfig config,
    RuleRegistry rule_registry
  ) -> void

  def create: () -> Linter

  private

  def build_enabled_rules: () -> Array[Rules::Base]
  def instantiate_rule: (singleton(Rules::Base) rule_class) -> Rules::Base
end
```

**Processing:**
1. Query RuleRegistry for available rules
2. Filter to enabled rules based on configuration
3. Instantiate each rule with configured severity and options
4. Create Linter with enabled rule instances

### Herb::Lint::Context

**Responsibility:** Provides contextual information during rule execution.

**Design Note:** Directive parsing (inline disable comments) is handled by the Linter, not individual rules. Context provides read-only access to configuration and source information that rules need for their checks.

```rbs
class Herb::Lint::Context
  @file_path: String
  @source: String
  @config: Herb::Config::LinterConfig
  @source_lines: Array[String]?

  attr_reader file_path: String
  attr_reader source: String
  attr_reader config: Herb::Config::LinterConfig

  def initialize: (
    file_path: String,
    source: String,
    config: Herb::Config::LinterConfig
  ) -> void

  def severity_for: (String rule_name) -> Symbol
  def options_for: (String rule_name) -> Hash[Symbol, untyped]
  def source_line: (Integer line) -> String
  def line_count: () -> Integer

  private

  def split_source_lines: () -> Array[String]
end
```

### Herb::Lint::RuleRegistry

**Responsibility:** Central registry for rule classes (Registry Pattern).

**MVP Implementation Note:**

In the MVP release, RuleRegistry is implemented using class methods with a class variable (`@@rules`) instead of instance methods. This simplification is appropriate for the initial release with only 2-3 rules.

```ruby
# MVP Implementation (class methods)
class RuleRegistry
  @@rules = {}

  def self.register(rule_class)
    @@rules[rule_class.rule_name] = rule_class
  end

  def self.all
    @@rules.values
  end

  def self.load_builtin_rules
    # Manually register built-in rules
    require_relative "rules/html_img_require_alt"
    require_relative "rules/html_attribute_double_quotes"
    register(Rules::Html::ImgRequireAlt)
    register(Rules::Html::AttributeDoubleQuotes)
  end
end
```

The full implementation below uses instance methods for better testability and when rule count grows beyond ~10 rules.

```rbs
class Herb::Lint::RuleRegistry
  @rules: Hash[String, singleton(Rules::Base)]

  def initialize: () -> void

  def register: (singleton(Rules::Base) rule_class) -> void
  def get: (String name) -> singleton(Rules::Base)?
  def registered?: (String name) -> bool
  def all: () -> Array[singleton(Rules::Base)]
  def rule_names: () -> Array[String]
  def load_builtin_rules: () -> void

  private

  def discover_rules: (String directory) -> Array[singleton(Rules::Base)]
  def validate_rule_class: (singleton(Rules::Base) rule_class) -> bool
end
```

**Rule Categories:**
- `Rules::Erb::*` - ERB-specific rules
- `Rules::Html::*` - HTML validation and accessibility rules

**Rule List (TypeScript herb-lint reference):**

The following tables list all rules from the TypeScript `@herb-tools/linter`. The "Ruby rule name" column shows the corresponding name used in this Ruby implementation. Rules marked "—" are not yet implemented.

ERB rules (13):

| TypeScript rule name | Ruby rule name | Status |
|---|---|---|
| `erb-comment-syntax` | — | Not implemented |
| `erb-no-case-node-children` | — | Not implemented |
| `erb-no-empty-tags` | — | Not implemented |
| `erb-no-extra-newline` | — | Not implemented |
| `erb-no-extra-whitespace-inside-tags` | — | Not implemented |
| `erb-no-output-control-flow` | — | Not implemented |
| `erb-no-silent-tag-in-attribute-name` | — | Not implemented |
| `erb-prefer-image-tag-helper` | — | Not implemented |
| `erb-require-trailing-newline` | — | Not implemented |
| `erb-require-whitespace-inside-tags` | — | Not implemented |
| `erb-right-trim` | — | Not implemented |
| `erb-strict-locals-comment-syntax` | — | Not implemented |
| `erb-strict-locals-required` | — | Not implemented |

HTML rules (31):

| TypeScript rule name | Ruby rule name | Status |
|---|---|---|
| `html-anchor-require-href` | — | Not implemented |
| `html-aria-attribute-must-be-valid` | — | Not implemented |
| `html-aria-label-is-well-formatted` | — | Not implemented |
| `html-aria-level-must-be-valid` | — | Not implemented |
| `html-aria-role-heading-requires-level` | — | Not implemented |
| `html-aria-role-must-be-valid` | — | Not implemented |
| `html-attribute-double-quotes` | `html-attribute-double-quotes` | Implemented |
| `html-attribute-equals-spacing` | — | Not implemented |
| `html-attribute-values-require-quotes` | — | Not implemented |
| `html-avoid-both-disabled-and-aria-disabled` | — | Not implemented |
| `html-body-only-elements` | — | Not implemented |
| `html-boolean-attributes-no-value` | — | Not implemented |
| `html-head-only-elements` | — | Not implemented |
| `html-iframe-has-title` | `html-iframe-has-title` | Implemented |
| `html-img-require-alt` | `html-img-require-alt` | Implemented |
| `html-input-require-autocomplete` | — | Not implemented |
| `html-navigation-has-label` | — | Not implemented |
| `html-no-aria-hidden-on-focusable` | — | Not implemented |
| `html-no-block-inside-inline` | — | Not implemented |
| `html-no-duplicate-attributes` | `html-no-duplicate-attributes` | Implemented |
| `html-no-duplicate-ids` | `html-no-duplicate-ids` | Implemented |
| `html-no-duplicate-meta-names` | — | Not implemented |
| `html-no-empty-attributes` | — | Not implemented |
| `html-no-empty-headings` | — | Not implemented |
| `html-no-nested-links` | — | Not implemented |
| `html-no-positive-tab-index` | `html-no-positive-tab-index` | Implemented |
| `html-no-self-closing` | `html-no-self-closing` | Implemented |
| `html-no-space-in-tag` | — | Not implemented |
| `html-no-title-attribute` | — | Not implemented |
| `html-no-underscores-in-attribute-names` | — | Not implemented |
| `html-tag-name-lowercase` | `html-tag-name-lowercase` | Implemented |

Herb disable comment rules (6):

| TypeScript rule name | Ruby rule name | Status |
|---|---|---|
| `herb-disable-comment-malformed` | — | Not implemented |
| `herb-disable-comment-missing-rules` | — | Not implemented |
| `herb-disable-comment-no-duplicate-rules` | — | Not implemented |
| `herb-disable-comment-no-redundant-all` | — | Not implemented |
| `herb-disable-comment-unnecessary` | — | Not implemented |
| `herb-disable-comment-valid-rule-name` | — | Not implemented |

SVG rules (1):

| TypeScript rule name | Ruby rule name | Status |
|---|---|---|
| `svg-tag-name-capitalization` | — | Not implemented |

Parser rules (1):

| TypeScript rule name | Ruby rule name | Status |
|---|---|---|
| `parser-no-errors` | — | Not implemented |

**Processing:**
- Discovers rules by scanning rules/ subdirectories
- Validates rule classes inherit from Rules::Base
- Maintains name-to-class mapping
- Prevents duplicate registration

### Herb::Lint::CustomRuleLoader

**Responsibility:** Loads custom rule implementations from configured paths.

```rbs
class Herb::Lint::CustomRuleLoader
  @config: Herb::Config::LinterConfig
  @registry: RuleRegistry

  attr_reader config: Herb::Config::LinterConfig
  attr_reader registry: RuleRegistry

  def initialize: (
    Herb::Config::LinterConfig config,
    RuleRegistry registry
  ) -> void

  def load: () -> void

  private

  def load_custom_rules_from: (String path) -> void
  def require_rule_file: (String file_path) -> void
  def auto_register_rules: () -> void
end
```

**Processing:**
1. Reads custom rule paths from configuration
2. Requires Ruby files containing rule classes
3. Auto-registers newly loaded rule classes with RuleRegistry
4. Handles load errors gracefully

### Herb::Lint::Fixer

**Responsibility:** Applies automatic fixes to source code.

```rbs
class Herb::Lint::Fixer
  @source: String
  @offenses: Array[Offense]
  @fix_unsafely: bool

  attr_reader source: String
  attr_reader offenses: Array[Offense]
  attr_reader fix_unsafely: bool

  def initialize: (
    String source,
    Array[Offense] offenses,
    ?fix_unsafely: bool
  ) -> void

  def apply_fixes: () -> String

  private

  def fixable_offenses: () -> Array[Offense]
  def sort_by_location: (Array[Offense] offenses) -> Array[Offense]
  def apply_fix: (Offense offense, String current_source) -> String
end
```

**Processing:**
1. Filters offenses to fixable ones only
2. Sorts offenses by location (reverse order to maintain positions)
3. Applies each fix Proc to the source
4. Returns modified source code

**Safety:**
- Only applies fixes marked as fixable
- Requires `fix_unsafely: true` for potentially unsafe fixes
- Processes fixes in reverse document order to maintain positions

### Herb::Lint::Rules::Base

**Responsibility:** Abstract base class defining the rule interface.

```rbs
# Abstract rule interface that all rules must implement
interface _Rule
  # Class methods (must override)
  def self.rule_name: () -> String
  def self.description: () -> String

  # Class methods (optional overrides)
  def self.default_severity: () -> Symbol
  def self.fixable?: () -> bool
  def self.category: () -> Symbol

  # Instance interface
  def initialize: (?severity: Symbol?, ?options: Hash[Symbol, untyped]) -> void
  def check: (Herb::AST::Document document, Context context) -> Array[Offense]
  def fix: (Offense offense, String source) -> String
end

# Base class implementation providing common functionality
class Herb::Lint::Rules::Base
  include _Rule

  attr_reader severity: Symbol
  attr_reader options: Hash[Symbol, untyped]

  def self.rule_name: () -> String
  def self.description: () -> String
  def self.default_severity: () -> Symbol
  def self.fixable?: () -> bool
  def self.category: () -> Symbol

  def initialize: (?severity: Symbol?, ?options: Hash[Symbol, untyped]) -> void
  def check: (Herb::AST::Document document, Context context) -> Array[Offense]
  def fix: (Offense offense, String source) -> String

  private

  def create_offense: (
    message: String,
    location: Herb::Location,
    ?node: Herb::AST::Node?,
    ?fix: Proc?
  ) -> Offense
end
```

### Herb::Lint::Rules::VisitorRule

**Responsibility:** Base class for rules that traverse the AST using Herb gem's Visitor Pattern.

**Architecture:**
- Inherits from `Base` to implement the `_Rule` interface
- Includes `Herb::Visitor` module to leverage the gem's traversal mechanism
- Subclasses override specific `visit_*_node` methods for targeted node inspection
- Uses instance variables to accumulate offenses during traversal
- Provides `check` method that initializes traversal via `document.visit(self)`

**Design Note:** Ruby supports single inheritance only. Since VisitorRule needs both the rule interface (from Base) and visitor functionality (from Herb::Visitor), we inherit from Base and include Herb::Visitor as a module.

**Integration with Herb Gem:**
- The Herb gem provides `Herb::Visitor` module with built-in AST traversal
- Each node type has a corresponding `visit_*_node` method
- Calling `super(node)` ensures child nodes are visited recursively
- Rules can override specific visitor methods to inspect relevant node types

**Available Visitor Methods (from Herb::Visitor):**
- `visit_document_node(node)` - Document root
- `visit_literal_node(node)` - Plain text literals
- `visit_html_element_node(node)` - HTML elements (with open/close tags)
- `visit_html_open_tag_node(node)` - HTML opening tags
- `visit_html_close_tag_node(node)` - HTML closing tags
- `visit_html_attribute_node(node)` - HTML attributes
- `visit_html_attribute_name_node(node)` - Attribute names
- `visit_html_attribute_value_node(node)` - Attribute values
- `visit_html_text_node(node)` - Text content
- `visit_html_comment_node(node)` - HTML comments
- `visit_html_doctype_node(node)` - DOCTYPE declarations
- `visit_xml_declaration_node(node)` - XML declarations
- `visit_cdata_node(node)` - CDATA sections
- `visit_whitespace_node(node)` - Whitespace nodes
- `visit_erb_content_node(node)` - ERB output/statement tags
- `visit_erb_end_node(node)` - ERB end tags
- `visit_erb_else_node(node)` - ERB else clauses
- `visit_erb_if_node(node)` - ERB if blocks
- `visit_erb_unless_node(node)` - ERB unless blocks
- `visit_erb_block_node(node)` - ERB block structures
- `visit_erb_when_node(node)` - ERB when clauses
- `visit_erb_case_node(node)` - ERB case statements
- `visit_erb_case_match_node(node)` - ERB case/in pattern matching
- `visit_erb_while_node(node)` - ERB while loops
- `visit_erb_until_node(node)` - ERB until loops
- `visit_erb_for_node(node)` - ERB for loops
- `visit_erb_rescue_node(node)` - ERB rescue clauses
- `visit_erb_ensure_node(node)` - ERB ensure clauses
- `visit_erb_begin_node(node)` - ERB begin blocks
- `visit_erb_yield_node(node)` - ERB yield statements
- `visit_erb_in_node(node)` - ERB in clauses

```rbs
class Herb::Lint::Rules::VisitorRule < Base
  include Herb::Visitor

  @offenses: Array[Offense]
  @context: Context

  def initialize: (?severity: Symbol?, ?options: Hash[Symbol, untyped]) -> void

  # Main check method - initializes traversal
  def check: (Herb::AST::Document document, Context context) -> Array[Offense]

  # Override specific visit_*_node methods in subclasses as needed
  # Always call super(node) to continue traversal
  def visit_html_element_node: (Herb::AST::HTMLElementNode node) -> void
  def visit_erb_content_node: (Herb::AST::ERBContentNode node) -> void
  def visit_html_attribute_node: (Herb::AST::HTMLAttributeNode node) -> void
  # ... override other visit_*_node methods as needed

  private

  # Helper method for adding offenses during traversal
  def add_offense: (
    message: String,
    location: Herb::Location,
    ?node: Herb::AST::Node?,
    ?fix: Proc?
  ) -> void
end
```

## Rule Implementation Examples

### Example: Html::ImgRequireAlt

**Purpose:** Ensures `<img>` tags have alt attributes for accessibility.

**Interface:**
```rbs
class Herb::Lint::Rules::Html::ImgRequireAlt < VisitorRule
  def self.rule_name: () -> String
  def self.description: () -> String
  def self.default_severity: () -> Symbol
  def self.category: () -> Symbol

  def check: (Herb::AST::Document document, Context context) -> Array[Offense]
  def visit_html_element_node: (Herb::AST::HTMLElementNode node) -> void

  private

  def check_img_element: (Herb::AST::HTMLElementNode node) -> void
end
```

**Responsibilities:**
- Override `visit_html_element_node` to inspect HTML elements
- Identify `<img>` elements by checking node.tag_name
- Verify presence of `alt` attribute in node.open_tag.children
- Report offense if `alt` attribute is missing
- Call `super(node)` to continue traversal

### Example: Html::AttributeQuotes

**Purpose:** Enforces consistent quoting of HTML attribute values.

**Interface:**
```rbs
class Herb::Lint::Rules::Html::AttributeQuotes < VisitorRule
  def self.rule_name: () -> String
  def self.description: () -> String
  def self.default_severity: () -> Symbol
  def self.fixable?: () -> bool
  def self.category: () -> Symbol

  def check: (Herb::AST::Document document, Context context) -> Array[Offense]
  def visit_html_attribute_node: (Herb::AST::HTMLAttributeNode node) -> void

  private

  def check_attribute_quotes: (Herb::AST::HTMLAttributeNode attr_node) -> void
  def unquoted?: (Herb::AST::HTMLAttributeValueNode value_node) -> bool
  def wrong_quote_style?: (Herb::AST::HTMLAttributeValueNode value_node, String required_style) -> bool
  def fix_quotes: (Herb::AST::HTMLAttributeValueNode value_node, String style) -> String
end
```

**Responsibilities:**
- Override `visit_html_attribute_node` to inspect HTML attributes
- Check quoting style against configured option (e.g., `style: "double"`)
- Detect unquoted attributes using value_node.quoted?
- Verify quote character matches required style using value_node.opening_quote.value
- Report offense with fix Proc if improperly quoted
- Call `super(node)` to continue traversal

**Configuration Options:**
- `style` - Quote style: "double" or "single" (default: "double")

## Reporter Interface

### Herb::Lint::Reporter::BaseReporter

**Responsibility:** Abstract base class for result formatters.

```rbs
# Abstract reporter interface that all reporters must implement
interface _Reporter
  def initialize: (?output: IO) -> void
  def report: (AggregatedResult result) -> void
end

# Base class implementation providing common functionality
class Herb::Lint::Reporter::BaseReporter
  include _Reporter

  attr_reader output: IO

  def initialize: (?output: IO) -> void
  def report: (AggregatedResult result) -> void

  private

  def format_location: (Offense offense) -> String
  def format_severity: (Symbol severity) -> String
end
```

### Reporter Implementations

#### DetailedReporter

Human-readable format with color-coded severity.

```rbs
class Herb::Lint::Reporter::DetailedReporter < BaseReporter
  include _Reporter

  def initialize: (?output: IO) -> void
  def report: (AggregatedResult result) -> void

  private

  def format_file_header: (LintResult result) -> String
  def format_offense: (Offense offense) -> String
  def format_summary: (AggregatedResult result) -> String
  def colorize: (String text, Symbol color) -> String
end
```

Features:
- Groups offenses by file
- Shows line:column location
- Color codes severity levels (red=error, yellow=warning, etc.)
- Displays summary statistics

#### SimpleReporter

Compact text format.

```rbs
class Herb::Lint::Reporter::SimpleReporter < BaseReporter
  include _Reporter

  def initialize: (?output: IO) -> void
  def report: (AggregatedResult result) -> void

  private

  def format_offense_line: (LintResult result, Offense offense) -> String
end
```

Features:
- One line per offense
- Minimal formatting

#### JsonReporter

Machine-readable JSON output.

```rbs
class Herb::Lint::Reporter::JsonReporter < BaseReporter
  include _Reporter

  def initialize: (?output: IO) -> void
  def report: (AggregatedResult result) -> void

  private

  def to_json: (Hash[Symbol, untyped] data) -> String
end
```

Features:
- Serializes AggregatedResult.to_h
- Pretty-printed JSON format

#### GithubReporter

GitHub Actions annotations.

```rbs
class Herb::Lint::Reporter::GithubReporter < BaseReporter
  include _Reporter

  def initialize: (?output: IO) -> void
  def report: (AggregatedResult result) -> void

  private

  def format_annotation: (LintResult result, Offense offense) -> String
  def map_severity: (Symbol severity) -> String
end
```

Features:
- Outputs workflow commands
- Format: `::error file=path,line=N,col=M::message`
- Maps severities: error→error, warning→warning, info/hint→notice

## Processing Flow

```
CLI#run
  │
  ├── parse_options
  │
  ├── Config.load (herb-config)
  │
  ├── Runner.new(config)
  │   ├── RuleRegistry.load_builtin_rules
  │   └── CustomRuleLoader.load
  │
  ├── Runner#run(files)
  │   ├── FileDiscovery.discover (herb-core)
  │   │
  │   └── files.each do |file|
  │       ├── File.read(file)
  │       │
  │       └── Linter#lint(file, source)
  │           ├── DirectiveParser.new(source) (herb-core)
  │           ├── Check ignore_file?
  │           ├── Herb.parse(source) (herb gem)
  │           ├── Context.new
  │           ├── rules.each { |r| r.check(document, context) }
  │           ├── filter_by_directives
  │           └── return LintResult
  │
  ├── AggregatedResult.new(results)
  │
  ├── Reporter.report(aggregated_result)
  │
  └── Exit Code
```

## Error Handling

### Custom Exceptions

```ruby
module Herb
  module Lint
    module Errors
      class Error < StandardError; end

      class ConfigurationError < Error; end
      class ParseError < Error; end
      class RuleError < Error; end
      class FileNotFoundError < Error; end
    end
  end
end
```

## Testing Strategy

### Unit Tests - Rules

**Focus:** Individual rule logic in isolation

**Test Structure:**
- Parse sample ERB into AST using `Herb.parse`
- Create mock Context with test configuration
- Execute rule's `check` method
- Verify offense detection and attributes

**Key Test Cases:**
- Valid input produces no offenses
- Invalid input produces expected offenses
- Offense metadata (line, column, severity, rule_name) is correct
- Auto-fix logic works correctly (if fixable)
- Rule options affect behavior appropriately

### Integration Tests - Runner

**Focus:** End-to-end linting workflow

**Test Structure:**
- Create temporary test files
- Configure linter with specific rules
- Execute Runner.run
- Verify AggregatedResult correctness

**Key Test Cases:**
- Multiple files are processed correctly
- File discovery respects include/exclude patterns
- Inline directives (herb-lint-disable) work
- Auto-fix writes corrected files
- Error handling for parse failures

### Integration Tests - CLI

**Focus:** Command-line interface behavior

**Test Structure:**
- Invoke CLI with test arguments and output streams
- Verify exit codes
- Verify output format

**Key Test Cases:**
- Exit codes match offense severity
- Format options produce correct output
- Fix options modify files
- Configuration loading works

## Related Documents

- [Overall Architecture](./architecture.md)
- [herb-config Design](./herb-config-design.md)
- [herb-core Design](./herb-core-design.md)
- [Requirements: herb-lint](../requirements/herb-lint.md)
