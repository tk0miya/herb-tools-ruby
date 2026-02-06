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

    context "when replacing a structural child (end_node)" do
      subject { helper.replace_node(parse_result, old_end_node, new_end_node) }

      let(:source) { "<% if true %><p>yes</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:if_node) { parse_result.value.children.first }
      let(:old_end_node) { if_node.end_node }
      let(:new_end_node) do
        helper.copy_erb_end_node(
          old_end_node,
          tag_closing: helper.copy_token(old_end_node.tag_closing, content: "-%>")
        )
      end

      it "replaces the structural child and returns true" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(parse_result)
        expect(result).to eq("<% if true %><p>yes</p><% end -%>")
      end
    end

    context "when replacing a structural child (subsequent)" do
      subject { helper.replace_node(parse_result, old_else_node, new_else_node) }

      let(:source) { "<% if true %><p>yes</p><% else %><p>no</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:if_node) { parse_result.value.children.first }
      let(:old_else_node) { if_node.subsequent }
      let(:new_else_node) do
        helper.copy_erb_else_node(
          old_else_node,
          tag_closing: helper.copy_token(old_else_node.tag_closing, content: "-%>")
        )
      end

      it "replaces the structural child and returns true" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(parse_result)
        expect(result).to eq("<% if true %><p>yes</p><% else -%><p>no</p><% end %>")
      end
    end

    context "when replacing a structural child on a node with multiple structural attributes" do
      subject { helper.replace_node(parse_result, old_rescue_node, new_rescue_node) }

      let(:source) { "<% begin %><p>text</p><% rescue %><p>error</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:begin_node) { parse_result.value.children.first }
      let(:old_rescue_node) { begin_node.rescue_clause }
      let(:new_rescue_node) do
        helper.copy_erb_rescue_node(
          old_rescue_node,
          tag_closing: helper.copy_token(old_rescue_node.tag_closing, content: "-%>")
        )
      end

      it "replaces only the targeted attribute and preserves others" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(parse_result)
        expect(result).to eq("<% begin %><p>text</p><% rescue -%><p>error</p><% end %>")
      end
    end
  end

  describe "#remove_node" do
    context "when removing a node from children array" do
      subject { helper.remove_node(parse_result, element_to_remove) }

      let(:source) { "<div>hello</div><span>world</span>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:document) { parse_result.value }
      let(:element_to_remove) { document.children.first }

      it "removes the node and returns true" do
        original_size = document.children.size
        expect(subject).to be(true)
        expect(document.children.size).to eq(original_size - 1)
        expect(document.children).not_to include(element_to_remove)
      end
    end

    context "when removing a node from body array" do
      subject { helper.remove_node(parse_result, span_to_remove) }

      let(:source) { "<div><span>hello</span><p>world</p></div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:div) { parse_result.value.children.first }
      let(:span_to_remove) { div.body.first }

      it "removes the node and returns true" do
        original_size = div.body.size
        expect(subject).to be(true)
        expect(div.body.size).to eq(original_size - 1)
        expect(div.body).not_to include(span_to_remove)
      end
    end

    context "when node has no parent in the parse result" do
      subject { helper.remove_node(parse_result, stale_node) }

      let(:source) { "<p>hello</p>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:other_parse_result) { Herb.parse("<div>world</div>", track_whitespace: true) }
      let(:stale_node) { other_parse_result.value.children.first }

      it "returns false without modifying the tree" do
        original_children = parse_result.value.children.dup
        expect(subject).to be(false)
        expect(parse_result.value.children).to eq(original_children)
      end
    end

    context "when removing an ERB tag from document children" do
      subject { helper.remove_node(parse_result, erb_to_remove) }

      let(:source) { "<% %>text<%= value %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:document) { parse_result.value }
      let(:erb_to_remove) { document.children.first }

      it "removes the ERB tag and returns true" do
        original_size = document.children.size
        expect(subject).to be(true)
        expect(document.children.size).to eq(original_size - 1)
        expect(document.children).not_to include(erb_to_remove)
      end
    end

    context "when parent array does not contain the node" do
      subject { helper.remove_node(parse_result, orphan_node) }

      let(:source) { "<div>hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:orphan_node) do
        other_source = "<span>orphan</span>"
        other_parse = Herb.parse(other_source, track_whitespace: true)
        other_parse.value.children.first
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

  describe "#copy_html_attribute_node" do
    context "when copying an attribute node without overrides" do
      subject { helper.copy_html_attribute_node(original_attr) }

      let(:source) { '<div class="foo">hello</div>' }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:element) { parse_result.value.children.first }
      let(:original_attr) do
        element.open_tag.children.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
      end

      it "creates a new attribute node with same attributes" do
        expect(subject).to be_a(Herb::AST::HTMLAttributeNode)
        expect(subject).not_to equal(original_attr)
        expect(subject).to have_attributes(
          type: original_attr.type,
          location: original_attr.location,
          errors: original_attr.errors,
          name: original_attr.name,
          equals: original_attr.equals,
          value: original_attr.value
        )
      end
    end

    context "when copying an attribute node with overrides" do
      subject do
        helper.copy_html_attribute_node(
          original_attr,
          name: new_name_node,
          value: new_value_node
        )
      end

      let(:source) { '<div class="foo" id="bar">hello</div>' }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:element) { parse_result.value.children.first }
      let(:original_attr) do
        element.open_tag.children.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) && c.name.children.first.content == "class" }
      end
      let(:new_attr) do
        element.open_tag.children.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) && c.name.children.first.content == "id" }
      end
      let(:new_name_node) { new_attr.name }
      let(:new_value_node) { new_attr.value }

      it "creates a new attribute node with overridden attributes" do
        expect(subject.name).to equal(new_name_node)
        expect(subject.value).to equal(new_value_node)
        expect(subject.equals).to eq(original_attr.equals)
      end
    end
  end

  describe "#copy_html_element_node" do
    context "when copying an element node without overrides" do
      subject { helper.copy_html_element_node(original_element) }

      let(:source) { "<div>hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_element) { parse_result.value.children.first }

      it "creates a new element node with same attributes" do
        expect(subject).to be_a(Herb::AST::HTMLElementNode)
        expect(subject).not_to equal(original_element)
        expect(subject).to have_attributes(
          type: original_element.type,
          location: original_element.location,
          errors: original_element.errors,
          open_tag: original_element.open_tag,
          tag_name: original_element.tag_name,
          body: original_element.body,
          close_tag: original_element.close_tag,
          is_void: original_element.is_void,
          source: original_element.source
        )
      end
    end

    context "when copying an element node with overrides" do
      subject do
        helper.copy_html_element_node(
          original_element,
          tag_name: new_tag_name_token,
          body: new_body
        )
      end

      let(:source) { "<div>hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_element) { parse_result.value.children.first }
      let(:new_tag_name_token) { helper.copy_token(original_element.tag_name, content: "span") }
      let(:new_body) { [] }

      it "creates a new element node with overridden attributes" do
        expect(subject).to have_attributes(
          tag_name: have_attributes(value: "span"),
          body: [],
          open_tag: original_element.open_tag,
          close_tag: original_element.close_tag
        )
      end
    end
  end

  describe "#copy_html_text_node" do
    context "when copying a text node without overrides" do
      subject { helper.copy_html_text_node(original_text) }

      let(:source) { "<div>hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:element) { parse_result.value.children.first }
      let(:original_text) { element.body.first }

      it "creates a new text node with same attributes" do
        expect(subject).to be_a(Herb::AST::HTMLTextNode)
        expect(subject).not_to equal(original_text)
        expect(subject).to have_attributes(
          type: original_text.type,
          location: original_text.location,
          errors: original_text.errors,
          content: original_text.content
        )
      end
    end

    context "when copying a text node with overrides" do
      subject do
        helper.copy_html_text_node(original_text, content: "goodbye")
      end

      let(:source) { "<div>hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:element) { parse_result.value.children.first }
      let(:original_text) { element.body.first }

      it "creates a new text node with overridden content" do
        expect(subject).to have_attributes(
          content: "goodbye"
        )
      end
    end
  end

  describe "#copy_erb_block_node" do
    context "when copying an ERB block node without overrides" do
      subject { helper.copy_erb_block_node(original_node) }

      let(:source) { "<% [1,2,3].each do |i| %><p><%= i %></p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBBlockNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          body: original_node.body,
          end_node: original_node.end_node
        )
      end
    end

    context "when copying an ERB block node with overrides" do
      subject do
        helper.copy_erb_block_node(
          original_node,
          body: []
        )
      end

      let(:source) { "<% [1,2,3].each do |i| %><p><%= i %></p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          body: [],
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          end_node: original_node.end_node
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

  describe "#copy_erb_if_node" do
    context "when copying an ERB if node without overrides" do
      subject { helper.copy_erb_if_node(original_node) }

      let(:source) { "<% if true %><p>yes</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBIfNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          then_keyword: original_node.then_keyword,
          statements: original_node.statements,
          subsequent: original_node.subsequent,
          end_node: original_node.end_node
        )
      end
    end

    context "when copying an ERB if node with overrides" do
      subject do
        helper.copy_erb_if_node(
          original_node,
          statements: []
        )
      end

      let(:source) { "<% if true %><p>yes</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          statements: [],
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          end_node: original_node.end_node
        )
      end
    end
  end

  describe "#copy_erb_unless_node" do
    context "when copying an ERB unless node without overrides" do
      subject { helper.copy_erb_unless_node(original_node) }

      let(:source) { "<% unless false %><p>yes</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBUnlessNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          then_keyword: original_node.then_keyword,
          statements: original_node.statements,
          else_clause: original_node.else_clause,
          end_node: original_node.end_node
        )
      end
    end

    context "when copying an ERB unless node with overrides" do
      subject do
        helper.copy_erb_unless_node(
          original_node,
          statements: []
        )
      end

      let(:source) { "<% unless false %><p>yes</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          statements: [],
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          end_node: original_node.end_node
        )
      end
    end
  end

  describe "#copy_erb_begin_node" do
    context "when copying an ERB begin node without overrides" do
      subject { helper.copy_erb_begin_node(original_node) }

      let(:source) { "<% begin %><p>text</p><% rescue %><p>error</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBBeginNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          statements: original_node.statements,
          rescue_clause: original_node.rescue_clause,
          else_clause: original_node.else_clause,
          ensure_clause: original_node.ensure_clause,
          end_node: original_node.end_node
        )
      end
    end

    context "when copying an ERB begin node with overrides" do
      subject { helper.copy_erb_begin_node(original_node, statements: []) }

      let(:source) { "<% begin %><p>text</p><% rescue %><p>error</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          statements: [],
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          rescue_clause: original_node.rescue_clause,
          end_node: original_node.end_node
        )
      end
    end
  end

  describe "#copy_erb_case_match_node" do
    context "when copying an ERB case-match node without overrides" do
      subject { helper.copy_erb_case_match_node(original_node) }

      let(:source) { "<% case x %><% in 1 %><p>one</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBCaseMatchNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          children: original_node.children,
          conditions: original_node.conditions,
          else_clause: original_node.else_clause,
          end_node: original_node.end_node
        )
      end
    end

    context "when copying an ERB case-match node with overrides" do
      subject { helper.copy_erb_case_match_node(original_node, children: []) }

      let(:source) { "<% case x %><% in 1 %><p>one</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          children: [],
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          conditions: original_node.conditions,
          end_node: original_node.end_node
        )
      end
    end
  end

  describe "#copy_erb_case_node" do
    context "when copying an ERB case node without overrides" do
      subject { helper.copy_erb_case_node(original_node) }

      let(:source) { "<% case x %><% when 1 %><p>one</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBCaseNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          children: original_node.children,
          conditions: original_node.conditions,
          else_clause: original_node.else_clause,
          end_node: original_node.end_node
        )
      end
    end

    context "when copying an ERB case node with overrides" do
      subject { helper.copy_erb_case_node(original_node, children: []) }

      let(:source) { "<% case x %><% when 1 %><p>one</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          children: [],
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          conditions: original_node.conditions,
          end_node: original_node.end_node
        )
      end
    end
  end

  describe "#copy_erb_else_node" do
    context "when copying an ERB else node without overrides" do
      subject { helper.copy_erb_else_node(original_node) }

      let(:source) { "<% if true %><p>yes</p><% else %><p>no</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:if_node) { parse_result.value.children.first }
      let(:original_node) { if_node.subsequent }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBElseNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          statements: original_node.statements
        )
      end
    end

    context "when copying an ERB else node with overrides" do
      subject { helper.copy_erb_else_node(original_node, statements: []) }

      let(:source) { "<% if true %><p>yes</p><% else %><p>no</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:if_node) { parse_result.value.children.first }
      let(:original_node) { if_node.subsequent }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          statements: [],
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing
        )
      end
    end
  end

  describe "#copy_erb_end_node" do
    context "when copying an ERB end node without overrides" do
      subject { helper.copy_erb_end_node(original_node) }

      let(:source) { "<% if true %><p>yes</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:if_node) { parse_result.value.children.first }
      let(:original_node) { if_node.end_node }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBEndNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing
        )
      end
    end

    context "when copying an ERB end node with overrides" do
      subject { helper.copy_erb_end_node(original_node, content: new_token) }

      let(:source) { "<% if true %><p>yes</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:if_node) { parse_result.value.children.first }
      let(:original_node) { if_node.end_node }
      let(:new_token) { helper.copy_token(original_node.content, content: "end") }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          content: new_token,
          tag_opening: original_node.tag_opening,
          tag_closing: original_node.tag_closing
        )
      end
    end
  end

  describe "#copy_erb_ensure_node" do
    context "when copying an ERB ensure node without overrides" do
      subject { helper.copy_erb_ensure_node(original_node) }

      let(:source) { "<% begin %><p>text</p><% ensure %><p>cleanup</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:begin_node) { parse_result.value.children.first }
      let(:original_node) { begin_node.ensure_clause }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBEnsureNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          statements: original_node.statements
        )
      end
    end

    context "when copying an ERB ensure node with overrides" do
      subject { helper.copy_erb_ensure_node(original_node, statements: []) }

      let(:source) { "<% begin %><p>text</p><% ensure %><p>cleanup</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:begin_node) { parse_result.value.children.first }
      let(:original_node) { begin_node.ensure_clause }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          statements: [],
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing
        )
      end
    end
  end

  describe "#copy_erb_for_node" do
    context "when copying an ERB for node without overrides" do
      subject { helper.copy_erb_for_node(original_node) }

      let(:source) { "<% for i in [1,2,3] %><p><%= i %></p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBForNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          statements: original_node.statements,
          end_node: original_node.end_node
        )
      end
    end

    context "when copying an ERB for node with overrides" do
      subject { helper.copy_erb_for_node(original_node, statements: []) }

      let(:source) { "<% for i in [1,2,3] %><p><%= i %></p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          statements: [],
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          end_node: original_node.end_node
        )
      end
    end
  end

  describe "#copy_erb_in_node" do
    context "when copying an ERB in node without overrides" do
      subject { helper.copy_erb_in_node(original_node) }

      let(:source) { "<% case x %><% in 1 %><p>one</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:case_match_node) { parse_result.value.children.first }
      let(:original_node) { case_match_node.conditions.first }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBInNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          then_keyword: original_node.then_keyword,
          statements: original_node.statements
        )
      end
    end

    context "when copying an ERB in node with overrides" do
      subject { helper.copy_erb_in_node(original_node, statements: []) }

      let(:source) { "<% case x %><% in 1 %><p>one</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:case_match_node) { parse_result.value.children.first }
      let(:original_node) { case_match_node.conditions.first }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          statements: [],
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          then_keyword: original_node.then_keyword
        )
      end
    end
  end

  describe "#copy_erb_rescue_node" do
    context "when copying an ERB rescue node without overrides" do
      subject { helper.copy_erb_rescue_node(original_node) }

      let(:source) { "<% begin %><p>text</p><% rescue %><p>error</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:begin_node) { parse_result.value.children.first }
      let(:original_node) { begin_node.rescue_clause }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBRescueNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          statements: original_node.statements,
          subsequent: original_node.subsequent
        )
      end
    end

    context "when copying an ERB rescue node with overrides" do
      subject { helper.copy_erb_rescue_node(original_node, statements: []) }

      let(:source) { "<% begin %><p>text</p><% rescue %><p>error</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:begin_node) { parse_result.value.children.first }
      let(:original_node) { begin_node.rescue_clause }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          statements: [],
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          subsequent: original_node.subsequent
        )
      end
    end
  end

  describe "#copy_erb_until_node" do
    context "when copying an ERB until node without overrides" do
      subject { helper.copy_erb_until_node(original_node) }

      let(:source) { "<% until false %><p>text</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBUntilNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          statements: original_node.statements,
          end_node: original_node.end_node
        )
      end
    end

    context "when copying an ERB until node with overrides" do
      subject { helper.copy_erb_until_node(original_node, statements: []) }

      let(:source) { "<% until false %><p>text</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          statements: [],
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          end_node: original_node.end_node
        )
      end
    end
  end

  describe "#copy_erb_when_node" do
    context "when copying an ERB when node without overrides" do
      subject { helper.copy_erb_when_node(original_node) }

      let(:source) { "<% case x %><% when 1 %><p>one</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:case_node) { parse_result.value.children.first }
      let(:original_node) { case_node.conditions.first }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBWhenNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          then_keyword: original_node.then_keyword,
          statements: original_node.statements
        )
      end
    end

    context "when copying an ERB when node with overrides" do
      subject { helper.copy_erb_when_node(original_node, statements: []) }

      let(:source) { "<% case x %><% when 1 %><p>one</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:case_node) { parse_result.value.children.first }
      let(:original_node) { case_node.conditions.first }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          statements: [],
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          then_keyword: original_node.then_keyword
        )
      end
    end
  end

  describe "#copy_erb_while_node" do
    context "when copying an ERB while node without overrides" do
      subject { helper.copy_erb_while_node(original_node) }

      let(:source) { "<% while false %><p>text</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBWhileNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          statements: original_node.statements,
          end_node: original_node.end_node
        )
      end
    end

    context "when copying an ERB while node with overrides" do
      subject { helper.copy_erb_while_node(original_node, statements: []) }

      let(:source) { "<% while false %><p>text</p><% end %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          statements: [],
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing,
          end_node: original_node.end_node
        )
      end
    end
  end

  describe "#copy_erb_yield_node" do
    context "when copying an ERB yield node without overrides" do
      subject { helper.copy_erb_yield_node(original_node) }

      let(:source) { "<% yield %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }

      it "creates a new node with same attributes" do
        expect(subject).to be_a(Herb::AST::ERBYieldNode)
        expect(subject).not_to equal(original_node)
        expect(subject).to have_attributes(
          type: original_node.type,
          location: original_node.location,
          errors: original_node.errors,
          tag_opening: original_node.tag_opening,
          content: original_node.content,
          tag_closing: original_node.tag_closing
        )
      end
    end

    context "when copying an ERB yield node with overrides" do
      subject { helper.copy_erb_yield_node(original_node, content: new_token) }

      let(:source) { "<% yield %>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:original_node) { parse_result.value.children.first }
      let(:new_token) { helper.copy_token(original_node.content, content: "yield") }

      it "creates a new node with overridden attributes" do
        expect(subject).to have_attributes(
          content: new_token,
          tag_opening: original_node.tag_opening,
          tag_closing: original_node.tag_closing
        )
      end
    end
  end
end
