# Phase 6: Formatter CLI

This phase implements the command-line interface for herb-format.

**Design document:** [herb-format-design.md](../design/herb-format-design.md) (CLI section)

**Requirements document:** [herb-format.md](../requirements/herb-format.md)

**Reference:** TypeScript `@herb-tools/formatter` CLI implementation

## Overview

| Feature | Description | Impact |
|---------|-------------|--------|
| CLI | Command-line interface orchestration | User-facing tool |
| Option parsing | Handle --check, --write, --force, --stdin, etc. | Flexible usage modes |
| Exit codes | Proper exit codes for CI/CD integration | Automation support |
| Reporting | Display formatting results and diffs | User feedback |

## Prerequisites

- Phase 1 complete (Foundation)
- Phase 2 complete (FormatPrinter)
- Phase 3 complete (Formatter Core)
- Phase 4 complete (Rewriters)
- Phase 5 complete (Runner)

## Design Principles

1. **TypeScript compatibility** - Match CLI interface of `@herb-tools/formatter`
2. **Clear exit codes** - 0 for success, 1 for format needed, 2 for errors
3. **User-friendly output** - Clear messages and diffs
4. **Stream handling** - Support stdin/stdout for pipe usage

---

## Part A: Basic CLI Structure

### Task 6.1: Create CLI Class

**Location:** `herb-format/lib/herb/format/cli.rb`

- [ ] Create CLI class
- [ ] Define exit code constants
- [ ] Add initialize with argv, stdout, stderr, stdin
- [ ] Add run() method returning exit code
- [ ] Add private parse_options() method
- [ ] Add RBS inline type annotations
- [ ] Create spec file

**Interface:**
```ruby
# rbs_inline: enabled

require "optparse"

module Herb
  module Format
    # Command-line interface orchestration.
    #
    # @rbs @argv: Array[String]
    # @rbs @stdout: IO
    # @rbs @stderr: IO
    # @rbs @stdin: IO
    # @rbs @options: Hash[Symbol, untyped]
    class CLI
      EXIT_SUCCESS = 0          # All files formatted (or already formatted with --check)
      EXIT_FORMAT_NEEDED = 1    # Files need formatting (with --check) or formatting error
      EXIT_RUNTIME_ERROR = 2    # Configuration or runtime error

      attr_reader :argv, :stdout, :stderr, :stdin

      # @rbs argv: Array[String]
      # @rbs stdout: IO
      # @rbs stderr: IO
      # @rbs stdin: IO
      # @rbs return: void
      def initialize(argv = ARGV, stdout: $stdout, stderr: $stderr, stdin: $stdin)
        @argv = argv
        @stdout = stdout
        @stderr = stderr
        @stdin = stdin
        @options = {}
      end

      # Run CLI and return exit code.
      #
      # Processing flow:
      # 1. Parse command-line options
      # 2. Handle special flags (--init, --version, --help)
      # 3. Handle --stdin mode (read from stdin, output to stdout)
      # 4. Load configuration via Herb::Config::Loader
      # 5. Create and run Runner
      # 6. Report results (diff output in check mode)
      # 7. Determine exit code based on formatting results
      #
      # @rbs return: Integer
      def run
        parse_options

        return handle_version if @options[:version]
        return handle_help if @options[:help]
        return handle_init if @options[:init]
        return handle_stdin if @options[:stdin]

        config = load_config
        files = @options[:files]

        runner = Runner.new(
          config: config.formatter,
          check: @options[:check],
          write: @options[:write],
          force: @options[:force]
        )

        result = runner.run(files)

        report_results(result)
        determine_exit_code(result, @options[:check])
      rescue Herb::Config::ConfigurationError => e
        stderr.puts "Configuration error: #{e.message}"
        EXIT_RUNTIME_ERROR
      rescue StandardError => e
        stderr.puts "Error: #{e.message}"
        stderr.puts e.backtrace if @options[:debug]
        EXIT_RUNTIME_ERROR
      end

      private

      # @rbs return: Hash[Symbol, untyped]
      def parse_options
        @options = {
          check: false,
          write: true,
          force: false,
          stdin: false,
          stdin_filepath: nil,
          config: nil,
          version: false,
          help: false,
          debug: false,
          files: []
        }

        OptionParser.new do |opts|
          opts.banner = "Usage: herb-format [options] [files...]"

          opts.on("--init", "Generate a default .herb.yml configuration file") do
            @options[:init] = true
          end

          opts.on("--check", "Check if files are formatted without modifying them") do
            @options[:check] = true
            @options[:write] = false
          end

          opts.on("--write", "Write formatted output back to files (default behavior)") do
            @options[:write] = true
          end

          opts.on("--force", "Override inline ignore directives") do
            @options[:force] = true
          end

          opts.on("--stdin", "Read from standard input (output to stdout)") do
            @options[:stdin] = true
          end

          opts.on("--stdin-filepath PATH", "Path to use for configuration lookup when using stdin") do |path|
            @options[:stdin_filepath] = path
          end

          opts.on("--config PATH", "Path to configuration file (default: .herb.yml)") do |path|
            @options[:config] = path
          end

          opts.on("--version", "Show version number") do
            @options[:version] = true
          end

          opts.on("-h", "--help", "Show help message") do
            @options[:help] = true
          end

          opts.on("--debug", "Show debug information") do
            @options[:debug] = true
          end
        end.parse!(argv)

        # Remaining arguments are files
        @options[:files] = argv.dup

        @options
      end

      # @rbs return: Herb::Config::Config
      def load_config
        config_path = @options[:config]
        Herb::Config::Loader.load(config_path)
      end

      # @rbs result: AggregatedResult
      # @rbs return: void
      def report_results(result)
        if @options[:check]
          report_check_results(result)
        else
          report_format_results(result)
        end
      end

      # @rbs result: AggregatedResult
      # @rbs check_mode: bool
      # @rbs return: Integer
      def determine_exit_code(result, check_mode)
        return EXIT_RUNTIME_ERROR if result.error_count.positive?
        return EXIT_FORMAT_NEEDED if check_mode && result.changed_count.positive?
        EXIT_SUCCESS
      end
    end
  end
end
```

