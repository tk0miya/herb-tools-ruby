# frozen_string_literal: true

require "herb/highlighter/cli"
require "stringio"
require "tempfile"

RSpec.describe Herb::Highlighter::CLI do
  let(:cli) { described_class.new(argv) }
  let(:argv) { [] }

  describe "#run" do
    subject { cli.run }

    describe "--version option" do
      let(:argv) { ["--version"] }

      it "outputs version and returns EXIT_SUCCESS" do
        output = capture_stdout { subject }
        expect(output).to include("herb-highlighter #{Herb::Highlighter::VERSION}")
        expect(subject).to eq(described_class::EXIT_SUCCESS)
      end
    end

    describe "--help option" do
      let(:argv) { ["--help"] }

      it "outputs usage and returns EXIT_SUCCESS" do
        output = capture_stdout { subject }
        expect(output).to include("Usage: herb-highlight")
        expect(subject).to eq(described_class::EXIT_SUCCESS)
      end
    end

    describe "file argument" do
      context "when no arguments are provided" do
        let(:argv) { [] }

        it "prints error to stderr and returns EXIT_ERROR" do
          output = capture_stderr { subject }
          expect(output).to include("Please specify an input file.")
          expect(subject).to eq(described_class::EXIT_ERROR)
        end
      end

      context "when the file does not exist" do
        let(:argv) { ["/nonexistent/path/to/file.erb"] }

        it "prints error to stderr and returns EXIT_ERROR" do
          output = capture_stderr { subject }
          expect(output).to include("File not found:")
          expect(subject).to eq(described_class::EXIT_ERROR)
        end
      end

      context "when the file exists" do
        let(:tempfile) { Tempfile.new(["test", ".erb"]) }
        let(:argv) { [tempfile.path] }

        before do
          tempfile.write("<div>Hello</div>")
          tempfile.flush
        end

        after { tempfile.close! }

        it "reads the file and prints highlighted content to stdout and returns EXIT_SUCCESS" do
          output = capture_stdout { subject }
          expect(output).to include("<div>Hello</div>")
          expect(output).to include("    1 │")
          expect(subject).to eq(described_class::EXIT_SUCCESS)
        end
      end
    end

    describe "--theme option" do
      let(:tempfile) { Tempfile.new(["test", ".erb"]) }
      let(:argv) { ["--theme", "onedark", tempfile.path] }

      before do
        tempfile.write("<div>Hello</div>")
        tempfile.flush
        mapping = { "TOKEN_HTML_TAG_START" => "cyan", "TOKEN_HTML_TAG_END" => "cyan", "TOKEN_IDENTIFIER" => "white" }
        Herb::Highlighter::Themes.register("onedark", mapping)
      end

      after { tempfile.close! }

      # SyntaxRenderer applies ANSI codes regardless of TTY, so we can verify
      # that the theme color (cyan = \e[36m) appears around the HTML tag token.
      it "applies the theme colors to the syntax-highlighted output and returns EXIT_SUCCESS" do
        output = capture_stdout { subject }
        expect(output).to include("\e[36m<\e[0m")
        expect(subject).to eq(described_class::EXIT_SUCCESS)
      end
    end

    describe "--focus option" do
      let(:tempfile) { Tempfile.new(["test", ".erb"]) }
      let(:argv) { ["--focus", "2", tempfile.path] }

      before do
        tempfile.write("line one\nline two\nline three\n")
        tempfile.flush
      end

      after { tempfile.close! }

      # FileRenderer renders an arrow marker "  → " on the focus line and
      # a plain "    " prefix on other lines (colorize is a no-op when tty: false).
      it "marks the focus line with an arrow and renders other lines with plain prefix" do
        output = capture_stdout { subject }
        expect(output).to include("    1 │")
        expect(output).to include("  → 2 │")
        expect(output).to include("    3 │")
        expect(subject).to eq(described_class::EXIT_SUCCESS)
      end

      context "with a non-integer value" do
        let(:argv) { ["--focus", "abc", tempfile.path] }

        it "prints error to stderr and returns EXIT_ERROR" do
          output = capture_stderr { subject }
          expect(output).to include("Invalid argument")
          expect(subject).to eq(described_class::EXIT_ERROR)
        end
      end
    end

    describe "--context-lines option" do
      let(:tempfile) { Tempfile.new(["test", ".erb"]) }

      after { tempfile.close! }

      context "without --focus (context_lines is accepted but has no filtering effect)" do
        let(:argv) { ["--context-lines", "2", tempfile.path] }

        before do
          tempfile.write("line one\nline two\nline three\n")
          tempfile.flush
        end

        it "shows all lines with plain prefix and returns EXIT_SUCCESS" do
          output = capture_stdout { subject }
          expect(output).to include("    1 │")
          expect(output).to include("    2 │")
          expect(output).to include("    3 │")
          expect(subject).to eq(described_class::EXIT_SUCCESS)
        end
      end

      context "with a non-integer value" do
        let(:argv) { ["--context-lines", "abc", tempfile.path] }

        before do
          tempfile.write("line one\n")
          tempfile.flush
        end

        it "prints error to stderr and returns EXIT_ERROR" do
          output = capture_stderr { subject }
          expect(output).to include("Invalid argument")
          expect(subject).to eq(described_class::EXIT_ERROR)
        end
      end

      context "with --focus and --context-lines filtering (5-line file)" do
        before do
          tempfile.write("line one\nline two\nline three\nline four\nline five\n")
          tempfile.flush
        end

        context "with focus within normal range (focus=3, context_lines=1)" do
          let(:argv) { ["--focus", "3", "--context-lines", "1", tempfile.path] }

          it "shows lines 2-4 with arrow on line 3" do
            output = capture_stdout { subject }
            expect(output).to include("  → 3 │")
            expect(output).to include("    2 │")
            expect(output).to include("    4 │")
            expect(output).not_to include("    1 │")
            expect(output).not_to include("    5 │")
          end
        end

        context "with focus clamped to start (focus=1, context_lines=2)" do
          let(:argv) { ["--focus", "1", "--context-lines", "2", tempfile.path] }

          it "shows lines 1-3 with arrow on line 1" do
            output = capture_stdout { subject }
            expect(output).to include("  → 1 │")
            expect(output).to include("    2 │")
            expect(output).to include("    3 │")
            expect(output).not_to include("    4 │")
          end
        end

        context "with focus clamped to end (focus=5, context_lines=2)" do
          let(:argv) { ["--focus", "5", "--context-lines", "2", tempfile.path] }

          it "shows lines 3-5 with arrow on line 5" do
            output = capture_stdout { subject }
            expect(output).to include("  → 5 │")
            expect(output).to include("    4 │")
            expect(output).to include("    3 │")
            expect(output).not_to include("    2 │")
          end
        end
      end
    end
  end

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
