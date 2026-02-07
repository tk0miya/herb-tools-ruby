# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::CommentSyntax do
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
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
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
      let(:source) { "<%# This is a proper ERB comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using multi-line comment starting on new line" do
      let(:source) do
        <<~ERB.chomp
          <%
            # This is a proper ERB comment
          %>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using multi-line Ruby comments spanning multiple lines" do
      let(:source) do
        <<~ERB.chomp
          <%
            # Multi-line Ruby comment
            # spanning multiple lines
          %>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using statement tag with space before hash" do
      let(:source) { "<% # This should be an ERB comment %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-comment-syntax")
        expect(subject.first.message).to eq(
          "Use `<%#` instead of `<% #`. Ruby comments immediately after ERB tags can cause parsing issues."
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when using output tag with space before hash" do
      let(:source) { "<%= # This should also be an ERB comment %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-comment-syntax")
        expect(subject.first.message).to eq(
          "Use `<%#` instead of `<%= #`. Ruby comments immediately after ERB tags can cause parsing issues."
        )
      end
    end

    context "when ERB tag contains code, not a comment" do
      let(:source) { "<% foo %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB output tag is used with code" do
      let(:source) { "<%= output %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when code contains an inline comment after code" do
      let(:source) { "<% foo(a: 1) # inline comment %>" }

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

    context "when content contains herb:disable directive" do
      let(:source) { "<% # herb:disable erb-comment-syntax %>" }

      it "reports an offense with herb:disable specific message" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Use `<%#` instead of `<% #` for `herb:disable` directives. " \
          "Herb directives only work with ERB comment syntax (`<%# ... %>`)."
        )
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
