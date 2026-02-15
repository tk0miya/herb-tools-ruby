# frozen_string_literal: true

RSpec.describe Herb::Format::FormatPrinter do
  let(:config) do
    Herb::Config::FormatterConfig.new({
                                        "formatter" => {
                                          "enabled" => true,
                                          "indentWidth" => indent_width,
                                          "maxLineLength" => max_line_length
                                        }
                                      })
  end
  let(:indent_width) { 2 }
  let(:max_line_length) { 80 }
  let(:source) { "" }
  let(:format_context) { Herb::Format::Context.new(file_path: "test.erb", config:, source:) }

  describe ".format" do
    subject { described_class.format(ast, format_context:) }

    let(:ast) { Herb.parse(source, track_whitespace: true) }

    context "with document node" do
      let(:source) { "Hello World" }

      it "visits all children" do
        expect(subject).to eq("Hello World")
      end
    end

    context "with literal nodes" do
      let(:source) { "Plain text" }

      it "preserves literal content" do
        expect(subject).to eq("Plain text")
      end
    end

    context "with HTML text nodes" do
      let(:source) { "<div>Hello</div>" }

      it "outputs text content" do
        expect(subject).to eq("Hello")
      end
    end

    context "with whitespace nodes" do
      let(:source) { "<div class='foo'></div>" }

      it "outputs whitespace between attributes" do
        expect(subject).to eq(" classfoo")
      end
    end
  end

  describe "#indent_string" do
    subject { printer.send(:indent_string, level) }

    let(:printer) do
      described_class.new(indent_width:, max_line_length:, format_context:)
    end

    context "with level 0" do
      let(:level) { 0 }

      it { is_expected.to eq("") }
    end

    context "with level 1" do
      let(:level) { 1 }

      it { is_expected.to eq("  ") }
    end

    context "with custom indent_width" do
      let(:indent_width) { 4 }
      let(:level) { 1 }

      it { is_expected.to eq("    ") }
    end
  end

  describe "#void_element?" do
    subject { printer.send(:void_element?, tag_name) }

    let(:printer) do
      described_class.new(indent_width:, max_line_length:, format_context:)
    end

    context "with void element" do
      let(:tag_name) { "br" }

      it { is_expected.to be true }
    end

    context "with non-void element" do
      let(:tag_name) { "div" }

      it { is_expected.to be false }
    end

    context "with uppercase void element" do
      let(:tag_name) { "BR" }

      it { is_expected.to be true }
    end

    context "with uppercase non-void element" do
      let(:tag_name) { "DIV" }

      it { is_expected.to be false }
    end
  end

  describe "#preserved_element?" do
    subject { printer.send(:preserved_element?, tag_name) }

    let(:printer) do
      described_class.new(indent_width:, max_line_length:, format_context:)
    end

    context "with preserved element" do
      let(:tag_name) { "pre" }

      it { is_expected.to be true }
    end

    context "with non-preserved element" do
      let(:tag_name) { "div" }

      it { is_expected.to be false }
    end

    context "with uppercase preserved element" do
      let(:tag_name) { "PRE" }

      it { is_expected.to be true }
    end

    context "with uppercase non-preserved element" do
      let(:tag_name) { "DIV" }

      it { is_expected.to be false }
    end
  end
end