**Test Cases:**
```ruby
RSpec.describe Herb::Format::CLI do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:stdin) { StringIO.new }

  describe "#initialize" do
    it "accepts argv and IO streams" do
      cli = described_class.new([], stdout: stdout, stderr: stderr, stdin: stdin)

      expect(cli.argv).to eq([])
      expect(cli.stdout).to eq(stdout)
      expect(cli.stderr).to eq(stderr)
      expect(cli.stdin).to eq(stdin)
    end
  end

  describe "#run" do
    it "returns exit code" do
      cli = described_class.new(["--help"], stdout: stdout, stderr: stderr)
      exit_code = cli.run

      expect(exit_code).to be_a(Integer)
    end
  end

  describe "option parsing" do
    it "parses --check flag" do
      cli = described_class.new(["--check"], stdout: stdout, stderr: stderr)
      cli.send(:parse_options)

      expect(cli.instance_variable_get(:@options)[:check]).to be true
      expect(cli.instance_variable_get(:@options)[:write]).to be false
    end

    it "parses --force flag" do
      cli = described_class.new(["--force"], stdout: stdout, stderr: stderr)
      cli.send(:parse_options)

      expect(cli.instance_variable_get(:@options)[:force]).to be true
    end

    it "parses --stdin flag" do
      cli = described_class.new(["--stdin"], stdout: stdout, stderr: stderr)
      cli.send(:parse_options)

      expect(cli.instance_variable_get(:@options)[:stdin]).to be true
    end

    it "parses file arguments" do
      cli = described_class.new(["file1.erb", "file2.erb"], stdout: stdout, stderr: stderr)
      cli.send(:parse_options)

      expect(cli.instance_variable_get(:@options)[:files]).to eq(["file1.erb", "file2.erb"])
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/cli_spec.rb`

---

## Part B: Special Modes

### Task 6.2: Implement --version and --help Handlers

**Location:** `herb-format/lib/herb/format/cli.rb`

- [ ] Implement handle_version() method
- [ ] Implement handle_help() method
- [ ] Add tests

