# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::ErbNoEmptyTags do
  describe ".rule_name" do
    it "returns 'erb-no-empty-tags'" do
      expect(described_class.rule_name).to eq("erb-no-empty-tags")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow empty ERB tags")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe ".autocorrectable?" do
    it "returns true" do
      expect(described_class.autocorrectable?).to be(true)
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(template, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when ERB tag has content" do
      let(:template) { "<% do_something %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB output tag has content" do
      let(:template) { "<%= value %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag is completely empty" do
      let(:template) { "<%=%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-empty-tags")
        expect(subject.first.message).to eq("Remove empty ERB tag")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when ERB tag contains only one space" do
      let(:template) { "<% %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-empty-tags")
        expect(subject.first.message).to eq("Remove empty ERB tag")
      end
    end

    context "when ERB tag contains only multiple spaces" do
      let(:template) { "<%  %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-empty-tags")
      end
    end

    context "when ERB output tag contains only whitespace" do
      let(:template) { "<%= %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-empty-tags")
      end
    end

    context "when multiple empty tags exist" do
      let(:template) do
        <<~ERB
          <% %>
          <p>content</p>
          <%= %>
        ERB
      end

      it "reports an offense for each empty tag" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:line)).to contain_exactly(1, 3)
      end
    end

    context "when both empty and non-empty tags exist" do
      let(:template) do
        <<~ERB
          <% value %>
          <% %>
          <%= another_value %>
        ERB
      end

      it "reports only one offense for the empty tag" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "when ERB tag contains only whitespace (tabs/newlines/mixed)" do
      let(:template) { "<% \t\n %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-empty-tags")
      end
    end

    context "when empty tags are in HTML" do
      let(:template) do
        <<~ERB
          <div>
            <% %>
            <p>text</p>
          </div>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "when ERB tag has content with leading/trailing spaces" do
      let(:template) { "<%  foo  %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end

  describe "#autofix" do
    subject { described_class.new.autofix(node, document) }

    let(:document) { Herb.parse(template, track_whitespace: true) }

    context "when fixing a simple empty tag" do
      let(:template) { "<% %>" }
      let(:node) { document.value.children.first }

      it "removes the empty tag and returns true" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq("")
      end
    end

    context "when fixing an empty output tag" do
      let(:template) { "<%= %>" }
      let(:node) { document.value.children.first }

      it "removes the empty tag" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq("")
      end
    end

    context "when fixing an empty tag with surrounding content" do
      let(:template) { "<p>before</p><% %><p>after</p>" }
      let(:node) { document.value.children.find { |n| n.is_a?(Herb::AST::ERBContentNode) } }

      it "removes only the empty tag" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq("<p>before</p><p>after</p>")
      end
    end

    context "when fixing multiple empty tags in sequence" do
      let(:template) do
        <<~ERB
          <% %>
          <p>content</p>
          <%= %>
        ERB
      end

      it "can fix each tag independently" do
        nodes = document.value.children.select { |n| n.is_a?(Herb::AST::ERBContentNode) }
        expect(nodes.size).to eq(2)

        # Fix first empty tag
        result1 = described_class.new.autofix(nodes[0], document)
        expect(result1).to be(true)

        # Fix second empty tag
        result2 = described_class.new.autofix(nodes[1], document)
        expect(result2).to be(true)

        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq("\n<p>content</p>\n\n")
      end
    end

    context "when fixing an empty tag with tabs and newlines" do
      let(:template) { "<% \t\n %>" }
      let(:node) { document.value.children.first }

      it "removes the empty tag" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq("")
      end
    end

    context "when empty tags are in HTML structure" do
      let(:template) do
        <<~ERB
          <div>
            <% %>
            <p>text</p>
          </div>
        ERB
      end
      let(:node) do
        # Find the ERB content node inside the div
        div = document.value.children.find { |n| n.is_a?(Herb::AST::HTMLElementNode) }
        div.body.find { |n| n.is_a?(Herb::AST::ERBContentNode) }
      end

      it "removes the empty tag from HTML structure" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq("<div>\n  \n  <p>text</p>\n</div>\n")
      end
    end
  end
end
