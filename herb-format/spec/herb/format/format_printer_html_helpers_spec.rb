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

  describe "#build_content_units_with_nodes" do
    subject { printer.send(:build_content_units_with_nodes, children) }

    let(:printer) do
      described_class.new(indent_width:, max_line_length:, format_context:)
    end

    context "with a text node" do
      let(:children) do
        Herb.parse("Hello world", track_whitespace: true).value.children
            .select { _1.is_a?(Herb::AST::HTMLTextNode) }
      end

      it "returns a :text ContentUnit with the text content" do
        expect(subject.length).to eq(1)
        unit, = subject.first
        expect(unit.type).to eq(:text)
        expect(unit.content).to eq("Hello world")
        expect(unit.is_atomic).to be(false)
        expect(unit.breaks_flow).to be(false)
      end

      it "associates the original node" do
        _, node = subject.first
        expect(node).to be_a(Herb::AST::HTMLTextNode)
      end
    end

    context "with an ERB content node" do
      let(:children) do
        Herb.parse("<%= @user.name %>", track_whitespace: true).value.children
            .select { _1.is_a?(Herb::AST::ERBContentNode) }
      end

      it "returns an :erb ContentUnit" do
        expect(subject.length).to eq(1)
        unit, = subject.first
        expect(unit.type).to eq(:erb)
        expect(unit.is_atomic).to be(true)
        expect(unit.breaks_flow).to be(false)
        expect(unit.is_herb_disable).to be(false)
      end

      it "contains the formatted ERB string" do
        unit, = subject.first
        expect(unit.content).to eq("<%= @user.name %>")
      end

      it "associates the original node" do
        _, node = subject.first
        expect(node).to be_a(Herb::AST::ERBContentNode)
      end
    end

    context "with a herb:disable ERB comment node" do
      let(:children) do
        Herb.parse("<%# herb:disable %>", track_whitespace: true).value.children
            .select { _1.is_a?(Herb::AST::ERBContentNode) }
      end

      it "marks the unit as is_herb_disable" do
        expect(subject.length).to eq(1)
        unit, = subject.first
        expect(unit.type).to eq(:erb)
        expect(unit.is_herb_disable).to be(true)
      end
    end

    context "with an inline HTML element" do
      let(:children) do
        Herb.parse("<span>hello</span>", track_whitespace: true).value.children
            .select { _1.is_a?(Herb::AST::HTMLElementNode) }
      end

      it "returns an :inline ContentUnit that is atomic" do
        expect(subject.length).to eq(1)
        unit, = subject.first
        expect(unit.type).to eq(:inline)
        expect(unit.is_atomic).to be(true)
        expect(unit.breaks_flow).to be(false)
      end

      it "contains the rendered element string" do
        unit, = subject.first
        expect(unit.content).to eq("<span>hello</span>")
      end
    end

    context "with a block HTML element" do
      let(:children) do
        Herb.parse("<div>content</div>", track_whitespace: true).value.children
            .select { _1.is_a?(Herb::AST::HTMLElementNode) }
      end

      it "returns a :block ContentUnit that breaks flow" do
        expect(subject.length).to eq(1)
        unit, = subject.first
        expect(unit.type).to eq(:block)
        expect(unit.is_atomic).to be(true)
        expect(unit.breaks_flow).to be(true)
      end

      it "associates the original node for later re-visiting" do
        _, node = subject.first
        expect(node).to be_a(Herb::AST::HTMLElementNode)
      end
    end

    context "with whitespace-only text nodes" do
      let(:children) do
        Herb.parse("  \n  ", track_whitespace: true).value.children
            .select { _1.is_a?(Herb::AST::HTMLTextNode) }
      end

      it "includes whitespace text as a :text unit (skipping is left to caller)" do
        # WhitespaceNode is skipped, but HTMLTextNode whitespace is included as :text
        # so callers can decide how to handle it
        subject.each do |(unit, _)|
          expect(unit.type).to eq(:text)
        end
      end
    end

    context "with mixed nodes" do
      let(:source_text) { "Hello <span>world</span> <div>block</div> <%= foo %>" }
      let(:children) do
        Herb.parse(source_text, track_whitespace: true).value.children
      end

      it "classifies each node correctly" do
        types = subject.map { |(unit, _)| unit.type }
        expect(types).to include(:text)
        expect(types).to include(:inline)
        expect(types).to include(:block)
        expect(types).to include(:erb)
      end
    end
  end

  describe "#should_add_spacing_between_siblings?" do
    subject { printer.send(:should_add_spacing_between_siblings?, nil, siblings, current_index) }

    let(:printer) { described_class.new(indent_width:, max_line_length:, format_context:) }

    context "when there is no previous meaningful sibling" do
      let(:siblings) do
        Herb.parse("<div></div>", track_whitespace: true).value.children
            .reject { _1.is_a?(Herb::AST::WhitespaceNode) }
      end
      let(:current_index) { 0 }

      it { is_expected.to be false }
    end

    context "when the previous node is an HTMLDoctypeNode" do
      let(:siblings) do
        Herb.parse("<!DOCTYPE html><div></div>", track_whitespace: true).value.children
            .reject { _1.is_a?(Herb::AST::WhitespaceNode) }
      end
      let(:current_index) { 1 }

      it { is_expected.to be true }
    end

    context "when siblings contain mixed text content" do
      let(:siblings) do
        Herb.parse("<p>text <span>inline</span> more</p>", track_whitespace: true)
            .value.children.first.body
      end
      let(:current_index) do
        siblings.index { _1.is_a?(Herb::AST::HTMLElementNode) }
      end

      it { is_expected.to be false }
    end

    context "when both siblings are HTML comments" do
      let(:siblings) do
        Herb.parse("<!-- first --><!-- second -->", track_whitespace: true).value.children
            .reject { _1.is_a?(Herb::AST::WhitespaceNode) }
      end
      let(:current_index) { 1 }

      it { is_expected.to be false }
    end

    context "when the previous sibling is multiline" do
      let(:siblings) do
        Herb.parse("<div></div><p></p>", track_whitespace: true).value.children
            .reject { _1.is_a?(Herb::AST::WhitespaceNode) }
      end
      let(:current_index) { 1 }

      before do
        previous_node = siblings[0]
        printer.instance_variable_get(:@node_is_multiline)[previous_node] = true
      end

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "when the current sibling is multiline" do
      let(:siblings) do
        Herb.parse("<div></div><p></p>", track_whitespace: true).value.children
            .reject { _1.is_a?(Herb::AST::WhitespaceNode) }
      end
      let(:current_index) { 1 }

      before do
        current_node = siblings[1]
        printer.instance_variable_get(:@node_is_multiline)[current_node] = true
      end

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "when neither sibling is multiline and no special conditions" do
      let(:siblings) do
        Herb.parse("<div></div><p></p>", track_whitespace: true).value.children
            .reject { _1.is_a?(Herb::AST::WhitespaceNode) }
      end
      let(:current_index) { 1 }

      it { is_expected.to be false }
    end

    context "when the previous sibling is a comment and the current is an element" do
      let(:siblings) do
        Herb.parse("<!-- comment --><div></div>", track_whitespace: true).value.children
            .reject { _1.is_a?(Herb::AST::WhitespaceNode) }
      end
      let(:current_index) { 1 }

      context "when neither is multiline" do
        it { is_expected.to be false }
      end

      context "when only the previous (comment) is multiline" do
        before do
          printer.instance_variable_get(:@node_is_multiline)[siblings[0]] = true
        end

        it { is_expected.to be false }
      end

      context "when both are multiline" do
        before do
          printer.instance_variable_get(:@node_is_multiline)[siblings[0]] = true
          printer.instance_variable_get(:@node_is_multiline)[siblings[1]] = true
        end

        it "returns true" do
          expect(subject).to be true
        end
      end
    end
  end
end
