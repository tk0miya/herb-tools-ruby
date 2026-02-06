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
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when ERB tag has content" do
      let(:source) { "<% do_something %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB output tag has content" do
      let(:source) { "<%= value %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB tag is completely empty" do
      let(:source) { "<%=%>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-empty-tags")
        expect(subject.first.message).to eq("ERB tag should not be empty. Remove empty ERB tags or add content.")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when ERB tag contains only one space" do
      let(:source) { "<% %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-empty-tags")
        expect(subject.first.message).to eq("ERB tag should not be empty. Remove empty ERB tags or add content.")
      end
    end

    context "when ERB tag contains only multiple spaces" do
      let(:source) { "<%  %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-empty-tags")
      end
    end

    context "when ERB output tag contains only whitespace" do
      let(:source) { "<%= %>" }

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
end
