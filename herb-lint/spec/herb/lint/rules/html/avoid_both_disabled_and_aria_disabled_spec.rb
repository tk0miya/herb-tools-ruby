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
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    # Good examples from documentation
    context "when element has only disabled attribute" do
      let(:source) { "<button disabled>Submit</button>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when input has only disabled attribute with autocomplete" do
      let(:source) { '<input type="text" autocomplete="off" disabled>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when custom element has only aria-disabled" do
      let(:source) { '<div role="button" aria-disabled="true">Custom Button</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when button has only aria-disabled attribute" do
      let(:source) { '<button aria-disabled="true">Submit</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when button has both disabled and aria-disabled" do
      let(:source) { '<button disabled aria-disabled="true">Submit</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-avoid-both-disabled-and-aria-disabled")
        expect(subject.first.message).to eq(
          "aria-disabled may be used in place of native HTML disabled to allow tab-focus on an otherwise " \
          "ignored element. Setting both attributes is contradictory and confusing. Choose either disabled " \
          "or aria-disabled, not both."
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when input has both disabled and aria-disabled with autocomplete" do
      let(:source) { '<input type="text" autocomplete="off" disabled aria-disabled="true">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when select has both disabled and aria-disabled" do
      let(:source) do
        <<~HTML.chomp
          <select disabled aria-disabled="true">
           <option>Option 1</option>
          </select>
        HTML
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    # Additional edge case tests
    context "when element does not support native disabled attribute" do
      let(:source) { '<div disabled aria-disabled="true">Content</div>' }

      it "does not report an offense (div doesn't support native disabled)" do
        expect(subject).to be_empty
      end
    end

    context "when disabled attribute has ERB content" do
      let(:source) { '<button disabled="<%= @value %>" aria-disabled="true">Submit</button>' }

      it "does not report an offense (ERB content makes it dynamic)" do
        expect(subject).to be_empty
      end
    end

    context "when aria-disabled attribute has ERB content" do
      let(:source) { '<button disabled aria-disabled="<%= @value %>">Submit</button>' }

      it "does not report an offense (ERB content makes it dynamic)" do
        expect(subject).to be_empty
      end
    end

    context "when both attributes have ERB content" do
      let(:source) { '<button disabled="<%= @d %>" aria-disabled="<%= @a %>">Submit</button>' }

      it "does not report an offense (both have ERB content)" do
        expect(subject).to be_empty
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
  end
end
