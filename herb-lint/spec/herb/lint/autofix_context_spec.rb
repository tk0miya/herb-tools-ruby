# frozen_string_literal: true

RSpec.describe Herb::Lint::AutofixContext do
  let(:source) { '<img src="test.png">' }
  let(:parse_result) { Herb.parse(source, track_whitespace: true) }
  let(:node) { parse_result.value.children.first }
  let(:rule) { Herb::Lint::Rules::Html::ImgRequireAlt.new(matcher: build(:pattern_matcher)) }
  let(:autofix_context) { described_class.new(node:, rule:) }

  describe "#node" do
    subject { autofix_context.node }

    it "returns the direct node reference" do
      expect(subject).to equal(node)
    end
  end

  describe "#rule" do
    subject { autofix_context.rule }

    it "returns the rule instance" do
      expect(subject).to be_a(Herb::Lint::Rules::Html::ImgRequireAlt)
    end
  end

  describe "#source_rule?" do
    subject { autofix_context.source_rule? }

    context "when created with node (visitor rule)" do
      let(:autofix_context) { described_class.new(node:, rule:) }

      it { is_expected.to be false }
    end

    context "when created with offsets (source rule)" do
      let(:autofix_context) do
        described_class.new(rule:, start_offset: 10, end_offset: 20)
      end

      it { is_expected.to be true }
    end
  end

  describe "#visitor_rule?" do
    subject { autofix_context.visitor_rule? }

    context "when created with node (visitor rule)" do
      let(:autofix_context) { described_class.new(node:, rule:) }

      it { is_expected.to be true }
    end

    context "when created with offsets (source rule)" do
      let(:autofix_context) do
        described_class.new(rule:, start_offset: 10, end_offset: 20)
      end

      it { is_expected.to be false }
    end
  end

  describe "#autofixable?" do
    subject { autofix_context.autofixable?(unsafe:) }

    context "with unsafe: false" do
      let(:unsafe) { false }

      context "when rule declares safe_autofixable?" do
        let(:rule) { TestRules::SafeFixableRule.new(matcher: build(:pattern_matcher)) }

        it { is_expected.to be true }
      end

      context "when rule declares unsafe_autofixable?" do
        let(:rule) { TestRules::UnsafeFixableRule.new(matcher: build(:pattern_matcher)) }

        it { is_expected.to be false }
      end

      context "when rule declares neither" do
        it { is_expected.to be false }
      end
    end

    context "with unsafe: true" do
      let(:unsafe) { true }

      context "when rule declares safe_autofixable?" do
        let(:rule) { TestRules::SafeFixableRule.new(matcher: build(:pattern_matcher)) }

        it { is_expected.to be true }
      end

      context "when rule declares unsafe_autofixable?" do
        let(:rule) { TestRules::UnsafeFixableRule.new(matcher: build(:pattern_matcher)) }

        it { is_expected.to be true }
      end

      context "when rule declares neither" do
        it { is_expected.to be false }
      end
    end
  end

  describe "equality" do
    it "is equal to another AutofixContext with the same attributes" do
      other = described_class.new(node:, rule:)
      expect(autofix_context).to eq(other)
    end

    it "is not equal when rule class differs" do
      other = described_class.new(node:,
                                  rule: Herb::Lint::Rules::Html::TagNameLowercase.new(matcher: build(:pattern_matcher)))
      expect(autofix_context).not_to eq(other)
    end
  end
end
