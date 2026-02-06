# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::ErbCommentSyntax do
  describe ".rule_name" do
    it "returns 'erb-comment-syntax'" do
      expect(described_class.rule_name).to eq("erb-comment-syntax")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Enforce ERB comment style")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe ".safe_autocorrectable?" do
    it "returns true" do
      expect(described_class.safe_autocorrectable?).to be(true)
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when using proper ERB comment syntax" do
      let(:source) { "<%# This is a comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using statement tag with Ruby line comment" do
      let(:source) { "<% # This is a comment %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-comment-syntax")
        expect(subject.first.message).to eq("Use ERB comment tag `<%#` instead of `<% #`")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when ERB tag contains code, not a comment" do
      let(:source) { "<% foo %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB output tag is used" do
      let(:source) { "<%= output %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple bad comments exist" do
      let(:source) do
        <<~ERB
          <% # first comment %>
          <p>content</p>
          <% # second comment %>
        ERB
      end

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
      end
    end

    context "when both good and bad comments exist" do
      let(:source) do
        <<~ERB
          <%# good comment %>
          <% # bad comment %>
        ERB
      end

      it "reports only one offense for the bad comment" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "when statement tag has multiple spaces before hash" do
      let(:source) { "<%   # comment %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-comment-syntax")
      end
    end

    context "when code contains a hash character in non-comment context" do
      let(:source) { "<% foo(a: 1) # inline comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end

  describe "#autofix" do
    subject { described_class.new.autofix(node, document) }

    let(:document) { Herb.parse(source, track_whitespace: true) }

    context "when fixing a simple comment" do
      let(:source) { "<% # This is a comment %>" }
      let(:expected) { "<%# This is a comment %>" }
      let(:node) { document.value.children.first }

      it "converts to ERB comment tag and returns true" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a comment with multiple spaces before hash" do
      let(:source) { "<%   # comment %>" }
      let(:expected) { "<%# comment %>" }
      let(:node) { document.value.children.first }

      it "converts to ERB comment tag" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a comment with no space after hash" do
      let(:source) { "<% #comment %>" }
      let(:expected) { "<%#comment %>" }
      let(:node) { document.value.children.first }

      it "converts to ERB comment tag" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing multiple comments in sequence" do
      let(:source) do
        <<~ERB
          <% # first comment %>
          <p>content</p>
          <% # second comment %>
        ERB
      end
      let(:expected) { "<%# first comment %>\n<p>content</p>\n<%# second comment %>\n" }

      it "can fix each comment independently" do
        nodes = document.value.children.select { |n| n.is_a?(Herb::AST::ERBContentNode) }
        expect(nodes.size).to eq(2)

        # Fix first comment
        result1 = described_class.new.autofix(nodes[0], document)
        expect(result1).to be(true)

        # Fix second comment
        result2 = described_class.new.autofix(nodes[1], document)
        expect(result2).to be(true)

        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end
  end
end
