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

      it { is_expected.to be true }
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

      it { is_expected.to be false }
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
end
