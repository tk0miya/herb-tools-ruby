# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HerbDisableCommentMalformed do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:directives) { Herb::Lint::DirectiveParser.parse(document, template) }
  let(:context) { instance_double(Herb::Lint::Context, directives:) }

  describe ".rule_name" do
    it "returns 'herb-disable-comment-malformed'" do
      expect(described_class.rule_name).to eq("herb-disable-comment-malformed")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Detect malformed herb:disable comments")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    context "when comment is not a directive" do
      let(:template) { "<%# regular comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable is properly formatted with a single rule" do
      let(:template) { "<%# herb:disable rule-name %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable is properly formatted with multiple rules" do
      let(:template) { "<%# herb:disable rule1, rule2 %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable has no rule names" do
      let(:template) { "<%# herb:disable %>" }

      it "does not report an offense (handled by herb-disable-comment-missing-rules)" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable uses 'all'" do
      let(:template) { "<%# herb:disable all %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when herb:disable is missing space before rule name" do
      let(:template) { "<%# herb:disablerule-name %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("herb-disable-comment-malformed")
        expect(subject.first.message).to match(/missing space after `herb:disable`/)
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when herb:disable has a leading comma" do
      let(:template) { "<%# herb:disable ,rule-name %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("herb-disable-comment-malformed")
        expect(subject.first.message).to match(/leading comma/)
      end
    end

    context "when herb:disable has a trailing comma" do
      let(:template) { "<%# herb:disable rule-name, %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("herb-disable-comment-malformed")
        expect(subject.first.message).to match(/trailing comma/)
      end
    end

    context "when herb:disable has consecutive commas" do
      let(:template) { "<%# herb:disable rule1,,rule2 %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("herb-disable-comment-malformed")
        expect(subject.first.message).to match(/consecutive commas/)
      end
    end

    context "when herb:disable has both leading and trailing commas" do
      let(:template) { "<%# herb:disable ,rule-name, %>" }

      it "reports offenses for both issues" do
        expect(subject.size).to eq(2)
        messages = subject.map(&:message)
        expect(messages).to include(match(/leading comma/))
        expect(messages).to include(match(/trailing comma/))
      end
    end

    context "when herb:disable has consecutive commas with spaces" do
      let(:template) { "<%# herb:disable rule1, , rule2 %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to match(/consecutive commas/)
      end
    end

    context "when non-comment ERB tag is used" do
      let(:template) { "<%= output %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple comments exist with one malformed" do
      let(:template) do
        <<~ERB
          <%# herb:disable rule-name %>
          <%# herb:disableother-rule %>
        ERB
      end

      it "reports only one offense for the malformed comment" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to match(/missing space/)
      end
    end
  end
end
