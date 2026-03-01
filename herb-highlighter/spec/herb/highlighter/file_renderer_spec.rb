# frozen_string_literal: true

RSpec.describe Herb::Highlighter::FileRenderer do
  def strip_ansi(str)
    str.gsub(/\e\[[^m]*m/, "")
  end

  let(:passthrough_renderer) do
    instance = instance_double(Herb::Highlighter::SyntaxRenderer)
    allow(instance).to receive(:render) { _1 }
    instance
  end

  describe "#render" do
    subject do
      described_class.new(syntax_renderer: passthrough_renderer, tty:).render(source, focus_line:, context_lines:)
    end

    let(:source) { "<html>\n<body>\n<div>hello</div>\n</body>\n</html>\n" }
    let(:tty) { true }
    let(:focus_line) { nil }
    let(:context_lines) { 2 }

    context "with a 5-line source and no focus" do
      it "renders all lines with sequential line numbers, each ending with a newline, with gray ANSI codes" do
        plain = strip_ansi(subject)
        expect(subject.lines.count).to eq(5)
        expect(plain).to include("    1 │ <html>")
        expect(plain).to include("    2 │ <body>")
        expect(plain).to include("    3 │ <div>hello</div>")
        expect(plain).to include("    4 │ </body>")
        expect(plain).to include("    5 │ </html>")
        expect(subject.lines).to all(end_with("\n"))
        expect(subject.lines.first).to include("\e[90m") # gray line numbers
      end
    end

    context "with tty: false" do
      let(:tty) { false }

      it "produces plain text output with correct line numbers and content" do
        expect(subject).not_to match(/\e\[[^m]*m/)
        expect(subject).to include("    1 │ <html>")
        expect(subject).to include("    5 │ </html>")
      end
    end

    context "with focus_line specified" do
      let(:focus_line) { 3 }

      it "applies cyan arrow and bold line number to the focus line and gray to all other lines" do
        lines = subject.lines
        expect(lines[2]).to include("\e[36m") # cyan arrow prefix on focus line
        expect(lines[2]).to include("\e[1m")  # bold line number on focus line
        expect(lines[0]).to include("\e[90m") # gray on context lines
        expect(lines[4]).to include("\e[90m")
        expect(strip_ansi(subject)).to include("  → 3 │ <div>hello</div>")
      end
    end

    context "with empty source" do
      let(:source) { "" }

      it "returns an empty string" do
        expect(subject).to eq("")
      end
    end

    context "with single-line source" do
      let(:source) { "<html>\n" }

      it "renders one line with width-1 line number" do
        expect(strip_ansi(subject)).to eq("    1 │ <html>\n")
      end
    end

    context "with multi-digit line count (right-justified line numbers)" do
      let(:source) { Array.new(12) { "line #{_1 + 1}\n" }.join }

      it "right-justifies line numbers to the width of the total line count" do
        plain = strip_ansi(subject)
        # Width should be 2 (for "12"); line 1 padded to " 1", line 12 not padded
        expect(plain).to include("     1 │ line 1")
        expect(plain).to include("    12 │ line 12")
      end
    end

    context "with focus_line and tty: false" do
      let(:tty) { false }
      let(:focus_line) { 2 }

      it "produces no ANSI codes even for the focus line, with arrow prefix on focus line" do
        expect(subject).not_to match(/\e\[[^m]*m/)
        expect(subject).to include("  → 2 │ <body>")
      end
    end

    context "with focus_line and context_lines filtering" do
      let(:source) { "line one\nline two\nline three\nline four\nline five\n" }

      context "with focus within normal range (focus=3, context_lines=1)" do
        let(:focus_line) { 3 }
        let(:context_lines) { 1 }

        it "renders only lines 2-4 with arrow on line 3" do
          plain = strip_ansi(subject)
          expect(plain).to include("  → 3 │ line three")
          expect(plain).to include("    2 │ line two")
          expect(plain).to include("    4 │ line four")
          expect(plain).not_to include("    1 │")
          expect(plain).not_to include("    5 │")
          expect(subject.lines.count).to eq(3)
        end
      end

      context "with focus clamped to start (focus=1, context_lines=2)" do
        let(:focus_line) { 1 }
        let(:context_lines) { 2 }

        it "renders only lines 1-3 with arrow on line 1" do
          plain = strip_ansi(subject)
          expect(plain).to include("  → 1 │ line one")
          expect(plain).to include("    2 │ line two")
          expect(plain).to include("    3 │ line three")
          expect(plain).not_to include("    4 │")
          expect(subject.lines.count).to eq(3)
        end
      end

      context "with focus clamped to end (focus=5, context_lines=2)" do
        let(:focus_line) { 5 }
        let(:context_lines) { 2 }

        it "renders only lines 3-5 with arrow on line 5" do
          plain = strip_ansi(subject)
          expect(plain).to include("  → 5 │ line five")
          expect(plain).to include("    4 │ line four")
          expect(plain).to include("    3 │ line three")
          expect(plain).not_to include("    2 │")
          expect(subject.lines.count).to eq(3)
        end
      end

      context "without focus_line (context_lines has no filtering effect)" do
        let(:focus_line) { nil }
        let(:context_lines) { 1 }

        it "renders all 5 lines" do
          expect(subject.lines.count).to eq(5)
        end
      end
    end
  end
end
