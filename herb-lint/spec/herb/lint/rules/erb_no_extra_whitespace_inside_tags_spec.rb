# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::ErbNoExtraWhitespaceInsideTags do
  describe ".rule_name" do
    it "returns 'erb-no-extra-whitespace-inside-tags'" do
      expect(described_class.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow extra whitespace inside ERB tag delimiters")
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

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when ERB tag has single space on each side" do
      let(:source) { "<% value %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB output tag has single space on each side" do
      let(:source) { "<%= value %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag has no spaces (touching delimiters)" do
      let(:source) { "<%value%>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag has two spaces at the beginning" do
      let(:source) { "<%  value %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
        expect(subject.first.message).to eq("Remove extra whitespace inside ERB tag")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when ERB tag has two spaces at the end" do
      let(:source) { "<% value  %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
      end
    end

    context "when ERB tag has two spaces on both sides" do
      let(:source) { "<%  value  %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
      end
    end

    context "when ERB output tag has multiple spaces at the beginning" do
      let(:source) { "<%=   value %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
      end
    end

    context "when ERB tag has tabs at the beginning" do
      let(:source) { "<%\t\tvalue %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
      end
    end

    context "when ERB tag has tabs at the end" do
      let(:source) { "<% value\t\t%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
      end
    end

    context "when ERB tag has mixed spaces and tabs" do
      let(:source) { "<% \tvalue %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
      end
    end

    context "when ERB tag is empty" do
      let(:source) { "<%  %>" }

      it "does not report an offense (handled by erb-no-empty-tags)" do
        expect(subject).to be_empty
      end
    end

    context "when content has spaces within it" do
      let(:source) { "<% foo bar %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple tags have extra whitespace" do
      let(:source) do
        <<~ERB
          <%  first  %>
          <p>content</p>
          <%=  second  %>
        ERB
      end

      it "reports an offense for each tag" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:line)).to contain_exactly(1, 3)
      end
    end

    context "when only one tag has extra whitespace" do
      let(:source) do
        <<~ERB
          <% first %>
          <%  second  %>
          <%= third %>
        ERB
      end

      it "reports only one offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "when ERB tag is inside HTML" do
      let(:source) do
        <<~ERB
          <div>
            <%  value  %>
            <p>text</p>
          </div>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end
  end

  describe "#autofix" do
    subject { described_class.new.autofix(node, document) }

    let(:document) { Herb.parse(source, track_whitespace: true) }

    context "when fixing a tag with two spaces at the beginning" do
      let(:source) { "<%  value %>" }
      let(:expected) { "<% value %>" }
      let(:node) { document.value.children.first }

      it "removes extra leading whitespace and returns true" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a tag with two spaces at the end" do
      let(:source) { "<% value  %>" }
      let(:expected) { "<% value %>" }
      let(:node) { document.value.children.first }

      it "removes extra trailing whitespace" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a tag with two spaces on both sides" do
      let(:source) { "<%  value  %>" }
      let(:expected) { "<% value %>" }
      let(:node) { document.value.children.first }

      it "removes extra whitespace on both sides" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing an output tag with multiple spaces at the beginning" do
      let(:source) { "<%=   value %>" }
      let(:expected) { "<%= value %>" }
      let(:node) { document.value.children.first }

      it "removes extra leading whitespace keeping one space" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a tag with tabs at the beginning" do
      let(:source) { "<%\t\tvalue %>" }
      let(:expected) { "<% value %>" }
      let(:node) { document.value.children.first }

      it "removes extra leading tabs" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a tag with tabs at the end" do
      let(:source) { "<% value\t\t%>" }
      let(:expected) { "<% value %>" }
      let(:node) { document.value.children.first }

      it "removes extra trailing tabs" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a tag with mixed spaces and tabs" do
      let(:source) { "<% \tvalue %>" }
      let(:expected) { "<% value %>" }
      let(:node) { document.value.children.first }

      it "removes extra leading mixed whitespace" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a tag with surrounding content" do
      let(:source) { "<p>before</p><%  value  %><p>after</p>" }
      let(:expected) { "<p>before</p><% value %><p>after</p>" }
      let(:node) { document.value.children.find { |n| n.is_a?(Herb::AST::ERBContentNode) } }

      it "removes extra whitespace without affecting surrounding content" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing multiple tags in sequence" do
      let(:source) do
        <<~ERB
          <%  first  %>
          <p>content</p>
          <%=  second  %>
        ERB
      end
      let(:expected) { "<% first %>\n<p>content</p>\n<%= second %>\n" }

      it "can fix each tag independently" do
        nodes = document.value.children.select { |n| n.is_a?(Herb::AST::ERBContentNode) }
        expect(nodes.size).to eq(2)

        # Fix first tag
        result1 = described_class.new.autofix(nodes[0], document)
        expect(result1).to be(true)

        # Fix second tag
        result2 = described_class.new.autofix(nodes[1], document)
        expect(result2).to be(true)

        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a tag inside HTML structure" do
      let(:source) do
        <<~ERB
          <div>
            <%  value  %>
            <p>text</p>
          </div>
        ERB
      end
      let(:expected) { "<div>\n  <% value %>\n  <p>text</p>\n</div>\n" }
      let(:node) do
        # Find the ERB content node inside the div
        div = document.value.children.find { |n| n.is_a?(Herb::AST::HTMLElementNode) }
        div.body.find { |n| n.is_a?(Herb::AST::ERBContentNode) }
      end

      it "removes extra whitespace from tag inside HTML" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end
  end
end
