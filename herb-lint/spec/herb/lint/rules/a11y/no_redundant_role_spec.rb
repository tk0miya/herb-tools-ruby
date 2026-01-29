# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::A11y::NoRedundantRole do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context) }

  describe ".rule_name" do
    it "returns 'a11y/no-redundant-role'" do
      expect(described_class.rule_name).to eq("a11y/no-redundant-role")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow redundant ARIA roles matching implicit semantics")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    context "when button has role='button'" do
      let(:template) { '<button role="button">Click</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("a11y/no-redundant-role")
        expect(subject.first.message).to include("button")
        expect(subject.first.message).to include("redundant")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when anchor with href has role='link'" do
      let(:template) { '<a href="#" role="link">Link</a>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("implicit role of 'link'")
      end
    end

    context "when anchor without href has role='link'" do
      let(:template) { '<a role="link">Not a real link</a>' }

      it "does not report an offense (no href means no implicit link role)" do
        expect(subject).to be_empty
      end
    end

    context "when tag name differs from implicit role (nav -> navigation)" do
      let(:template) { '<nav role="navigation">Menu</nav>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("navigation")
      end
    end

    context "when multiple tags share the same implicit role (h1-h6 -> heading)" do
      let(:template) do
        <<~HTML
          <h1 role="heading">Title</h1>
          <h2 role="heading">Subtitle</h2>
          <h3 role="heading">Section</h3>
        HTML
      end

      it "reports an offense for each" do
        expect(subject.size).to eq(3)
      end
    end

    context "when different tags map to the same implicit role (ul/ol -> list)" do
      let(:template) do
        <<~HTML
          <ul role="list"><li>item</li></ul>
          <ol role="list"><li>item</li></ol>
        HTML
      end

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
      end
    end

    context "when element has a different (non-redundant) role" do
      let(:template) { '<div role="button">Click</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when button has a different role" do
      let(:template) { '<button role="tab">Tab</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when nav has a different role" do
      let(:template) { '<nav role="tablist">Tabs</nav>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has no role attribute" do
      let(:template) { "<button>Click</button>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with role attribute in different case" do
      let(:template) { '<button role="BUTTON">Click</button>' }

      it "reports an offense (case insensitive)" do
        expect(subject.size).to eq(1)
      end
    end

    context "with area element with href and role='link'" do
      let(:template) { '<area href="#" role="link">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("link")
      end
    end

    context "with area element without href and role='link'" do
      let(:template) { '<area role="link">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with multiple elements having mixed redundant and non-redundant roles" do
      let(:template) do
        <<~HTML
          <nav role="navigation">
            <button role="tab">Tab</button>
            <main role="main">
              <h1 role="heading">Title</h1>
            </main>
          </nav>
        HTML
      end

      it "reports offenses only for redundant roles" do
        expect(subject.size).to eq(3)
        expect(subject.map(&:message)).to all(include("redundant"))
      end
    end
  end
end
