# frozen_string_literal: true

RSpec.describe Herb::Highlight::DiagnosticRenderer do
  # Helper to strip ANSI escape sequences from a string
  def strip_ansi(str)
    str.gsub(/\e\[[^m]*m/, "")
  end

  let(:source_lines) do
    [
      "<html>",
      "<body>",
      "<div>",
      '<div class="foo">',
      "</div>",
      "</body>",
      "</html>"
    ]
  end

  let(:plain_syntax_renderer) { Herb::Highlight::SyntaxRenderer.new }

  describe "#render" do
    subject(:rendered) do
      described_class.new(syntax_renderer: plain_syntax_renderer, context_lines: 2, tty: false)
                     .render(source_lines, line: 4, column: 8, end_line: 4, end_column: 10)
    end

    it "outputs the correct number of lines (context + offense + caret)" do
      # lines 2..6 = 5 source lines + 1 caret line = 6 output lines
      expect(rendered.lines.count).to eq(6)
    end

    it "includes context lines before the offense" do
      plain = strip_ansi(rendered)
      expect(plain).to include("<body>")
      expect(plain).to include("<div>")
    end

    it "includes context lines after the offense" do
      plain = strip_ansi(rendered)
      expect(plain).to include("</div>")
    end

    it "includes the offense line" do
      plain = strip_ansi(rendered)
      expect(plain).to include('<div class="foo">')
    end

    it "includes correct line numbers" do
      plain = strip_ansi(rendered)
      expect(plain).to include("2 |")
      expect(plain).to include("3 |")
      expect(plain).to include("4 |")
      expect(plain).to include("5 |")
      expect(plain).to include("6 |")
    end

    it "right-justifies line numbers" do
      plain = strip_ansi(rendered)
      # All numbers should be padded to the same width (1 char for single-digit)
      expect(plain).to match(/  \d \|/)
    end

    it "appends a caret row after the offense line" do
      plain = strip_ansi(rendered)
      lines = plain.lines
      # offense line is at index 2 (lines 2,3,4,caret,5,6 = offense at position 2, caret at 3)
      offense_index = lines.index { |l| l.include?('<div class="foo">') }
      caret_line = lines[offense_index + 1]
      expect(caret_line).to include("^")
    end

    it "places the caret at the correct column" do
      plain = strip_ansi(rendered)
      lines = plain.lines
      offense_index = lines.index { |l| l.include?('<div class="foo">') }
      caret_line = lines[offense_index + 1]
      # The caret row is "  <width spaces> | <column-1 spaces>^^^"
      # column=8 → 7 spaces before the first ^, plus 1 space from " | " = 8 spaces after |
      expect(caret_line).to match(/\| {8}\^/)
    end

    it "produces correct caret length for multi-column offense" do
      plain = strip_ansi(rendered)
      lines = plain.lines
      offense_index = lines.index { |l| l.include?('<div class="foo">') }
      caret_line = lines[offense_index + 1]
      # end_column=10, column=8 → length = (10-8)+1 = 3
      expect(caret_line).to include("^^^")
    end
  end

  describe "with tty: false" do
    subject(:rendered) do
      described_class.new(syntax_renderer: plain_syntax_renderer, context_lines: 2, tty: false)
                     .render(source_lines, line: 4, column: 1)
    end

    it "contains no ANSI escape codes" do
      expect(rendered).not_to match(/\e\[/)
    end
  end

  describe "with tty: true" do
    subject(:rendered) do
      described_class.new(syntax_renderer: plain_syntax_renderer, context_lines: 2, tty: true)
                     .render(source_lines, line: 4, column: 1)
    end

    it "contains ANSI escape codes for offense line coloring" do
      expect(rendered).to match(/\e\[/)
    end
  end

  describe "when offense is at line 1" do
    subject(:rendered) do
      described_class.new(syntax_renderer: plain_syntax_renderer, context_lines: 2, tty: false)
                     .render(source_lines, line: 1, column: 1)
    end

    it "does not include lines before line 1" do
      plain = strip_ansi(rendered)
      lines = plain.lines
      # First line should be line 1
      expect(lines.first).to include("1 |")
    end

    it "includes correct number of lines (line 1 + 2 context after + caret)" do
      # lines 1..3 = 3 source lines + 1 caret = 4 output lines
      expect(rendered.lines.count).to eq(4)
    end
  end

  describe "when offense is at the last line" do
    subject(:rendered) do
      described_class.new(syntax_renderer: plain_syntax_renderer, context_lines: 2, tty: false)
                     .render(source_lines, line: 7, column: 1)
    end

    it "does not include lines after the last line" do
      plain = strip_ansi(rendered)
      expect(plain).not_to include("8 |")
    end

    it "includes correct number of lines (2 context before + last line + caret)" do
      # lines 5..7 = 3 source lines + 1 caret = 4 output lines
      expect(rendered.lines.count).to eq(4)
    end
  end

  describe "single-character offense (no end_column)" do
    subject(:rendered) do
      described_class.new(syntax_renderer: plain_syntax_renderer, context_lines: 0, tty: false)
                     .render(source_lines, line: 1, column: 2)
    end

    it "produces a caret of length 1" do
      lines = rendered.lines
      caret_line = lines[1]
      expect(caret_line.gsub(/\s/, "")).to eq("|^")
    end
  end

  describe "multi-line offense (end_line differs from line)" do
    subject(:rendered) do
      described_class.new(syntax_renderer: plain_syntax_renderer, context_lines: 0, tty: false)
                     .render(source_lines, line: 2, column: 1, end_line: 3, end_column: 5)
    end

    it "renders a caret of length 1 for multi-line offense" do
      lines = rendered.lines
      offense_index = lines.index { |l| strip_ansi(l).include?("<body>") }
      caret_line = lines[offense_index + 1]
      caret_part = caret_line.split("|").last&.strip
      expect(caret_part).to eq("^")
    end
  end

  describe "source content syntax highlighting" do
    it "delegates content rendering to syntax_renderer" do
      mock_renderer = instance_double(Herb::Highlight::SyntaxRenderer)
      allow(mock_renderer).to receive(:render).and_return("HIGHLIGHTED")

      renderer = described_class.new(syntax_renderer: mock_renderer, context_lines: 0, tty: false)
      output = renderer.render(["<p>hello</p>"], line: 1, column: 1)

      expect(output).to include("HIGHLIGHTED")
      expect(mock_renderer).to have_received(:render).with("<p>hello</p>")
    end
  end
end
