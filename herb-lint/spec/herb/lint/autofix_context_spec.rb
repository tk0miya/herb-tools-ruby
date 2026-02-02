# frozen_string_literal: true

RSpec.describe Herb::Lint::AutofixContext do
  subject { described_class.new(node_location:, node_type:, rule_class:) }

  let(:node_location) { build(:location) }
  let(:node_type) { "HTMLElementNode" }
  let(:rule_class) { Herb::Lint::Rules::HtmlImgRequireAlt }

  describe "#node_location" do
    it "returns the node location" do
      expect(subject.node_location).to eq(node_location)
    end
  end

  describe "#node_type" do
    it "returns the node type" do
      expect(subject.node_type).to eq("HTMLElementNode")
    end
  end

  describe "#rule_class" do
    it "returns the rule class" do
      expect(subject.rule_class).to eq(Herb::Lint::Rules::HtmlImgRequireAlt)
    end
  end

  describe "equality" do
    it "is equal to another AutofixContext with the same attributes" do
      other = described_class.new(node_location:, node_type:, rule_class:)
      expect(subject).to eq(other)
    end

    it "is not equal when node_type differs" do
      other = described_class.new(node_location:, node_type: "HTMLAttributeNode", rule_class:)
      expect(subject).not_to eq(other)
    end
  end
end
