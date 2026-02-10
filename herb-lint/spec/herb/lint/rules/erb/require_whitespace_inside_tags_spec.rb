# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::RequireWhitespaceInsideTags do
  describe ".rule_name" do
    it "returns 'erb-require-whitespace-inside-tags'" do
      expect(described_class.rule_name).to eq("erb-require-whitespace-inside-tags")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require whitespace inside ERB tag delimiters")
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
    context "when ERB output tag has whitespace (documentation example)" do
      let(:source) { "<%= user.name %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB statement tag block has whitespace (documentation example)" do
      let(:source) do
        <<~ERB
          <% if admin %>
            Hello, admin.
          <% end %>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when ERB output tag has no whitespace after opening (documentation example)" do
      let(:source) { "<%=user.name %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-require-whitespace-inside-tags")
        expect(subject.first.message).to eq("Add whitespace inside ERB tag delimiters")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when ERB if tag has no whitespace after opening (documentation example)" do
      let(:source) { "<%if admin %>\n  Hello, admin.\n<% end %>" }

      it "reports an offense for the if tag" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-require-whitespace-inside-tags")
        expect(subject.first.message).to eq("Add whitespace inside ERB tag delimiters")
      end
    end

    context "when ERB end tag has no whitespace before closing (documentation example)" do
      let(:source) { "<% if admin %>\n  Hello, admin.\n<% end%>" }

      it "reports an offense for the end tag" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-require-whitespace-inside-tags")
        expect(subject.first.message).to eq("Add whitespace inside ERB tag delimiters")
      end
    end

    # Additional edge cases
    context "when ERB statement tag has whitespace inside" do
      let(:source) { "<% value %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB statement tag has no whitespace inside" do
      let(:source) { "<%value%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-require-whitespace-inside-tags")
        expect(subject.first.message).to eq("Add whitespace inside ERB tag delimiters")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when whitespace is missing only after opening delimiter" do
      let(:source) { "<%value %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when whitespace is missing only before closing delimiter" do
      let(:source) { "<% value%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when ERB tag uses tab as whitespace" do
      let(:source) { "<%\tvalue\t%>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag uses newline as whitespace" do
      let(:source) { "<%\nvalue\n%>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB trim tag has no whitespace inside" do
      let(:source) { "<%-value-%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when ERB trim tag has whitespace inside" do
      let(:source) { "<%- value -%>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB comment tag has no whitespace" do
      let(:source) { "<%#comment%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject[0].message).to eq("Add whitespace inside ERB tag delimiters")
      end
    end

    context "when ERB comment tag has proper whitespace" do
      let(:source) { "<%# comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB comment tag with equals has proper spacing" do
      let(:source) { "<%#= comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB comment tag with equals has no space after equals" do
      let(:source) { "<%#=comment%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-require-whitespace-inside-tags")
      end
    end

    context "when ERB tag is empty" do
      let(:source) { "<% %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple tags with missing whitespace exist" do
      let(:source) do
        <<~ERB
          <%value%>
          <p>content</p>
          <%=other%>
        ERB
      end

      it "reports an offense for each tag" do
        expect(subject.size).to eq(2)
      end
    end

    context "when both valid and invalid tags exist" do
      let(:source) do
        <<~ERB
          <% good %>
          <%bad%>
          <%= also_good %>
        ERB
      end

      it "reports only one offense for the invalid tag" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "when control flow if tag has no whitespace after opening" do
      let(:source) { "<%if true %>test<% end %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-require-whitespace-inside-tags")
      end
    end

    context "when control flow end tag has no whitespace before closing" do
      let(:source) { "<% if true %>test<% end%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when control flow unless tag has whitespace" do
      let(:source) { "<% unless false %>test<% end %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when control flow case tag has no whitespace" do
      let(:source) { "<%case value %><%when 1 %>one<% end %>" }

      it "reports an offense for the case tag" do
        offenses = subject.select { |o| o.message.include?("whitespace") }
        expect(offenses.size).to be >= 1
      end
    end
  end

  describe "#autofix" do
    subject { described_class.new(matcher:).autofix(node, document) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }

    context "when fixing a tag with no whitespace on either side" do
      let(:source) { "<%value%>" }
      let(:expected) { "<% value %>" }
      let(:node) { document.value.children.first }

      it "adds whitespace on both sides and returns true" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing an output tag with no whitespace" do
      let(:source) { "<%=value%>" }
      let(:expected) { "<%= value %>" }
      let(:node) { document.value.children.first }

      it "adds whitespace on both sides" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a tag missing whitespace only after opening" do
      let(:source) { "<%value %>" }
      let(:expected) { "<% value %>" }
      let(:node) { document.value.children.first }

      it "adds whitespace after opening" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a tag missing whitespace only before closing" do
      let(:source) { "<% value%>" }
      let(:expected) { "<% value %>" }
      let(:node) { document.value.children.first }

      it "adds whitespace before closing" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a trim tag with no whitespace" do
      let(:source) { "<%-value-%>" }
      let(:expected) { "<%- value -%>" }
      let(:node) { document.value.children.first }

      it "adds whitespace on both sides" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing multiple tags in sequence" do
      let(:source) do
        <<~ERB
          <%value%>
          <p>content</p>
          <%=other%>
        ERB
      end
      let(:expected) { "<% value %>\n<p>content</p>\n<%= other %>\n" }

      it "can fix each tag independently" do
        nodes = document.value.children.select { |n| n.is_a?(Herb::AST::ERBContentNode) }
        expect(nodes.size).to eq(2)

        result1 = described_class.new(matcher: build(:pattern_matcher)).autofix(nodes[0], document)
        expect(result1).to be(true)

        result2 = described_class.new(matcher: build(:pattern_matcher)).autofix(nodes[1], document)
        expect(result2).to be(true)

        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a comment tag with equals and no space" do
      let(:source) { "<%#=comment%>" }
      let(:expected) { "<%#= comment %>" }
      let(:node) { document.value.children.first }

      it "adds space after equals and before closing" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a control flow if tag with no whitespace" do
      let(:source) { "<%if true %>test<% end %>" }
      let(:expected) { "<% if true %>test<% end %>" }
      let(:node) { document.value.children.first }

      it "adds whitespace after opening" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end

    context "when fixing a control flow end tag with no whitespace" do
      let(:source) { "<% if true %>test<% end%>" }
      let(:expected) { "<% if true %>test<% end %>" }
      let(:node) { document.value.children.first.end_node }

      it "adds whitespace before closing" do
        expect(subject).to be(true)
        result = Herb::Printer::IdentityPrinter.print(document)
        expect(result).to eq(expected)
      end
    end
  end
end
