# herb-tools-ruby Architecture

This document describes the high-level architecture and design decisions for the herb-tools-ruby project. It focuses on component structure, responsibilities, and relationships rather than implementation details.

## Overview

herb-tools-ruby provides Ruby implementations of ERB template linting and formatting tools, maintaining CLI compatibility with the TypeScript `@herb-tools` packages. The system is architected as a collection of focused, single-purpose gems that share common functionality through well-defined interfaces.

## Gem Structure

The project is organized into four gems with clear separation of concerns:

```
herb-tools-ruby/
├── herb-config/     # Shared: Configuration file management
├── herb-core/       # Shared: Common components
├── herb-lint/       # Linter
└── herb-format/     # Formatter (future)
```

## Dependencies

```
                    ┌─────────────┐
                    │    herb     │
                    │  (parser)   │
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
      ┌──────────────┐         ┌──────────────┐
      │  herb-config │         │  herb-core   │
      │   (config)   │         │   (shared)   │
      └──────┬───────┘         └──────┬───────┘
              │                         │
              └────────────┬────────────┘
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
      ┌──────────────┐         ┌──────────────┐
      │  herb-lint   │         │ herb-format  │
      │  (linter)    │         │ (formatter)  │
      └──────────────┘         └──────────────┘
```

### Dependency Rules

Dependencies flow in one direction: from tool-specific gems to shared infrastructure gems. This ensures:

- Shared gems remain general-purpose and reusable
- Tool gems can be developed independently
- Clear separation between common and specialized functionality

| Gem | Dependencies |
|-----|--------------|
| herb-config | herb (parser) |
| herb-core | herb (parser) |
| herb-lint | herb-config, herb-core, herb |
| herb-format | herb-config, herb-core, herb |

## Gem Responsibilities

### herb-config

**Purpose**: Centralized configuration management for all herb tools.

**Responsibilities**:
- Search for and load `.herb.yml` configuration files
- Validate configuration against schema
- Provide default values for unspecified settings
- Expose tool-specific configuration interfaces

**Key Components**:
```
Herb::Config
├── Loader           # Configuration file discovery and loading
├── Validator        # Schema validation
├── Schema           # Configuration structure definition
├── Defaults         # Default configuration values
├── LinterConfig     # Linter-specific view of configuration
└── FormatterConfig  # Formatter-specific view of configuration
```

**Design Decisions**:
- Single source of truth for configuration across all tools
- Tool-specific interfaces (LinterConfig, FormatterConfig) provide focused views
- Validation happens at load time to fail fast

For detailed design, see [herb-config Design](./herb-config-design.md).

### herb-core

**Purpose**: Shared infrastructure components used by multiple tools.

**Responsibilities**:
- File discovery and filtering based on patterns
- Processing inline directive comments (e.g., `# herb-disable`)
- Common utilities that don't belong in configuration

**Key Components**:
```
Herb::Core
├── FileDiscovery    # File discovery and glob processing
├── PatternMatcher   # Include/exclude pattern matching
└── DirectiveParser  # Parse inline disable comments
```

**Design Decisions**:
- Keeps file system operations separate from tool logic
- PatternMatcher handles both include and exclude patterns consistently
- DirectiveParser provides generic comment parsing, usable by any tool

For detailed design, see [herb-core Design](./herb-core-design.md).

### herb-lint

**Purpose**: Static analysis tool for ERB templates, detecting code quality, style, and accessibility issues.

**Responsibilities**:
- Parse ERB templates using the `herb` parser gem
- Execute configured rules against the AST
- Report violations in various formats
- Support custom rule loading
- Handle inline directive comments to suppress specific violations

**Key Components**:
```
Herb::Lint
├── CLI              # Command-line interface
├── Runner           # Orchestrate linting workflow
├── Linter           # Core linting logic per file
├── RuleRegistry     # Rule registration and lookup
├── Context          # Execution context passed to rules
├── Offense          # Violation representation
├── Reporter         # Output formatting strategy
│   ├── BaseReporter
│   ├── DetailedReporter
│   ├── SimpleReporter
│   ├── JsonReporter
│   └── GithubReporter
├── CustomRuleLoader # Custom rule discovery and loading
├── Rules            # Rule implementations
│   ├── Base         # Rule interface definition
│   ├── VisitorRule  # AST traversal support
│   ├── Erb/         # ERB-specific rules
│   ├── Html/        # HTML-specific rules
│   └── A11y/        # Accessibility rules
└── Errors           # Custom exceptions
```

