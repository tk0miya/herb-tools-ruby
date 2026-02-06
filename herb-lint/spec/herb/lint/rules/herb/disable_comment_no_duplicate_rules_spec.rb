# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HerbDisableCommentNoDuplicateRules do
  describe ".rule_name" do
    it "returns 'herb-disable-comment-no-duplicate-rules'" do
      expect(described_class.rule_name).to eq("herb-disable-comment-no-duplicate-rules")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow duplicate rule names in herb:disable comments")
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

    context "when the comment is not a directive" do
      let(:source) { "<%# just a regular comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when the comment is a non-ERB-comment tag" do
      let(:source) { "<%= output %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable has distinct rule names" do
      let(:source) { "<%# herb:disable rule1, rule2 %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable has a single rule name" do
      let(:source) { "<%# herb:disable rule1 %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable uses 'all'" do
      let(:source) { "<%# herb:disable all %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable has duplicate rule names" do
      let(:source) { "<%# herb:disable rule1, rule1 %>" }

      it "reports an offense for the duplicate" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("herb-disable-comment-no-duplicate-rules")
        expect(subject.first.message).to eq("Duplicate rule 'rule1' in herb:disable comment")
        expect(subject.first.severity).to eq("warning")
      end

      it "reports the offense at the location of the second occurrence" do
        offense = subject.first
        # The first "rule1" appears earlier in the comment;
        # the offense should be on the second one, which is at a higher column
        expect(offense.line).to eq(1)
        expect(offense.location).not_to be_nil
      end
    end

    context "when herb:disable has a rule duplicated three times" do
      let(:source) { "<%# herb:disable rule1, rule1, rule1 %>" }

      it "reports an offense for each duplicate" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to all(eq("Duplicate rule 'rule1' in herb:disable comment"))
      end
    end

    context "when herb:disable has multiple different duplicates" do
      let(:source) { "<%# herb:disable rule1, rule2, rule1, rule2 %>" }

      it "reports an offense for each duplicate" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to contain_exactly(
          "Duplicate rule 'rule1' in herb:disable comment",
          "Duplicate rule 'rule2' in herb:disable comment"
        )
      end
    end

    context "when there are multiple directive comments" do
      let(:source) do
        <<~ERB
          <%# herb:disable rule1, rule1 %>
          <div>content</div>
          <%# herb:disable rule2, rule3 %>
        ERB
      end

      it "reports an offense only for the comment with duplicates" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Duplicate rule 'rule1' in herb:disable comment")
      end
    end

    context "when the directive is malformed (no space after prefix)" do
      let(:source) { "<%# herb:disablerule1 %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable has no rules" do
      let(:source) { "<%# herb:disable %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end
end
