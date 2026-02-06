# frozen_string_literal: true

RSpec.describe Herb::Lint::AutofixContext do
  let(:source) { '<img src="test.png">' }
  let(:parse_result) { Herb.parse(source, track_whitespace: true) }
  let(:node) { parse_result.value.children.first }
  let(:rule_class) { Herb::Lint::Rules::Html::ImgRequireAlt }
  let(:autofix_context) { described_class.new(node:, rule_class:) }

  describe "#node" do
    subject { autofix_context.node }

    it "returns the direct node reference" do
      expect(subject).to equal(node)
    end
  end

  describe "#rule_class" do
    subject { autofix_context.rule_class }

    it "returns the rule class" do
      expect(subject).to eq(Herb::Lint::Rules::Html::ImgRequireAlt)
    end
  end

  describe "#autocorrectable?" do
    subject { autofix_context.autocorrectable?(unsafe:) }

    context "with unsafe: false" do
      let(:unsafe) { false }

      context "when rule declares safe_autocorrectable?" do
        let(:rule_class) do
          Class.new(Herb::Lint::Rules::VisitorRule) do
            def self.rule_name = "test/safe-rule"
            def self.description = "Safe test rule"
            def self.safe_autocorrectable? = true
          end
        end

        it { is_expected.to be true }
      end

      context "when rule declares unsafe_autocorrectable?" do
        let(:rule_class) do
          Class.new(Herb::Lint::Rules::VisitorRule) do
            def self.rule_name = "test/unsafe-rule"
            def self.description = "Unsafe test rule"
            def self.unsafe_autocorrectable? = true
          end
        end

        it { is_expected.to be false }
      end

      context "when rule declares neither" do
        it { is_expected.to be false }
      end
    end

    context "with unsafe: true" do
      let(:unsafe) { true }

      context "when rule declares safe_autocorrectable?" do
        let(:rule_class) do
          Class.new(Herb::Lint::Rules::VisitorRule) do
            def self.rule_name = "test/safe-rule"
            def self.description = "Safe test rule"
            def self.safe_autocorrectable? = true
          end
        end

        it { is_expected.to be true }
      end

      context "when rule declares unsafe_autocorrectable?" do
        let(:rule_class) do
          Class.new(Herb::Lint::Rules::VisitorRule) do
            def self.rule_name = "test/unsafe-rule"
            def self.description = "Unsafe test rule"
            def self.unsafe_autocorrectable? = true
          end
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
      other = described_class.new(node:, rule_class:)
      expect(autofix_context).to eq(other)
    end

    it "is not equal when rule_class differs" do
      other = described_class.new(node:, rule_class: Herb::Lint::Rules::Html::TagNameLowercase)
      expect(autofix_context).not_to eq(other)
    end
  end
end
