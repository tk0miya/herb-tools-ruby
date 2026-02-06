# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::AvoidBothDisabledAndAriaDisabled do
  describe ".rule_name" do
    it "returns 'html-avoid-both-disabled-and-aria-disabled'" do
      expect(described_class.rule_name).to eq("html-avoid-both-disabled-and-aria-disabled")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq(
        "Disallow using both `disabled` and `aria-disabled` on the same element"
      )
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
    let(:context) { build(:context) }

    context "when element has only disabled attribute" do
      let(:source) { "<button disabled>Submit</button>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has only aria-disabled attribute" do
      let(:source) { '<button aria-disabled="true">Submit</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has both disabled and aria-disabled" do
      let(:source) { '<button disabled aria-disabled="true">Submit</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-avoid-both-disabled-and-aria-disabled")
        expect(subject.first.message).to eq(
          "Avoid using both 'disabled' and 'aria-disabled' on the same element; they are redundant"
        )
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when element has neither disabled nor aria-disabled" do
      let(:source) { "<button>Submit</button>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has both with aria-disabled set to false" do
      let(:source) { '<button disabled aria-disabled="false">Submit</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when element has both with uppercase attribute names" do
      let(:source) { '<button DISABLED ARIA-DISABLED="true">Submit</button>' }

      it "reports an offense (case-insensitive)" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-avoid-both-disabled-and-aria-disabled")
      end
    end

    context "when multiple elements each have both attributes" do
      let(:source) do
        <<~HTML
          <button disabled aria-disabled="true">Submit</button>
          <input disabled aria-disabled="true">
        HTML
      end

      it "reports an offense for each element" do
        expect(subject.size).to eq(2)
      end
    end

    context "when nested elements have different attributes" do
      let(:source) do
        <<~HTML
          <fieldset disabled>
            <button aria-disabled="true">Submit</button>
          </fieldset>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has other attributes alongside both disabled and aria-disabled" do
      let(:source) { '<button class="btn" disabled aria-disabled="true" id="submit">Submit</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when element has no attributes" do
      let(:source) { "<div>text</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when input element has only disabled" do
      let(:source) { '<input type="text" disabled>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when select element has both disabled and aria-disabled" do
      let(:source) { '<select disabled aria-disabled="true"><option>A</option></select>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-avoid-both-disabled-and-aria-disabled")
      end
    end
  end
end
