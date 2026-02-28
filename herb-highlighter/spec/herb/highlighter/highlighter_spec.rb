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

  describe "#initialize" do
    it "creates SyntaxRenderer with the given theme_name" do
      described_class.new(theme_name: "my-theme")
      expect(Herb::Highlighter::SyntaxRenderer).to have_received(:new).with(theme_name: "my-theme")
    end

    it "creates FileRenderer with the SyntaxRenderer instance and tty" do
      described_class.new(tty: false)
      expect(Herb::Highlighter::FileRenderer).to have_received(:new).with(syntax_renderer:, tty: false)
    end

    it "creates DiagnosticRenderer with the SyntaxRenderer instance, context_lines, and tty" do
      described_class.new(context_lines: 5, tty: false)
      expect(Herb::Highlighter::DiagnosticRenderer).to have_received(:new)
        .with(syntax_renderer:, context_lines: 5, tty: false)
    end
  end

  describe "#highlight_source" do
    let(:source) { "<html>\n<body>\n</body>\n</html>\n" }

    before { allow(file_renderer).to receive(:render).and_return("rendered") }

    it "delegates to FileRenderer#render with source and focus_line" do
      described_class.new.highlight_source(source, focus_line: 2)
      expect(file_renderer).to have_received(:render).with(source, focus_line: 2)
    end

    it "passes nil focus_line when not specified" do
      described_class.new.highlight_source(source)
      expect(file_renderer).to have_received(:render).with(source, focus_line: nil)
    end

    it "returns the result from FileRenderer#render" do
      expect(described_class.new.highlight_source(source)).to eq("rendered")
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
