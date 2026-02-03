# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::ErbNoExtraWhitespaceInsideTags do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template, track_whitespace: true) }
  let(:context) { build(:context) }

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

  describe "#check" do
    context "when ERB tag has single space on each side" do
      let(:template) { "<% value %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB output tag has single space on each side" do
      let(:template) { "<%= value %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag has no spaces (touching delimiters)" do
      let(:template) { "<%value%>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag has two spaces at the beginning" do
      let(:template) { "<%  value %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
        expect(subject.first.message).to eq("Remove extra whitespace inside ERB tag")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when ERB tag has two spaces at the end" do
      let(:template) { "<% value  %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
      end
    end

    context "when ERB tag has two spaces on both sides" do
      let(:template) { "<%  value  %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
      end
    end

    context "when ERB output tag has multiple spaces at the beginning" do
      let(:template) { "<%=   value %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
      end
    end

    context "when ERB tag has tabs at the beginning" do
      let(:template) { "<%\t\tvalue %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
      end
    end

    context "when ERB tag has tabs at the end" do
      let(:template) { "<% value\t\t%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
      end
    end

    context "when ERB tag has mixed spaces and tabs" do
      let(:template) { "<% \tvalue %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-extra-whitespace-inside-tags")
      end
    end

    context "when ERB tag is empty" do
      let(:template) { "<%  %>" }

      it "does not report an offense (handled by erb-no-empty-tags)" do
        expect(subject).to be_empty
      end
    end

    context "when content has spaces within it" do
      let(:template) { "<% foo bar %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple tags have extra whitespace" do
      let(:template) do
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
      let(:template) do
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
      let(:template) do
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
end
