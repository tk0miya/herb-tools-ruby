# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::A11y::NoAccessKey do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context) }

  describe ".rule_name" do
    it "returns 'a11y/no-access-key'" do
      expect(described_class.rule_name).to eq("a11y/no-access-key")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow use of accesskey attribute")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    context "when element has accesskey attribute" do
      let(:template) { '<button accesskey="s">Save</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("a11y/no-access-key")
        expect(subject.first.message).to include("accesskey")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when element has no accesskey attribute" do
      let(:template) { "<button>Save</button>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when input has accesskey attribute" do
      let(:template) { '<input accesskey="n" type="text">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("a11y/no-access-key")
      end
    end

    context "when anchor has accesskey attribute" do
      let(:template) { '<a href="#" accesskey="h">Home</a>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when multiple elements have accesskey attribute" do
      let(:template) do
        <<~HTML
          <button accesskey="s">Save</button>
          <button accesskey="c">Cancel</button>
        HTML
      end

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("a11y/no-access-key"))
      end
    end

    context "when accesskey attribute is uppercase" do
      let(:template) { '<button ACCESSKEY="s">Save</button>' }

      it "reports an offense (case insensitive)" do
        expect(subject.size).to eq(1)
      end
    end

    context "with mixed elements with and without accesskey" do
      let(:template) do
        <<~HTML
          <button>OK</button>
          <button accesskey="s">Save</button>
          <a href="#">Link</a>
        HTML
      end

      it "reports offense only for element with accesskey" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "with non-interactive elements" do
      let(:template) { '<div class="container"><p>Hello</p></div>' }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end
  end
end