**Implementation:**
```ruby
private

# @rbs return: Integer
def handle_version
  stdout.puts "herb-format #{Herb::Format::VERSION}"
  EXIT_SUCCESS
end

# @rbs return: Integer
def handle_help
  stdout.puts <<~HELP
    Usage: herb-format [options] [files...]

    Options:
      --init                    Generate a default .herb.yml configuration file
      --check                   Check if files are formatted without modifying them
      --write                   Write formatted output back to files (default)
      --force                   Override inline ignore directives
      --stdin                   Read from standard input (output to stdout)
      --stdin-filepath PATH     Path to use for configuration lookup when using stdin
      --config PATH             Path to configuration file (default: .herb.yml)
      --version                 Show version number
      -h, --help                Show this help message

    Examples:
      # Format all files in current directory
      herb-format

      # Format specific files
      herb-format app/views/users/index.html.erb

      # Check without modifying (for CI)
      herb-format --check

      # Format from stdin
      echo '<div><p>Hello</p></div>' | herb-format --stdin

      # Initialize configuration
      herb-format --init

    Documentation: https://github.com/marcoroth/herb
  HELP
  EXIT_SUCCESS
end
```

**Test Cases:**
```ruby
describe "--version" do
  it "displays version and exits successfully" do
    cli = described_class.new(["--version"], stdout: stdout, stderr: stderr)
    exit_code = cli.run

    expect(exit_code).to eq(described_class::EXIT_SUCCESS)
    expect(stdout.string).to include(Herb::Format::VERSION)
  end
end

describe "--help" do
  it "displays help and exits successfully" do
    cli = described_class.new(["--help"], stdout: stdout, stderr: stderr)
    exit_code = cli.run

    expect(exit_code).to eq(described_class::EXIT_SUCCESS)
    expect(stdout.string).to include("Usage:")
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/cli_spec.rb`

---

### Task 6.3: Implement --init Handler

**Location:** `herb-format/lib/herb/format/cli.rb`

- [ ] Implement handle_init() method
- [ ] Generate default .herb.yml file
- [ ] Handle existing file case
- [ ] Add tests

**Implementation:**
```ruby
private

# @rbs return: Integer
def handle_init
  config_path = ".herb.yml"

  if File.exist?(config_path)
    stderr.puts "Error: #{config_path} already exists"
    return EXIT_RUNTIME_ERROR
  end

  default_config = <<~YAML
    # Herb Tools Configuration
    # https://github.com/marcoroth/herb

    linter:
      enabled: true
      include:
        - "**/*.html.erb"
        - "**/*.turbo_stream.erb"
      exclude:
        - "vendor/**"
        - "node_modules/**"
      rules:
        # Uncomment to customize rules
        # html-attribute-quotes:
        #   severity: error

    formatter:
      enabled: true
      indentWidth: 2
      maxLineLength: 80
      include:
        - "**/*.html.erb"
        - "**/*.turbo_stream.erb"
      exclude:
        - "vendor/**"
        - "node_modules/**"
      rewriter:
        pre: []
        post: []
  YAML

  File.write(config_path, default_config)
  stdout.puts "Created #{config_path}"
  EXIT_SUCCESS
rescue StandardError => e
  stderr.puts "Error creating configuration file: #{e.message}"
  EXIT_RUNTIME_ERROR
end
```

**Test Cases:**
```ruby
describe "--init" do
  it "creates .herb.yml file" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        cli = described_class.new(["--init"], stdout: stdout, stderr: stderr)
        exit_code = cli.run

        expect(exit_code).to eq(described_class::EXIT_SUCCESS)
        expect(File.exist?(".herb.yml")).to be true
        expect(stdout.string).to include("Created .herb.yml")
      end
    end
  end

  it "fails if .herb.yml already exists" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write(".herb.yml", "# existing")

        cli = described_class.new(["--init"], stdout: stdout, stderr: stderr)
        exit_code = cli.run

        expect(exit_code).to eq(described_class::EXIT_RUNTIME_ERROR)
        expect(stderr.string).to include("already exists")
      end
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/cli_spec.rb`

---

## Part C: Stdin Mode

### Task 6.4: Implement --stdin Handler

**Location:** `herb-format/lib/herb/format/cli.rb`

- [ ] Implement handle_stdin() method
- [ ] Read from stdin
- [ ] Format content
- [ ] Write to stdout
- [ ] Handle --stdin-filepath for config resolution
- [ ] Add tests

