# frozen_string_literal: true

RSpec.describe Herb::Highlighter::Highlighter do
  let(:syntax_renderer) { instance_double(Herb::Highlighter::SyntaxRenderer) }
  let(:file_renderer) { instance_double(Herb::Highlighter::FileRenderer) }
  let(:diagnostic_renderer) { instance_double(Herb::Highlighter::DiagnosticRenderer) }

  before do
    allow(Herb::Highlighter::SyntaxRenderer).to receive(:new).and_return(syntax_renderer)
    allow(Herb::Highlighter::FileRenderer).to receive(:new).and_return(file_renderer)
    allow(Herb::Highlighter::DiagnosticRenderer).to receive(:new).and_return(diagnostic_renderer)
  end

  describe "#highlight_source" do
    let(:source) { "<html>\n<body>\n</body>\n</html>\n" }

    before { allow(file_renderer).to receive(:render).and_return("rendered") }

    context "with explicit focus_line and context_lines" do
      it "forwards them to FileRenderer#render" do
        described_class.new(context_lines: 3).highlight_source(source, focus_line: 2)
        expect(file_renderer).to have_received(:render).with(source, focus_line: 2, context_lines: 3)
      end
    end

    context "with default arguments" do
      it "uses nil focus_line and default context_lines and returns the rendered result" do
        result = described_class.new.highlight_source(source)
        expect(file_renderer).to have_received(:render).with(source, focus_line: nil, context_lines: 2)
        expect(result).to eq("rendered")
      end
    end
  end

  describe "#render_diagnostic" do
    let(:source_lines) { ["<html>\n", "<body>\n", "<div>\n"] }

    before { allow(diagnostic_renderer).to receive(:render).and_return("rendered diagnostic") }

    it "delegates to DiagnosticRenderer#render with all arguments" do
      described_class.new.render_diagnostic(source_lines, line: 2, column: 3, end_line: 2, end_column: 7)
      expect(diagnostic_renderer).to have_received(:render)
        .with(source_lines, line: 2, column: 3, end_line: 2, end_column: 7)
    end

    it "passes nil end_line and end_column by default" do
      described_class.new.render_diagnostic(source_lines, line: 2, column: 3)
      expect(diagnostic_renderer).to have_received(:render)
        .with(source_lines, line: 2, column: 3, end_line: nil, end_column: nil)
    end

    it "returns the result from DiagnosticRenderer#render" do
      expect(described_class.new.render_diagnostic(source_lines, line: 2, column: 3)).to eq("rendered diagnostic")
    end
  end
end
