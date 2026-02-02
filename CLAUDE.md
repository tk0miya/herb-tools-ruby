# herb-tools-ruby

Ruby implementation of `@herb-tools/linter` and `@herb-tools/formatter` from the TypeScript ecosystem.

## Project Overview

This project provides two gems for working with ERB template files:

- **herb-lint**: Static analysis tool for ERB templates
- **herb-format**: Formatter for ERB templates

Both tools maintain CLI compatibility with their TypeScript counterparts, sharing the same configuration file format (`.herb.yml`) and providing equivalent functionality.

## Reference Implementation

- Repository: https://github.com/marcoroth/herb
- TypeScript packages: `javascript/packages/linter`, `javascript/packages/formatter`

## Directory Structure

```
herb-tools-ruby/
├── CLAUDE.md                    # This file
├── bin/                         # Root binstubs (uses root Gemfile)
│   ├── rake
│   ├── rbs
│   ├── rbs-inline
│   ├── rspec
│   ├── rubocop
│   └── steep
├── docs/
│   └── requirements/            # Specification documents
│       ├── overview.md
│       ├── herb-lint.md
│       ├── herb-format.md
│       └── config.md
│
├── herb-config/                 # Configuration gem
│   ├── bin/                     # Binstubs (uses herb-config/Gemfile)
│   ├── lib/
│   ├── spec/
│   └── herb-config.gemspec
│
├── herb-core/                   # Core gem
│   ├── bin/                     # Binstubs (uses herb-core/Gemfile)
│   ├── lib/
│   ├── spec/
│   └── herb-core.gemspec
│
├── herb-printer/                # Printer gem (AST-to-source)
│   ├── bin/                     # Binstubs (uses herb-printer/Gemfile)
│   ├── lib/
│   ├── spec/
│   └── herb-printer.gemspec
│
├── herb-lint/                   # Linter gem
│   ├── bin/                     # Binstubs (uses herb-lint/Gemfile)
│   ├── lib/
│   │   └── herb/
│   │       └── lint/
│   │           ├── version.rb
│   │           ├── cli.rb
│   │           ├── runner.rb
│   │           ├── config.rb
│   │           ├── reporter.rb
│   │           ├── rule_registry.rb
│   │           └── rules/
│   │               ├── base.rb
│   │               ├── erb/
│   │               ├── html/
│   │               └── a11y/
│   ├── exe/
│   │   └── herb-lint
│   ├── spec/
│   └── herb-lint.gemspec
│
├── herb-format/                 # Formatter gem
│   ├── bin/                     # Binstubs (uses herb-format/Gemfile)
│   ├── lib/
│   │   └── herb/
│   │       └── format/
│   │           ├── version.rb
│   │           ├── cli.rb
│   │           ├── formatter.rb
│   │           ├── config.rb
│   │           └── rewriters/
│   │               └── base.rb
│   ├── exe/
│   │   └── herb-format
│   ├── spec/
│   └── herb-format.gemspec
│
└── Gemfile                      # Development dependencies
```

## Development Setup

### Prerequisites

- Ruby 3.3 or later
- Bundler

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd herb-tools-ruby

# Install dependencies
bundle install
```

### Using Binstubs

Each gem has its own binstubs in its `bin/` directory. Run commands from within the gem directory using `./bin/`:

```bash
# Run all checks (spec, rubocop, steep) for a gem
cd herb-config && ./bin/rake

# Run tests only
cd herb-config && ./bin/rspec

# Run type checker
cd herb-config && ./bin/steep check

# Run linter
cd herb-config && ./bin/rubocop
```

Each gem's binstubs use that gem's Gemfile, ensuring proper dependency resolution.

## Coding Conventions

### Ruby Style

- Follow [Ruby Style Guide](https://rubystyle.guide/)
- Use RuboCop for style enforcement
- Target Ruby 3.3+ features where appropriate
- Sort lists of definitions in ASCII order unless there is a specific reason not to (e.g., `require` statements, `gem` declarations in Gemfile, constant definitions)
- Always pass `track_whitespace: true` when calling `Herb.parse`. This applies to production code, test code, and any ad-hoc scripts. Example: `Herb.parse(source, track_whitespace: true)`

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `RuleRegistry` |
| Methods | snake_case | `run_checks` |
| Constants | SCREAMING_SNAKE_CASE | `DEFAULT_CONFIG` |
| Files | snake_case | `rule_registry.rb` |

### Module Structure

```ruby
# lib/herb/lint/rules/html/alt_text.rb
module Herb
  module Lint
    module Rules
      module Html
        class AltText < Base
          # Implementation
        end
      end
    end
  end
end
```

### Error Handling

- Use custom exception classes derived from `StandardError`
- Provide meaningful error messages
- Handle file I/O errors gracefully

## Writing Lint Rules

### Rule Structure

All lint rules inherit from `VisitorRule` and override `visit_*` methods to inspect AST nodes. Each rule must define three class methods: `rule_name`, `description`, and `default_severity`. Always call `super` at the end of visit methods to continue traversal.

```ruby
# lib/herb/lint/rules/html/my_rule.rb
module Herb
  module Lint
    module Rules
      module Html
        class MyRule < VisitorRule
          def self.rule_name = "html/my-rule"
          def self.description = "Description of the rule"
          def self.default_severity = "warning"

          # @rbs override
          def visit_html_element_node(node)
            if some_condition?(node)
              add_offense(message: "Explanation", location: node.location)
            end
            super
          end
        end
      end
    end
  end
