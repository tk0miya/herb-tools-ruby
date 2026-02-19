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

      it "outputs opening tag, text content, and closing tag" do
        expect(subject).to eq("<div>Hello</div>")
      end
    end

    context "with whitespace nodes" do
      let(:source) { "<div class='foo'></div>" }

      it "outputs opening tag with attribute and closing tag" do
        expect(subject).to eq("<div classfoo></div>")
      end
    end

    context "with void element" do
      let(:source) { "<br>" }

      it "outputs void element without closing tag" do
        expect(subject).to eq("<br>")
      end
    end

    context "with simple HTML element" do
      let(:source) { "<div>content</div>" }

      it "outputs opening tag, content, and closing tag" do
        expect(subject).to eq("<div>content</div>")
      end
    end

    context "with HTML element with attributes" do
      let(:source) { "<div class=\"foo\" id=\"bar\">content</div>" }

      it "outputs opening tag with attributes, content, and closing tag" do
        expect(subject).to eq("<div classfoo idbar>content</div>")
      end
    end

    context "with nested elements" do
      let(:source) { "<div><p>nested</p></div>" }

      it "outputs both opening and closing tags for nested elements" do
        expect(subject).to eq("<div><p>nested</p></div>")
      end
    end

    context "with preserved element" do
      context "with multi-line pre element" do
        let(:source) { "<pre>\n  def hello\n    puts 'world'\n  end\n</pre>" }

        it "preserves all newlines and indentation" do
          expect(subject).to include("\n  def hello\n    puts 'world'\n  end\n")
        end
      end

      context "with textarea element" do
        let(:source) { "<textarea>\n  User input\n    with indents\n</textarea>" }

        it "preserves content as-is" do
          expect(subject).to include("\n  User input\n    with indents\n")
        end
      end

      context "with script element" do
        let(:source) { "<script>\n  console.log('test');\n</script>" }

        it "preserves script content with original formatting" do
          expect(subject).to include("\n  console.log('test');\n")
        end
      end

      context "with style element" do
        let(:source) { "<style>\n  .foo { color: red; }\n</style>" }

        it "preserves style content with original formatting" do
          expect(subject).to include("\n  .foo { color: red; }\n")
        end
      end
    end
  end

  describe "#initialize" do
    subject(:printer) do
      described_class.new(indent_width:, max_line_length:, format_context:)
    end

    it "initializes output management fields" do
      expect(printer.instance_variable_get(:@lines)).to eq([])
      expect(printer.instance_variable_get(:@indent_level)).to eq(0)
      expect(printer.instance_variable_get(:@string_line_count)).to eq(0)
    end

    it "initializes context management fields" do
      expect(printer.instance_variable_get(:@inline_mode)).to be false
      expect(printer.instance_variable_get(:@in_conditional_open_tag_context)).to be false
      expect(printer.instance_variable_get(:@current_attribute_name)).to be_nil
      expect(printer.instance_variable_get(:@element_stack)).to eq([])
    end

    it "initializes cache and analysis fields" do
      expect(printer.instance_variable_get(:@element_formatting_analysis)).to eq({})
      expect(printer.instance_variable_get(:@node_is_multiline)).to eq({})
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

    context "with script tag" do
      let(:tag_name) { "script" }

      it { is_expected.to be true }
    end

    context "with style tag" do
      let(:tag_name) { "style" }

      it { is_expected.to be true }
    end

    context "with pre tag" do
      let(:tag_name) { "pre" }

      it { is_expected.to be true }
    end

    context "with textarea tag" do
      let(:tag_name) { "textarea" }

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
