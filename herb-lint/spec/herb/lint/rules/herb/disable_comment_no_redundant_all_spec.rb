# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HerbDisableCommentNoRedundantAll do
  describe ".rule_name" do
    it "returns 'herb-disable-comment-no-redundant-all'" do
      expect(described_class.rule_name).to eq("herb-disable-comment-no-redundant-all")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow specific rule names alongside `all` in herb:disable comments")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context, source:) }

    context "when comment is not a directive" do
      let(:source) { "<%# This is a regular comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable all is used alone" do
      let(:source) { "<%# herb:disable all %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable is used with specific rules only" do
      let(:source) { "<%# herb:disable rule-name %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable all is used with a specific rule" do
      let(:source) { "<%# herb:disable all, rule-name %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("herb-disable-comment-no-redundant-all")
        expect(subject.first.message).to eq("Redundant rule name `rule-name` when `all` is already specified")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when herb:disable all is used with multiple specific rules" do
      let(:source) { "<%# herb:disable all, rule1, rule2 %>" }

      it "reports an offense for each redundant rule" do
        expect(subject.size).to eq(2)
        expect(subject[0].message).to eq("Redundant rule name `rule1` when `all` is already specified")
        expect(subject[1].message).to eq("Redundant rule name `rule2` when `all` is already specified")
      end
    end

    context "when specific rule is listed before all" do
      let(:source) { "<%# herb:disable rule-name, all %>" }

      it "reports an offense for the specific rule" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Redundant rule name `rule-name` when `all` is already specified")
      end
    end

    context "when multiple herb:disable comments exist" do
      let(:source) do
        <<~ERB
          <%# herb:disable all, rule-name %>
          <p>content</p>
          <%# herb:disable rule1, rule2 %>
        ERB
      end

      it "only reports offense for the comment with all and specific rules" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Redundant rule name `rule-name` when `all` is already specified")
      end
    end
  end
end