end
```

### NodeHelpers

`VisitorRule` includes the `NodeHelpers` module (`lib/herb/lint/rules/node_helpers.rb`), which provides common methods for working with HTML AST nodes. Use these helpers instead of accessing AST internals directly.

| Method | Description |
|--------|-------------|
| `attributes(node)` | Return all attribute nodes for an element node. Returns `Array[HTMLAttributeNode]` |
| `find_attribute(node, "name")` | Find an attribute by name (case-insensitive) on an element node. Returns `HTMLAttributeNode?` |
| `attribute?(node, "name")` | Check if an element has an attribute (case-insensitive). Returns `bool` |
| `attribute_name(attr_node)` | Extract the raw name string from an attribute node. Returns `String?` |
| `attribute_value(attr_node)` | Extract the text value from an attribute node. Returns `String?` |

`attribute_name` and `attribute_value` are nil-safe — they accept `nil` and return `nil`, enabling composition:

```ruby
attribute_value(find_attribute(node, "role"))
```

### Registering a New Rule

When adding a new rule:

1. Create the rule file under `lib/herb/lint/rules/{category}/`
2. Add `require_relative` to `lib/herb/lint.rb` (in ASCII order)
3. Add the class to `RuleRegistry.builtin_rules` in `lib/herb/lint/rule_registry.rb` (in ASCII order)

## Testing Policy

### Framework

- Use RSpec for all tests
- herb-lint uses factory_bot for test data construction. Factories are defined in `herb-lint/spec/factories/`:
  - `:context` — `Herb::Lint::Context`
  - `:lint_result` — `Herb::Lint::LintResult`
  - `:location` — `Herb::Location`
  - `:offense` — `Herb::Lint::Offense`

### Test Organization

Each gem has its own spec directory:

```
herb-lint/spec/
├── spec_helper.rb
├── herb/
│   └── lint/
│       ├── cli_spec.rb
│       ├── runner_spec.rb
│       ├── config_spec.rb
│       └── rules/
│           ├── erb/
│           └── html/
└── fixtures/
    └── templates/

herb-format/spec/
├── spec_helper.rb
├── herb/
│   └── format/
│       ├── cli_spec.rb
│       ├── formatter_spec.rb
│       ├── config_spec.rb
│       └── rewriters/
└── fixtures/
    └── templates/
```

### Test Types

1. **Unit Tests**: Test individual classes and methods in isolation
2. **Integration Tests**: Test CLI commands and full workflows
3. **Fixture Tests**: Test against real-world ERB template samples

### Writing Tests

- Define the test subject using `subject` (without a name)
- Use `context` blocks when preconditions or execution conditions differ
- Consolidate multiple expectations into a single `it` block within the same context

```ruby
RSpec.describe Herb::Lint::Rules::Html::AltText do
  describe "#check" do
    subject { described_class.new.check(parse(template)) }

    context "when img tag has alt attribute" do
      let(:template) { '<img src="image.png" alt="Description">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when img tag is missing alt attribute" do
      let(:template) { '<img src="image.png">' }

      it "reports an offense with correct rule name" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule).to eq("alt-text")
      end
    end
  end
end
```

### Running Tests

```bash
# Run all tests for a gem (from gem directory)
cd herb-config && ./bin/rspec

# Run specific test file
cd herb-config && ./bin/rspec spec/herb/config_spec.rb
```

## Writing Type Annotations

This project uses [rbs-inline](https://github.com/soutaro/rbs-inline) style annotations. Types are written as comments in Ruby source files:

- **Argument types**: Use `@rbs argname: Type` comments before the method. Add `-- description` for documentation (e.g., `@rbs column: Integer -- 0-based column number`)
- **Return types**: Use `#: Type` comment at the end of the `def` line
- **Attributes**: Use `#: Type` comment at the end of `attr_accessor`/`attr_reader` (also defines instance variable type)
- **Instance variables**: Use `@rbs @name: Type` comment (must have blank line before method definition)
- **Data classes**: Use `#: Type` comment at the end of each member in `Data.define`

```ruby
# @rbs name: String -- the user's name
# @rbs age: Integer -- the user's age in years
def greet(name, age) #: String
  "Hello, #{name}! You are #{age} years old."
end

attr_reader :name #: String

# @rbs @count: Integer

def initialize
  @count = 0
end

# Data class with typed members
Result = Data.define(
  :parse_result, #: ParseResult
  :code, #: String
  :tags #: Hash[Integer, Tag]
)
```

## Generating RBS Files

Type definition files (`.rbs`) are generated automatically by the PostToolUse hook when `.rb` files in `lib/` are modified. **Never edit `.rbs` files directly** - always modify the inline annotations in Ruby source files.

## Dependencies

### Runtime Dependencies

- `herb` gem: ERB parser providing AST for analysis

### Development Dependencies

- `rake`: Task runner for running all checks
- `rspec`: Testing framework
- `rubocop`: Style enforcement
- `rbs-inline`: Type annotation support
- `steep`: Static type checker
