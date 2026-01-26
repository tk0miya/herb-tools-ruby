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
├── bin/                         # Binstubs for development tools
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
├── herb-lint/                   # Linter gem
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

This project provides binstubs in `bin/` for common development tools. Use these instead of `bundle exec`:

```bash
# Run all checks (spec, rubocop, steep) for a gem
(cd herb-config && ../bin/rake)

# Run tests only
bin/rspec herb-config/spec

# Run type checker (from gem directory)
(cd herb-config && ../bin/steep check)

# Run linter
bin/rubocop herb-config

# Generate RBS files from inline annotations
bin/rbs-inline --output lib
```

Note: The `bin/rake` binstub automatically detects and uses the Gemfile in the current directory, making it suitable for running gem-specific rake tasks.

## Coding Conventions

### Ruby Style

- Follow [Ruby Style Guide](https://rubystyle.guide/)
- Use RuboCop for style enforcement
- Target Ruby 3.3+ features where appropriate

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

## Testing Policy

### Framework

- Use RSpec for all tests

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

- Use `context` blocks when preconditions or execution conditions differ
- Consolidate multiple expectations into a single `it` block within the same context

```ruby
RSpec.describe Herb::Lint::Rules::Html::AltText do
  subject(:rule) { described_class.new }

  describe "#check" do
    context "when img tag has alt attribute" do
      it "does not report an offense" do
        template = '<img src="image.png" alt="Description">'
        offenses = rule.check(parse(template))
        expect(offenses).to be_empty
      end
    end

    context "when img tag is missing alt attribute" do
      it "reports an offense with correct rule name" do
        template = '<img src="image.png">'
        offenses = rule.check(parse(template))
        expect(offenses.size).to eq(1)
        expect(offenses.first.rule).to eq("alt-text")
      end
    end
  end
end
```

### Running Tests

```bash
# Run all tests for a gem (from project root)
bin/rspec herb-config/spec

# Run specific test file
bin/rspec herb-config/spec/herb/config_spec.rb
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