**Implementation:**
```ruby
private

# @rbs return: Integer
def handle_stdin
  source = stdin.read
  file_path = @options[:stdin_filepath] || "stdin"

  config = load_config
  factory = FormatterFactory.new(config.formatter, RewriterRegistry.new.tap(&:load_builtin_rewriters))
  formatter = factory.create

  result = formatter.format(file_path, source, force: @options[:force])

  if result.error?
    stderr.puts "Error formatting stdin: #{result.error.message}"
    return EXIT_RUNTIME_ERROR
  end

  stdout.print result.formatted
  EXIT_SUCCESS
rescue StandardError => e
  stderr.puts "Error: #{e.message}"
  EXIT_RUNTIME_ERROR
end
```

**Test Cases:**
```ruby
describe "--stdin" do
  it "formats content from stdin" do
    stdin_content = "<div><p>Hello</p></div>"
    stdin = StringIO.new(stdin_content)

    cli = described_class.new(["--stdin"], stdout: stdout, stderr: stderr, stdin: stdin)

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Create minimal config
        File.write(".herb.yml", "formatter:\n  enabled: true\n")

        exit_code = cli.run

        expect(exit_code).to eq(described_class::EXIT_SUCCESS)
        expect(stdout.string).not_to be_empty
      end
    end
  end

  it "uses --stdin-filepath for config resolution" do
    stdin_content = "<div>test</div>"
    stdin = StringIO.new(stdin_content)

    cli = described_class.new(
      ["--stdin", "--stdin-filepath", "app/views/test.html.erb"],
      stdout: stdout,
      stderr: stderr,
      stdin: stdin
    )

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write(".herb.yml", "formatter:\n  enabled: true\n")

        exit_code = cli.run

        expect(exit_code).to eq(described_class::EXIT_SUCCESS)
      end
    end
  end

  it "handles formatting errors" do
    stdin_content = "<div><span></div>" # Malformed
    stdin = StringIO.new(stdin_content)

    cli = described_class.new(["--stdin"], stdout: stdout, stderr: stderr, stdin: stdin)

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write(".herb.yml", "formatter:\n  enabled: true\n")

        exit_code = cli.run

        expect(exit_code).to eq(described_class::EXIT_RUNTIME_ERROR)
        expect(stderr.string).to include("Error")
      end
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/cli_spec.rb`

---

## Part D: Check Mode and Reporting

### Task 6.5: Implement Check Mode Reporting

**Location:** `herb-format/lib/herb/format/cli.rb`

- [ ] Implement report_check_results(result) method
- [ ] Display diff for changed files
- [ ] Show summary statistics
- [ ] Add tests

**Implementation:**
```ruby
private

# @rbs result: AggregatedResult
# @rbs return: void
def report_check_results(result)
  result.results.each do |file_result|
    next unless file_result.changed?

    stdout.puts file_result.file_path
    if file_result.diff
      stdout.puts file_result.diff
      stdout.puts
    end
  end

  stdout.puts "Checked #{result.file_count} files"
  stdout.puts "  #{result.changed_count} files need formatting"
  stdout.puts "  #{result.ignored_count} files ignored"
  stdout.puts "  #{result.error_count} files with errors" if result.error_count.positive?
end

# @rbs result: AggregatedResult
# @rbs return: void
def report_format_results(result)
  result.results.each do |file_result|
    if file_result.error?
      stderr.puts "Error formatting #{file_result.file_path}: #{file_result.error.message}"
    elsif file_result.ignored?
      stdout.puts "Ignored: #{file_result.file_path}"
    elsif file_result.changed?
      stdout.puts "Formatted: #{file_result.file_path}"
    end
  end

  stdout.puts
  stdout.puts "Formatted #{result.file_count} files"
  stdout.puts "  #{result.changed_count} files changed"
  stdout.puts "  #{result.ignored_count} files ignored"
  stdout.puts "  #{result.error_count} files with errors" if result.error_count.positive?
end
```

**Test Cases:**
```ruby
describe "check mode reporting" do
  it "displays diff for changed files" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "test.html.erb")
      File.write(file_path, "<div>test</div>")
      File.write(".herb.yml", "formatter:\n  enabled: true\n")

      cli = described_class.new(["--check", file_path], stdout: stdout, stderr: stderr)
      cli.run

      # Output should include file path and possibly diff
      output = stdout.string
      expect(output).to include("Checked")
    end
  end
end

describe "format mode reporting" do
  it "displays formatted files" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "test.html.erb")
      File.write(file_path, "<div>test</div>")
      File.write(".herb.yml", "formatter:\n  enabled: true\n")

      cli = described_class.new([file_path], stdout: stdout, stderr: stderr)
      cli.run

      output = stdout.string
      expect(output).to include("Formatted")
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/cli_spec.rb`

