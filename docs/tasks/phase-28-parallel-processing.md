# Phase 28: herb-lint 並列ファイル処理（--jobs オプション）

herb-lint TypeScript v0.9.0 で `worker_threads` ベースの並列ファイル処理が導入された。
Ruby 版でも同等の並列処理と `--jobs` CLI オプションを実装する。

**Status**: Not Started
**Priority**: Low（機能パリティとして重要だがパフォーマンス最適化のため後回し可）
**Dependencies**: Phase 26 complete

## Overview

TypeScript v0.9.0 の変更:
- `--jobs <n>` / `-j <n>` オプションを追加（`auto` でシステムの CPU コア数を自動設定）
- ファイル数が 10 以上かつ `--jobs` > 1 の場合に `worker_threads` による並列処理を実行
- ファイルリストを `jobs` 数に分割し、各 Worker が独立して `Herb.load` → `Config.load` → `Linter.from` を初期化して処理
- ベンチマーク: 421 ファイルで 2958ms → 1264ms（約 2.3 倍）、1384 ファイルで 7292ms → 2427ms（約 3 倍）

Ruby での実装方針:
- `Thread` + `Queue` または `Ractor` を使用する（`worker_threads` の Ruby 相当）
- ファイル数の閾値（TypeScript は 10）を設定して少数ファイルはシーケンシャル処理
- スレッドセーフな結果集約ロジックを実装

## Implementation Checklist

### Task 28.1: `--jobs` / `-j` CLI オプションの追加

- [ ] `herb-lint/lib/herb/lint/cli.rb` に `--jobs <n>` オプションを追加
  ```
  -j, --jobs [n]    Run linter in parallel with n jobs (default: auto = CPU core count)
  ```
- [ ] `auto` を指定した場合（またはオプション省略時）は `Etc.nprocessors` でコア数を取得
- [ ] `--jobs 1` でシーケンシャル処理になることを確認
- [ ] CLI ヘルプテキストを更新
- [ ] CLI のスペックにオプション解析のテストを追加

### Task 28.2: 並列ファイル処理の実装

- [ ] `herb-lint/lib/herb/lint/parallel_runner.rb`（または `Runner` の並列処理メソッド）を作成
- [ ] ファイルリストを `jobs` 数に分割するロジックを実装（`Array#each_slice` 等）
- [ ] 各スレッドが独立して `Linter` を初期化して処理するよう実装
  - スレッドセーフのため、各スレッド内で `Herb.parse`・`Config.load`・`Linter.new` を呼ぶ
- [ ] スレッド間の結果集約ロジックを実装（`Mutex` を使用して `AggregatedResult` に集約）
- [ ] `PARALLEL_FILE_THRESHOLD = 10`（または TypeScript と同じ閾値）を設定し、少数ファイルはシーケンシャル処理にフォールバック
- [ ] `Runner#run` からジョブ数に応じてシーケンシャル・並列を切り替えるロジックを追加
- [ ] `Ractor` が利用可能な環境では `Ractor` の使用も検討（ただし gem の互換性制約を確認）

### Task 28.3: テストと検証

- [ ] 複数ファイルを並列処理した場合の結果が正しいことを確認するスペックを追加
- [ ] `--jobs 1` と `--jobs 4` で同じ結果が得られることを確認
- [ ] スレッドセーフ性のテスト（同じ violation が重複しないこと等）
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認
- [ ] パフォーマンスの確認（大量ファイルで高速化されることを手動で確認）
