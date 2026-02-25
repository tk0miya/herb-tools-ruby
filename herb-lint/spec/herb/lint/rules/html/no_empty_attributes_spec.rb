# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoEmptyAttributes do
  describe ".rule_name" do
    it "returns 'html-no-empty-attributes'" do
      expect(described_class.rule_name).to eq("html-no-empty-attributes")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow empty attribute values")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    def empty_attribute_message(name)
      "Attribute `#{name}` must not be empty. " \
        "Either provide a meaningful value or remove the attribute entirely."
    end

    # Good examples from documentation
    context "when restricted attribute has a non-empty value" do
      let(:source) { '<div id="header"></div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when src attribute has a non-empty value" do
      let(:source) { '<img src="/logo.png" alt="Company logo">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple restricted attributes have non-empty values" do
      let(:source) { '<input type="text" name="email" autocomplete="off">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when dynamic attributes have meaningful ERB output values" do
      let(:source) do
        <<~ERB
          <div data-<%= key %>="<%= value %>" aria-<%= prop %>="<%= description %>">
            Dynamic content
          </div>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has no attributes" do
      let(:source) { "<div>Plain div</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when id attribute has an empty value" do
      let(:source) { '<div id=""></div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-empty-attributes")
        expect(subject.first.message).to eq(empty_attribute_message("id"))
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when src attribute has an empty value" do
      let(:source) { '<img src="" alt="Company logo">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(empty_attribute_message("src"))
      end
    end

    context "when name attribute has an empty value" do
      let(:source) { '<input name="" autocomplete="off">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(empty_attribute_message("name"))
      end
    end

    context "when data- attribute has an empty value" do
      let(:source) { '<div data-config="">Content</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to start_with(
          "Data attribute `data-config` should not have an empty value."
        )
        expect(subject.first.message).to include(
          "Either provide a meaningful value or use `data-config` instead of"
        )
      end
    end

    context "when aria- attribute has an empty value" do
      let(:source) { '<button aria-label="">×</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(empty_attribute_message("aria-label"))
      end
    end

    context "when class attribute has an empty value" do
      let(:source) { '<div class="">Plain div</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(empty_attribute_message("class"))
      end
    end

    context "when dynamic attribute names have empty static values" do
      let(:source) do
        <<~ERB
          <div data-<%= key %>="" aria-<%= prop %>="   ">
            Problematic dynamic attributes
          </div>
        ERB
      end

      it "reports an offense for each attribute with an empty value" do
        expect(subject.size).to eq(2)
      end
    end

    # Additional edge cases
    context "when alt attribute has an empty value" do
      let(:source) { '<img alt="">' }

      it "does not report an offense (alt is not a restricted attribute)" do
        expect(subject).to be_empty
      end
    end

    context "when boolean attribute has no value" do
      let(:source) { "<input disabled>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when non-restricted attribute has an empty value" do
      let(:source) { '<input type="">' }

      it "does not report an offense (type is not a restricted attribute)" do
        expect(subject).to be_empty
      end
    end

    context "when multiple restricted attributes have empty values" do
      let(:source) { '<div class="" id="">text</div>' }

      it "reports an offense for each empty restricted attribute" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to contain_exactly(
          empty_attribute_message("class"),
          empty_attribute_message("id")
        )
      end
    end

    context "with mixed empty and non-empty restricted attributes" do
      let(:source) { '<div class="" id="main">text</div>' }

      it "reports offense only for the empty restricted attribute" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(empty_attribute_message("class"))
      end
    end

    context "with nested elements containing empty restricted attributes" do
      let(:source) do
        <<~HTML
          <div class="">
            <span id="">text</span>
          </div>
        HTML
      end

      it "reports an offense for each element" do
        expect(subject.size).to eq(2)
      end
    end
  end
end
