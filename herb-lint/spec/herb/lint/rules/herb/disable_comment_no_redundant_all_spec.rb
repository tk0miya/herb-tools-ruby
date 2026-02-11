# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HerbDirective::DisableCommentNoRedundantAll do
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
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context, source:) }

    context "when comment is not a directive" do
      let(:source) { "<%# This is a regular comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Good examples from documentation
    context "when herb:disable all is used alone" do
      let(:source) { "<DIV>test</DIV> <%# herb:disable all %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable is used with multiple specific rules" do
      let(:source) do
        "<DIV class='value'>test</DIV> <%# herb:disable html-tag-name-lowercase, html-attribute-double-quotes %>"
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable is used with one specific rule" do
      let(:source) { "<DIV>test</DIV> <%# herb:disable html-tag-name-lowercase %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when herb:disable all is used with a specific rule" do
      let(:source) { "<DIV>test</DIV> <%# herb:disable all, html-tag-name-lowercase %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("herb-disable-comment-no-redundant-all")
        expect(subject.first.message).to eq(
          "Redundant rule name `html-tag-name-lowercase` when `all` is already specified"
        )
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when herb:disable has specific rule before all and after all" do
      let(:source) { "<DIV>test</DIV> <%# herb:disable html-tag-name-lowercase, all, html-attribute-double-quotes %>" }

      it "reports an offense for each redundant rule" do
        expect(subject.size).to eq(2)
        expect(subject[0].message).to eq(
          "Redundant rule name `html-tag-name-lowercase` when `all` is already specified"
        )
        expect(subject[1].message).to eq(
          "Redundant rule name `html-attribute-double-quotes` when `all` is already specified"
        )
      end
    end

    context "when herb:disable all is used multiple times" do
      let(:source) { "<DIV>test</DIV> <%# herb:disable all, all %>" }

      it "reports an offense for the duplicate all" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Redundant rule name `all` when `all` is already specified")
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
