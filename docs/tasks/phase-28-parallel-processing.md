# Phase 28: herb-lint Parallel File Processing (--jobs option)

herb-lint TypeScript v0.9.0 introduced `worker_threads`-based parallel file
processing. Implement equivalent parallel processing and a `--jobs` CLI option
in the Ruby implementation.

**Status**: Not Started
**Priority**: Low (important for feature parity but a performance optimization
  that can be deferred)
**Dependencies**: Phase 26 complete

## Overview

TypeScript v0.9.0 changes:
- Added `--jobs <n>` / `-j <n>` option (`auto` uses the system CPU core count)
- Enables parallel processing when file count >= 10 and `--jobs` > 1
- Splits the file list into chunks and each Worker independently initializes
  `Herb.load` → `Config.load` → `Linter.from` before processing its chunk
- Benchmarks: 421 files 2958ms → 1264ms (~2.3x), 1384 files 7292ms → 2427ms (~3x)

Ruby implementation approach:
- Use `Thread` + `Queue` (Ruby equivalent of `worker_threads`)
- Set a file count threshold (TypeScript uses 10) below which processing is sequential
- Implement thread-safe result aggregation

## Implementation Checklist

### Task 28.1: Add `--jobs` / `-j` CLI Option

- [ ] Add `--jobs <n>` option to `herb-lint/lib/herb/lint/cli.rb`:
  ```
  -j, --jobs [n]    Run linter in parallel with n jobs (default: auto = CPU core count)
  ```
- [ ] When `auto` is specified (or the option is omitted), use `Etc.nprocessors`
  to determine the core count
- [ ] Verify that `--jobs 1` falls back to sequential processing
- [ ] Update CLI help text
- [ ] Add option-parsing tests to the CLI spec

### Task 28.2: Implement Parallel File Processing

- [ ] Create `herb-lint/lib/herb/lint/parallel_runner.rb` (or add parallel
  processing methods to the existing `Runner`)
- [ ] Implement logic to split the file list into chunks (`Array#each_slice`, etc.)
- [ ] Implement per-thread independent `Linter` initialization
  (each thread calls `Herb.parse`, `Config.load`, and `Linter.new` independently
  to ensure thread safety)
- [ ] Implement thread-safe result aggregation using `Mutex` into `AggregatedResult`
- [ ] Define `PARALLEL_FILE_THRESHOLD = 10` (same threshold as TypeScript) and
  fall back to sequential processing for fewer files
- [ ] Add logic to `Runner#run` to choose between sequential and parallel
  processing based on the job count
- [ ] Evaluate `Ractor` for environments where it is available (check gem
  compatibility constraints first)

### Task 28.3: Tests and Verification

- [ ] Add specs to verify that results are correct when files are processed in parallel
- [ ] Verify that `--jobs 1` and `--jobs 4` produce identical results
- [ ] Add thread-safety tests (e.g. verify that no violations are duplicated)
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes
- [ ] Manually verify speedup with a large number of files
