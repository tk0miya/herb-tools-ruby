# Phase 5: Formatter Runner

This phase implements the Runner class that orchestrates formatting across multiple files.

**Design document:** [herb-format-design.md](../design/herb-format-design.md) (Runner section)

**Reference:** TypeScript `@herb-tools/formatter` Runner implementation

## Overview

| Feature | Description | Impact |
|---------|-------------|--------|
| Runner | Orchestrates formatting across multiple files | Core workflow coordination |
| File discovery | Find files matching include/exclude patterns | Uses herb-core FileDiscovery |
| Batch processing | Format multiple files efficiently | Production-ready tool |
| Result aggregation | Collect and report formatting results | User feedback |

## Prerequisites

- Phase 1 complete (Foundation)
- Phase 2 complete (FormatPrinter)
- Phase 3 Task 3.3 complete (FormatterFactory)
- Phase 4 Task 4.11 complete (Herb::Rewriter::Registry in herb-rewriter)
- herb-core gem available (FileDiscovery)

## Design Principles

1. **Reuse file discovery** - Leverage herb-core's FileDiscovery
2. **Factory pattern** - Use FormatterFactory for formatter creation
3. **Config-driven rewriter loading** - FormatterFactory auto-loads rewriters by requiring
   names listed in `config.rewriter_pre` and `config.rewriter_post`
4. **Error resilience** - Continue processing on individual file errors

## Design Note: CustomRewriterLoader removal

`CustomRewriterLoader` (which loaded Ruby files from `.herb/rewriters/*.rb`) has been
removed. Rewriters are now specified explicitly in `.herb.yml` as gem names or require
paths under `formatter.rewriter.pre` / `formatter.rewriter.post`. `FormatterFactory`
is responsible for resolving and loading those names before instantiating rewriters.

---

## Part A: Runner Implementation

### Task 5.1: Create Runner Class

**Location:** `herb-format/lib/herb/format/runner.rb`

- [ ] Create Runner class
- [ ] Add initialize with config, check, write, force parameters
- [ ] Create `Herb::Rewriter::Registry` instance and pass to FormatterFactory
- [ ] Create formatter via FormatterFactory
- [ ] Implement run(files) method
- [ ] Add RBS inline type annotations
- [ ] Create spec file

**Interface:**
```ruby
# rbs_inline: enabled

module Herb
  module Format
    # Orchestrates the formatting process across multiple files.
    #
    # @rbs config: Herb::Config::FormatterConfig
    # @rbs check: bool
    # @rbs write: bool
    # @rbs force: bool
    # @rbs rewriter_registry: Herb::Rewriter::Registry
    # @rbs formatter: Formatter
    class Runner
      attr_reader :config   #: Herb::Config::FormatterConfig
      attr_reader :check    #: bool
      attr_reader :write    #: bool
      attr_reader :force    #: bool

      # @rbs config: Herb::Config::FormatterConfig
      # @rbs check: bool
      # @rbs write: bool
      # @rbs force: bool
      # @rbs return: void
      def initialize(config:, check: false, write: true, force: false)
        @config = config
        @check = check
        @write = write
        @force = force
        @rewriter_registry = Herb::Rewriter::Registry.new
        @formatter = build_formatter
      end

      # Run formatting on files and return aggregated result.
      #
      # Processing flow:
      # 1. File Discovery: Use Herb::Core::FileDiscovery to find target files
      #    (or use provided files, filtered by exclude patterns)
      # 2. Formatter Creation: Build Formatter instance via FormatterFactory
      #    FormatterFactory auto-loads rewriters by requiring names from
      #    config.rewriter_pre and config.rewriter_post
      # 3. Per-File Processing:
      #    - Read source file
      #    - Execute formatting via Formatter
      #    - If write mode: update file
      #    - Collect results
      # 4. Aggregation: Combine results into AggregatedResult
      #
      # @rbs files: Array[String]?
      # @rbs return: AggregatedResult
      def run(files = nil)
        target_files = discover_files(files)
        results = target_files.map { |file_path| format_file(file_path) }

        AggregatedResult.new(results: results)
      end

      private

      # @rbs return: Formatter
      def build_formatter
        factory = FormatterFactory.new(config, @rewriter_registry)
        factory.create
      end

      # Discover files to format.
      # If files is nil or empty, use config include/exclude patterns.
      # If files is provided, use those paths directly (still respecting exclude).
      #
      # @rbs files: Array[String]?
      # @rbs return: Array[String]
      def discover_files(files)
        if files.nil? || files.empty?
          # Use config patterns
          discovery = Herb::Core::FileDiscovery.new(
            include_patterns: config.include_patterns,
            exclude_patterns: config.exclude_patterns
          )
          discovery.discover
        else
          # Use provided files, filter by exclude patterns
          files.reject { |file| excluded?(file) }
        end
      end

      # @rbs file: String
      # @rbs return: bool
      def excluded?(file)
        config.exclude_patterns.any? { |pattern| File.fnmatch?(pattern, file, File::FNM_PATHNAME) }
      end

      # Format a single file.
      #
      # @rbs file_path: String
      # @rbs return: FormatResult
      def format_file(file_path)
        source = File.read(file_path)
        result = @formatter.format(file_path, source, force: force)

        # Write file if write mode and changed
        if write && !check && result.changed? && !result.ignored? && !result.error?
          write_file(result)
        end

        result
      rescue StandardError => e
        FormatResult.new(
          file_path: file_path,
          original: "",
          formatted: "",
          error: e
        )
      end

      # Write formatted content back to file.
      #
      # @rbs result: FormatResult
      # @rbs return: void
      def write_file(result)
        File.write(result.file_path, result.formatted)
      end
    end
  end
end
```

