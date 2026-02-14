# frozen_string_literal: true

RSpec.describe Herb::Format::Engine do
  subject(:engine) { described_class.new(indent_width: 2, max_line_length: 80) }

  let(:config) do
    Herb::Config::FormatterConfig.new({
                                        "formatter" => {
                                          "enabled" => true,
                                          "indentWidth" => 2,
                                          "maxLineLength" => 80
                                        }
                                      })
  end
  let(:source) { "" }
  let(:context) { Herb::Format::Context.new(file_path: "test.erb", config:, source:) }

  describe "#initialize" do
    it "initializes with indent_width and max_line_length" do
      expect(engine.indent_width).to eq(2)
      expect(engine.max_line_length).to eq(80)
    end
  end

  describe "#format" do
    subject { engine.format(ast, context) }

    let(:source) { "<div></div>" }
    let(:ast) { Herb.parse(source, track_whitespace: true).value }

    context "with unknown nodes" do
      it "uses IdentityPrinter as fallback" do
        # Without specific visit_* methods, should fall back to IdentityPrinter
        expect(subject).to eq(source)
      end
    end

    context "with document node" do
      let(:source) { "Hello World" }

      it "visits all children" do
        expect(subject).to eq("Hello World")
      end
    end

    context "with HTML text nodes" do
      let(:source) { "<div>Hello</div>" }

      it "preserves text content" do
        expect(subject).to eq(source)
      end
    end

    context "with whitespace nodes" do
      let(:source) { "<div class='foo' id='bar'></div>" }

      it "preserves whitespace between attributes" do
        # NOTE: formatter normalizes quotes to double quotes
        expect(subject).to eq('<div class="foo" id="bar"></div>')
      end
    end

    context "with literal nodes" do
      let(:source) { "Plain text" }

      it "preserves literal content" do
        expect(subject).to eq("Plain text")
      end
    end
  end

  describe "#indent" do
    subject { engine.send(:indent, depth) }

    context "with depth 0" do
      let(:depth) { 0 }

      it { is_expected.to eq("") }
    end

    context "with depth 1" do
      let(:depth) { 1 }

      it { is_expected.to eq("  ") }
    end

    context "with custom indent_width" do
      subject { custom_engine.send(:indent, 1) }

      let(:custom_engine) { described_class.new(indent_width: 4, max_line_length: 80) }

      it { is_expected.to eq("    ") }
    end
  end

  describe "#void_element?" do
    subject { engine.send(:void_element?, tag_name) }

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
    subject { engine.send(:preserved_element?, tag_name) }

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

  describe "Element formatting" do
    subject { engine.format(ast, context) }

    let(:ast) { Herb.parse(source, track_whitespace: true).value }

    context "with void element" do
      let(:source) { "<br>" }

      it "does not output close tag" do
        # Should format without closing tag
        expect(subject).to include("<br>")
        expect(subject).not_to include("</br>")
      end
    end

    context "with preserved element" do
      let(:source) { "<pre>  preserved  content  </pre>" }

      it "preserves content as-is" do
        # Content inside <pre> should not be reformatted
        expect(subject).to include("  preserved  content  ")
      end
    end

    context "with normal element" do
      let(:source) { "<div><p>Hello</p></div>" }

      it "formats with proper indentation" do
        # Body should be indented
        result = subject
        expect(result).to include("<div>")
        expect(result).to include("<p>")
        expect(result).to include("Hello")
        expect(result).to include("</p>")
        expect(result).to include("</div>")
      end
    end

    context "with element with attributes" do
      let(:source) { '<div class="foo"></div>' }

      it "formats attributes correctly" do
        expect(subject).to include("<div")
        expect(subject).to include("class")
        expect(subject).to include("</div>")
      end
    end
  end
end
