# herb-tools-ruby MVP Implementation Tasks

This directory contains implementation tasks for the herb-tools-ruby MVP (Minimum Viable Product).

## MVP Scope

### Included (Must have)

✅ Basic `.herb.yml` loading (linter.rules section only)
✅ Simple file discovery (`**/*.html.erb` patterns only)
✅ 2-3 representative rule implementations
✅ Basic CLI (`herb-lint <path>`, `--version`, `--help` only)
✅ SimpleReporter (text output only)

### Excluded (Won't have in MVP)

❌ Custom rule loading
❌ Inline directives (`# herb:disable`)
❌ Multiple reporters (JSON, GitHub Actions, etc.)
❌ `--fix` option (auto-fix)
❌ Advanced configuration validation
❌ Environment variable support
❌ Complex glob exclusion rules
❌ Parallel processing

## Phase Structure

The implementation is divided into 7 phases:

| Phase | File | Tasks | Description |
|-------|------|-------|-------------|
| Phase 1 | [phase-1-herb-config.md](./phase-1-herb-config.md) | 5 | herb-config gem & CI setup |
| Phase 2 | [phase-2-herb-core.md](./phase-2-herb-core.md) | 3 | herb-core gem & CI setup |
| Phase 3 | [phase-3-herb-lint-foundation.md](./phase-3-herb-lint-foundation.md) | 4 | herb-lint gem foundation & CI setup |
| Phase 4 | [phase-4-rules.md](./phase-4-rules.md) | 2 | Lint rule implementation |
| Phase 5 | [phase-5-linter-runner.md](./phase-5-linter-runner.md) | 4 | Linter & Runner implementation |
| Phase 6 | [phase-6-reporter-cli.md](./phase-6-reporter-cli.md) | 2 | Reporter & CLI implementation |
| Phase 7 | [phase-7-integration.md](./phase-7-integration.md) | 3 | Integration testing & documentation |

**Total: 23 tasks**

## Dependencies

```
Phase 1: herb-config gem
  └─> Phase 2: herb-core gem
        └─> Phase 3: herb-lint gem foundation
              └─> Phase 4: Rule implementation
                    └─> Phase 5: Linter & Runner
                          └─> Phase 6: Reporter & CLI
                                └─> Phase 7: Integration tests
```

**Important:** Each phase must be completed before starting the next phase.

## How to Proceed

1. **Start with Phase 1**
2. Open each phase's task file
3. Implement tasks from top to bottom
4. Test according to each task's verification method
5. Check off completed tasks (`- [ ]` → `- [x]`)
6. Move to the next phase when all tasks in the current phase are complete

## MVP Completion Criteria

The MVP is complete when all of the following conditions are met:

1. ✅ CI passes (rspec tests and type checking)
2. ✅ All 3 gems (herb-config, herb-core, herb-lint) can be built
3. ✅ All unit tests pass
4. ✅ Integration tests pass
5. ✅ `herb-lint` command can lint actual ERB files
6. ✅ 2 or more rules are working
7. ✅ Configuration file (.herb.yml) can be loaded
8. ✅ README.md is complete

## Important Notes

- **No root Gemfile needed**: Develop each gem independently, using local path references in each gem's Gemfile as needed
- **Comparison with full spec**: This MVP scope is **72% reduced** compared to the full specification (72 tasks)

## Related Documentation

- [Requirements](../requirements/) - Requirements specifications
- [Design](../design/) - Architecture design
