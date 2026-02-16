# Documentation

This directory contains documentation for the herb-tools-ruby project.

## Directory Structure

### `/requirements`
User-facing specifications describing what each tool does:

- **[overview.md](requirements/overview.md)** - Project overview and architecture
- **[herb-lint.md](requirements/herb-lint.md)** - Linter specification
- **[herb-format.md](requirements/herb-format.md)** - Formatter specification
- **[config.md](requirements/config.md)** - Configuration file format (.herb.yml)

### `/design`
Implementation design documents for developers:

- **[architecture.md](design/architecture.md)** - Overall architecture
- **[herb-config-design.md](design/herb-config-design.md)** - Configuration gem design
- **[herb-core-design.md](design/herb-core-design.md)** - Core gem design
- **[printer-design.md](design/printer-design.md)** - Printer gem design
- **[herb-lint-design.md](design/herb-lint-design.md)** - Linter gem design
- **[herb-lint-rules.md](design/herb-lint-rules.md)** - Linter rules catalog
- **[herb-lint-autofix-design.md](design/herb-lint-autofix-design.md)** - Autofix implementation
- **[herb-format-design.md](design/herb-format-design.md)** - Formatter gem design
- **[formatting-rules.md](design/formatting-rules.md)** - Detailed formatting rules specification

### `/tasks`
Implementation task lists and milestones for each development phase.

See [tasks/README.md](tasks/README.md) for details on all phases and current progress.

## Additional Resources

### TypeScript Reference Implementation

The herb-tools-ruby project is based on the TypeScript implementation:

- **Repository**: https://github.com/marcoroth/herb
- **Key files**:
  - `javascript/packages/formatter/src/FormatPrinter.ts` - Main formatter logic
  - `javascript/packages/formatter/src/format-helpers.ts` - Helper functions
  - `javascript/packages/linter/src/rules/` - Linter rules

When implementing features, refer to the TypeScript codebase for detailed behavior and edge cases.

### Coding Conventions

See [CODING_CONVENTIONS.md](CODING_CONVENTIONS.md) for Ruby style guidelines, testing practices, and type annotation standards.

## Document Lifecycle

1. **Requirements** (stable) - Define what tools do
2. **Design** (evolving) - Plan how to implement
3. **Tasks** (active) - Track implementation progress
4. **Code** (implementation) - Final working code

Task lists are the primary reference during implementation. Once a feature is implemented, the code becomes the source of truth, and task documents serve as historical records.
