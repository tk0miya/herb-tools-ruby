# frozen_string_literal: true

require "json"
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
          expect(output).to include('"files"')
          expect(output).to include('"summary"')
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
        let(:argv) { ["--fix"] }

        before do
          create_file("app/views/test.html.erb", "<% %>\n<p>Hello</p>")
        end

        it "applies safe automatic fixes" do
          subject
          content = File.read("app/views/test.html.erb")
          expect(content).not_to include("<% %>")
          expect(content).to include("<p>Hello</p>")
        end

        it "returns EXIT_SUCCESS when all offenses are fixed" do
          expect(subject).to eq(described_class::EXIT_SUCCESS)
        end

        context "with non-fixable offenses" do
          before do
            create_file("app/views/mixed.html.erb", '<% %><img src="test.png">')
          end

          let(:argv) { ["--fix", "app/views/mixed.html.erb"] }

          it "applies fixable offenses and reports remaining offenses" do
            output = capture_stdout { subject }
            expect(subject).to eq(described_class::EXIT_LINT_ERROR)
            expect(output).to include("html-img-require-alt")
            # Verify the empty tag was fixed
            content = File.read("app/views/mixed.html.erb")
            expect(content).not_to include("<% %>")
          end
        end
      end

      context "with --fix-unsafely option" do
        let(:argv) { ["--fix-unsafely"] }

        before do
          create_file("app/views/test.html.erb", "<% %>\n<p>Hello</p>")
        end

        it "applies all automatic fixes including unsafe ones" do
          subject
          content = File.read("app/views/test.html.erb")
          expect(content).not_to include("<% %>")
        end

        it "returns EXIT_SUCCESS when all offenses are fixed" do
          expect(subject).to eq(described_class::EXIT_SUCCESS)
        end
      end

      context "with --fix and files without fixable offenses" do
        let(:argv) { ["--fix"] }

        before do
          create_file("app/views/valid.html.erb", "<p>Hello</p>")
        end

        it "does not modify files without offenses" do
          original_content = File.read("app/views/valid.html.erb")
          subject
          expect(File.read("app/views/valid.html.erb")).to eq(original_content)
        end

        it "returns EXIT_SUCCESS" do
          expect(subject).to eq(described_class::EXIT_SUCCESS)
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
