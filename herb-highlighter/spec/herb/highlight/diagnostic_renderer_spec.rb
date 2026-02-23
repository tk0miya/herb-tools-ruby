# frozen_string_literal: true

RSpec.describe Herb::Highlight::DiagnosticRenderer do
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

  # Subject: offense at line 4, column 8, end_column 10, context_lines 2, tty off
  describe "#render" do
    subject(:rendered) do
      described_class.new(syntax_renderer: plain_syntax_renderer, context_lines: 2, tty: false)
                     .render(source_lines, line: 4, column: 8, end_line: 4, end_column: 10)
    end

    it "outputs the correct number of lines (context + offense + pointer)" do
      # lines 2..6 = 5 source lines + 1 pointer line = 6 output lines
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

    it "uses the arrow prefix on the offense line" do
      plain = strip_ansi(rendered)
      expect(plain).to include("  → ")
    end

    it "uses 4-space prefix on context lines" do
      plain = strip_ansi(rendered)
      lines = plain.lines.reject { |l| l.include?('<div class="foo">') || l.include?("~") }
      expect(lines).to all(start_with("    "))
    end

    it "uses '│' as separator" do
      plain = strip_ansi(rendered)
      expect(plain).to include("│")
    end

    it "uses 3-digit right-justified line numbers" do
      plain = strip_ansi(rendered)
      expect(plain).to match(/  2 │/)
      expect(plain).to match(/  3 │/)
      expect(plain).to match(/  4 │/)
      expect(plain).to match(/  5 │/)
      expect(plain).to match(/  6 │/)
    end

    it "appends a pointer row after the offense line" do
      plain = strip_ansi(rendered)
      lines = plain.lines
      offense_index = lines.index { |l| l.include?('<div class="foo">') }
      pointer_line = lines[offense_index + 1]
      expect(pointer_line).to include("~")
    end

    it "places the pointer at the correct column" do
      plain = strip_ansi(rendered)
      lines = plain.lines
      offense_index = lines.index { |l| l.include?('<div class="foo">') }
      pointer_line = lines[offense_index + 1]
      # TypeScript: pointerSpacing = adjustedColumn + 2 = (column - 1) + 2 = column + 1
      # column=8 → 9 spaces after │
      expect(pointer_line).to match(/│ {9}~/)
    end

    it "produces correct pointer length for multi-column offense" do
      plain = strip_ansi(rendered)
      lines = plain.lines
      offense_index = lines.index { |l| l.include?('<div class="foo">') }
      pointer_line = lines[offense_index + 1]
      # TypeScript: Math.max(1, end.column - start.column) = Math.max(1, 10 - 8) = 2
      expect(pointer_line).to match(/~~/)
      expect(pointer_line).not_to match(/~~~/)
    end

    it "pointer row starts with 8 spaces then │" do
      plain = strip_ansi(rendered)
      lines = plain.lines
      offense_index = lines.index { |l| l.include?('<div class="foo">') }
      pointer_line = lines[offense_index + 1]
      expect(pointer_line).to start_with("        │")
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

    it "still uses structural characters (→, │, ~)" do
      expect(rendered).to include("  → ")
      expect(rendered).to include("│")
      expect(rendered).to include("~")
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

    it "first output line is line 1" do
      plain = strip_ansi(rendered)
      expect(plain.lines.first).to match(/  1 │/)
    end

    it "includes correct number of lines (line 1 + 2 context after + pointer)" do
      # lines 1..3 = 3 source lines + 1 pointer = 4 output lines
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
      expect(plain).not_to match(/  8 │/)
    end

    it "includes correct number of lines (2 context before + last line + pointer)" do
      # lines 5..7 = 3 source lines + 1 pointer = 4 output lines
      expect(rendered.lines.count).to eq(4)
    end
  end

  describe "single-character offense (no end_column)" do
    subject(:rendered) do
      described_class.new(syntax_renderer: plain_syntax_renderer, context_lines: 0, tty: false)
                     .render(source_lines, line: 1, column: 2)
    end

    it "produces a pointer of length 1" do
      pointer_line = rendered.lines[1]
      expect(pointer_line.gsub(/[^│~]/, "")).to eq("│~")
    end
  end

  describe "multi-line offense (end_line differs from line)" do
    subject(:rendered) do
      described_class.new(syntax_renderer: plain_syntax_renderer, context_lines: 0, tty: false)
                     .render(source_lines, line: 2, column: 1, end_line: 3, end_column: 5)
    end

    it "renders a pointer of length 1 for multi-line offense" do
      lines = rendered.lines
      offense_index = lines.index { |l| strip_ansi(l).include?("<body>") }
      pointer_line = lines[offense_index + 1]
      pointer_part = pointer_line.split("│").last&.strip
      expect(pointer_part).to eq("~")
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