**Design Decisions**:
- Runner orchestrates high-level workflow; Linter handles per-file execution
- Context object provides rules with configuration and utilities
- Rules are self-contained and testable in isolation
- Registry Pattern enables dynamic rule loading
- Visitor Pattern simplifies AST traversal for most rules

For detailed design, see [herb-lint Design](./herb-lint-design.md).

### herb-format (future)

**Purpose**: Code formatter for ERB templates, automatically fixing style and formatting issues.

**Responsibilities**:
- Parse and rewrite ERB templates
- Apply formatting rules consistently
- Support check-only mode (verify without modifying)
- Handle custom rewriter extensions

**Key Components**:
```
Herb::Format
├── CLI              # Command-line interface
├── Formatter        # Format workflow orchestration
├── Engine           # AST rewriting logic
├── Context          # Formatting execution context
├── RewriterRegistry # Rewriter registration and lookup
├── Rewriters        # Rewriter implementations
│   └── Base         # Rewriter interface definition
└── Errors           # Custom exceptions
```

**Design Decisions**:
- Mirrors herb-lint architecture for consistency
- Rewriters operate on AST for reliable transformations
- Registry Pattern enables custom rewriter loading
- Check mode allows CI integration without modification

## Processing Flow Overview

### herb-lint Processing Flow

The linting process follows a linear pipeline with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. CLI Initialization                                                │
│    - Parse command-line arguments                                    │
│    - Load configuration (herb-config)                                │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 2. Setup                                                              │
│    - Initialize RuleRegistry                                         │
│    - Load built-in rules                                             │
│    - Load custom rules (if configured)                               │
│    - Create Runner with enabled rules                                │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 3. File Discovery                                                    │
│    - Discover files matching patterns (herb-core)                    │
│    - Apply include/exclude filters                                   │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 4. Lint Each File                                                    │
│    - Parse template to AST (herb parser)                             │
│    - Parse inline directives (herb-core)                             │
│    - Execute each enabled rule                                       │
│    - Filter offenses based on directives                             │
│    - Collect results                                                 │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 5. Report Results                                                    │
│    - Format results using selected reporter                          │
│    - Output to console or file                                       │
│    - Determine exit code based on fail-level                         │
└─────────────────────────────────────────────────────────────────────┘
```

**Key Points**:
- Configuration is loaded once and shared across all files
- Rules are instantiated per-file to maintain isolation
- Each file is processed independently for parallelization potential
- Inline directives are evaluated after rules run, allowing selective suppression

## Design Principles

### Single Responsibility Principle (SRP)

Each component has one well-defined purpose:

- **Gems**: herb-config handles configuration, herb-core handles shared utilities, herb-lint handles linting
- **Classes**: Runner orchestrates workflow, Linter processes files, Rules detect violations, Reporters format output
- **Modules**: Each rule namespace (Erb, Html, A11y) groups related functionality

This separation makes components easier to test, maintain, and reason about in isolation.

### Dependency Inversion Principle (DIP)

High-level modules do not depend on low-level modules. Both depend on abstractions:

- **Rules interface**: All rules implement a common `Base` class defining the `check` method signature. The linter depends on this interface, not specific rule implementations.
- **Reporter interface**: All reporters implement a common interface. The CLI depends on the abstraction, not concrete reporters.
- **Configuration interface**: Tools depend on configuration interfaces (LinterConfig, FormatterConfig) rather than the raw configuration structure.

This enables extensibility and makes components interchangeable.

### Open-Closed Principle (OCP)

The system is open for extension but closed for modification:

- **Custom rules**: New rules can be added by implementing the Rules::Base interface without modifying existing code
- **Custom reporters**: New output formats can be added by implementing the reporter interface
- **Custom rewriters**: New formatters can be added without changing the core engine
- **Plugin architecture**: Custom rules and rewriters are loaded dynamically through the registry

Users can extend functionality without forking or modifying the core gems.

## Design Patterns

### Registry Pattern

**Purpose**: Manage dynamic registration and lookup of rules and rewriters.

**Application**:
- RuleRegistry maintains a mapping of rule names to rule classes
- Allows runtime registration of custom rules
- Enables configuration-based rule selection

**Interface**:
```rbs
interface _RuleRegistry
  def register: (Class rule_class) -> void
  def get: (String name) -> Class?
  def all: () -> Array[Class]