**Test Cases:**
```ruby
RSpec.describe Herb::Format::Runner do
  let(:config) { build(:formatter_config) }
  let(:runner) { described_class.new(config: config) }

  describe "#initialize" do
    it "sets up a Herb::Rewriter::Registry" do
      expect(runner.instance_variable_get(:@rewriter_registry)).to be_a(Herb::Rewriter::Registry)
    end

    it "resolves built-in rewriters from registry" do
      registry = runner.instance_variable_get(:@rewriter_registry)
      expect(registry.registered?("tailwind-class-sorter")).to be true
    end

    it "creates formatter via factory" do
      formatter = runner.instance_variable_get(:@formatter)
      expect(formatter).to be_a(Herb::Format::Formatter)
    end
  end

  describe "#run" do
    context "with no files" do
      it "returns an AggregatedResult" do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            result = runner.run

            expect(result).to be_a(Herb::Format::AggregatedResult)
          end
        end
      end
    end

    context "with specific files" do
      it "formats provided files" do
        Dir.mktmpdir do |dir|
          file_path = File.join(dir, "test.html.erb")
          File.write(file_path, "<div>test</div>")

          result = runner.run([file_path])

          expect(result.file_count).to eq(1)
        end
      end

      it "excludes files matching exclude patterns" do
        config_with_exclude = Herb::Config::FormatterConfig.new(
          "formatter" => { "enabled" => true, "exclude" => ["vendor/**"] }
        )
        runner_with_exclude = described_class.new(config: config_with_exclude)

        Dir.mktmpdir do |dir|
          # Use relative path so fnmatch pattern matching works
          Dir.chdir(dir) do
            FileUtils.mkdir_p("vendor")
            File.write("vendor/test.html.erb", "<div>test</div>")

            result = runner_with_exclude.run(["vendor/test.html.erb"])
            expect(result.file_count).to eq(0)
          end
        end
      end
    end
  end

  describe "write mode" do
    it "writes formatted content when write: true and check: false" do
      Dir.mktmpdir do |dir|
        file_path = File.join(dir, "test.html.erb")
        File.write(file_path, "<div>test</div>")

        runner_write = described_class.new(config: config, write: true, check: false)
        runner_write.run([file_path])

        # Verify file was written (content may have changed due to formatting)
        expect(File.exist?(file_path)).to be true
      end
    end

    it "does not write when check: true" do
      Dir.mktmpdir do |dir|
        file_path = File.join(dir, "test.html.erb")
        original_content = "<div>test</div>"
        File.write(file_path, original_content)

        runner_check = described_class.new(config: config, check: true, write: false)
        runner_check.run([file_path])

        # Verify file content unchanged
        expect(File.read(file_path)).to eq(original_content)
      end
    end

    it "does not write ignored files" do
      Dir.mktmpdir do |dir|
        file_path = File.join(dir, "test.html.erb")
        original_content = "<%# herb:formatter ignore %>\n<div>test</div>"
        File.write(file_path, original_content)

        runner_write = described_class.new(config: config, write: true, check: false)
        runner_write.run([file_path])

        # Verify file content unchanged
        expect(File.read(file_path)).to eq(original_content)
      end
    end

    it "does not write files with errors" do
      Dir.mktmpdir do |dir|
        file_path = File.join(dir, "test.html.erb")
        original_content = "<div><span></div>" # Malformed
        File.write(file_path, original_content)

        runner_write = described_class.new(config: config, write: true, check: false)
        runner_write.run([file_path])

        # Verify file content unchanged
        expect(File.read(file_path)).to eq(original_content)
      end
    end
  end

  describe "error handling" do
    it "continues processing on individual file errors" do
      Dir.mktmpdir do |dir|
        file1 = File.join(dir, "test1.html.erb")
        file2 = File.join(dir, "test2.html.erb")
        File.write(file1, "<div>test</div>")
        File.write(file2, "<div>test</div>")

        # Simulate error on file1
        allow(File).to receive(:read).with(file1).and_raise(StandardError.new("Read error"))
        allow(File).to receive(:read).with(file2).and_call_original

        result = runner.run([file1, file2])

        expect(result.file_count).to eq(2)
        expect(result.error_count).to eq(1)
      end
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/runner_spec.rb`
- All tests pass

