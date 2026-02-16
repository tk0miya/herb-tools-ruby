# frozen_string_literal: true

require "json"
require "yaml"
require "tmpdir"
require "fileutils"
require "stringio"

RSpec.describe Herb::Lint::CLI do
  describe "#run" do
    subject { cli.run }

    let(:cli) { described_class.new(argv) }
    let(:argv) { [] }

    describe "--version option" do
      let(:argv) { ["--version"] }

      it "outputs version and returns EXIT_SUCCESS" do
        output = capture_stdout { subject }
        expect(output).to include("herb-lint #{Herb::Lint::VERSION}")
        expect(subject).to eq(described_class::EXIT_SUCCESS)
      end
    end

    describe "--help option" do
      let(:argv) { ["--help"] }

      it "outputs help with examples and exit codes, and returns EXIT_SUCCESS" do
        output = capture_stdout { subject }
        expect(output).to include("Usage: herb-lint")
        expect(output).to include("Examples:")
        expect(output).to include("Exit codes:")
        expect(subject).to eq(described_class::EXIT_SUCCESS)
      end
    end

    describe "--init option" do
      around do |example|
        Dir.mktmpdir do |temp_dir|
          Dir.chdir(temp_dir) do
            example.run
          end
        end
      end

      let(:argv) { ["--init"] }
      let(:config_path) { ".herb.yml" }

      context "when .herb.yml does not exist" do
        it "creates .herb.yml and returns EXIT_SUCCESS" do
          output = capture_stdout { subject }
          expect(subject).to eq(described_class::EXIT_SUCCESS)
          expect(output).to include("Created .herb.yml")
          expect(File.exist?(config_path)).to be true
        end

        it "creates .herb.yml with valid YAML content" do
          subject
          content = File.read(config_path)
          expect { YAML.safe_load(content, permitted_classes: [Symbol]) }.not_to raise_error
        end

        it "creates .herb.yml with linter configuration" do
          subject
          config = YAML.safe_load_file(config_path, permitted_classes: [Symbol])
          expect(config).to have_key("linter")
          expect(config["linter"]).to have_key("enabled")
          expect(config["linter"]).to have_key("include")
          expect(config["linter"]).to have_key("exclude")
          expect(config["linter"]).to have_key("rules")
        end

        it "creates .herb.yml with formatter configuration" do
          subject
          config = YAML.safe_load_file(config_path, permitted_classes: [Symbol])
          expect(config).to have_key("formatter")
          expect(config["formatter"]).to have_key("enabled")
          expect(config["formatter"]).to have_key("indentWidth")
          expect(config["formatter"]).to have_key("maxLineLength")
        end
      end

      context "when .herb.yml already exists" do
        before do
          File.write(config_path, "existing: config")
        end

        it "returns EXIT_RUNTIME_ERROR without overwriting" do
          output = capture_stderr { subject }
          expect(subject).to eq(described_class::EXIT_RUNTIME_ERROR)
          expect(output).to include("Error: .herb.yml already exists")
          expect(File.read(config_path)).to eq("existing: config")
        end
      end
    end

    describe "linting files" do
      around do |example|
        Dir.mktmpdir do |temp_dir|
          Dir.chdir(temp_dir) do
            example.run
          end
        end
      end

      def create_file(relative_path, content = "")
        full_path = File.join(Dir.pwd, relative_path)
        FileUtils.mkdir_p(File.dirname(full_path))
        # Ensure content ends with newline if not empty
        content_with_newline = if content.empty? || content.end_with?("\n")
                                 content
                               else
                                 "#{content}\n"
                               end
        File.write(full_path, content_with_newline)
      end

      context "when no arguments are provided" do
        let(:argv) { [] }

        before do
          create_file("app/views/index.html.erb", '<%= image_tag "test.png", alt: "Test" %>')
        end

        it "lints files in the current directory" do
          expect(subject).to eq(described_class::EXIT_SUCCESS)
        end
      end

      context "when single path argument is provided" do
        let(:argv) { ["app/views/users"] }

        before do
          create_file("app/views/users/index.html.erb", '<img src="test.png">')
          create_file("app/views/posts/index.html.erb", '<img src="other.png">')
        end

        it "lints only files in the specified path" do
          output = capture_stdout { subject }
          expect(output).to include("app/views/users/index.html.erb")
          expect(output).not_to include("app/views/posts/index.html.erb")
        end
      end

      context "when multiple path arguments are provided" do
        let(:argv) { ["app/views/users", "app/views/posts"] }

        before do
          create_file("app/views/users/index.html.erb", '<img src="test.png">')
          create_file("app/views/posts/index.html.erb", '<img src="other.png">')
          create_file("app/views/admin/index.html.erb", '<img src="admin.png">')
        end

        it "lints files in all specified paths" do
          output = capture_stdout { subject }
          expect(output).to include("app/views/users/index.html.erb")
          expect(output).to include("app/views/posts/index.html.erb")
          expect(output).not_to include("app/views/admin/index.html.erb")
        end
      end

      context "when files have no offenses" do
        let(:argv) { [] }

        before do
          create_file("app/views/valid.html.erb", '<%= image_tag "test.png", alt: "Test" %>')
        end

        it "returns EXIT_SUCCESS" do
          expect(subject).to eq(described_class::EXIT_SUCCESS)
        end
      end

      context "when files have offenses" do
        let(:argv) { [] }

        before do
          create_file("app/views/invalid.html.erb", '<img src="test.png">')
        end

        it "returns EXIT_LINT_ERROR and outputs offense information" do
          output = capture_stdout { subject }
          expect(subject).to eq(described_class::EXIT_LINT_ERROR)
          expect(output).to include("app/views/invalid.html.erb")
          expect(output).to include("html-img-require-alt")
        end
      end

      context "when no files are found" do
        let(:argv) { [] }

        it "returns EXIT_SUCCESS with empty result" do
          expect(subject).to eq(described_class::EXIT_SUCCESS)
        end
      end

      context "when offense is suppressed by herb:disable" do
        let(:argv) { [] }

        before do
          create_file(
            "app/views/disabled.html.erb",
            '<img src="test.png"> <%# herb:disable html-img-require-alt, erb-prefer-image-tag-helper %>'
          )
        end

        it "returns EXIT_SUCCESS when all offenses are suppressed" do
          expect(subject).to eq(described_class::EXIT_SUCCESS)
        end
      end

      context "with --ignore-disable-comments flag" do
        let(:argv) { ["--ignore-disable-comments"] }

        before do
          create_file("app/views/disabled.html.erb", '<img src="test.png"> <%# herb:disable html-img-require-alt %>')
        end

        it "reports suppressed offenses and returns EXIT_LINT_ERROR" do
          output = capture_stdout { subject }
          expect(subject).to eq(described_class::EXIT_LINT_ERROR)
          expect(output).to include("html-img-require-alt")
        end
      end

      context "when file has herb:linter ignore" do
        let(:argv) { [] }

        before do
          create_file("app/views/ignored.html.erb", "<%# herb:linter ignore %>\n<img src=\"test.png\">")
        end

        it "returns EXIT_SUCCESS as the file is entirely ignored" do
          expect(subject).to eq(described_class::EXIT_SUCCESS)
        end
      end

      context "with --format json option" do
        let(:argv) { ["--format", "json"] }

        before do
          create_file("app/views/test.html.erb", '<img src="test.png">')
        end

        it "outputs JSON format" do
          output = capture_stdout { subject }
          expect(output).to include('"offenses"')
          expect(output).to include('"summary"')
          expect(output).to include('"completed"')
          expect { JSON.parse(output) }.not_to raise_error
        end
      end

      context "with --format simple option" do
        let(:argv) { ["--format", "simple"] }

        before do
          create_file("app/views/test.html.erb", '<img src="test.png">')
        end

        it "outputs simple format" do
          output = capture_stdout { subject }
          expect(output).to include("app/views/test.html.erb")
          expect(output).to include("html-img-require-alt")
        end
      end

      context "with --github option" do
        let(:argv) { ["--github"] }

        before do
          create_file("app/views/test.html.erb", '<img src="test.png">')
        end

        it "outputs GitHub Actions annotations" do
          output = capture_stdout { subject }
          expect(output).to include("::error")
          expect(output).to include("file=app/views/test.html.erb")
          expect(output).to include("html-img-require-alt")
        end
      end

      context "with invalid --format option" do
        let(:argv) { ["--format", "invalid"] }

        before do
          create_file("app/views/test.html.erb", '<img src="test.png">')
        end

        it "returns EXIT_RUNTIME_ERROR with error message" do
          output = capture_stderr { subject }
          expect(subject).to eq(described_class::EXIT_RUNTIME_ERROR)
          expect(output).to include("Invalid format")
        end
      end

      context "with --fix option" do
        let(:argv) { ["--fix", "app/views/test.html.erb"] }

        before do
          # Create a file with fixable offense (unquoted attribute value)
          create_file("app/views/test.html.erb", "<div class=test>content</div>")
        end

        it "applies safe autofixes to the file" do
          result = subject

          # File should be fixed (unquoted → quoted)
          expect(File.read("app/views/test.html.erb")).to eq(%(<div class="test">content</div>\n))
          # Exit code may be success or error depending on remaining unfixed offenses
          expect([described_class::EXIT_SUCCESS, described_class::EXIT_LINT_ERROR]).to include(result)
        end
      end

      context "with --fix-unsafely option" do
        # NOTE: This test is skipped because no unsafe autofixable rules exist yet.
        # Will be implemented when unsafe autofix rules are added.
        let(:argv) { ["--fix-unsafely", "app/views/test.html.erb"] }

        before do
          create_file("app/views/test.html.erb", "<div class=test>content</div>")
        end

        it "applies both safe and unsafe fixes" do
          skip "no unsafe autofixable rules exist yet"
          subject
          expect(File.read("app/views/test.html.erb")).to include('class="test"')
        end

        it "accepts the option without error" do
          expect { subject }.not_to raise_error
        end
      end

      context "with --fail-level option" do
        # Use a file that triggers only warning-level offenses (no errors)
        # This allows us to properly test how failLevel affects exit codes
        before do
          # Triggers html-no-empty-attributes (warning)
          create_file("app/views/test.html.erb", '<div class=""></div>')
        end

        context "when --fail-level is 'error'" do
          let(:argv) { ["--fail-level", "error"] }

          it "returns EXIT_SUCCESS because warnings are below threshold" do
            expect(subject).to eq(described_class::EXIT_SUCCESS)
          end
        end

        context "when --fail-level is 'warning'" do
          let(:argv) { ["--fail-level", "warning"] }

          it "returns EXIT_LINT_ERROR because warnings meet threshold" do
            expect(subject).to eq(described_class::EXIT_LINT_ERROR)
          end
        end

        context "when failLevel is configured in .herb.yml" do
          let(:argv) { [] }

          before do
            File.write(".herb.yml", <<~YAML)
              linter:
                failLevel: warning
            YAML
          end

          it "uses the configured failLevel from config and returns EXIT_LINT_ERROR" do
            expect(subject).to eq(described_class::EXIT_LINT_ERROR)
          end
        end

        context "when --fail-level CLI option overrides config" do
          before do
            File.write(".herb.yml", <<~YAML)
              linter:
                failLevel: warning
            YAML
          end

          context "when CLI sets error (higher threshold than config)" do
            let(:argv) { ["--fail-level", "error"] }

            it "CLI option takes precedence and returns EXIT_SUCCESS" do
              expect(subject).to eq(described_class::EXIT_SUCCESS)
            end
          end
        end

        context "when no offenses exist" do
          let(:argv) { [] }

          before do
            create_file("app/views/test.html.erb", '<%= image_tag "test.png", alt: "Test" %>')
          end

          it "returns EXIT_SUCCESS regardless of failLevel" do
            expect(subject).to eq(described_class::EXIT_SUCCESS)
          end
        end

        context "when offenses are below threshold due to severity override" do
          let(:argv) { ["--fail-level", "error"] }

          before do
            File.write(".herb.yml", <<~YAML)
              linter:
                rules:
                  html-img-require-alt:
                    severity: warning
                  erb-prefer-image-tag-helper:
                    enabled: false
            YAML
            create_file("app/views/test.html.erb", '<img src="test.png">')
          end

          it "returns EXIT_SUCCESS when only warnings exist and failLevel is error" do
            expect(subject).to eq(described_class::EXIT_SUCCESS)
          end
        end

        context "when multiple rules have severity overrides" do
          let(:argv) { ["--fail-level", "warning"] }

          before do
            File.write(".herb.yml", <<~YAML)
              linter:
                rules:
                  html-img-require-alt:
                    severity: info
                  erb-prefer-image-tag-helper:
                    enabled: false
            YAML
            create_file("app/views/test.html.erb", '<img src="test.png">')
          end

          it "returns EXIT_SUCCESS when offenses are below threshold" do
            expect(subject).to eq(described_class::EXIT_SUCCESS)
          end
        end
      end
    end

    describe "error handling" do
      context "when configuration file is invalid" do
        around do |example|
          Dir.mktmpdir do |temp_dir|
            Dir.chdir(temp_dir) do
              example.run
            end
          end
        end

        before do
          File.write(".herb.yml", "invalid: yaml: content: [")
        end

        it "returns EXIT_RUNTIME_ERROR and outputs configuration error to stderr" do
          output = capture_stderr { subject }
          expect(subject).to eq(described_class::EXIT_RUNTIME_ERROR)
          expect(output).to include("Configuration error")
        end
      end
    end
  end

  # Helper methods for capturing output
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def capture_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
  end
end
