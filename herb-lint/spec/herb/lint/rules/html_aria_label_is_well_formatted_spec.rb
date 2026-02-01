# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlAriaLabelIsWellFormatted do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { build(:context) }

  describe ".rule_name" do
    it "returns 'html-aria-label-is-well-formatted'" do
      expect(described_class.rule_name).to eq("html-aria-label-is-well-formatted")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require well-formatted aria-label values")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    context "when aria-label has a well-formatted value" do
      let(:template) { '<button aria-label="Submit form">Submit</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when aria-label value is empty" do
      let(:template) { '<button aria-label="">Submit</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-aria-label-is-well-formatted")
        expect(subject.first.message).to eq("Unexpected empty aria-label value")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when aria-label value is whitespace only" do
      let(:template) { '<button aria-label="   ">Submit</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Unexpected empty aria-label value")
      end
    end

    context "when aria-label value starts with a lowercase letter" do
      let(:template) { '<button aria-label="submit form">Submit</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("aria-label value should start with an uppercase letter")
      end
    end

    context "when aria-label value has leading whitespace" do
      let(:template) { '<button aria-label=" Submit form">Submit</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Unexpected leading or trailing whitespace in aria-label value")
      end
    end

    context "when aria-label value has trailing whitespace" do
      let(:template) { '<button aria-label="Submit form ">Submit</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Unexpected leading or trailing whitespace in aria-label value")
      end
    end

    context "when aria-label starts with a number" do
      let(:template) { '<button aria-label="3 items in cart">Cart</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has no aria-label" do
      let(:template) { "<button>Submit</button>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ARIA-LABEL attribute is uppercase" do
      let(:template) { '<button ARIA-LABEL="Submit form">Submit</button>' }

      it "does not report an offense (case insensitive)" do
        expect(subject).to be_empty
      end
    end

    context "when multiple elements have invalid aria-label values" do
      let(:template) { '<button aria-label="">Submit</button><nav aria-label="">Nav</nav>' }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-aria-label-is-well-formatted"))
      end
    end

    context "with non-labeled elements" do
      let(:template) { '<div class="container"><p>Hello</p></div>' }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end

    context "with mixed valid and invalid aria-labels on multiple lines" do
      let(:template) do
        <<~HTML
          <button aria-label="Submit form">Submit</button>
          <button aria-label="">Cancel</button>
          <nav aria-label="Main navigation">Nav</nav>
        HTML
      end

      it "reports offense only for the invalid aria-label with correct line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end
  end
end
