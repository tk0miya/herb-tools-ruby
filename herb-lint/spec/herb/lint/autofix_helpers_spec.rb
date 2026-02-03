# frozen_string_literal: true

RSpec.describe Herb::Lint::AutofixHelpers do
  # Test class that includes AutofixHelpers for testing
  let(:helper_class) do
    Class.new do
      include Herb::Lint::AutofixHelpers
    end
  end
  let(:helper) { helper_class.new }

  describe "#find_parent" do
    context "when target is a top-level element in the document" do
      subject { helper.find_parent(parse_result, element) }

      let(:source) { "<div>hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:document) { parse_result.value }
      let(:element) { document.children.first }

      it "returns the document node as parent" do
        expect(subject).to equal(document)
      end
    end

    context "when target is a nested element" do
      subject { helper.find_parent(parse_result, span) }

      let(:source) { "<div><span>hello</span></div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:div) { parse_result.value.children.first }
      let(:span) { div.body.first }

      it "returns the outer element as parent" do
        expect(subject).to equal(div)
      end
    end

    context "when target node is not in the tree" do
      subject { helper.find_parent(parse_result, stale_node) }

      let(:source) { "<p>hello</p>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:other_parse_result) { Herb.parse("<div>world</div>", track_whitespace: true) }
      let(:stale_node) { other_parse_result.value.children.first }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#parent_array_for" do
    context "when node is in parent's children array" do
      subject { helper.parent_array_for(open_tag, attribute) }

      let(:source) { '<div class="foo">hello</div>' }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:element) { parse_result.value.children.first }
      let(:open_tag) { element.open_tag }
      let(:attribute) do
        open_tag.children.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "returns the children array" do
        expect(subject).to equal(open_tag.children)
        expect(subject).to include(attribute)
      end
    end

    context "when node is in parent's body array" do
      subject { helper.parent_array_for(div, span) }

      let(:source) { "<div><span>hello</span></div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:div) { parse_result.value.children.first }
      let(:span) { div.body.first }

      it "returns the body array" do
        expect(subject).to equal(div.body)
        expect(subject).to include(span)
      end
    end

    context "when node is in document's children array" do
      subject { helper.parent_array_for(document, element) }

      let(:source) { "<div>hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:document) { parse_result.value }
      let(:element) { document.children.first }

      it "returns the children array" do
        expect(subject).to equal(document.children)
        expect(subject).to include(element)
      end
    end

    context "when node is not in any parent array" do
      subject { helper.parent_array_for(document, other_node) }

      let(:source) { "<p>hello</p>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:document) { parse_result.value }
      let(:element) { parse_result.value.children.first }
      let(:other_node) { Herb.parse("<div>world</div>", track_whitespace: true).value.children.first }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when parent has children but node is not in it" do
      subject { helper.parent_array_for(open_tag, span) }

      let(:source) { '<div class="foo"><span>hello</span></div>' }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:div) { parse_result.value.children.first }
      let(:span) { div.body.first }
      let(:open_tag) { div.open_tag }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when parent has body but node is not in it" do
      subject { helper.parent_array_for(div, attribute) }

      let(:source) { '<div class="foo"><span>hello</span></div>' }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:div) { parse_result.value.children.first }
      let(:open_tag) { div.open_tag }
      let(:attribute) do
        open_tag.children.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end
end
