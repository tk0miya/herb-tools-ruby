# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::NoTrailingWhitespace do
  describe ".rule_name" do
    it "returns 'erb-no-trailing-whitespace'" do
      expect(described_class.rule_name).to eq("erb-no-trailing-whitespace")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow trailing whitespace in ERB tag content")
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

    context "when ERB tag has content with exactly one trailing space" do
      let(:source) { "<%= foo %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB statement tag has content with exactly one trailing space" do
      let(:source) { "<% bar %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB comment tag has content with exactly one trailing space" do
      let(:source) { "<%# comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag has content with two trailing spaces" do
      let(:source) { "<%= foo  %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-trailing-whitespace")
        expect(subject.first.message).to eq("Remove trailing whitespace in ERB tag")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when ERB tag has content with trailing tab" do
      let(:source) { "<%= foo\t%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-trailing-whitespace")
      end
    end

    context "when ERB tag has content with trailing newline" do
      let(:source) { "<%= foo\n%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-trailing-whitespace")
      end
    end

    context "when ERB tag has content with mixed trailing whitespace" do
      let(:source) { "<%= foo  \t %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-trailing-whitespace")
      end
    end

    context "when ERB tag has no trailing whitespace at all" do
      let(:source) { "<%=foo%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-trailing-whitespace")
      end
    end

    context "when multiple ERB tags have trailing whitespace issues" do
      let(:source) do
        <<~ERB
          <%= foo  %>
          <p>content</p>
          <%= bar\t%>
        ERB
      end

      it "reports an offense for each tag" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:line)).to contain_exactly(1, 3)
      end
    end

    context "when both correct and incorrect tags exist" do
      let(:source) do
        <<~ERB
          <%= foo %>
          <%= bar  %>
          <%= baz %>
        ERB
      end

      it "reports only one offense for the incorrect tag" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "when ERB tags are in HTML structure" do
      let(:source) do
        <<~ERB
          <div>
            <%= foo  %>
            <p>text</p>
          </div>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "when ERB tag has leading and trailing spaces" do
      let(:source) { "<%  foo  %>" }

      it "reports an offense for trailing whitespace" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-trailing-whitespace")
      end
    end
  end

  describe "#autofix" do
    subject { described_class.new.autofix(node, document) }

    let(:document) { Herb.parse(source, track_whitespace: true) }

    context "when fixing a tag with two trailing spaces" do
      let(:source) { "<%= foo  %>" }
      let(:expected) { "<%= foo %>" }
      let(:node) { document.value.children.first }

      it "removes extra trailing spaces and returns true" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a tag with trailing tab" do
      let(:source) { "<%= foo\t%>" }
      let(:expected) { "<%= foo %>" }
      let(:node) { document.value.children.first }

      it "removes trailing tab and adds single space" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a tag with trailing newline" do
      let(:source) { "<%= foo\n%>" }
      let(:expected) { "<%= foo %>" }
      let(:node) { document.value.children.first }

      it "removes trailing newline and adds single space" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a tag with mixed trailing whitespace" do
      let(:source) { "<%= foo  \t %>" }
      let(:expected) { "<%= foo %>" }
      let(:node) { document.value.children.first }

      it "removes all trailing whitespace and adds single space" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a tag with no trailing whitespace" do
      let(:source) { "<%=foo%>" }
      let(:expected) { "<%=foo %>" }
      let(:node) { document.value.children.first }

      it "adds single trailing space" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a tag with surrounding content" do
      let(:source) { "<p>before</p><%= foo  %><p>after</p>" }
      let(:expected) { "<p>before</p><%= foo %><p>after</p>" }
      let(:node) { document.value.children.find { |n| n.is_a?(Herb::AST::ERBContentNode) } }

      it "fixes only the ERB tag content" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing multiple tags with issues" do
      let(:source) do
        <<~ERB
          <%= foo  %>
          <p>content</p>
          <%= bar\t%>
        ERB
      end
      let(:expected) { "<%= foo %>\n<p>content</p>\n<%= bar %>\n" }

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

    context "when fixing tags in HTML structure" do
      let(:source) do
        <<~ERB
          <div>
            <%= foo  %>
            <p>text</p>
          </div>
        ERB
      end
      let(:expected) { "<div>\n  <%= foo %>\n  <p>text</p>\n</div>\n" }
      let(:node) do
        # Find the ERB content node inside the div
        div = document.value.children.find { |n| n.is_a?(Herb::AST::HTMLElementNode) }
        div.body.find { |n| n.is_a?(Herb::AST::ERBContentNode) }
      end

      it "fixes the ERB tag in HTML structure" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a statement tag with trailing spaces" do
      let(:source) { "<% bar  %>" }
      let(:expected) { "<% bar %>" }
      let(:node) { document.value.children.first }

      it "removes extra trailing spaces" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a comment tag with trailing spaces" do
      let(:source) { "<%# comment  %>" }
      let(:expected) { "<%# comment %>" }
      let(:node) { document.value.children.first }

      it "removes extra trailing spaces" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end
  end
end
