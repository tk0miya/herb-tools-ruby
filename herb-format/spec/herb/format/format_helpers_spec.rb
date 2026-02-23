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
        attribute_node = element_node.open_tag.children.find { _1.is_a?(Herb::AST::HTMLAttributeNode) }
        attribute_node.value.children.first
      end

      it { is_expected.to be false }
    end

    context "when LiteralNode with text content" do
      let(:node) do
        ast = Herb.parse('<div class="foo"></div>', track_whitespace: true).value
        element_node = ast.children.first
        attribute_node = element_node.open_tag.children.find { _1.is_a?(Herb::AST::HTMLAttributeNode) }
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
        element_node.open_tag.children.find { _1.is_a?(Herb::AST::WhitespaceNode) }
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
        attribute_node = element_node.open_tag.children.find { _1.is_a?(Herb::AST::HTMLAttributeNode) }
        attribute_node.value.children.first
      end

      it { is_expected.to be true }
    end

    context "when LiteralNode with text content" do
      let(:node) do
        ast = Herb.parse('<div class="foo"></div>', track_whitespace: true).value
        element_node = ast.children.first
        attribute_node = element_node.open_tag.children.find { _1.is_a?(Herb::AST::HTMLAttributeNode) }
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
        expect(subject.all? { _1.is_a?(Herb::AST::HTMLElementNode) }).to be true
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
        expect(subject.all? { _1.is_a?(Herb::AST::HTMLElementNode) }).to be true
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

  describe "#multiline_text_content?" do
    subject { helper.multiline_text_content?(children) }

    context "when text node contains newline" do
      let(:children) do
        ast = Herb.parse("<div>text\nmore</div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be true }
    end

    context "when text node has no newline" do
      let(:children) do
        ast = Herb.parse("<div>text</div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end

    context "when nested element text contains newline" do
      let(:children) do
        ast = Herb.parse("<div><span>text\nmore</span></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be true }
    end

    context "when nested element text has no newline" do
      let(:children) do
        ast = Herb.parse("<div><span>text</span></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end

    context "with empty children" do
      let(:children) { [] }

      it { is_expected.to be false }
    end

    context "with ERB nodes only" do
      let(:children) do
        ast = Herb.parse("<div><%= @user %></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end
  end

  describe "#all_nested_elements_inline?" do
    subject { helper.all_nested_elements_inline?(children) }

    context "with all inline elements" do
      let(:children) do
        ast = Herb.parse("<div><span>a</span><em>b</em></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be true }
    end

    context "with block element" do
      let(:children) do
        ast = Herb.parse("<div><div>a</div></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end

    context "with text nodes only" do
      let(:children) do
        ast = Herb.parse("<div>text</div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be true }
    end

    context "with nested inline elements" do
      let(:children) do
        ast = Herb.parse("<div><span><em>text</em></span></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be true }
    end

    context "with nested block element inside inline" do
      let(:children) do
        ast = Herb.parse("<div><span><div>text</div></span></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end

    context "with HTML comment" do
      let(:children) do
        ast = Herb.parse("<div><!-- comment --></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end

    context "with ERB content node" do
      let(:children) do
        ast = Herb.parse("<div><%= @user %></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be true }
    end

    context "with ERB control flow node" do
      let(:children) do
        ast = Herb.parse("<div><% if true %><% end %></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end

    context "with empty children" do
      let(:children) { [] }

      it { is_expected.to be true }
    end

    context "with whitespace nodes" do
      let(:children) do
        ast = Herb.parse("<div>  \n  </div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be true }
    end

    context "with HTML doctype node" do
      let(:children) do
        ast = Herb.parse("<div><!DOCTYPE html></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end
  end

  describe "#mixed_text_and_inline_content?" do
    subject { helper.mixed_text_and_inline_content?(children) }

    context "with text and inline elements" do
      let(:children) do
        ast = Herb.parse("<p>Hello <em>world</em>!</p>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be true }
    end

    context "with text only" do
      let(:children) do
        ast = Herb.parse("<div>text</div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end

    context "with inline elements only" do
      let(:children) do
        ast = Herb.parse("<div><span>a</span><em>b</em></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end

    context "with text and block element" do
      let(:children) do
        ast = Herb.parse("<div>text<div>block</div></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end

    context "with text and ERB content node" do
      let(:children) do
        ast = Herb.parse("<p>Hello <%= @name %>!</p>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be true }
    end

    context "with empty children" do
      let(:children) { [] }

      it { is_expected.to be false }
    end

    context "with whitespace only text and inline element" do
      let(:children) do
        ast = Herb.parse("<div>   <span>a</span></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end

    context "with text and ERB control flow node" do
      let(:children) do
        ast = Herb.parse("<p>text<% if true %><% end %></p>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end
  end

  describe "#complex_erb_control_flow?" do
    subject { helper.complex_erb_control_flow?(children) }

    context "with multiline ERB if" do
      let(:children) do
        ast = Herb.parse("<div><% if true %>\n<p>hello</p>\n<% end %></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be true }
    end

    context "with single-line ERB if" do
      let(:children) do
        ast = Herb.parse("<div><% if true %><% end %></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end

    context "with no ERB control flow" do
      let(:children) do
        ast = Herb.parse("<div><span>text</span></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end

    context "with ERB content node (not control flow)" do
      let(:children) do
        ast = Herb.parse("<div><%= @user %></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be false }
    end

    context "with empty children" do
      let(:children) { [] }

      it { is_expected.to be false }
    end

    context "with multiline ERB block" do
      let(:children) do
        ast = Herb.parse("<div><% @items.each do |item| %>\n<p>item</p>\n<% end %></div>", track_whitespace: true).value
        ast.children.first.body
      end

      it { is_expected.to be true }
    end
  end

  describe "#appendable_after_inline_or_erb?" do
    subject { helper.appendable_after_inline_or_erb?(child) }

    context "when child is an HTMLTextNode" do
      let(:child) do
        ast = Herb.parse("<div>text</div>", track_whitespace: true).value
        ast.children.first.body.first
      end

      it { is_expected.to be true }
    end

    context "when child is an ERBContentNode" do
      let(:child) do
        ast = Herb.parse("<div><%= @user %></div>", track_whitespace: true).value
        ast.children.first.body.first
      end

      it { is_expected.to be true }
    end

    context "when child is an inline HTMLElementNode" do
      let(:child) do
        ast = Herb.parse("<div><span>text</span></div>", track_whitespace: true).value
        ast.children.first.body.first
      end

      it { is_expected.to be true }
    end

    context "when child is a block HTMLElementNode" do
      let(:child) do
        ast = Herb.parse("<div><div>text</div></div>", track_whitespace: true).value
        ast.children.first.body.first
      end

      it { is_expected.to be false }
    end

    context "when child is a WhitespaceNode" do
      let(:child) do
        ast = Herb.parse("<div class='foo'></div>", track_whitespace: true).value
        ast.children.first.open_tag.children.find { _1.is_a?(Herb::AST::WhitespaceNode) }
      end

      it { is_expected.to be false }
    end

    context "when child is an ERB control flow node" do
      let(:child) do
        ast = Herb.parse("<div><% if true %><% end %></div>", track_whitespace: true).value
        ast.children.first.body.first
      end

      it { is_expected.to be false }
    end
  end

  describe "#should_append_to_last_line?" do
    subject { helper.should_append_to_last_line?(child, siblings, index) }

    context "with adjacent inline elements (no whitespace)" do
      let(:siblings) do
        ast = Herb.parse("<div><span>a</span><em>b</em></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[1] }
      let(:index) { 1 }

      it { is_expected.to be true }
    end

    context "with text after inline element (no whitespace)" do
      let(:siblings) do
        ast = Herb.parse("<div><span>a</span>text</div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[1] }
      let(:index) { 1 }

      it { is_expected.to be true }
    end

    context "with ERB after inline element (no whitespace)" do
      let(:siblings) do
        ast = Herb.parse("<div><span>a</span><%= @val %></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[1] }
      let(:index) { 1 }

      it { is_expected.to be true }
    end

    context "with inline element after text (no whitespace)" do
      let(:siblings) do
        ast = Herb.parse("<div>text<span>a</span></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[1] }
      let(:index) { 1 }

      it { is_expected.to be true }
    end

    context "with ERB after text (no whitespace)" do
      let(:siblings) do
        ast = Herb.parse("<div>text<%= @val %></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[1] }
      let(:index) { 1 }

      it { is_expected.to be true }
    end

    context "with text after ERB (no whitespace)" do
      let(:siblings) do
        ast = Herb.parse("<div><%= @val %>text</div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[1] }
      let(:index) { 1 }

      it { is_expected.to be true }
    end

    context "with adjacent ERB nodes (no whitespace)" do
      let(:siblings) do
        ast = Herb.parse("<div><%= @a %><%= @b %></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[1] }
      let(:index) { 1 }

      it { is_expected.to be true }
    end

    context "with whitespace between inline elements" do
      let(:siblings) do
        ast = Herb.parse("<div><span>a</span>  <em>b</em></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[2] }
      let(:index) { 2 }

      it { is_expected.to be false }
    end

    context "with block element after inline" do
      let(:siblings) do
        ast = Herb.parse("<div><span>a</span><div>b</div></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[1] }
      let(:index) { 1 }

      it { is_expected.to be false }
    end

    context "with block element before inline" do
      let(:siblings) do
        ast = Herb.parse("<div><div>a</div><span>b</span></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[1] }
      let(:index) { 1 }

      it { is_expected.to be false }
    end

    context "with no previous sibling" do
      let(:siblings) do
        ast = Herb.parse("<div><span>a</span></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[0] }
      let(:index) { 0 }

      it { is_expected.to be false }
    end

    context "with ERB control flow after inline element" do
      let(:siblings) do
        ast = Herb.parse("<div><span>a</span><% if true %><% end %></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[1] }
      let(:index) { 1 }

      it { is_expected.to be false }
    end

    context "with inline element after ERB (no whitespace)" do
      let(:siblings) do
        ast = Herb.parse("<div><%= @val %><span>a</span></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[1] }
      let(:index) { 1 }

      it { is_expected.to be true }
    end

    context "with block element after text (no whitespace)" do
      let(:siblings) do
        ast = Herb.parse("<div>text<div>b</div></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[1] }
      let(:index) { 1 }

      it { is_expected.to be false }
    end

    context "with block element after ERB (no whitespace)" do
      let(:siblings) do
        ast = Herb.parse("<div><%= @val %><div>b</div></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[1] }
      let(:index) { 1 }

      it { is_expected.to be false }
    end

    context "with ERB control flow as previous sibling" do
      let(:siblings) do
        ast = Herb.parse("<div><% if true %><% end %><span>a</span></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[1] }
      let(:index) { 1 }

      it { is_expected.to be false }
    end
  end

  describe "#needs_space_between?" do
    subject { helper.needs_space_between?(current_line, word) }

    context "with two regular words" do
      let(:current_line) { "Hello" }
      let(:word) { "world" }

      it { is_expected.to be true }
    end

    context "with closing punctuation as word" do
      let(:current_line) { "text" }
      let(:word) { ")" }

      it { is_expected.to be false }
    end

    context "with period as word" do
      let(:current_line) { "text" }
      let(:word) { "." }

      it { is_expected.to be false }
    end

    context "with comma as word" do
      let(:current_line) { "text" }
      let(:word) { "," }

      it { is_expected.to be false }
    end

    context "with current line ending with opening punctuation" do
      let(:current_line) { "(" }
      let(:word) { "text" }

      it { is_expected.to be false }
    end

    context "with current line ending with opening bracket" do
      let(:current_line) { "[" }
      let(:word) { "text" }

      it { is_expected.to be false }
    end

    context "with ERB tag after special symbol" do
      let(:current_line) { "$" }
      let(:word) { "<%= value %>" }

      it { is_expected.to be false }
    end

    context "with ERB tag after regular word" do
      let(:current_line) { "text" }
      let(:word) { "<%= value %>" }

      it { is_expected.to be true }
    end

    context "with regular word after ERB tag" do
      let(:current_line) { "<%= value %>" }
      let(:word) { "text" }

      it { is_expected.to be true }
    end
  end

  describe "#closing_punctuation?" do
    subject { helper.closing_punctuation?(word) }

    context "with a closing punctuation character" do
      let(:word) { ")" }

      it { is_expected.to be true }
    end

    context "with multiple punctuation characters" do
      let(:word) { ")." }

      it { is_expected.to be true }
    end

    context "with regular word" do
      let(:word) { "hello" }

      it { is_expected.to be false }
    end

    context "with word ending in punctuation" do
      let(:word) { "hello." }

      it { is_expected.to be false }
    end
  end

  describe "#opening_punctuation?" do
    subject { helper.opening_punctuation?(word) }

    context "with an opening punctuation character" do
      let(:word) { "(" }

      it { is_expected.to be true }
    end

    context "with word ending in opening punctuation" do
      let(:word) { "func(" }

      it { is_expected.to be true }
    end

    context "with regular word" do
      let(:word) { "hello" }

      it { is_expected.to be false }
    end

    context "with closing punctuation" do
      let(:word) { ")" }

      it { is_expected.to be false }
    end
  end

  describe "#ends_with_erb_tag?" do
    subject { helper.ends_with_erb_tag?(text) }

    context "with text ending in ERB tag" do
      let(:text) { "<%= value %>" }

      it { is_expected.to be true }
    end

    context "with text ending in ERB comment tag" do
      let(:text) { "<%# comment %>" }

      it { is_expected.to be true }
    end

    context "with text ending in ERB tag followed by space" do
      let(:text) { "<%= value %> " }

      it { is_expected.to be false }
    end

    context "with regular text" do
      let(:text) { "hello world" }

      it { is_expected.to be false }
    end

    context "with ERB tag in the middle" do
      let(:text) { "<%= value %> more" }

      it { is_expected.to be false }
    end
  end

  describe "#starts_with_erb_tag?" do
    subject { helper.starts_with_erb_tag?(text) }

    context "with text starting with ERB output tag" do
      let(:text) { "<%= value %>" }

      it { is_expected.to be true }
    end

    context "with text starting with ERB code tag" do
      let(:text) { "<% code %>" }

      it { is_expected.to be true }
    end

    context "with text starting with ERB comment tag" do
      let(:text) { "<%# comment %>" }

      it { is_expected.to be true }
    end

    context "with regular text" do
      let(:text) { "hello world" }

      it { is_expected.to be false }
    end

    context "with ERB tag preceded by other text" do
      let(:text) { "before <%= value %>" }

      it { is_expected.to be false }
    end
  end

  describe "#herb_disable_comment?" do
    subject { helper.herb_disable_comment?(node) }

    context "with herb:disable comment" do
      let(:node) do
        ast = Herb.parse("<%# herb:disable %>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be true }
    end

    context "with herb:disable-next-line comment" do
      let(:node) do
        ast = Herb.parse("<%# herb:disable-next-line %>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be true }
    end

    context "with regular ERB comment" do
      let(:node) do
        ast = Herb.parse("<%# regular comment %>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to be false }
    end

    context "with ERB output node" do
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

  describe "#dedent" do
    subject { helper.dedent(text) }

    context "with uniformly indented text" do
      let(:text) { "  hello\n  world" }

      it { is_expected.to eq("hello\nworld") }
    end

    context "with mixed indentation" do
      let(:text) { "  hello\n    world\n  end" }

      it { is_expected.to eq("hello\n  world\nend") }
    end

    context "with no indentation" do
      let(:text) { "hello\nworld" }

      it { is_expected.to eq("hello\nworld") }
    end

    context "with blank lines preserved" do
      let(:text) { "  hello\n\n  world" }

      it { is_expected.to eq("hello\n\nworld") }
    end

    context "with single line" do
      let(:text) { "  hello" }

      it { is_expected.to eq("hello") }
    end

    context "with empty string" do
      let(:text) { "" }

      it { is_expected.to eq("") }
    end
  end

  describe "#get_tag_name" do
    subject { helper.get_tag_name(node) }

    context "with a div element" do
      let(:node) do
        ast = Herb.parse("<div></div>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to eq("div") }
    end

    context "with a span element" do
      let(:node) do
        ast = Herb.parse("<span></span>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to eq("span") }
    end

    context "with uppercase tag name" do
      let(:node) do
        ast = Herb.parse("<DIV></DIV>", track_whitespace: true).value
        ast.children.first
      end

      it { is_expected.to eq("DIV") }
    end
  end

  describe "#should_preserve_user_spacing?" do
    subject { helper.should_preserve_user_spacing?(child, siblings, index) }

    context "with double newline whitespace between meaningful nodes" do
      let(:siblings) do
        ast = Herb.parse("<div><p>a</p>\n\n<p>b</p></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:index) { 1 }
      let(:child) { siblings[index] }

      it { is_expected.to be true }
    end

    context "with single newline whitespace between meaningful nodes" do
      let(:siblings) do
        ast = Herb.parse("<div><p>a</p>\n<p>b</p></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:index) { 1 }
      let(:child) { siblings[index] }

      it { is_expected.to be false }
    end

    context "with non-whitespace node" do
      let(:siblings) do
        ast = Herb.parse("<div><p>a</p><p>b</p></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:child) { siblings[0] }
      let(:index) { 0 }

      it { is_expected.to be false }
    end

    context "with whitespace at start (no previous meaningful node)" do
      let(:siblings) do
        ast = Herb.parse("<div>\n\n<p>b</p></div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:index) { 0 }
      let(:child) { siblings[index] }

      it { is_expected.to be false }
    end

    context "with whitespace at end (no next meaningful node)" do
      let(:siblings) do
        ast = Herb.parse("<div><p>a</p>\n\n</div>", track_whitespace: true).value
        ast.children.first.body
      end
      let(:index) { 1 }
      let(:child) { siblings[index] }

      it { is_expected.to be false }
    end
  end
end
