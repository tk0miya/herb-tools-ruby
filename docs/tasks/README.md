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

Phases 1-9 have been completed and their task files have been removed from this directory. The completed work is documented in the git history and reflected in the current implementation.

## Remaining Implementation Phases

| Phase | File | Tasks | Description | Status |
|-------|------|-------|-------------|--------|
| Phase 8 | [phase-8-rule-expansion.md](./phase-8-rule-expansion.md) | 6 | herb-lint rule expansion | 🚧 |
| Phase 10 | [phase-10-reporters-validation.md](./phase-10-reporters-validation.md) | 6 | Multiple reporters & Config validation | 📋 |
| Phase 11 | [phase-11-html-rule-expansion.md](./phase-11-html-rule-expansion.md) | 23 | Remaining HTML rules | 📋 |
| Phase 12 | [phase-12-erb-rule-expansion.md](./phase-12-erb-rule-expansion.md) | 12 | Remaining ERB rules | 📋 |
| Phase 13 | [phase-13-svg-parser-rules.md](./phase-13-svg-parser-rules.md) | 2 | SVG & Parser rules | 📋 |
| Phase 14 | [phase-14-herb-printer.md](./phase-14-herb-printer.md) | 12 | herb-printer gem (AST-to-source) | 🚧 |
| Phase 15 | [phase-15-autofix.md](./phase-15-autofix.md) | 8 | Autofix (`--fix` / `--fix-unsafely`) | 📋 |
| Phase 16 | [phase-16-rule-autofix-expansion.md](./phase-16-rule-autofix-expansion.md) | TBD | Rule autofix expansion | 📋 |
| Source Rule | [source-rule.md](./source-rule.md) | 6 | SourceRule base class, autofix, NoExtraNewline migration | 📋 |

**Remaining Total: ~69 tasks**

Legend: ✅ Complete | 🚧 In Progress | 📋 Planned

## Phase Overview

### Phase 8: Rule Expansion (6 rules)

| Batch | Rules | Focus |
|-------|-------|-------|
| Batch 1 | 3 | Simple HTML rules |
| Batch 2 | 2 | Void elements & A11y |
| Batch 3 | 1 | ERB rules |

### Phase 10: Reporters & Validation (6 tasks)

| Part | Tasks | Description |
|------|-------|-------------|
| Part A | 3 | JsonReporter, GithubReporter, CLI options |
| Part B | 3 | Validator, Loader integration, search path extension |

### Phase 11: HTML Rule Expansion (23 rules)

| Batch | Rules | Focus |
|-------|-------|-------|
| Batch 1 | 5 | Attribute rules |
| Batch 2 | 5 | Element structure rules |
| Batch 3 | 6 | ARIA accessibility rules |
| Batch 4 | 4 | Other accessibility rules |
| Batch 5 | 3 | Document structure rules |

### Phase 12: ERB Rule Expansion (12 rules)

| Batch | Rules | Focus |
|-------|-------|-------|
| Batch 1 | 4 | Tag spacing & whitespace rules |
| Batch 2 | 4 | Control flow & output rules |
| Batch 3 | 4 | Convention & strict locals rules |

### Phase 13: SVG & Parser Rules (2 rules)

| Task | Rule | Category |
|------|------|----------|
| 13.1 | `svg-tag-name-capitalization` | SVG |
| 13.2 | `parser-no-errors` | Parser |

### Phase 14: herb-printer (12 tasks)

| Part | Tasks | Description |
|------|-------|-------------|
| Part A | 3 | Gem skeleton, CI setup, PrintContext |
| Part B | 2 | Base Printer, HTML Leaf Nodes |
| Part C | 3 | HTML Structure, Attributes, Comment/Doctype |
| Part D | 4 | ERB Leaf Nodes, Control Flow, Begin/Rescue |

### Phase 15: Autofix (8 tasks)

| Part | Tasks | Description |
|------|-------|-------------|
| Part A | 3 | AutofixContext, RuleMethods extensions, NodeLocator |
| Part B | 3 | AutoFixResult, AutoFixer, Runner/CLI integration |
| Part C | 2 | Autofix utility helpers, rule autofix methods |

### Phase 16: Rule Autofix Expansion

Expand autofix capabilities to additional rules. Details in [phase-16-rule-autofix-expansion.md](./phase-16-rule-autofix-expansion.md).

### Source Rule Introduction (6 tasks)

| Part | Tasks | Description |
|------|-------|-------------|
| Part A | 3 | AutofixContext extension, SourceRule base class, AutoFixer source phase |
| Part B | 1 | NoExtraNewline migration to SourceRule with autofix |
| Part C | 2 | Type annotations, full verification |

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
