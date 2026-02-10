# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::AriaRoleMustBeValid do
  describe ".rule_name" do
    it "returns 'html-aria-role-must-be-valid'" do
      expect(described_class.rule_name).to eq("html-aria-role-must-be-valid")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("The role attribute must contain a valid WAI-ARIA role")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when element has a valid role" do
      let(:source) { '<div role="button">Click me</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has an invalid role" do
      let(:source) { '<div role="invalid-role">Content</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-aria-role-must-be-valid")
        expect(subject.first.message).to eq("'invalid-role' is not a valid WAI-ARIA role")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when role attribute is empty" do
      let(:source) { '<div role="">Content</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("The role attribute must not be empty")
      end
    end

    context "when role attribute is whitespace-only" do
      let(:source) { '<div role="   ">Content</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("The role attribute must not be empty")
      end
    end

    context "when element has no role attribute" do
      let(:source) { "<div>Content</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when role attribute has multiple valid roles" do
      let(:source) { '<div role="button link">Content</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when role attribute has one invalid role among valid ones" do
      let(:source) { '<div role="button foobar">Content</div>' }

      it "reports an offense for the invalid role" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("'foobar' is not a valid WAI-ARIA role")
      end
    end

    context "when role attribute has multiple invalid roles" do
      let(:source) { '<div role="foo bar">Content</div>' }

      it "reports an offense for each invalid role" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to contain_exactly(
          "'foo' is not a valid WAI-ARIA role",
          "'bar' is not a valid WAI-ARIA role"
        )
      end
    end

    context "when role value is case-insensitive" do
      let(:source) { '<div role="Button">Content</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ROLE attribute name is uppercase" do
      let(:source) { '<div ROLE="navigation">Content</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple elements have role attributes" do
      let(:source) do
        <<~HTML
          <div role="button">OK</div>
          <div role="invalid">Bad</div>
          <div role="navigation">Nav</div>
        HTML
      end

      it "reports an offense only for invalid roles" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("'invalid' is not a valid WAI-ARIA role")
        expect(subject.first.line).to eq(2)
      end
    end

    context "when role is an abstract WAI-ARIA role" do
      let(:source) { '<div role="command">Content</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("'command' is not a valid WAI-ARIA role")
      end
    end

    context "with nested elements" do
      let(:source) do
        <<~HTML
          <div role="navigation">
            <div role="invalid">Content</div>
          </div>
        HTML
      end

      it "reports an offense for the invalid nested role" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("'invalid' is not a valid WAI-ARIA role")
      end
    end
  end
end
