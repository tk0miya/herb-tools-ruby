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
│           ├── autofixer.rb
│           ├── errors.rb
│           ├── directive_parser.rb
│           ├── unnecessary_directive_detector.rb
│           ├── reporter/
│           │   ├── base_reporter.rb
│           │   ├── detailed_reporter.rb
│           │   ├── simple_reporter.rb
│           │   ├── json_reporter.rb
│           │   └── github_reporter.rb
│           └── rules/
│               ├── base.rb
│               ├── visitor_rule.rb
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
├── CLI                       # Command line interface
├── Runner                    # Lint execution orchestration
├── Linter                    # Core linting implementation
├── LinterFactory             # Linter instance creation (Factory Pattern)
├── Context                   # Lint execution context
├── Offense                   # Offense representation
├── LintResult                # Lint result for a single file
├── AggregatedResult          # Aggregated result for multiple files
├── RuleRegistry              # Rule registration and lookup (Registry Pattern)
├── CustomRuleLoader          # Custom rule loading
├── Autofixer                 # Autofix application
├── Errors                    # Custom exceptions
├── DirectiveParser           # Directive parsing (herb:disable, herb:linter ignore)
├── UnnecessaryDirectiveDetector  # Detect unused herb:disable directives
├── Reporter                  # Output formatter
│   ├── BaseReporter
│   ├── DetailedReporter
│   ├── SimpleReporter
│   ├── JsonReporter
│   └── GithubReporter
└── Rules                     # Rule implementations
    ├── Base
    ├── VisitorRule
    ├── HtmlAttributeDoubleQuotes
    ├── HtmlIframeHasTitle
    ├── HtmlImgRequireAlt
    ├── HtmlNoDuplicateAttributes
    ├── HtmlNoDuplicateIds
    ├── HtmlNoPositiveTabIndex
    ├── HtmlNoSelfClosing
    ├── HtmlTagNameLowercase
    └── ...
```

## Data Structures

### Herb::Lint::Offense

Represents a single linting violation.

```rbs
class Herb::Lint::Offense
  attr_reader rule_name: String
  attr_reader message: String
  attr_reader severity: String
  attr_reader location: Herb::Location
  attr_reader autofix_context: AutofixContext?

  def initialize: (
    rule_name: String,
    message: String,
    severity: String,
    location: Herb::Location,
    ?autofix_context: AutofixContext?
  ) -> void

  def line: () -> Integer
  def column: () -> Integer
  def fixable?: () -> bool   # true when autofix_context is present
  def to_h: () -> Hash[Symbol, untyped]
end
```

See [Autofix Design](./herb-lint-autofix-design.md) for `AutofixContext` and the autofix processing flow.

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
- `--fix` - Apply safe autofixes
- `--fix-unsafely` - Apply potentially unsafe autofixes
- `--format TYPE` - Output format (detailed, simple, json)
- `--github` - GitHub Actions annotation format
- `--fail-level LEVEL` - Minimum severity to trigger failure (error, warning, info, hint)
- `--config PATH` - Custom configuration file path
- `--ignore-disable-comments` - Report offenses even when suppressed with `<%# herb:disable %>` comments
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
   - Apply autofixes if requested and available
   - Handle errors gracefully
5. Aggregation: Combine results into AggregatedResult

**Dependencies:**
- `Herb::Config::LinterConfig` - Configuration
- `RuleRegistry` - Rule management
- `CustomRuleLoader` - Custom rule loading
- `LinterFactory` - Linter instantiation
- `Herb::Core::FileDiscovery` - File discovery
- `Autofixer` - Autofix application

### Herb::Lint::Linter

**Responsibility:** Core single-file linting implementation. Uses `DirectiveParser` for directive processing and offense filtering.

