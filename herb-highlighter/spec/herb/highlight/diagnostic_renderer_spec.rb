# frozen_string_literal: true

RSpec.describe Herb::Highlight::DiagnosticRenderer do
  def strip_ansi(str)
    str.gsub(/\e\[[^m]*m/, "")
  end

  # 7-line source used for most tests
  let(:source_lines) do
    [
      "<html>\n",
      "<body>\n",
      "<div>\n",
      "<div class=\"foo\">\n",
      "</div>\n",
      "</body>\n",
      "</html>\n"
    ]
  end

  let(:passthrough_renderer) do
    instance_double(Herb::Highlight::SyntaxRenderer).tap do |dbl|
      allow(dbl).to receive(:render) { _1 }
    end
  end

  let(:renderer) do
    described_class.new(syntax_renderer: passthrough_renderer, context_lines: 2)
  end

  describe "#render" do
    # offense at line 4, column 8, end_column 10  (3 carets)
    subject { renderer.render(source_lines, line: 4, column: 8, end_column: 10) }

    it "renders lines and context around the offense" do
      # start=2, end=6 → 5 source lines + 1 caret row = 6 output lines
      expect(subject.lines.count).to eq(6)
      stripped = strip_ansi(subject)
      expect(stripped).to include("2 | <body>")
      expect(stripped).to include("3 | <div>")
      expect(stripped).to include("4 | <div class=\"foo\">")
      expect(stripped).to include("5 | </div>")
      expect(stripped).to include("6 | </body>")
    end

    describe "line number right-justification" do
      # 20-line source: end_display = min(20, 15+2) = 17, width = 17.to_s.length = 2
      subject { renderer.render(wide_source, line: 15, column: 1) }

      let(:wide_source) { (1..20).map { "line #{_1}\n" } }

      it "right-justifies line numbers to the display range width" do
        stripped = strip_ansi(subject)
        # Line 13 should appear as " 13" (right-justified in width 2)
        expect(stripped).to include(" 13 | ")
        expect(stripped).to include(" 15 | ")
      end
    end

    describe "offense vs. context line colors" do
      it "colors the offense line in brightRed and context lines in gray" do
        # brightRed ANSI code is \e[91m; gray is \e[90m
        expect(subject).to include("\e[91m4\e[0m")
        expect(subject).to include("\e[91m | \e[0m")
        expect(subject).to include("\e[90m2\e[0m")
        expect(subject).to include("\e[90m | \e[0m")
      end
    end

    describe "caret position" do
      it "places the caret under the offense column" do
        stripped = strip_ansi(subject)
        caret_line = stripped.lines.find { _1.include?("^") }
        expect(caret_line).not_to be_nil
        # After stripping, the caret row is: "   | " + (column-1) spaces + "^^^"
        # column=8, so 7 offset spaces + 1 trailing space from " | " = 8 spaces between "|" and "^"
        expect(caret_line).to match(/\| {8}\^/)
      end
    end

    describe "caret length" do
      context "with a multi-column offense (column 8, end_column 10)" do
        it "renders 3 carets" do
          stripped = strip_ansi(subject)
          caret_line = stripped.lines.find { _1.include?("^") }
          expect(caret_line.count("^")).to eq(3)
        end
      end

      context "with a single-character offense (column=5, end_column=5)" do
        subject { renderer.render(source_lines, line: 4, column: 5, end_column: 5) }

        it "renders exactly 1 caret" do
          stripped = strip_ansi(subject)
          caret_line = stripped.lines.find { _1.include?("^") }
          expect(caret_line.count("^")).to eq(1)
        end
      end

      context "with nil end_column (defaults to column + 1)" do
        subject { renderer.render(source_lines, line: 4, column: 5, end_column: nil) }

        it "renders 2 carets" do
          stripped = strip_ansi(subject)
          caret_line = stripped.lines.find { _1.include?("^") }
          expect(caret_line.count("^")).to eq(2)
        end
      end

      context "with a multi-line offense (end_line differs from line)" do
        subject { renderer.render(source_lines, line: 4, column: 5, end_line: 6, end_column: 3) }

        it "renders exactly 1 caret" do
          stripped = strip_ansi(subject)
          caret_line = stripped.lines.find { _1.include?("^") }
          expect(caret_line.count("^")).to eq(1)
        end
      end
    end

    context "with tty: false" do
      let(:renderer) { described_class.new(syntax_renderer: passthrough_renderer, tty: false) }

      it "emits no ANSI escape codes but still renders content" do
        result = renderer.render(source_lines, line: 4, column: 8, end_column: 10)
        expect(result).not_to match(/\e\[/)
        expect(result).to include("4 | ")
        expect(result).to include("^^^")
      end
    end

    context "with syntax highlighting via SyntaxRenderer" do
      let(:highlighting_renderer) do
        instance_double(Herb::Highlight::SyntaxRenderer).tap do |dbl|
          allow(dbl).to receive(:render) { "HIGHLIGHTED:#{_1}" }
        end
      end

      let(:renderer) { described_class.new(syntax_renderer: highlighting_renderer) }

      it "passes source lines through the syntax renderer for all lines" do
        result = renderer.render(source_lines, line: 4, column: 8, end_column: 10)
        expect(result).to include("HIGHLIGHTED:<div class=\"foo\">")
        expect(result).to include("HIGHLIGHTED:<body>")
      end
    end

    context "when offense is at line 1 (no lines before)" do
      subject { renderer.render(source_lines, line: 1, column: 2) }

      it "renders only lines from 1 onward with caret and no line 0" do
        # start=max(1,1-2)=1, end=min(7,1+2)=3 → 3 source lines + 1 caret = 4 lines
        expect(subject.lines.count).to eq(4)
        stripped = strip_ansi(subject)
        expect(stripped).not_to match(/\A\s*0 \|/)
        expect(stripped).to include("1 | ")
        expect(stripped).to include("2 | ")
        expect(stripped).to include("3 | ")
        expect(stripped).to include("^")
      end
    end

    context "when offense is at the last line (no lines after)" do
      subject { renderer.render(five_lines, line: 5, column: 3) }

      let(:five_lines) { ["<html>\n", "<body>\n", "<div>\n", "</body>\n", "</html>\n"] }

      it "renders only up to the last line with caret and preceding context" do
        # start=max(1,5-2)=3, end=min(5,5+2)=5 → 3 source lines + 1 caret = 4 lines
        expect(subject.lines.count).to eq(4)
        stripped = strip_ansi(subject)
        expect(stripped).not_to include("6 | ")
        expect(stripped).to include("3 | ")
        expect(stripped).to include("4 | ")
        expect(stripped).to include("5 | ")
        expect(stripped).to include("^")
      end
    end
  end
end
