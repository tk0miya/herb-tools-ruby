# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::NoSpaceBeforeClose do
  describe ".rule_name" do
    it "returns 'erb-no-space-before-close'" do
      expect(described_class.rule_name).to eq("erb-no-space-before-close")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow space before closing ERB tag delimiter")
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

    context "when ERB tag has no trailing space" do
      let(:source) { "<% foo %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag with right trim has no trailing space" do
      let(:source) { "<% foo -%>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag has one trailing space" do
      let(:source) { "<% foo  %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-space-before-close")
        expect(subject.first.message).to eq("Remove space before closing `%>`")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when ERB tag with right trim has trailing space" do
      let(:source) { "<% foo  -%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-space-before-close")
      end
    end

    context "when ERB tag has trailing tab" do
      let(:source) { "<% foo\t%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-space-before-close")
      end
    end

    context "when ERB comment tag has trailing space" do
      let(:source) { "<%# comment  %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag is empty" do
      let(:source) { "<% %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple ERB tags have trailing spaces" do
      let(:source) do
        <<~ERB
          <% foo  %>
          <%= bar %>
          <% baz  %>
        ERB
      end

      it "reports an offense for each tag with trailing space" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:line)).to contain_exactly(1, 3)
      end
    end

    context "when ERB tags are in HTML" do
      let(:source) do
        <<~ERB
          <div>
            <% value  %>
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

    context "when fixing an ERB tag with one trailing space" do
      let(:source) { "<% foo  %>" }
      let(:expected) { "<% foo %>" }
      let(:node) { document.value.children.first }

      it "removes the trailing space" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing an ERB tag with right trim and trailing space" do
      let(:source) { "<% foo  -%>" }
      let(:expected) { "<% foo -%>" }
      let(:node) { document.value.children.first }

      it "removes the trailing space before the trim marker" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing an ERB tag with trailing tab" do
      let(:source) { "<% foo\t%>" }
      let(:expected) { "<% foo %>" }
      let(:node) { document.value.children.first }

      it "removes the trailing tab" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing multiple ERB tags with trailing spaces" do
      let(:source) do
        <<~ERB
          <% foo  %>
          <%= bar %>
          <% baz  %>
        ERB
      end
      let(:expected) { "<% foo %>\n<%= bar %>\n<% baz %>\n" }

      it "can fix each tag independently" do
        nodes = document.value.children.select { |n| n.is_a?(Herb::AST::ERBContentNode) }
        expect(nodes.size).to eq(3)

        # Fix first tag with trailing space
        result1 = described_class.new.autofix(nodes[0], document)
        expect(result1).to be(true)

        # Fix third tag with trailing space
        result2 = described_class.new.autofix(nodes[2], document)
        expect(result2).to be(true)

        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing an ERB tag with surrounding content" do
      let(:source) { "<p>before</p><% foo  %><p>after</p>" }
      let(:expected) { "<p>before</p><% foo %><p>after</p>" }
      let(:node) { document.value.children.find { |n| n.is_a?(Herb::AST::ERBContentNode) } }

      it "removes only the trailing space from the ERB tag" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end
  end
end
