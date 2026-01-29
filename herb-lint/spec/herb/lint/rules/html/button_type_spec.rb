# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::ButtonType do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context) }

  describe ".rule_name" do
    it "returns 'html/button-type'" do
      expect(described_class.rule_name).to eq("html/button-type")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require type attribute on button elements")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    context "when button has type='button'" do
      let(:template) { '<button type="button">Click</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when button has type='submit'" do
      let(:template) { '<button type="submit">Submit</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when button has type='reset'" do
      let(:template) { '<button type="reset">Reset</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when button is missing type attribute" do
      let(:template) { "<button>Click</button>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/button-type")
        expect(subject.first.message).to eq("Missing type attribute on button element (defaults to 'submit')")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when button has other attributes but no type" do
      let(:template) { '<button class="btn" id="save">Save</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/button-type")
      end
    end

    context "when there are multiple buttons without type" do
      let(:template) do
        <<~HTML
          <button>First</button>
          <button>Second</button>
        HTML
      end

      it "reports an offense for each button" do
        expect(subject.size).to eq(2)
      end
    end

    context "when some buttons have type and some do not" do
      let(:template) do
        <<~HTML
          <button type="button">OK</button>
          <button>Missing</button>
          <button type="submit">Submit</button>
        HTML
      end

      it "reports an offense only for the button without type" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Missing type attribute on button element (defaults to 'submit')")
      end
    end

    context "when type attribute is uppercase" do
      let(:template) { '<button TYPE="button">Click</button>' }

      it "does not report an offense (case-insensitive check)" do
        expect(subject).to be_empty
      end
    end

    context "when element is not a button" do
      let(:template) { '<div class="btn">Click</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with nested buttons" do
      let(:template) do
        <<~HTML
          <form>
            <button>First</button>
            <div>
              <button>Second</button>
            </div>
          </form>
        HTML
      end

      it "reports an offense for each button" do
        expect(subject.size).to eq(2)
      end
    end
  end
end
