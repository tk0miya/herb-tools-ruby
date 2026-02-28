# herb-tools-ruby Implementation Tasks

This directory contains implementation tasks for herb-tools-ruby.

## herb-lint Implementation Phases

### Active Phases

| Phase | File | Tasks | Description | Status |
|-------|------|-------|-------------|--------|
| Phase 25 | [phase-25-linter-missing-features.md](./phase-25-linter-missing-features.md) | TBD | herb-lint missing features implementation | 📋 |

Legend: ✅ Complete | 🚧 In Progress | 📋 Planned

### Phase Overview (herb-lint)

#### Phase 25: herb-lint Missing Features

Features that exist in the TypeScript reference implementation but are missing in Ruby:

- `DetailedFormatter` (default output format with syntax highlighting and code snippets)
- Additional missing features from TypeScript analysis

## herb-format Implementation Phases

| Phase | File | Tasks | Description | Status |
|-------|------|-------|-------------|--------|
| Phase 6 | [phase-6-formatter-cli.md](./phase-6-formatter-cli.md) | 9 | CLI (options, --init, --stdin, --check, reporting) | 📋 |

**Total: ~9 tasks**

Legend: ✅ Complete | 🚧 In Progress | 📋 Planned

### Phase Overview (herb-format)

#### Phase 6: CLI (9 tasks)

| Part | Tasks | Description |
|------|-------|-------------|
| Part A | 1 | Basic CLI structure |
| Part B | 2 | --version, --help, --init handlers |
| Part C | 1 | --stdin handler |
| Part D | 1 | Check mode and reporting |
| Part E | 4 | Executable and integration tests |

## How to Proceed

1. Open the current phase's task file
2. Implement tasks from top to bottom
3. Test according to each task's verification method
4. Check off completed tasks (`- [ ]` → `- [x]`)
5. Move to the next phase when all tasks are complete

## Unscheduled Tasks (Low Priority)

The following features are not yet scheduled into phases. Consider adding them when needed:

### Code Architecture Improvements
- PatternMatcher class separation (currently integrated in FileDiscovery)
- LinterFactory implementation (currently Runner creates Linter directly)

### Performance
- Parallel file processing
- Caching for repeated lints/formats

## Related Documentation

- [Requirements](../requirements/) - Requirements specifications
- [Design](../design/) - Architecture design