```rbs
class Herb::Lint::Linter
  @rules: Array[Rules::Base]
  @config: Herb::Config::LinterConfig
  @rule_registry: RuleRegistry?
  @ignore_disable_comments: bool

  attr_reader rules: Array[Rules::Base]
  attr_reader config: Herb::Config::LinterConfig
  attr_reader rule_registry: RuleRegistry?
  attr_reader ignore_disable_comments: bool

  def initialize: (
    Array[Rules::Base] rules,
    Herb::Config::LinterConfig config,
    ?rule_registry: RuleRegistry?,
    ?ignore_disable_comments: bool
  ) -> void

  def lint: (file_path: String, source: String) -> LintResult

  private

  def build_context: (String file_path, String source) -> Context
  def collect_offenses: (Herb::ParseResult document, Context context) -> Array[Offense]
  def build_lint_result: (String file_path, String source, DirectiveParser::Directives directives, Array[Offense] offenses) -> LintResult
  def parse_error_result: (String file_path, String source, Array[untyped] errors) -> LintResult
  def parse_error_offense: (untyped error) -> Offense
end
```

**Processing Flow:**
1. Parse ERB template into AST via `Herb.parse`
2. Parse directives via `DirectiveParser.parse(parse_result, source)` → `directives`
3. Check for file-level ignore via `directives.ignore_file?`; return empty result if found
4. Create Context with source and configuration
5. Execute all rules against the AST and collect offenses
6. Build LintResult (filtering offenses and detecting unnecessary directives)

**Non-Excludable Rules:**

The following meta-rules validate `herb:disable` comments themselves and cannot be suppressed by `herb:disable` directives:

- `herb-disable-comment-malformed`
- `herb-disable-comment-missing-rules`
- `herb-disable-comment-valid-rule-name`
- `herb-disable-comment-no-duplicate-rules`
- `herb-disable-comment-no-redundant-all`

**Note:** `herb-disable-comment-unnecessary` is not implemented as a rule. It is handled by `UnnecessaryDirectiveDetector`, which is called by the Linter after offense filtering. This is because it requires knowledge of which offenses were suppressed, which is only available after filtering.

**Dependencies:**
- `DirectiveParser` - Parse directives; returns `Directives` data object
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

**Design Note:** Directive parsing (inline disable comments) is handled by the Linter, not individual rules. Context provides read-only access to configuration and source information that rules need.

