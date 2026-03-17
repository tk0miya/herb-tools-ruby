# herb-tools-ruby Implementation Tasks

This directory contains implementation tasks for herb-tools-ruby.

## herb-lint Implementation Phases

### Active Phases

| Phase | File | Tasks | Description | Status |
|-------|------|-------|-------------|--------|
| Phase 25 | [phase-25-linter-missing-features.md](./phase-25-linter-missing-features.md) | 8 | herb-lint missing features implementation | 📋 |
| Phase 26 | [phase-26-herb-09-compatibility.md](./phase-26-herb-09-compatibility.md) | 6 | herb gem 0.9.0 compatibility (breaking changes, AST changes) | 📋 |
| Phase 27 | [phase-27-new-linter-rules.md](./phase-27-new-linter-rules.md) | 23 | New herb-lint rules (v0.9.0 additions) | 📋 |
| Phase 28 | [phase-28-parallel-processing.md](./phase-28-parallel-processing.md) | 3 | herb-lint parallel file processing (--jobs option) | 📋 |

Legend: ✅ Complete | 🚧 In Progress | 📋 Planned

### Phase Overview (herb-lint)

#### Phase 25: herb-lint Missing Features

Features that exist in the TypeScript reference implementation but are missing in Ruby:

- `DetailedFormatter` (default output format with syntax highlighting and code snippets)
- Additional missing features from TypeScript analysis

#### Phase 26: herb gem 0.9.0 Compatibility (Priority: High)

Address breaking changes in herb gem v0.9.0:

- `HTMLElementNode#source` → `#element_source` field rename
- Adapt to `strict: true` becoming the default
- Add Visitor support for 7 new AST node types
- Change 14 accessibility rule severities from `"error"` to `"warning"`
- Expand `html-anchor-require-href` (Action View helper support, new offense patterns)
- Per-rule `parser_options` API (rules declare required parser options; Linter merges them)

#### Phase 27: New Linter Rules (Priority: Medium)

Port 23 new rules added in TypeScript v0.9.0 to the Ruby implementation:

- ERB rules: conditional HTML elements, attribute/output, security, partials/helpers (17 rules)
- HTML rules: script type, details/summary, ARIA, closing tags (5 rules)
- Turbo rules: turbo-permanent-require-id (1 rule)

#### Phase 28: Parallel Processing (Priority: Low)

Implement the worker-based parallel file processing introduced in TypeScript v0.9.0:

- `--jobs` / `-j` CLI option
- Parallel file processing using `Thread` + `Queue`

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
- Caching for repeated lints/formats

## Related Documentation

- [Requirements](../requirements/) - Requirements specifications
- [Design](../design/) - Architecture design
