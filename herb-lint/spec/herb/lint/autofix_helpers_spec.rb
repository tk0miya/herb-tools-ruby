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

  describe "#replace_node" do
    context "when replacing a node in children array" do
      subject { helper.replace_node(parse_result, old_element, new_element) }

      let(:source) { "<div>hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:document) { parse_result.value }
      let(:old_element) { document.children.first }
      let(:new_element) do
        # Create a replacement element
        new_source = "<span>world</span>"
        new_parse = Herb.parse(new_source, track_whitespace: true)
        new_parse.value.children.first
      end

      it "replaces the node and returns true" do
        expect(subject).to be(true)
        expect(document.children.first).to equal(new_element)
        expect(document.children).not_to include(old_element)
      end
    end

    context "when replacing a node in body array" do
      subject { helper.replace_node(parse_result, old_span, new_span) }

      let(:source) { "<div><span>hello</span></div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:div) { parse_result.value.children.first }
      let(:old_span) { div.body.first }
      let(:new_span) do
        new_source = "<p>world</p>"
        new_parse = Herb.parse(new_source, track_whitespace: true)
        new_parse.value.children.first
      end

      it "replaces the node and returns true" do
        expect(subject).to be(true)
        expect(div.body.first).to equal(new_span)
        expect(div.body).not_to include(old_span)
      end
    end

    context "when node has no parent in the parse result" do
      subject { helper.replace_node(parse_result, stale_node, new_element) }

      let(:source) { "<p>hello</p>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:other_parse_result) { Herb.parse("<div>world</div>", track_whitespace: true) }
      let(:stale_node) { other_parse_result.value.children.first }
      let(:new_element) do
        new_source = "<span>new</span>"
        new_parse = Herb.parse(new_source, track_whitespace: true)
        new_parse.value.children.first
      end

      it "returns false without modifying the tree" do
        original_children = parse_result.value.children.dup
        expect(subject).to be(false)
        expect(parse_result.value.children).to eq(original_children)
      end
    end

    context "when replacing an attribute in open tag children" do
      subject { helper.replace_node(parse_result, old_attr, new_attr) }

      let(:source) { '<div class="foo">hello</div>' }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:element) { parse_result.value.children.first }
      let(:open_tag) { element.open_tag }
      let(:old_attr) do
        open_tag.children.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
      end
      let(:new_attr) do
        new_source = '<div id="bar"></div>'
        new_parse = Herb.parse(new_source, track_whitespace: true)
        new_element = new_parse.value.children.first
        new_element.open_tag.children.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "replaces the attribute and returns true" do
        expect(subject).to be(true)
        attributes = open_tag.children.select { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
        expect(attributes).to include(new_attr)
        expect(attributes).not_to include(old_attr)
      end
    end

    context "when parent array does not contain the node" do
      subject { helper.replace_node(parse_result, orphan_node, new_element) }

      let(:source) { "<div>hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      # Create a node that exists in parsing but not in the actual tree
      let(:orphan_node) do
        other_source = "<span>orphan</span>"
        other_parse = Herb.parse(other_source, track_whitespace: true)
        other_parse.value.children.first
      end
      let(:new_element) do
        new_source = "<p>new</p>"
        new_parse = Herb.parse(new_source, track_whitespace: true)
        new_parse.value.children.first
      end

      it "returns false without modifying the tree" do
        original_children = parse_result.value.children.dup
        expect(subject).to be(false)
        expect(parse_result.value.children).to eq(original_children)
      end
    end
  end

  describe "#copy_token" do
    context "when copying a token without overrides" do
      subject { helper.copy_token(original_token) }

      let(:source) { "<div>hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:element) { parse_result.value.children.first }
      let(:original_token) { element.open_tag.tag_name }

      it "creates a new token with same attributes" do
        expect(subject).to be_a(Herb::Token)
        expect(subject).not_to equal(original_token)
        expect(subject).to have_attributes(
          value: original_token.value,
          range: original_token.range,
          location: original_token.location,
          type: original_token.type
        )
      end
    end

    context "when copying a token with overrides" do
      subject { helper.copy_token(original_token, content: "p", type: "custom_type") }

      let(:source) { "<div>hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:element) { parse_result.value.children.first }
      let(:original_token) { element.open_tag.tag_name }

      it "creates a new token with overridden attributes" do
        expect(subject).to have_attributes(
          value: "p",
          type: "custom_type",
          range: original_token.range,
          location: original_token.location
        )
      end
    end
  end

  describe "#copy_erb_content_node" do
    context "when copying an ERB node without overrides" do
      subject { helper.copy_erb_content_node(original_node) }

      let(:source) { "<%= 'hello' %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBContentNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          analyzed_ruby: original_node.analyzed_ruby,
          parsed: original_node.parsed,
          valid: original_node.valid
        )
      end
    end

    context "when copying an ERB node with overrides" do
      subject do
        helper.copy_erb_content_node(
          original_node,
          content: new_content_token,
          parsed: false,
          valid: false
        )
      end

      let(:source) { "<%= 'hello' %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }
      let(:new_content_token) do
        helper.copy_token(original_node.content, content: " 'goodbye' ")
      end

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          content: have_attributes(value: " 'goodbye' "),
          parsed: false,
          valid: false,
          tag_opening: original_node.tag_opening,
          tag_closing: original_node.tag_closing
        )
      end
    end
  end
end
