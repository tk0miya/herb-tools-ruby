# herb-tools-ruby Implementation Tasks

This directory contains implementation tasks for herb-tools-ruby.

## MVP Status: ✅ Complete

The MVP (Minimum Viable Product) has been completed with:

- ✅ Basic `.herb.yml` loading (linter.rules section only)
- ✅ Simple file discovery (`**/*.html.erb` patterns only)
- ✅ Initial rule implementations (html-img-require-alt, html-attribute-double-quotes, html-no-duplicate-ids)
- ✅ Basic CLI (`herb-lint <path>`, `--version`, `--help`)
- ✅ SimpleReporter (text output only)
- ✅ Inline directives (`herb:disable`, `herb:linter ignore`)

Phases 1-14, 19, and 20 have been completed and their task files have been removed from this directory. The completed work is documented in the git history and reflected in the current implementation.

## Remaining Implementation Phases

| Phase | File | Tasks | Description | Status |
|-------|------|-------|-------------|--------|
| Phase 15 | [phase-15-autofix.md](./phase-15-autofix.md) | 9 | Autofix (`--fix` / `--fix-unsafely`) | 🚧 |
| Phase 16 | [phase-16-rule-autofix-expansion.md](./phase-16-rule-autofix-expansion.md) | 15 | Rule autofix expansion | 🚧 |
| Phase 17 | [phase-17-advanced-config.md](./phase-17-advanced-config.md) | 6 | Advanced configuration features | 📋 |
| Phase 18 | [phase-18-source-rule.md](./phase-18-source-rule.md) | 7 | SourceRule base class, autofix, NoExtraNewline migration | 📋 |
| Phase 21 | [phase-21-review-linter-rules.md](./phase-21-review-linter-rules.md) | 408 | Review and update all linter rules | 🚧 |
| Phase 23 | [phase-23-json-reporter-completion.md](./phase-23-json-reporter-completion.md) | 6 | Complete JSON reporter summary fields | 📋 |
| Phase 24 | [phase-24-typescript-alignment.md](./phase-24-typescript-alignment.md) | 24 | TypeScript implementation alignment | 📋 |

**Remaining Total: ~475 tasks**

Legend: ✅ Complete | 🚧 In Progress | 📋 Planned

## Phase Overview

### Phase 15: Autofix (9 tasks)

| Part | Tasks | Description |
|------|-------|-------------|
| Part A | 3 | AutofixContext, RuleMethods extensions, NodeLocator |
| Part B | 3 | AutoFixResult, Autofixer, Runner/CLI integration |
| Part C | 3 | Autofix reporting |

### Phase 16: Rule Autofix Expansion (15 tasks)

| Part | Tasks | Description |
|------|-------|-------------|
| Part A | 1 | Complete autofix infrastructure |
| Part B | 6 | ERB rules autofix |
| Part C | 7 | HTML rules autofix |
| Part E | 1 | SVG rules autofix |

### Phase 17: Advanced Configuration (6 tasks)

| Part | Tasks | Description |
|------|-------|-------------|
| Part A | 1 | failLevel exit code control |
| Part B | 1 | Top-level files section |
| Part C | 2 | Per-rule configuration |
| Part D | 2 | Formatter configuration (deferred) |

### Phase 18: Source Rule Introduction (7 tasks)

| Part | Tasks | Description |
|------|-------|-------------|
| Part A | 3 | AutofixContext extension, SourceRule base class, Autofixer source phase |
| Part B | 2 | NoExtraNewline and RequireTrailingNewline migration |
| Part C | 2 | Type annotations, full verification |

### Phase 21: Review Linter Rules (408 tasks)

| Category | Rules | Tasks per rule |
|----------|-------|----------------|
| ERB | 13 | 8 steps each |
| HERB | 5 | 8 steps each |
| HTML | 31 | 8 steps each |
| SVG | 1 | 8 steps each |
| Parser | 1 | 8 steps each |

### Phase 23: JSON Reporter Completion (6 tasks)

| Task | Description |
|------|-------------|
| 23.1 | Add info/hint severity level support |
| 23.2 | Track ignored offenses count |
| 23.3 | Report active rule count |
| 23.4 | Update RBS type signatures |
| 23.5 | Integration testing |
| 23.6 | Update documentation |

### Phase 24: TypeScript Alignment (24 tasks)

| Part | Tasks | Description |
|------|-------|-------------|
| Part A | 2 | Missing rules (herb-disable-comment-unnecessary, html-no-space-in-tag) |
| Part B | 2 | Autofix alignment (erb-no-extra-newline) |
| Part C | 17 | Severity alignment (16 rules + policy decision) |
| Part D | 3 | Documentation + enabled-by-default alignment (5 rules) |

**Key Discovery:** 5 rules are disabled by default in TypeScript:
- `erb-strict-locals-required`
- `html-navigation-has-label`
- `html-no-block-inside-inline`
- `html-no-space-in-tag`
- `html-no-title-attribute`

## How to Proceed

1. Open the current phase's task file
2. Implement tasks from top to bottom
3. Test according to each task's verification method
4. Check off completed tasks (`- [ ]` → `- [x]`)
5. Move to the next phase when all tasks are complete

## Completed Phases

The following phases have been completed and their task files removed:

- **Phases 1-9**: MVP implementation (basic linter, config, file discovery, inline directives)
- **Phase 8**: Rule expansion (6 rules)
- **Phase 10**: Reporters & validation
- **Phase 11**: HTML rule expansion (23 rules)
- **Phase 12**: ERB rule expansion (12 rules)
- **Phase 13**: SVG & parser rules (2 rules)
- **Phase 14**: herb-printer gem
- **Phase 19**: Rule naming alignment
- **Phase 20**: factory_bot introduction

All completed work is documented in the git history and reflected in the current implementation.

## Unscheduled Tasks (Low Priority)

The following features are not yet scheduled into phases. Consider adding them when needed:

### Custom Rule Loading
- CustomRuleLoader implementation
- Plugin mechanism for third-party rules
- Dynamic rule discovery from `.herb/rules/` directory

### RuleRegistry Dynamic Discovery
- Automatic rule discovery by directory scanning
- Dynamic loading using reflection
- Consider when rule count exceeds 10

### Code Architecture Improvements
- PatternMatcher class separation (currently integrated in FileDiscovery)
- LinterFactory implementation (currently Runner creates Linter directly)

### Performance
- Parallel file processing
- Caching for repeated lints

### herb-format Implementation
- Full formatter gem (see [herb-format requirements](../requirements/herb-format.md))
- Formatter engine, rewriters, CLI

See [phase-22-future-enhancements.md](./phase-22-future-enhancements.md) for detailed descriptions of each feature.

## Related Documentation

- [Requirements](../requirements/) - Requirements specifications
- [Design](../design/) - Architecture design