end
```

**Benefits**: Custom rules can be added without modifying the registry implementation.

### Visitor Pattern

**Purpose**: Traverse and inspect AST nodes without coupling rules to the tree structure.

**Application**:
- Custom visitors inherit from `Herb::Visitor`
- Override specific `visit_*_node` methods for node types of interest
- Call `super(node)` to continue traversal to child nodes
- Invoked via `document.visit(visitor)`

**Interface**:
```rbs
# Base visitor provided by Herb parser gem
class Herb::Visitor
  # Available visit methods for each node type
  def visit_document_node: (Herb::AST::Node node) -> void
  def visit_html_element_node: (Herb::AST::Node node) -> void
  def visit_html_attribute_node: (Herb::AST::Node node) -> void
  def visit_html_comment_node: (Herb::AST::Node node) -> void
  def visit_html_doctype_node: (Herb::AST::Node node) -> void
  def visit_erb_content_node: (Herb::AST::Node node) -> void
  def visit_erb_yield_node: (Herb::AST::Node node) -> void
  def visit_erb_block_node: (Herb::AST::Node node) -> void
end

# Custom visitor interface for rule implementations
class CustomRuleVisitor < Herb::Visitor
  def initialize: (Herb::Lint::Context context, Array[Offense] offenses) -> void

  # Override specific visit methods for nodes requiring analysis
  # Each method should:
  # 1. Perform checks on the node
  # 2. Record offenses if violations detected
  # 3. Call super(node) to continue traversal to child nodes
  def visit_html_element_node: (Herb::AST::Node node) -> void
  def visit_erb_content_node: (Herb::AST::Node node) -> void
  # ... override only the methods relevant to your rule
end
```

**Usage Pattern**:
1. Create a visitor class inheriting from `Herb::Visitor`
2. Override `visit_*_node` methods for node types relevant to your rule
3. In each overridden method, perform checks and call `super(node)` to traverse children
4. Instantiate the visitor and invoke via `document.visit(visitor)`

**Benefits**:
- Rules focus on specific node types through targeted `visit_*_node` methods
- Only override methods for relevant node types, reducing boilerplate
- Traversal logic is centralized and reusable through the Herb gem's visitor infrastructure
- Type-specific method names make code more self-documenting

### Strategy Pattern

**Purpose**: Select output formatting algorithm at runtime.

**Application**:
- Multiple reporter implementations (detailed, simple, JSON, GitHub)
- Reporter is selected based on CLI option or configuration
- All reporters implement the same interface

**Interface**:
```rbs
interface _Reporter
  # Format and output linting results
  def report: (Array[Herb::Lint::Result] results, ?io: IO) -> void
end
```

**Benefits**: New output formats can be added without changing the core linting logic.

### Factory Pattern

**Purpose**: Encapsulate complex object construction logic.

**Application**:
- LinterFactory creates Linter instances with appropriate rules based on configuration
- Handles rule filtering, instantiation, and dependency injection

**Interface**:
```rbs
class LinterFactory
  def initialize: (Herb::Config::LinterConfig config, _RuleRegistry registry) -> void
  # Create a configured linter instance
  def create: () -> Herb::Lint::Linter
end
```

**Benefits**: Centralizes rule selection logic and makes Linter creation testable.

## Error Handling

### Exception Hierarchy

The system uses custom exception classes for clear error categorization:

- **Error**: Base class for all herb-tools exceptions
  - **ConfigurationError**: Invalid configuration file or settings
  - **ParseError**: ERB template parsing failures
  - **RuleError**: Errors within rule execution
  - **FileNotFoundError**: Missing template files

This hierarchy allows error handling at different granularities and provides meaningful error messages to users.

### Exit Code Convention

CLI tools follow standard UNIX exit code conventions:

| Code | Meaning | Used When |
|------|---------|-----------|
| 0 | Success | No violations found, or violations below fail-level threshold |
| 1 | Lint failure | Violations found at or above configured fail-level |
| 2 | Runtime error | Configuration errors, file I/O errors, parser failures |

This enables integration with CI/CD pipelines and build scripts.

## Related Documents

- [herb-config Design](./herb-config-design.md)
- [herb-core Design](./herb-core-design.md)
- [herb-lint Design](./herb-lint-design.md)
- [Requirements: Overview](../requirements/overview.md)
