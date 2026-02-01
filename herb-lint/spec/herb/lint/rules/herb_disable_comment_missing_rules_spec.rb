# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HerbDisableCommentMissingRules do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(source) }
  let(:context) { build(:context, source:) }

  describe ".rule_name" do
    it "returns 'herb-disable-comment-missing-rules'" do
      expect(described_class.rule_name).to eq("herb-disable-comment-missing-rules")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require rule names in herb:disable comments")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    context "when comment is not a directive" do
      let(:source) { "<%# This is a regular comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable specifies a rule name" do
      let(:source) { "<%# herb:disable rule-name %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable specifies multiple rule names" do
      let(:source) { "<%# herb:disable rule1, rule2 %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable specifies all" do
      let(:source) { "<%# herb:disable all %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable has no rule names" do
      let(:source) { "<%# herb:disable %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("herb-disable-comment-missing-rules")
        expect(subject.first.message).to eq("`herb:disable` comment must specify at least one rule name or `all`")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when source has mixed comments" do
      let(:source) do
        <<~ERB
          <%# regular comment %>
          <%# herb:disable rule-name %>
          <%# herb:disable %>
        ERB
      end

      it "reports an offense only for the empty herb:disable comment" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(3)
      end
    end

    context "when source has no ERB comments" do
      let(:source) { "<div><p>Hello</p></div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable is malformed (no space after prefix)" do
      let(:source) { "<%# herb:disablerule-name %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end
end
