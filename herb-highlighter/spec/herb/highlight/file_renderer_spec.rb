# frozen_string_literal: true

RSpec.describe Herb::Highlight::FileRenderer do
  def strip_ansi(str)
    str.gsub(/\e\[[^m]*m/, "")
  end

  let(:passthrough_renderer) do
    instance = instance_double(Herb::Highlight::SyntaxRenderer)
    allow(instance).to receive(:render) { _1 }
    instance
  end

  describe "#render" do
    subject do
      described_class.new(syntax_renderer: passthrough_renderer, tty:).render(source, focus_line:)
    end

    let(:source) { "<html>\n<body>\n<div>hello</div>\n</body>\n</html>\n" }
    let(:tty) { true }
    let(:focus_line) { nil }

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
  end
end