```rbs
class Herb::Lint::Context
  @file_path: String
  @source: String
  @config: Herb::Config::LinterConfig
  @source_lines: Array[String]?
  @valid_rule_names: Array[String]?
  @ignore_disable_comments: bool

  attr_reader file_path: String
  attr_reader source: String
  attr_reader config: Herb::Config::LinterConfig

  # Optional RuleRegistry for severity lookup.
  attr_reader rule_registry: RuleRegistry?

  def initialize: (
    file_path: String,
    source: String,
    config: Herb::Config::LinterConfig,
    ?rule_registry: RuleRegistry?,
    ?valid_rule_names: Array[String]?,
    ?ignore_disable_comments: bool
  ) -> void

  def severity_for: (String rule_name) -> Symbol
  def source_line: (Integer line) -> String
  def line_count: () -> Integer

  # Returns list of all valid rule names for directive validation.
  # Used by herb-disable-comment-valid-rule-name meta-rule.
  def valid_rule_names: () -> Array[String]

  # Whether to ignore inline disable comments (from --ignore-disable-comments flag).
  def ignore_disable_comments?: () -> bool

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
    register(Rules::HtmlImgRequireAlt)
    register(Rules::HtmlAttributeDoubleQuotes)
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

**Rule Categories (by name prefix):**
- `html-*` - HTML validation and accessibility rules
- `erb-*` - ERB-specific rules
- `herb-*` - Herb disable comment rules
- `svg-*` - SVG rules

**Rule List:**

The following tables list all rules from the TypeScript `@herb-tools/linter`. Ruby uses identical rule names.

ERB rules (13):

| Rule name | Status |
|---|---|
| `erb-comment-syntax` | Not implemented |
| `erb-no-case-node-children` | Not implemented |
| `erb-no-empty-tags` | Not implemented |
| `erb-no-extra-newline` | Not implemented |
| `erb-no-extra-whitespace-inside-tags` | Not implemented |
| `erb-no-output-control-flow` | Not implemented |
| `erb-no-silent-tag-in-attribute-name` | Not implemented |
| `erb-prefer-image-tag-helper` | Not implemented |
| `erb-require-trailing-newline` | Not implemented |
| `erb-require-whitespace-inside-tags` | Not implemented |
| `erb-right-trim` | Not implemented |
| `erb-strict-locals-comment-syntax` | Not implemented |
| `erb-strict-locals-required` | Not implemented |

HTML rules (31):

| Rule name | Status |
|---|---|
| `html-anchor-require-href` | Not implemented |
| `html-aria-attribute-must-be-valid` | Not implemented |
| `html-aria-label-is-well-formatted` | Not implemented |
| `html-aria-level-must-be-valid` | Not implemented |
| `html-aria-role-heading-requires-level` | Not implemented |
| `html-aria-role-must-be-valid` | Not implemented |
| `html-attribute-double-quotes` | Implemented |
| `html-attribute-equals-spacing` | Not implemented |
| `html-attribute-values-require-quotes` | Not implemented |
| `html-avoid-both-disabled-and-aria-disabled` | Not implemented |
| `html-body-only-elements` | Not implemented |
| `html-boolean-attributes-no-value` | Not implemented |
| `html-head-only-elements` | Not implemented |
| `html-iframe-has-title` | Implemented |
| `html-img-require-alt` | Implemented |
| `html-input-require-autocomplete` | Not implemented |
| `html-navigation-has-label` | Not implemented |
| `html-no-aria-hidden-on-focusable` | Not implemented |
| `html-no-block-inside-inline` | Not implemented |
| `html-no-duplicate-attributes` | Implemented |
| `html-no-duplicate-ids` | Implemented |
| `html-no-duplicate-meta-names` | Not implemented |
| `html-no-empty-attributes` | Not implemented |
| `html-no-empty-headings` | Not implemented |
| `html-no-nested-links` | Not implemented |
| `html-no-positive-tab-index` | Implemented |
| `html-no-self-closing` | Implemented |
| `html-no-space-in-tag` | Not implemented |
| `html-no-title-attribute` | Not implemented |
| `html-no-underscores-in-attribute-names` | Not implemented |
| `html-tag-name-lowercase` | Implemented |

Herb disable comment rules (6):

| Rule name | Status |
|---|---|
| `herb-disable-comment-malformed` | Implemented |
| `herb-disable-comment-missing-rules` | Implemented |
| `herb-disable-comment-no-duplicate-rules` | Implemented |
| `herb-disable-comment-no-redundant-all` | Implemented |
| `herb-disable-comment-unnecessary` | Implemented (via UnnecessaryDirectiveDetector) |
| `herb-disable-comment-valid-rule-name` | Implemented |

SVG rules (1):

| Rule name | Status |
|---|---|
| `svg-tag-name-capitalization` | Not implemented |

Parser rules (1):

| Rule name | Status |
|---|---|
| `parser-no-errors` | Not implemented |

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

### Herb::Lint::Autofixer

**Responsibility:** Applies autofixes to source code using AST node replacement and IdentityPrinter serialization.

See [Autofix Design](./herb-lint-autofix-design.md) for the full detailed design, including node replacement patterns, autofix rule implementation, and the processing flow.

```rbs
class Herb::Lint::Autofixer
  @source: String
  @offenses: Array[Offense]
  @fix_unsafely: bool

  def initialize: (
    String source,
    Array[Offense] offenses,
    ?fix_unsafely: bool
  ) -> void

  def apply: () -> AutoFixResult

  private

  def apply_ast_fixes: (String source, Array[Offense] offenses) -> [String, Array[Offense], Array[Offense]]
  def fixable_offenses: (Array[Offense] offenses) -> Array[Offense]
  def safe_to_apply?: (Offense offense) -> bool
