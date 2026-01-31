# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HerbDisableCommentValidRuleName do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:valid_rule_names) do
    %w[
      erb-comment-syntax
      html-anchor-require-href
      html-attribute-double-quotes
      html-img-require-alt
      html-no-self-closing
      html-tag-name-lowercase
    ]
  end
  let(:context) { instance_double(Herb::Lint::Context, valid_rule_names:) }

  describe ".rule_name" do
    it "returns 'herb-disable-comment-valid-rule-name'" do
      expect(described_class.rule_name).to eq("herb-disable-comment-valid-rule-name")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow unknown rule names in herb:disable comments")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    context "when the comment is not a directive" do
      let(:template) { "<%# just a regular comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when the comment is a non-ERB-comment tag" do
      let(:template) { "<%= output %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable has a valid rule name" do
      let(:template) { "<%# herb:disable html-img-require-alt %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable has multiple valid rule names" do
      let(:template) { "<%# herb:disable html-img-require-alt, html-no-self-closing %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable uses 'all'" do
      let(:template) { "<%# herb:disable all %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable has a typo in a rule name" do
      let(:template) { "<%# herb:disable html-img-require-alts %>" }

      it "reports an offense with suggestion" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("herb-disable-comment-valid-rule-name")
        expect(subject.first.message).to include("Unknown rule `html-img-require-alts`")
        expect(subject.first.message).to include("Did you mean:")
        expect(subject.first.message).to include("html-img-require-alt")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when herb:disable has a completely unknown rule name" do
      let(:template) { "<%# herb:disable nonexistent-rule %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("herb-disable-comment-valid-rule-name")
        expect(subject.first.message).to include("Unknown rule `nonexistent-rule`")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when herb:disable has multiple unknown rule names" do
      let(:template) { "<%# herb:disable fake-rule, another-fake %>" }

      it "reports an offense for each unknown rule" do
        expect(subject.size).to eq(2)
        expect(subject[0].message).to include("Unknown rule `fake-rule`")
        expect(subject[1].message).to include("Unknown rule `another-fake`")
      end
    end

    context "when herb:disable has a mix of valid and invalid rule names" do
      let(:template) { "<%# herb:disable html-img-require-alt, nonexistent-rule %>" }

      it "reports an offense only for the invalid rule" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Unknown rule `nonexistent-rule`")
      end
    end

    context "when herb:disable has 'all' alongside an invalid rule" do
      let(:template) { "<%# herb:disable all, nonexistent-rule %>" }

      it "reports an offense for the invalid rule name" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Unknown rule `nonexistent-rule`")
      end
    end

    context "when the directive is malformed (no space after prefix)" do
      let(:template) { "<%# herb:disablerule-name %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable has no rules" do
      let(:template) { "<%# herb:disable %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when valid_rule_names is empty" do
      let(:valid_rule_names) { [] }
      let(:template) { "<%# herb:disable nonexistent-rule %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when there are multiple directive comments" do
      let(:template) do
        <<~ERB
          <%# herb:disable html-img-require-alt %>
          <div>content</div>
          <%# herb:disable nonexistent-rule %>
        ERB
      end

      it "reports an offense only for the comment with the unknown rule" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Unknown rule `nonexistent-rule`")
      end
    end

    context "when offense location is reported" do
      let(:template) { "<%# herb:disable nonexistent-rule %>" }

      it "reports the offense at the location of the unknown rule name" do
        offense = subject.first
        expect(offense.line).to eq(1)
        expect(offense.location).not_to be_nil
      end
    end
  end
end
