# herb-tools-ruby Implementation Tasks

This directory contains implementation tasks for herb-tools-ruby.

## MVP Status: ✅ Complete

The MVP (Minimum Viable Product) has been completed with:

- ✅ Basic `.herb.yml` loading (linter.rules section only)
- ✅ Simple file discovery (`**/*.html.erb` patterns only)
- ✅ 3 rule implementations (html-img-require-alt, html-attribute-double-quotes, html-no-duplicate-ids)
- ✅ Basic CLI (`herb-lint <path>`, `--version`, `--help`)
- ✅ SimpleReporter (text output only)

## Phase Structure

### MVP Phases (Complete)

| Phase | File | Tasks | Description | Status |
|-------|------|-------|-------------|--------|
| Phase 1 | [phase-1-herb-config.md](./phase-1-herb-config.md) | 5 | herb-config gem & CI setup | ✅ |
| Phase 2 | [phase-2-herb-core.md](./phase-2-herb-core.md) | 3 | herb-core gem & CI setup | ✅ |
| Phase 3 | [phase-3-herb-lint-foundation.md](./phase-3-herb-lint-foundation.md) | 4 | herb-lint gem foundation & CI setup | ✅ |
| Phase 4 | [phase-4-rules.md](./phase-4-rules.md) | 2 | Lint rule implementation | ✅ |
| Phase 5 | [phase-5-linter-runner.md](./phase-5-linter-runner.md) | 4 | Linter & Runner implementation | ✅ |
| Phase 6 | [phase-6-reporter-cli.md](./phase-6-reporter-cli.md) | 2 | Reporter & CLI implementation | ✅ |
| Phase 7 | [phase-7-integration.md](./phase-7-integration.md) | 3 | Integration testing & documentation | ✅ |

**MVP Total: 23 tasks** ✅

### Post-MVP Phases

| Phase | File | Tasks | Description | Status |
|-------|------|-------|-------------|--------|
| Phase 8 | [phase-8-rule-expansion.md](./phase-8-rule-expansion.md) | 6 | herb-lint rule expansion | 🚧 |
| Phase 9 | [phase-9-inline-directives-autofix.md](./phase-9-inline-directives-autofix.md) | 11 | Inline directives & Auto-fix | 📋 |
| Phase 10 | [phase-10-reporters-validation.md](./phase-10-reporters-validation.md) | 6 | Multiple reporters & Config validation | 📋 |

**Post-MVP Total: 23 tasks**

Legend: ✅ Complete | 🚧 In Progress | 📋 Planned

## Phase Overview

### Phase 8: Rule Expansion (6 rules)

| Batch | Rules | Focus |
|-------|-------|-------|
| Batch 1 | 3 | Simple HTML rules |
| Batch 2 | 2 | Void elements & A11y |
| Batch 3 | 1 | ERB rules |

### Phase 9: Inline Directives & Auto-fix (11 tasks)

| Part | Tasks | Description |
|------|-------|-------------|
| Part A | 2 | DirectiveParser implementation, Linter integration |
| Part B | 6 | herb-disable-comment meta-rules (one task per rule) |
| Part C | 3 | Fixer class, CLI/Runner integration, fix methods |

### Phase 10: Reporters & Validation (6 tasks)

| Part | Tasks | Description |
|------|-------|-------------|
| Part A | 3 | JsonReporter, GithubReporter, CLI options |
| Part B | 3 | Validator, Loader integration, search path extension |

## How to Proceed

1. Open the current phase's task file
2. Implement tasks from top to bottom
3. Test according to each task's verification method
4. Check off completed tasks (`- [ ]` → `- [x]`)
5. Move to the next phase when all tasks are complete

## Prerequisite Tasks

The following tasks should be completed before continuing with new rule implementations:

### Rule Naming Alignment

- [rule-naming-alignment.md](./rule-naming-alignment.md) — Align rule directory structure and naming with TypeScript reference

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

See [future-enhancements.md](./future-enhancements.md) for detailed descriptions of each feature.

## Related Documentation

- [Requirements](../requirements/) - Requirements specifications
- [Design](../design/) - Architecture design