end
```

**Processing:**
1. Filters offenses to fixable ones (those with `autofix_context`)
2. Re-parses source with `Herb.parse(source, track_whitespace: true)` for whitespace-preserving AST
3. Relocates each target node via `NodeLocator`, calls rule's `autofix` to create replacement nodes
4. Serializes the modified AST via `Herb::Printer::IdentityPrinter.print(parse_result)`
5. Returns `AutoFixResult` with corrected source and categorized offenses

**Safety:**
- `safe_autofixable?` rules are applied with `--fix`
- `unsafe_autofixable?` rules require `--fix-unsafely`
- Nodes not found after re-parse are skipped (added to unfixed list)

**Dependencies:**
- `herb-printer` gem for `IdentityPrinter`
- `Herb.parse(source, track_whitespace: true)` for whitespace-preserving AST

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
  def initialize: (?severity: Symbol?) -> void
  def check: (Herb::AST::Document document, Context context) -> Array[Offense]
  def fix: (Offense offense, String source) -> String
end

# Base class implementation providing common functionality
class Herb::Lint::Rules::Base
  include _Rule

  attr_reader severity: Symbol

  def self.rule_name: () -> String
  def self.description: () -> String
  def self.default_severity: () -> Symbol
  def self.fixable?: () -> bool
  def self.category: () -> Symbol

  def initialize: (?severity: Symbol?) -> void
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

  def initialize: (?severity: Symbol?) -> void

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

## Directive Handling

### Overview

herb-lint supports two types of inline directives in ERB templates:

| Directive | Syntax | Scope | Purpose |
|-----------|--------|-------|---------|
| Line disable (specific) | `<%# herb:disable rule1, rule2 %>` | Same line | Suppress specific rules on that line |
| Line disable (all) | `<%# herb:disable all %>` | Same line | Suppress all rules on that line |
| File ignore | `<%# herb:linter ignore %>` | Entire file | Skip the entire file from linting |

**Design Note:** This design matches the TypeScript reference implementation. Directives are line-scoped only — there is no `herb:enable`, no range-based disable, and no `next_line` scope. The `herb:disable` comment must appear on the **same line** as the offense it suppresses.

### Herb::Lint::DirectiveParser

**Responsibility:** Parse directive comments from an ERB template. Stateless parser that takes a parse result and source, and returns a `Directives` data object.

**Reference:** Corresponds to `herb-disable-comment-utils.ts` and `linter-ignore.ts` in the TypeScript implementation. The TS version keeps these as separate files, but since both operate on ERB comments, they are unified here.

#### Data Structures

```rbs
# Represents a parsed rule name with position information for error reporting.
class Herb::Lint::DirectiveParser::DisableRuleName
  attr_reader name: String
  attr_reader offset: Integer
  attr_reader length: Integer

  def initialize: (name: String, offset: Integer, length: Integer) -> void
end

# Represents a parsed herb:disable comment.
class Herb::Lint::DirectiveParser::DisableComment
  attr_reader match: String
  attr_reader rule_names: Array[String]
  attr_reader rule_name_details: Array[DisableRuleName]
  attr_reader rules_string: String
  attr_reader content_location: Herb::Location?

  def initialize: (
    match: String,
    rule_names: Array[String],
    rule_name_details: Array[DisableRuleName],
    rules_string: String,
    content_location: Herb::Location?
  ) -> void
end

# Parse result holding all directive information for a file.
# Provides query methods for the Linter to check disable state.
class Herb::Lint::DirectiveParser::Directives
  attr_reader herb_disable_cache: Hash[Integer, Array[String]]

  def initialize: (
    ignore_file: bool,
    herb_disable_cache: Hash[Integer, Array[String]]
  ) -> void

  # Whether the file contains a <%# herb:linter ignore %> directive.
  def ignore_file?: () -> bool

  # Check if a specific rule is disabled at a given line number (1-based).
  # Returns true if the line has a herb:disable comment listing the rule name or "all".
  def disabled_at?: (Integer line, String rule_name) -> bool
end
```

#### Public Interface

```rbs
class Herb::Lint::DirectiveParser
  HERB_DISABLE_PREFIX: String         # "herb:disable"
  HERB_LINTER_IGNORE_PREFIX: String   # "herb:linter ignore"

  # Parse all directives from a template.
  # Detects <%# herb:linter ignore %> via AST traversal and builds
  # the herb:disable cache via line-by-line source scan.
  def self.parse: (Herb::ParseResult parse_result, String source) -> Directives

  # Parse the content inside <%# ... %> delimiters.
  # Used by meta-rules for AST-based analysis of disable comments.
  # Returns nil if the content is not a valid herb:disable comment.
  def self.parse_disable_comment_content: (String content) -> DisableComment?

  # Check if content (inside delimiters) is a herb:disable comment.
  def self.disable_comment_content?: (String content) -> bool
end
```

**Design Note:**
- `DirectiveParser` is stateless. All methods are class methods.
- `parse` is the main entry point: it returns a `Directives` object that holds the parsed state and provides query methods (`ignore_file?`, `disabled_at?`).
- `parse_disable_comment_content` and `disable_comment_content?` are separate class methods used by meta-rules to inspect individual AST nodes during traversal.

