# frozen_string_literal: true

RSpec.describe Herb::Lint::NodeLocator do
  describe ".find_parent" do
    context "when target is a top-level element in the document" do
      let(:source) { "<div>hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:document) { parse_result.value }
      let(:element) { document.children.first }

      it "returns the document node as parent" do
        parent = described_class.find_parent(parse_result, element)

        expect(parent).to equal(document)
      end
    end

    context "when target is an attribute node within an element" do
      let(:source) { '<div class="foo">hello</div>' }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:element) { parse_result.value.children.first }
      let(:open_tag) { element.open_tag }
      let(:attribute) do
        open_tag.children.find { _1.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "returns the open tag node as parent" do
        parent = described_class.find_parent(parse_result, attribute)

        expect(parent).to equal(open_tag)
      end
    end

    context "when target is a nested element" do
      let(:source) { "<div><span>hello</span></div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:div) { parse_result.value.children.first }
      let(:span) { div.body.first }

      it "returns the outer element as parent" do
        parent = described_class.find_parent(parse_result, span)

        expect(parent).to equal(div)
      end
    end

    context "when target is a deeply nested element" do
      let(:source) { "<div><ul><li>item</li></ul></div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:div) { parse_result.value.children.first }
      let(:ul) { div.body.first }
      let(:li) { ul.body.first }

      it "returns the immediate parent" do
        parent = described_class.find_parent(parse_result, li)

        expect(parent).to equal(ul)
      end
    end

    context "when target node is not in the tree (stale reference)" do
      let(:source) { "<p>hello</p>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:other_parse_result) { Herb.parse("<div>world</div>", track_whitespace: true) }
      let(:stale_node) { other_parse_result.value.children.first }

      it "returns nil" do
        parent = described_class.find_parent(parse_result, stale_node)

        expect(parent).to be_nil
      end
    end

    context "when target is the open tag of an element" do
      let(:source) { "<div>hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:element) { parse_result.value.children.first }
      let(:open_tag) { element.open_tag }

      it "returns the element as parent" do
        parent = described_class.find_parent(parse_result, open_tag)

        expect(parent).to equal(element)
      end
    end
  end
end
