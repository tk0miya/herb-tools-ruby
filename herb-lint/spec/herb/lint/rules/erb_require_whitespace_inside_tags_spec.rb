# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::ErbRequireWhitespaceInsideTags do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template, track_whitespace: true) }
  let(:context) { build(:context) }

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

  describe "#check" do
    context "when ERB statement tag has whitespace inside" do
      let(:template) { "<% value %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB output tag has whitespace inside" do
      let(:template) { "<%= value %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB statement tag has no whitespace inside" do
      let(:template) { "<%value%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-require-whitespace-inside-tags")
        expect(subject.first.message).to eq("Add whitespace inside ERB tag delimiters")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when ERB output tag has no whitespace inside" do
      let(:template) { "<%=value%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-require-whitespace-inside-tags")
      end
    end

    context "when whitespace is missing only after opening delimiter" do
      let(:template) { "<%value %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when whitespace is missing only before closing delimiter" do
      let(:template) { "<% value%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when ERB tag uses tab as whitespace" do
      let(:template) { "<%\tvalue\t%>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag uses newline as whitespace" do
      let(:template) { "<%\nvalue\n%>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB trim tag has no whitespace inside" do
      let(:template) { "<%-value-%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when ERB trim tag has whitespace inside" do
      let(:template) { "<%- value -%>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB comment tag has no whitespace" do
      let(:template) { "<%#comment%>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag is empty" do
      let(:template) { "<% %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple tags with missing whitespace exist" do
      let(:template) do
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
      let(:template) do
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
  end
end
