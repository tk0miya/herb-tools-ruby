# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::NoEmptyTags do
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

  describe ".safe_autofixable?" do
    it "returns true" do
      expect(described_class.safe_autofixable?).to be(true)
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    # Good examples from documentation
    context "when using ERB output tag with content (documentation example)" do
      let(:source) { "<%= user.name %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using ERB control flow with content (documentation example)" do
      let(:source) do
        <<~ERB
          <% if user.admin? %>
           Admin tools
          <% end %>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when ERB tag is empty with space" do
      let(:source) { "<% %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-empty-tags")
      end
    end

    context "when ERB output tag is empty with space" do
      let(:source) { "<%= %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-empty-tags")
      end
    end

    context "when ERB tag is empty with newline" do
      let(:source) do
        <<~ERB
          <%
          %>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-empty-tags")
      end
    end

    context "when ERB tag is completely empty" do
      let(:source) { "<%=%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-empty-tags")
        expect(subject.first.message).to eq("Remove empty ERB tag")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when ERB tag contains only multiple spaces" do
      let(:source) { "<%  %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-empty-tags")
      end
    end

    context "when multiple empty tags exist" do
      let(:source) do
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
      let(:source) do
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
      let(:source) { "<% \t\n %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-empty-tags")
      end
    end

    context "when empty tags are in HTML" do
      let(:source) do
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
      let(:source) { "<%  foo  %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end

  describe "#autofix" do
    subject { described_class.new(matcher:).autofix(node, document) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }

    context "when fixing a simple empty tag" do
      let(:source) { "<% %>" }
      let(:expected) { "" }
      let(:node) { document.value.children.first }

      it "removes the empty tag and returns true" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing an empty output tag" do
      let(:source) { "<%= %>" }
      let(:expected) { "" }
      let(:node) { document.value.children.first }

      it "removes the empty tag" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing an empty tag with surrounding content" do
      let(:source) { "<p>before</p><% %><p>after</p>" }
      let(:expected) { "<p>before</p><p>after</p>" }
      let(:node) { document.value.children.find { |n| n.is_a?(Herb::AST::ERBContentNode) } }

      it "removes only the empty tag" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing an empty tag with tabs and newlines" do
      let(:source) { "<% \t\n %>" }
      let(:expected) { "" }
      let(:node) { document.value.children.first }

      it "removes the empty tag" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end
  end
end
