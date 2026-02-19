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

  describe "state initialization" do
    let(:printer) { described_class.new(indent_width:, max_line_length:, format_context:) }

    it "initializes @lines as empty array" do
      expect(printer.instance_variable_get(:@lines)).to eq([])
    end

    it "initializes @indent_level to 0" do
      expect(printer.instance_variable_get(:@indent_level)).to eq(0)
    end

    it "initializes @string_line_count to 0" do
      expect(printer.instance_variable_get(:@string_line_count)).to eq(0)
    end

    it "initializes @inline_mode to false" do
      expect(printer.instance_variable_get(:@inline_mode)).to be false
    end

    it "initializes @in_conditional_open_tag_context to false" do
      expect(printer.instance_variable_get(:@in_conditional_open_tag_context)).to be false
    end

    it "initializes @current_attribute_name to nil" do
      expect(printer.instance_variable_get(:@current_attribute_name)).to be_nil
    end

    it "initializes @element_stack as empty array" do
      expect(printer.instance_variable_get(:@element_stack)).to eq([])
    end

    it "initializes @element_formatting_analysis as empty hash" do
      expect(printer.instance_variable_get(:@element_formatting_analysis)).to eq({})
    end

    it "initializes @node_is_multiline as empty hash" do
      expect(printer.instance_variable_get(:@node_is_multiline)).to eq({})
    end
  end

  describe "#capture" do
    let(:printer) { described_class.new(indent_width:, max_line_length:, format_context:) }

    it "returns lines written inside the block as an array" do
      result = printer.send(:capture) do
        printer.send(:push, "hello")
        printer.send(:push, "world")
      end

      expect(result).to eq(%w[hello world])
    end

    it "restores @lines after the block" do
      printer.send(:push, "before")
      printer.send(:capture) { printer.send(:push, "inside") }

      expect(printer.instance_variable_get(:@lines)).to eq(["before"])
    end

    it "restores @inline_mode after the block" do
      printer.instance_variable_set(:@inline_mode, true)
      printer.send(:capture) do
        printer.instance_variable_set(:@inline_mode, false)
      end

      expect(printer.instance_variable_get(:@inline_mode)).to be true
    end

    it "does not affect outer @lines when writing inside capture" do
      printer.send(:push, "outer")
      result = printer.send(:capture) { printer.send(:push, "inner") }

      expect(result).to eq(["inner"])
      expect(printer.instance_variable_get(:@lines)).to eq(["outer"])
    end
  end

  describe "#track_boundary" do
    let(:printer) { described_class.new(indent_width:, max_line_length:, format_context:) }
    let(:node) { Herb.parse("<div>test</div>", track_whitespace: true).value }

    it "records node as multiline when output spans multiple lines" do
      printer.send(:track_boundary, node) do
        printer.send(:push, "line one\n")
        printer.send(:push, "line two")
      end

      expect(printer.instance_variable_get(:@node_is_multiline)[node]).to be true
    end

    it "does not record node when output is single-line" do
      printer.send(:track_boundary, node) do
        printer.send(:push, "single line")
      end

      expect(printer.instance_variable_get(:@node_is_multiline)[node]).to be_nil
    end
  end

  describe "#with_indent" do
    let(:printer) { described_class.new(indent_width:, max_line_length:, format_context:) }

    it "increases @indent_level inside the block" do
      level_inside = nil
      printer.send(:with_indent) { level_inside = printer.instance_variable_get(:@indent_level) }

      expect(level_inside).to eq(1)
    end

    it "restores @indent_level after the block" do
      printer.send(:with_indent) { nil }

      expect(printer.instance_variable_get(:@indent_level)).to eq(0)
    end

    it "supports nesting" do
      levels = []
      printer.send(:with_indent) do
        levels << printer.instance_variable_get(:@indent_level)
        printer.send(:with_indent) do
          levels << printer.instance_variable_get(:@indent_level)
        end
        levels << printer.instance_variable_get(:@indent_level)
      end

      expect(levels).to eq([1, 2, 1])
    end
  end

  describe "#indent" do
    let(:printer) { described_class.new(indent_width:, max_line_length:, format_context:) }

    it "returns empty string at indent level 0" do
      expect(printer.send(:indent)).to eq("")
    end

    it "returns correct spaces at indent level 1" do
      printer.instance_variable_set(:@indent_level, 1)

      expect(printer.send(:indent)).to eq("  ")
    end

    it "returns correct spaces at indent level 2" do
      printer.instance_variable_set(:@indent_level, 2)

      expect(printer.send(:indent)).to eq("    ")
    end

    context "with custom indent_width of 4" do
      let(:indent_width) { 4 }

      it "returns 4 spaces at indent level 1" do
        printer.instance_variable_set(:@indent_level, 1)

        expect(printer.send(:indent)).to eq("    ")
      end
    end
  end

  describe "#push_with_indent" do
    let(:printer) { described_class.new(indent_width:, max_line_length:, format_context:) }

    it "pushes line with indentation at level 1" do
      printer.instance_variable_set(:@indent_level, 1)
      printer.send(:push_with_indent, "hello")

      expect(printer.instance_variable_get(:@lines)).to eq(["  hello"])
    end

    it "pushes line without indentation for whitespace-only line" do
      printer.instance_variable_set(:@indent_level, 2)
      printer.send(:push_with_indent, "   ")

      expect(printer.instance_variable_get(:@lines)).to eq(["   "])
    end

    it "pushes line without indentation at level 0" do
      printer.send(:push_with_indent, "hello")

      expect(printer.instance_variable_get(:@lines)).to eq(["hello"])
    end
  end

  describe "#push_to_last_line" do
    let(:printer) { described_class.new(indent_width:, max_line_length:, format_context:) }

    it "appends text to the last line" do
      printer.send(:push, "hello")
      printer.send(:push_to_last_line, " world")

      expect(printer.instance_variable_get(:@lines)).to eq(["hello world"])
    end

    it "starts a new line when @lines is empty" do
      printer.send(:push_to_last_line, "hello")

      expect(printer.instance_variable_get(:@lines)).to eq(["hello"])
    end

    it "does not add a new entry to @lines" do
      printer.send(:push, "line1")
      printer.send(:push, "line2")
      printer.send(:push_to_last_line, " appended")

      expect(printer.instance_variable_get(:@lines).length).to eq(2)
      expect(printer.instance_variable_get(:@lines).last).to eq("line2 appended")
    end
  end

  describe "#push" do
    let(:printer) { described_class.new(indent_width:, max_line_length:, format_context:) }

    it "adds line to @lines" do
      printer.send(:push, "hello")

      expect(printer.instance_variable_get(:@lines)).to eq(["hello"])
    end

    it "increments @string_line_count when line contains newline" do
      printer.send(:push, "hello\n")

      expect(printer.instance_variable_get(:@string_line_count)).to eq(1)
    end

    it "does not increment @string_line_count when line has no newline" do
      printer.send(:push, "hello")

      expect(printer.instance_variable_get(:@string_line_count)).to eq(0)
    end

    it "accumulates multiple lines" do
      printer.send(:push, "line1")
      printer.send(:push, "line2")

      expect(printer.instance_variable_get(:@lines)).to eq(%w[line1 line2])
    end
  end
end
