# frozen_string_literal: true

RSpec.describe Herb::Format::FormatPrinter do
  let(:indent_width) { 2 }
  let(:max_line_length) { 80 }
  let(:source) { "" }
  let(:format_context) { build(:context, source:, indent_width:, max_line_length:) }

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

  describe "#render_multiline_attributes" do
    let(:printer) do
      Class.new(described_class) do
        public :render_multiline_attributes
        attr_accessor :indent_level
      end.new(indent_width:, max_line_length:, format_context:)
    end

    def open_tag_children(source)
      ast = Herb.parse(source, track_whitespace: true)
      element = ast.value.children.first
      element.open_tag.child_nodes
    end

    context "with multiple attributes" do
      subject { printer.capture { printer.render_multiline_attributes("button", open_tag_children(source), false) } }

      let(:source) { '<button type="submit" class="btn" disabled></button>' }

      it "outputs tag name, each attribute indented, and closing >" do
        expect(subject).to eq(["<button", '  type="submit"', '  class="btn"', "  disabled", ">"])
      end
    end

    context "with void element" do
      subject { printer.capture { printer.render_multiline_attributes("input", open_tag_children(source), true) } }

      let(:source) { '<input type="text" name="email">' }

      it "outputs tag name, each attribute indented, and closing />" do
        expect(subject).to eq(["<input", '  type="text"', '  name="email"', "/>"])
      end
    end

    context "with indented context" do
      subject { printer.capture { printer.render_multiline_attributes("div", open_tag_children(source), false) } }

      let(:source) { '<div class="foo" id="bar"></div>' }

      before { printer.indent_level = 1 }

      it "applies current indent to all lines" do
        expect(subject).to eq(["  <div", '    class="foo"', '    id="bar"', "  >"])
      end
    end

    context "with no children" do
      subject { printer.capture { printer.render_multiline_attributes("div", [], false) } }

      it "outputs tag name and closing > with no attributes" do
        expect(subject).to eq(["<div", ">"])
      end
    end

    context "with only whitespace children" do
      subject { printer.capture { printer.render_multiline_attributes("div", open_tag_children(source), false) } }

      let(:source) { "<div ></div>" }

      it "outputs tag name and closing > skipping whitespace nodes" do
        expect(subject).to eq(["<div", ">"])
      end
    end

    context "with ERB expression tag among children" do
      pending "implement after Task 2.21b (ERB tag rendering in attributes) — tracked in Task 2.21c"
    end

    context "with herb:disable comment in open tag" do
      pending "implement after Task 2.28 (ERB Comment Node) — tracked in Task 2.28b"
    end

    context "with ERB tag in attribute value" do
      pending "implement after Task 2.28 (ERB Comment Node) — tracked in Task 2.28b"
    end

    context "with multiple herb:disable comments" do
      pending "implement after Task 2.28 (ERB Comment Node) — tracked in Task 2.28b"
    end

    context "with herb:disable comment and no other attributes" do
      pending "implement after Task 2.28 (ERB Comment Node) — tracked in Task 2.28b"
    end
  end
end
