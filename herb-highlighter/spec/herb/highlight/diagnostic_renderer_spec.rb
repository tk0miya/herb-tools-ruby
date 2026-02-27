# frozen_string_literal: true

RSpec.describe Herb::Highlight::DiagnosticRenderer do
  def strip_ansi(str)
    str.gsub(/\e\[[^m]*m/, "")
  end

  # A 5-line source file for most tests
  let(:source_lines) do
    [
      "<html>\n",
      "<body>\n",
      "<div>\n",
      '<div class="foo">',
      "</body>\n"
    ]
  end

  # Mock SyntaxRenderer that passes content through unchanged
  let(:passthrough_renderer) do
    instance = instance_double(Herb::Highlight::SyntaxRenderer)
    allow(instance).to receive(:render) { _1 }
    instance
  end

  describe "#render" do
    context "with offense in the middle (context_lines: 2, offense at line 3)" do
      subject { renderer.render(source_lines, line: 3, column: 1) }

      let(:renderer) { described_class.new(syntax_renderer: passthrough_renderer, context_lines: 2) }

      it "renders all context lines with arrow prefix on the offense line and pointer below" do
        # start=1, end_display=5, width=1; lines 1,2,3(offense),pointer,4,5
        plain = strip_ansi(subject)
        expected = [
          "    1 │ <html>",
          "    2 │ <body>",
          "  → 3 │ <div>",
          "      │ ~",
          "    4 │ <div class=\"foo\">",
          "    5 │ </body>"
        ].join("\n")
        expect(plain).to include(expected)
      end
    end

    context "with tty: true (default), error severity, offense at line 2" do
      subject { renderer.render(source_lines, line: 2, column: 1) }

      let(:renderer) { described_class.new(syntax_renderer: passthrough_renderer, context_lines: 1) }

      it "colors context line numbers gray, offense arrow and pointer brightRed, offense number bold" do
        lines = subject.lines
        # Line 1 is a context line (before offense at line 2): number is gray
        expect(lines[0]).to include("\e[90m") # gray
        # Line 2 is the offense line: → prefix is brightRed, number is bold
        expect(lines[1]).to include("\e[91m") # brightRed (error: → prefix)
        expect(lines[1]).to include("\e[1m")  # bold (offense line number)
        # Pointer row: ~ is brightRed
        expect(lines[2]).to include("\e[91m") # brightRed
        expect(strip_ansi(lines[2])).to include("~")
      end
    end

    context "with tty: false" do
      subject { renderer.render(source_lines, line: 2, column: 1) }

      let(:renderer) { described_class.new(syntax_renderer: passthrough_renderer, context_lines: 1, tty: false) }

      it "produces plain text output without ANSI codes" do
        expect(subject).not_to match(/\e\[[^m]*m/)
        expected = [
          "    1 │ <html>",
          "  → 2 │ <body>",
          "      │ ~",
          "    3 │ <div>"
        ].join("\n")
        expect(subject).to include(expected)
      end
    end

    context "with offense at line 1 (no lines before)" do
      subject { renderer.render(source_lines, line: 1, column: 1) }

      let(:renderer) { described_class.new(syntax_renderer: passthrough_renderer, context_lines: 2) }

      it "starts at line 1 with pointer immediately after the offense line" do
        # start=max(1,1-2)=1; end_display=min(5,1+2)=3; lines 1(offense),pointer,2,3
        plain = strip_ansi(subject)
        expected = [
          "  → 1 │ <html>",
          "      │ ~",
          "    2 │ <body>",
          "    3 │ <div>"
        ].join("\n")
        expect(plain).to include(expected)
      end
    end

    context "with offense at last line (no lines after)" do
      subject { renderer.render(source_lines, line: 5, column: 1) }

      let(:renderer) { described_class.new(syntax_renderer: passthrough_renderer, context_lines: 2) }

      it "ends with pointer after the last line" do
        # start=max(1,5-2)=3; end_display=min(5,5+2)=5; lines 3,4,5(offense),pointer
        plain = strip_ansi(subject)
        expected = [
          "    3 │ <div>",
          "    4 │ <div class=\"foo\">",
          "  → 5 │ </body>",
          "      │ ~"
        ].join("\n")
        expect(plain).to include(expected)
      end
    end

    context "with multi-column offense (end_column specified)" do
      subject { renderer.render(source_lines, line: 4, column: 6, end_column: 10) }

      let(:renderer) { described_class.new(syntax_renderer: passthrough_renderer, context_lines: 0) }

      it "renders a pointer spanning the offense width at the correct column" do
        plain = strip_ansi(subject)
        # pointer_length = [10 - 6 + 1, 1].max = 5
        # column_offset = [6 - 1, 0].max = 5; with 1 space after │: 6 spaces then 5 tildes
        expected = [
          "  → 4 │ <div class=\"foo\">",
          "      │      ~~~~~"
        ].join("\n")
        expect(plain).to include(expected)
        expect(plain.lines[1]).to match(/│ {6}~{5}/)
      end
    end

    context "with single-char offense (no end_column given)" do
      subject { renderer.render(source_lines, line: 1, column: 3) }

      let(:renderer) { described_class.new(syntax_renderer: passthrough_renderer, context_lines: 0) }

      it "renders exactly one tilde pointer at the correct column" do
        plain = strip_ansi(subject)
        expected = [
          "  → 1 │ <html>",
          "      │   ~"
        ].join("\n")
        expect(plain).to include(expected)
        expect(plain.lines[1].count("~")).to eq(1)
      end
    end

    context "with multi-line offense (end_line != line)" do
      subject { renderer.render(source_lines, line: 2, column: 1, end_line: 3, end_column: 5) }

      let(:renderer) { described_class.new(syntax_renderer: passthrough_renderer, context_lines: 0) }

      it "renders exactly one tilde regardless of end_column" do
        plain = strip_ansi(subject)
        expected = [
          "  → 2 │ <body>",
          "      │ ~"
        ].join("\n")
        expect(plain).to include(expected)
        expect(plain.lines[1].count("~")).to eq(1)
      end
    end

    context "with warning severity" do
      subject { renderer.render(source_lines, line: 2, column: 1, severity: "warning") }

      let(:renderer) { described_class.new(syntax_renderer: passthrough_renderer, context_lines: 0) }

      it "uses brightYellow color for the offense prefix and pointer" do
        lines = subject.lines
        expect(lines[0]).to include("\e[93m") # brightYellow for → prefix
        expect(lines[1]).to include("\e[93m") # brightYellow for ~ pointer
      end
    end

    context "with syntax-highlighted content (mock SyntaxRenderer)" do
      subject { renderer.render(source_lines, line: 1, column: 1) }

      let(:coloring_renderer) do
        instance = instance_double(Herb::Highlight::SyntaxRenderer)
        allow(instance).to receive(:render) { "HIGHLIGHTED:#{_1}" }
        instance
      end

      let(:renderer) { described_class.new(syntax_renderer: coloring_renderer, context_lines: 0) }

      it "passes source content through the syntax renderer" do
        expect(strip_ansi(subject)).to include("HIGHLIGHTED:<html>")
      end
    end

    context "with right-justified line numbers (multi-digit file)" do
      subject { renderer.render(source_lines, line: 10, column: 1) }

      let(:source_lines) { Array.new(15) { "line #{_1 + 1}\n" } }
      let(:renderer) { described_class.new(syntax_renderer: passthrough_renderer, context_lines: 2) }

      it "right-justifies line numbers to the width of end_display_line" do
        plain = strip_ansi(subject)
        # end_display = min(15, 12) = 12; width = "12".length = 2
        # context lines 8 and 9 right-justified to 2 chars; pointer has 2 spaces for width
        expected = [
          "     8 │ line 8",
          "     9 │ line 9",
          "  → 10 │ line 10",
          "       │ ~",
          "    11 │ line 11",
          "    12 │ line 12"
        ].join("\n")
        expect(plain).to include(expected)
      end
    end
  end
end
