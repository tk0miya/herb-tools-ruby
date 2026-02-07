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
(cd herb-config && ./bin/rake)

# Run tests only
(cd herb-config && ./bin/rspec)

# Run type checker
(cd herb-config && ./bin/steep check)

# Run linter
(cd herb-config && ./bin/rubocop)
```

Each gem's binstubs use that gem's Gemfile, ensuring proper dependency resolution.

# Documents for coding agents

* [Coding Conventions](docs/CODING_CONVENTIONS.md) - Ruby style, testing, type annotations

## Dependencies

### Runtime Dependencies

- `herb` gem: ERB parser providing AST for analysis

### Development Dependencies

- `rake`: Task runner for running all checks
- `rspec`: Testing framework
- `rubocop`: Style enforcement
- `rbs-inline`: Type annotation support
- `steep`: Static type checker
