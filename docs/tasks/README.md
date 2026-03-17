# herb-tools-ruby Implementation Tasks

This directory contains implementation tasks for herb-tools-ruby.

## herb-lint Implementation Phases

### Active Phases

| Phase | File | Tasks | Description | Status |
|-------|------|-------|-------------|--------|
| Phase 25 | [phase-25-linter-missing-features.md](./phase-25-linter-missing-features.md) | 8 | herb-lint missing features implementation | 📋 |
| Phase 26 | [phase-26-herb-09-compatibility.md](./phase-26-herb-09-compatibility.md) | 5 | herb gem 0.9.0 互換性対応（破壊的変更・AST 変更） | 📋 |
| Phase 27 | [phase-27-new-linter-rules.md](./phase-27-new-linter-rules.md) | 23 | herb-lint 新規ルール実装（v0.9.0 追加分） | 📋 |
| Phase 28 | [phase-28-parallel-processing.md](./phase-28-parallel-processing.md) | 3 | herb-lint 並列ファイル処理（--jobs オプション） | 📋 |

Legend: ✅ Complete | 🚧 In Progress | 📋 Planned

### Phase Overview (herb-lint)

#### Phase 25: herb-lint Missing Features

Features that exist in the TypeScript reference implementation but are missing in Ruby:

- `DetailedFormatter` (default output format with syntax highlighting and code snippets)
- Additional missing features from TypeScript analysis

#### Phase 26: herb gem 0.9.0 互換性対応（優先度: High）

herb gem v0.9.0 の破壊的変更への対応:

- `HTMLElementNode#source` → `#element_source` フィールドリネーム
- `strict: true` デフォルト化への対応
- 新 AST ノード 7 種への Visitor 対応
- アクセシビリティルール 14 個の severity 変更（error → warning）
- `html-anchor-require-href` ルールの拡張（Action View ヘルパー対応、新違反パターン）

#### Phase 27: 新規リンタールール（優先度: Medium）

TypeScript v0.9.0 で追加された 23 の新ルールを Ruby 版に移植:

- ERB ルール: 条件付き HTML 要素、属性・出力関連、安全性、パーシャル・ヘルパー関連（17 ルール）
- HTML ルール: script type、details/summary、ARIA、closing tags（5 ルール）
- Turbo ルール: turbo-permanent-require-id（1 ルール）

#### Phase 28: 並列処理（優先度: Low）

TypeScript v0.9.0 で導入された Worker ベースの並列ファイル処理を Ruby で実装:

- `--jobs` / `-j` CLI オプション
- `Thread` + `Queue` による並列ファイル処理

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
