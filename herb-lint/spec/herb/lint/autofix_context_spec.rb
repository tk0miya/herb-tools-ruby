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

  describe "#autofixable?" do
    subject { autofix_context.autofixable?(unsafe:) }

    context "with unsafe: false" do
      let(:unsafe) { false }

      context "when rule declares safe_autofixable?" do
        let(:rule) do
          Class.new(Herb::Lint::Rules::VisitorRule) do
            def self.rule_name = "test/safe-rule"
            def self.description = "Safe test rule"
            def self.safe_autofixable? = true
            def self.unsafe_autofixable? = false
          end.new(matcher: build(:pattern_matcher))
        end

        it { is_expected.to be true }
      end

      context "when rule declares unsafe_autofixable?" do
        let(:rule) do
          Class.new(Herb::Lint::Rules::VisitorRule) do
            def self.rule_name = "test/unsafe-rule"
            def self.description = "Unsafe test rule"
            def self.safe_autofixable? = false
            def self.unsafe_autofixable? = true
          end.new(matcher: build(:pattern_matcher))
        end

        it { is_expected.to be false }
      end

      context "when rule declares neither" do
        it { is_expected.to be false }
      end
    end

    context "with unsafe: true" do
      let(:unsafe) { true }

      context "when rule declares safe_autofixable?" do
        let(:rule) do
          Class.new(Herb::Lint::Rules::VisitorRule) do
            def self.rule_name = "test/safe-rule"
            def self.description = "Safe test rule"
            def self.safe_autofixable? = true
            def self.unsafe_autofixable? = false
          end.new(matcher: build(:pattern_matcher))
        end

        it { is_expected.to be true }
      end

      context "when rule declares unsafe_autofixable?" do
        let(:rule) do
          Class.new(Herb::Lint::Rules::VisitorRule) do
            def self.rule_name = "test/unsafe-rule"
            def self.description = "Unsafe test rule"
            def self.safe_autofixable? = false
            def self.unsafe_autofixable? = true
          end.new(matcher: build(:pattern_matcher))
        end

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

    it "is not equal when rule differs" do
      other = described_class.new(node:,
                                  rule: Herb::Lint::Rules::Html::TagNameLowercase.new(matcher: build(:pattern_matcher)))
      expect(autofix_context).not_to eq(other)
    end
  end
end
