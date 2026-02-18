# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::FormatHelpers do
  # Create a test class that includes FormatHelpers
  let(:helper_class) do
    Class.new do
      include Herb::Format::FormatHelpers
    end
  end
  let(:helper) { helper_class.new }

  describe "#pure_whitespace_node?" do
    subject { helper.pure_whitespace_node?(node) }

    context "when HTMLTextNode with only whitespace" do
      let(:node) do
        ast = Herb.parse("   ", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be true }
    end

    context "when HTMLTextNode with tabs and newlines" do
      let(:node) do
        ast = Herb.parse("\n\t  \n", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be true }
    end

    context "when HTMLTextNode with text content" do
      let(:node) do
        ast = Herb.parse("  text  ", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be false }
    end

    context "when LiteralNode with only whitespace" do
      let(:node) do
        ast = Herb.parse('<div class=" "></div>', track_whitespace: true).value
        element_node = ast.children.first
        attribute_node = element_node.open_tag.children.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
        attribute_node.value.children.first
      end

      it { is_expected.to be false }
    end

    context "when LiteralNode with text content" do
      let(:node) do
        ast = Herb.parse('<div class="foo"></div>', track_whitespace: true).value
        element_node = ast.children.first
        attribute_node = element_node.open_tag.children.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
        attribute_node.value.children.first
      end

      it { is_expected.to be false }
    end

    context "when other node type" do
      let(:node) do
        ast = Herb.parse("<div></div>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be false }
    end
  end

  describe "#non_whitespace_node?" do
    subject { helper.non_whitespace_node?(node) }

    context "when WhitespaceNode" do
      let(:node) do
        ast = Herb.parse("<div class='foo'></div>", track_whitespace: true).value
        element_node = ast.children.first
        element_node.open_tag.children.find { |c| c.is_a?(Herb::AST::WhitespaceNode) }
      end

      it { is_expected.to be false }
    end

    context "when HTMLTextNode with only whitespace" do
      let(:node) do
        ast = Herb.parse("   ", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be false }
    end

    context "when HTMLTextNode with text content" do
      let(:node) do
        ast = Herb.parse("  text  ", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be true }
    end

    context "when LiteralNode with only whitespace" do
      let(:node) do
        ast = Herb.parse('<div class=" "></div>', track_whitespace: true).value
        element_node = ast.children.first
        attribute_node = element_node.open_tag.children.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
        attribute_node.value.children.first
      end

      it { is_expected.to be true }
    end

    context "when LiteralNode with text content" do
      let(:node) do
        ast = Herb.parse('<div class="foo"></div>', track_whitespace: true).value
        element_node = ast.children.first
        attribute_node = element_node.open_tag.children.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
        attribute_node.value.children.first
      end

      it { is_expected.to be true }
    end

    context "when HTMLElementNode" do
      let(:node) do
        ast = Herb.parse("<div></div>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be true }
    end
  end

  describe "#inline_element?" do
    subject { helper.inline_element?(tag_name) }

    context "when inline element" do
      let(:tag_name) { "span" }

      it { is_expected.to be true }
    end

    context "when uppercase tag name" do
      let(:tag_name) { "SPAN" }

      it { is_expected.to be true }
    end

    context "when mixed case tag name" do
      let(:tag_name) { "Span" }

      it { is_expected.to be true }
    end

    context "when block element" do
      let(:tag_name) { "div" }

      it { is_expected.to be false }
    end
  end

  describe "#content_preserving?" do
    subject { helper.content_preserving?(tag_name) }

    context "when content-preserving element" do
      let(:tag_name) { "pre" }

      it { is_expected.to be true }
    end

    context "when uppercase tag name" do
      let(:tag_name) { "PRE" }

      it { is_expected.to be true }
    end

    context "when mixed case tag name" do
      let(:tag_name) { "Script" }

      it { is_expected.to be true }
    end

    context "when non-preserving element" do
      let(:tag_name) { "div" }

      it { is_expected.to be false }
    end
  end

  describe "#block_level_node?" do
    subject { helper.block_level_node?(node) }

    context "when block element node" do
      let(:node) do
        ast = Herb.parse("<div></div>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be true }
    end

    context "when inline element node" do
      let(:node) do
        ast = Herb.parse("<span></span>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be false }
    end

    context "when non-HTMLElementNode" do
      let(:node) do
        ast = Herb.parse("text", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be false }
    end
  end

  describe "#line_breaking_element?" do
    subject { helper.line_breaking_element?(node) }

    context "when br element" do
      let(:node) do
        ast = Herb.parse("<br>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be true }
    end

    context "when hr element" do
      let(:node) do
        ast = Herb.parse("<hr>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be true }
    end

    context "when uppercase tag name" do
      let(:node) do
        ast = Herb.parse("<BR>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be true }
    end

    context "when other element" do
      let(:node) do
        ast = Herb.parse("<div></div>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be false }
    end

    context "when non-HTMLElementNode" do
      let(:node) do
        ast = Herb.parse("text", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be false }
    end
  end

  describe "#find_previous_meaningful_sibling" do
    subject { helper.find_previous_meaningful_sibling(siblings, current_index) }

    context "with no previous siblings" do
      let(:siblings) { [] }
      let(:current_index) { 0 }

      it { is_expected.to be_nil }
    end

    context "with no meaningful siblings before current" do
      let(:siblings) do
        ast = Herb.parse("<div>  \n  <span>a</span></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end
      let(:current_index) { 1 }

      it { is_expected.to be_nil }
    end

    context "with meaningful sibling immediately before" do
      let(:siblings) do
        ast = Herb.parse("<div><span>a</span><em>b</em></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end
      let(:current_index) { 1 }

      it { is_expected.to eq(0) }
    end

    context "with meaningful sibling with whitespace in between" do
      let(:siblings) do
        ast = Herb.parse("<div><span>a</span>  \n  <em>b</em></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end
      let(:current_index) { 2 }

      it { is_expected.to eq(0) }
    end
  end

  describe "#whitespace_between?" do
    subject { helper.whitespace_between?(children, start_index, end_index) }

    context "with adjacent indices" do
      let(:children) { [] }
      let(:start_index) { 0 }
      let(:end_index) { 1 }

      it { is_expected.to be false }
    end

    context "with start >= end" do
      let(:children) { [] }
      let(:start_index) { 1 }
      let(:end_index) { 1 }

      it { is_expected.to be false }
    end

    context "with whitespace between" do
      let(:children) do
        ast = Herb.parse("<div><span>a</span>  \n  <em>b</em></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end
      let(:start_index) { 0 }
      let(:end_index) { 2 }

      it { is_expected.to be true }
    end

    context "with no whitespace between" do
      let(:children) do
        ast = Herb.parse("<div><span>a</span><span>b</span><span>c</span></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end
      let(:start_index) { 0 }
      let(:end_index) { 2 }

      it { is_expected.to be false }
    end
  end

  describe "#filter_significant_children" do
    subject { helper.filter_significant_children(body) }

    context "with element nodes" do
      let(:body) do
        ast = Herb.parse("<div><span>a</span><em>b</em></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end

      it "returns all element nodes" do
        expect(subject.length).to eq(2)
        expect(subject.all? { |n| n.is_a?(Herb::AST::HTMLElementNode) }).to be true
      end
    end

    context "with elements and whitespace nodes" do
      let(:body) do
        ast = Herb.parse("<div><span>a</span>  \n  <em>b</em></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end

      it "excludes whitespace nodes" do
        expect(subject.length).to eq(2)
        expect(subject.all? { |n| n.is_a?(Herb::AST::HTMLElementNode) }).to be true
      end
    end

    context "with single space" do
      let(:body) do
        ast = Herb.parse("<div> </div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end

      it "preserves single space" do
        expect(subject.length).to eq(1)
        expect(subject.first.content).to eq(" ")
      end
    end

    context "with empty text nodes" do
      let(:body) do
        ast = Herb.parse("<div></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end

      it "returns empty array" do
        expect(subject).to be_empty
      end
    end

    context "with text content" do
      let(:body) do
        ast = Herb.parse("<div>text</div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end

      it "includes text nodes" do
        expect(subject.length).to eq(1)
        expect(subject.first).to be_a(Herb::AST::HTMLTextNode)
      end
    end
  end

  describe "#count_adjacent_inline_elements" do
    subject { helper.count_adjacent_inline_elements(children) }

    context "with no children" do
      let(:children) { [] }

      it { is_expected.to eq(0) }
    end

    context "with all inline elements" do
      let(:children) do
        ast = Herb.parse("<div><span>a</span><em>b</em><strong>c</strong></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end

      it { is_expected.to eq(3) }
    end

    context "with inline elements followed by block element" do
      let(:children) do
        ast = Herb.parse("<div><span>a</span><em>b</em><div>c</div></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end

      it { is_expected.to eq(2) }
    end

    context "with inline elements interrupted by whitespace" do
      let(:children) do
        ast = Herb.parse("<div><span>a</span>  \n  <em>b</em></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end

      it { is_expected.to eq(1) }
    end

    context "with text nodes" do
      let(:children) do
        ast = Herb.parse("<div>text</div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end

      it { is_expected.to eq(1) }
    end

    context "with ERB content node" do
      let(:children) do
        ast = Herb.parse("<div><%= @user %></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end

      it { is_expected.to eq(1) }
    end

    context "with inline elements followed by ERB content node" do
      let(:children) do
        ast = Herb.parse("<div><span>a</span><%= @user %></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end

      it { is_expected.to eq(2) }
    end

    context "with ERB control flow node" do
      let(:children) do
        ast = Herb.parse("<div><% if true %><% end %></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end

      it { is_expected.to eq(0) }
    end

    context "with inline elements followed by ERB control flow node" do
      let(:children) do
        ast = Herb.parse("<div><span>a</span><% if true %><% end %></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end

      it { is_expected.to eq(1) }
    end

    context "with ERB block node" do
      let(:children) do
        ast = Herb.parse("<div><% @items.each do |item| %><% end %></div>", track_whitespace: true).value
        element = ast.children.first
        element.body
      end

      it { is_expected.to eq(0) }
    end
  end

  describe "#erb_node?" do
    subject { helper.erb_node?(node) }

    context "with ERB content node" do
      let(:node) do
        ast = Herb.parse("<%= @user %>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be true }
    end

    context "with HTML element node" do
      let(:node) do
        ast = Herb.parse("<div></div>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be false }
    end
  end

  describe "#erb_control_flow_node?" do
    subject { helper.erb_control_flow_node?(node) }

    context "with ERB if node" do
      let(:node) do
        ast = Herb.parse("<% if true %><% end %>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be true }
    end

    context "with ERB unless node" do
      let(:node) do
        ast = Herb.parse("<% unless false %><% end %>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be true }
    end

    context "with ERB content node" do
      let(:node) do
        ast = Herb.parse("<%= @user %>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be false }
    end

    context "with HTML element node" do
      let(:node) do
        ast = Herb.parse("<div></div>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be false }
    end
  end
end