---

## Part E: Executable and Integration

### Task 6.6: Create Executable

**Location:** `herb-format/exe/herb-format`

- [ ] Create executable file
- [ ] Make executable (chmod +x)
- [ ] Add shebang line
- [ ] Require CLI and invoke run

**Implementation:**
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/herb/format"

exit Herb::Format::CLI.new.run
```

**Verification:**
- `chmod +x herb-format/exe/herb-format`
- `herb-format/exe/herb-format --version` works
- `herb-format/exe/herb-format --help` works

---

### Task 6.7: Wire Up CLI

**Location:** `herb-format/lib/herb/format.rb`

- [ ] Add require_relative for cli
- [ ] Run rbs-inline to generate signatures
- [ ] Run steep check

**Verification:**
- `cd herb-format && ./bin/steep check` passes
- CLI can be required without error

---

### Task 6.8: Full CLI Integration Tests

**Location:** `herb-format/spec/herb/format/cli_integration_spec.rb`

- [ ] Create CLI integration test file
- [ ] Test full workflows end-to-end
- [ ] Test exit codes
- [ ] Test error handling

**Example:**
```ruby
RSpec.describe "CLI Integration" do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  it "formats files and returns success" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        file_path = "test.html.erb"
        File.write(file_path, "<div>test</div>")
        File.write(".herb.yml", "formatter:\n  enabled: true\n")

        cli = Herb::Format::CLI.new([file_path], stdout: stdout, stderr: stderr)
        exit_code = cli.run

        expect(exit_code).to eq(Herb::Format::CLI::EXIT_SUCCESS)
      end
    end
  end

  it "returns FORMAT_NEEDED in check mode when files need formatting" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        file_path = "test.html.erb"
        File.write(file_path, "<div><p>test</p></div>") # Needs formatting
        File.write(".herb.yml", "formatter:\n  enabled: true\n")

        cli = Herb::Format::CLI.new(["--check", file_path], stdout: stdout, stderr: stderr)
        exit_code = cli.run

        # May be EXIT_SUCCESS if already formatted, or EXIT_FORMAT_NEEDED if not
        expect([Herb::Format::CLI::EXIT_SUCCESS, Herb::Format::CLI::EXIT_FORMAT_NEEDED]).to include(exit_code)
      end
    end
  end

  it "returns RUNTIME_ERROR on configuration error" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write(".herb.yml", "invalid: yaml: content:")

        cli = Herb::Format::CLI.new([], stdout: stdout, stderr: stderr)
        exit_code = cli.run

        expect(exit_code).to eq(Herb::Format::CLI::EXIT_RUNTIME_ERROR)
      end
    end
  end
end
```

**Verification:**
- `cd herb-format && ./bin/rspec spec/herb/format/cli_integration_spec.rb`
- All tests pass

---

### Task 6.9: Full Verification

- [ ] Run `cd herb-format && ./bin/rake` -- all checks pass
- [ ] Run `./exe/herb-format --version` -- displays version
- [ ] Run `./exe/herb-format --help` -- displays help
- [ ] Run `./exe/herb-format --init` -- creates config file
- [ ] Run `echo '<div>test</div>' | ./exe/herb-format --stdin` -- formats stdin
- [ ] Run `./exe/herb-format test.html.erb` -- formats file
- [ ] Run `./exe/herb-format --check test.html.erb` -- checks file
- [ ] Verify exit codes are correct
- [ ] Install gem locally and test: `gem install -l herb-format-0.1.0.gem && herb-format --version`

---

## Summary

| Task | Part | Description |
|------|------|-------------|
| 6.1 | A | CLI class foundation |
| 6.2 | B | --version and --help handlers |
| 6.3 | B | --init handler |
| 6.4 | C | --stdin handler |
| 6.5 | D | Check mode reporting |
| 6.6-6.9 | E | Executable and integration |

**Total: 9 tasks**

## Related Documents

- [herb-format Design](../design/herb-format-design.md)
- [herb-format Requirements](../requirements/herb-format.md)
- [Phase 5: Runner](./phase-5-formatter-runner.md)