---

## Part B: Integration

### Task 5.2: Wire Up Runner

**Location:** `herb-format/lib/herb/format.rb`

- [ ] Add require_relative for runner
- [ ] Run rbs-inline to generate signatures
- [ ] Run steep check

**Verification:**
- `cd herb-format && ./bin/steep check` passes
- Runner can be instantiated without error

---

### Task 5.3: Create Integration Tests

**Location:** `herb-format/spec/herb/format/runner_integration_spec.rb`

- [ ] Create integration test file
- [ ] Test full workflow with real files
- [ ] Test batch processing
- [ ] Test error recovery

**Example:**
```ruby
RSpec.describe "Runner Integration" do
  let(:config) { build(:formatter_config) }
  let(:runner) { Herb::Format::Runner.new(config: config) }

  it "formats multiple files" do
    Dir.mktmpdir do |dir|
      # Create test files
      files = [
        File.join(dir, "test1.html.erb"),
        File.join(dir, "test2.html.erb")
      ]

      files.each { |f| File.write(f, "<div>test</div>") }

      result = runner.run(files)

      expect(result.file_count).to eq(2)
    end
  end

  it "aggregates results correctly" do
    Dir.mktmpdir do |dir|
      # Create normal file
      normal_file = File.join(dir, "normal.html.erb")
      File.write(normal_file, "<div>test</div>")

      # Create ignored file
      ignored_file = File.join(dir, "ignored.html.erb")
      File.write(ignored_file, "<%# herb:formatter ignore %>\n<div>test</div>")

      # Create malformed file
      error_file = File.join(dir, "error.html.erb")
      File.write(error_file, "<div><span></div>")

      result = runner.run([normal_file, ignored_file, error_file])

      expect(result.file_count).to eq(3)
      expect(result.ignored_count).to eq(1)
      expect(result.error_count).to eq(1)
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/runner_integration_spec.rb`
- All tests pass

---

### Task 5.4: Full Verification

- [ ] Run `cd herb-format && ./bin/rake` -- all checks pass
- [ ] Verify Runner processes multiple files correctly
- [ ] Verify file discovery works with patterns
- [ ] Verify write mode updates files
- [ ] Verify check mode does not modify files
- [ ] Verify error handling and recovery

---

## Summary

| Task | Part | Description |
|------|------|-------------|
| 5.1 | A | Runner class implementation |
| 5.2-5.4 | B | Integration and verification |

**Total: 4 tasks**

## Related Documents

- [herb-format Design](../design/herb-format-design.md)
- [herb-core Design](../design/herb-core-design.md)
- [Phase 3: Formatter Core](./phase-3-formatter-core.md)
- [Phase 4: Rewriters](./phase-4-formatter-rewriters.md)
- [Phase 6: CLI](./phase-6-formatter-cli.md)