### Herb Disable Comment Meta-Rules

The following five meta-rules validate `herb:disable` comments themselves. They are **non-excludable** — they cannot be suppressed by `herb:disable` directives. Each inherits from `VisitorRule` directly.

| Rule Name | Severity | What It Detects |
|-----------|----------|-----------------|
| `herb-disable-comment-malformed` | error | Missing space after prefix, trailing/leading/consecutive commas |
| `herb-disable-comment-missing-rules` | error | `<%# herb:disable %>` with no rule names |
| `herb-disable-comment-valid-rule-name` | warning | Unknown rule names (with "did you mean?" suggestions using `valid_rule_names` from Context) |
| `herb-disable-comment-no-duplicate-rules` | warning | Same rule listed twice in one comment |
| `herb-disable-comment-no-redundant-all` | warning | `all` used alongside specific rules (redundant) |

All meta-rules override `visit_erb_content_node` to filter for ERB comment nodes (`<%#`), then use `DirectiveParser.parse_disable_comment_content` to parse and validate the content.

### Herb::Lint::UnnecessaryDirectiveDetector

**Responsibility:** Detects `herb:disable` directives that did not suppress any offense. Called by the Linter after offense filtering.

**Design Note:** This is not implemented as a rule because it requires knowledge of which offenses were suppressed — information only available after the Linter has filtered offenses using directives. It computes directly from `directives` and `ignored_offenses`.

| Property | Value |
|----------|-------|
| Rule name | `herb-disable-comment-unnecessary` |
| Severity | warning |
| Detects | `herb:disable` directive that does not suppress any actual offense |

```rbs
class Herb::Lint::UnnecessaryDirectiveDetector
  RULE_NAME: String

  def self.detect: (DirectiveParser::Directives directives, Array[Offense] ignored_offenses) -> Array[Offense]
end
```

**Processing:**
1. Build a lookup of suppressed rule names by line from `ignored_offenses`
2. Iterate over `directives.disable_comments`
3. For `herb:disable all` — report if no offenses were suppressed on that line
4. For specific rule names — report each rule name that did not match any suppressed offense

## Rule Implementation Examples

### Example: HtmlImgRequireAlt

**Purpose:** Ensures `<img>` tags have alt attributes for accessibility.

**Interface:**
```rbs
class Herb::Lint::Rules::HtmlImgRequireAlt < VisitorRule
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

### Example: HtmlAttributeDoubleQuotes

**Purpose:** Enforces consistent quoting of HTML attribute values.

**Interface:**
```rbs
class Herb::Lint::Rules::HtmlAttributeDoubleQuotes < VisitorRule
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
  ├── parse_options (including --ignore-disable-comments)
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
  │       └── Linter#lint(file_path:, source:)
  │           │
  │           ├── Herb.parse(source) (herb gem)
  │           │
  │           ├── directives = DirectiveParser.parse(parse_result, source)
  │           │   ├── Detect <%# herb:linter ignore %> via AST traversal
  │           │   └── Build disable_comments via AST comment scanning
  │           │
  │           ├── directives.ignore_file?
  │           │   └── (return empty LintResult if file ignored)
  │           │
  │           ├── Context.new(file_path:, source:, config:, rule_registry:)
  │           │
  │           ├── Execute all rules
  │           │   └── rules.flat_map { |rule| rule.check(document, context) }
  │           │
  │           └── build_lint_result
  │               ├── (if ignore_disable_comments) return LintResult as-is
  │               ├── directives.filter_offenses(offenses) → [kept, ignored]
  │               ├── UnnecessaryDirectiveDetector.detect(directives, ignored)
  │               └── return LintResult (kept + unnecessary, ignored count)
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
- Autofix logic works correctly (if fixable)
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
- Inline directives (`herb:disable`, `herb:linter ignore`) work
- Autofix writes corrected files
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
- Autofix options modify files
- Configuration loading works

## Related Documents

- [Overall Architecture](./architecture.md)
- [herb-config Design](./herb-config-design.md)
- [herb-core Design](./herb-core-design.md)
- [Requirements: herb-lint](../requirements/herb-lint.md)
