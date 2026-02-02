# frozen_string_literal: true

RSpec.describe Herb::Lint::AutofixContext do
  subject { described_class.new(node:, rule_class:) }

  let(:source) { '<img src="test.png">' }
  let(:parse_result) { Herb.parse(source, track_whitespace: true) }
  let(:node) { parse_result.value.children.first }
  let(:rule_class) { Herb::Lint::Rules::HtmlImgRequireAlt }

  describe "#node" do
    it "returns the direct node reference" do
      expect(subject.node).to equal(node)
    end
  end

  describe "#rule_class" do
    it "returns the rule class" do
      expect(subject.rule_class).to eq(Herb::Lint::Rules::HtmlImgRequireAlt)
    end
  end

  describe "equality" do
    it "is equal to another AutofixContext with the same attributes" do
      other = described_class.new(node:, rule_class:)
      expect(subject).to eq(other)
    end

    it "is not equal when rule_class differs" do
      other = described_class.new(node:, rule_class: Herb::Lint::Rules::HtmlTagNameLowercase)
      expect(subject).not_to eq(other)
    end
  end
end
