# frozen_string_literal: true

RSpec.describe Herb::Core::DirectiveParser do
  describe "#parse" do
    subject { parser.parse }

    let(:parser) { described_class.new(document, mode:) }
    let(:document) { Herb.parse(source) }
    let(:mode) { :linter }

    context "when source has a single rule disable directive" do
      let(:source) { "<%# herb:disable alt-text %>\n<img src=\"image.png\">\n" }

      it "parses the directive with correct attributes" do
        expect(subject.size).to eq(1)
        expect(subject.first).to have_attributes(
          type: Herb::Core::DirectiveType::DISABLE,
          rules: ["alt-text"],
          line: 1,
          scope: Herb::Core::DirectiveScope::NEXT_LINE
        )
      end
    end

    context "when source has multiple rules disable directive (comma-separated)" do
      let(:source) { "<%# herb:disable alt-text, no-inline-styles %>\n<img src=\"image.png\">\n" }

      it "parses the directive with all rules" do
        expect(subject.size).to eq(1)
        expect(subject.first).to have_attributes(
          type: Herb::Core::DirectiveType::DISABLE,
          rules: %w[alt-text no-inline-styles],
          line: 1,
          scope: Herb::Core::DirectiveScope::NEXT_LINE
        )
      end
    end

    context "when source has disable all directive" do
      let(:source) { "<%# herb:disable all %>\n<img src=\"image.png\">\n" }

      it "parses the directive with empty rules array" do
        expect(subject.size).to eq(1)
        expect(subject.first).to have_attributes(
          type: Herb::Core::DirectiveType::DISABLE,
          rules: [],
          line: 1,
          scope: Herb::Core::DirectiveScope::NEXT_LINE
        )
      end
    end

    context "when source has enable directive" do
      let(:source) { "<%# herb:enable alt-text %>\n" }

      it "parses the enable directive" do
        expect(subject.size).to eq(1)
        expect(subject.first).to have_attributes(
          type: Herb::Core::DirectiveType::ENABLE,
          rules: ["alt-text"],
          line: 1,
          scope: Herb::Core::DirectiveScope::RANGE_END
        )
      end
    end

    context "when source has enable all directive" do
      let(:source) { "<%# herb:enable all %>\n" }

      it "parses the enable all directive" do
        expect(subject.size).to eq(1)
        expect(subject.first).to have_attributes(
          type: Herb::Core::DirectiveType::ENABLE,
          rules: [],
          line: 1,
          scope: Herb::Core::DirectiveScope::RANGE_END
        )
      end
    end

    context "when source has file-level ignore directive" do
      let(:source) { "<%# herb:linter ignore %>\n<img src=\"image.png\">\n" }

      it "parses the ignore directive" do
        expect(subject.size).to eq(1)
        expect(subject.first).to have_attributes(
          type: Herb::Core::DirectiveType::IGNORE_FILE,
          rules: [],
          line: 1,
          scope: Herb::Core::DirectiveScope::FILE
        )
      end
    end

    context "when source has non-directive ERB comments" do
      let(:source) { "<%# This is a regular comment %>\n<img src=\"image.png\">\n" }

      it "returns no directives" do
        expect(subject).to be_empty
      end
    end

    context "when source has a malformed directive with no rules" do
      let(:source) { "<%# herb:disable %>\n<img src=\"image.png\">\n" }

      it "ignores the malformed directive" do
        expect(subject).to be_empty
      end
    end

    context "when source has multiple directives on different lines" do
      let(:source) do
        <<~ERB
          <%# herb:disable alt-text %>
          <img src="image1.png">
          <%# herb:disable no-inline-styles %>
          <div style="color: red;"></div>
        ERB
      end

      it "parses all directives with correct line numbers" do
        expect(subject.size).to eq(2)
        expect(subject[0]).to have_attributes(rules: ["alt-text"], line: 1)
        expect(subject[1]).to have_attributes(rules: ["no-inline-styles"], line: 3)
      end
    end

    context "when mode is :formatter" do
      let(:mode) { :formatter }

      context "with linter ignore directive" do
        let(:source) { "<%# herb:linter ignore %>\n" }

        it "does not match linter mode directives" do
          expect(subject).to be_empty
        end
      end

      context "with formatter ignore directive" do
        let(:source) { "<%# herb:formatter ignore %>\n" }

        it "matches formatter mode directives" do
          expect(subject.size).to eq(1)
          expect(subject.first.type).to eq(Herb::Core::DirectiveType::IGNORE_FILE)
        end
      end
    end

    context "when directive has extra whitespace" do
      let(:source) { "<%#   herb:disable   alt-text   %>\n" }

      it "handles extra whitespace correctly" do
        expect(subject.size).to eq(1)
        expect(subject.first.rules).to eq(["alt-text"])
      end
    end

    context "when source has HTML comments (non-ERB)" do
      let(:source) { "<!-- herb:disable alt-text -->\n<img src=\"image.png\">\n" }

      it "does not parse HTML comments as directives" do
        expect(subject).to be_empty
      end
    end
  end

  describe "#ignore_file?" do
    subject { parser.ignore_file? }

    let(:parser) { described_class.new(document) }
    let(:document) { Herb.parse(source) }

    context "when source has ignore directive" do
      let(:source) { "<%# herb:linter ignore %>\n<img src=\"image.png\">\n" }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "when source has no ignore directive" do
      let(:source) { "<%# herb:disable alt-text %>\n<img src=\"image.png\">\n" }

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "when source has no directives at all" do
      let(:source) { "<img src=\"image.png\">\n" }

      it "returns false" do
        expect(subject).to be false
      end
    end
  end

  describe "#disabled_at?" do
    let(:parser) { described_class.new(document) }
    let(:document) { Herb.parse(source) }

    context "when a specific rule is disabled on the next line" do
      let(:source) { "<%# herb:disable alt-text %>\n<img src=\"image.png\">\n<img src=\"other.png\">\n" }

      it "returns true for the disabled rule on the next line and false otherwise" do
        expect(parser.disabled_at?(2, "alt-text")).to be true
        expect(parser.disabled_at?(2, "no-inline-styles")).to be false
        expect(parser.disabled_at?(1, "alt-text")).to be false
        expect(parser.disabled_at?(3, "alt-text")).to be false
      end
    end

    context "when all rules are disabled" do
      let(:source) { "<%# herb:disable all %>\n<img src=\"image.png\">\n" }

      it "returns true for any rule on the next line" do
        expect(parser.disabled_at?(2, "alt-text")).to be true
        expect(parser.disabled_at?(2, "no-inline-styles")).to be true
        expect(parser.disabled_at?(2)).to be true
      end
    end

    context "when no directives are present" do
      let(:source) { "<img src=\"image.png\">\n" }

      it "returns false" do
        expect(parser.disabled_at?(1, "alt-text")).to be false
        expect(parser.disabled_at?(1)).to be false
      end
    end

    context "when rule_name is nil and specific rules are disabled" do
      let(:source) { "<%# herb:disable alt-text %>\n<img src=\"image.png\">\n" }

      it "returns true on the next line" do
        expect(parser.disabled_at?(2)).to be true
      end
    end
  end
end
