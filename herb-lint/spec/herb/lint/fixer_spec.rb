# frozen_string_literal: true

RSpec.describe Herb::Lint::Fixer do
  describe "#apply_fixes" do
    subject { described_class.new(source, offenses, fix_unsafely:).apply_fixes }

    let(:fix_unsafely) { false }

    context "when there are no fixable offenses" do
      let(:source) { "<img src='photo.png'>" }
      let(:offenses) do
        [build_offense(severity: "error", message: "Missing alt attribute", line: 1, column: 0)]
      end

      it "returns the original source" do
        expect(subject).to eq(source)
      end
    end

    context "when there are no offenses at all" do
      let(:source) { "<div></div>" }
      let(:offenses) { [] }

      it "returns the original source" do
        expect(subject).to eq(source)
      end
    end

    context "when a single fix is applied" do
      let(:source) { "<div class='foo'></div>" }
      let(:offenses) do
        [build_offense(
          severity: "warning",
          message: "Use double quotes",
          line: 1,
          column: 5,
          fix: ->(src) { src.sub("class='foo'", 'class="foo"') }
        )]
      end

      it "applies the fix and returns the modified source" do
        expect(subject).to eq('<div class="foo"></div>')
      end
    end

    context "when multiple fixes are applied in correct order" do
      let(:source) { "<div class='a' id='b'></div>" }
      let(:offenses) do
        [
          build_offense(
            severity: "warning",
            message: "Use double quotes for class",
            line: 1,
            column: 5,
            fix: ->(src) { src.sub("class='a'", 'class="a"') }
          ),
          build_offense(
            severity: "warning",
            message: "Use double quotes for id",
            line: 1,
            column: 15,
            fix: ->(src) { src.sub("id='b'", 'id="b"') }
          )
        ]
      end

      it "applies all fixes correctly" do
        expect(subject).to eq('<div class="a" id="b"></div>')
      end
    end

    context "when multiple fixes span different lines" do
      let(:source) { "<div class='a'>\n  <span id='b'></span>\n</div>" }
      let(:offenses) do
        [
          build_offense(
            severity: "warning",
            message: "Use double quotes for class",
            line: 1,
            column: 5,
            fix: ->(src) { src.sub("class='a'", 'class="a"') }
          ),
          build_offense(
            severity: "warning",
            message: "Use double quotes for id",
            line: 2,
            column: 8,
            fix: ->(src) { src.sub("id='b'", 'id="b"') }
          )
        ]
      end

      it "applies fixes in reverse document order" do
        expect(subject).to eq("<div class=\"a\">\n  <span id=\"b\"></span>\n</div>")
      end
    end

    context "when fix_unsafely is false and offense is unsafe" do
      let(:source) { "<div style='color: red'></div>" }
      let(:offenses) do
        [build_offense(
          severity: "warning",
          message: "Remove inline style",
          line: 1,
          column: 5,
          fix: ->(src) { src.sub(" style='color: red'", "") },
          unsafe: true
        )]
      end

      it "does not apply the unsafe fix" do
        expect(subject).to eq(source)
      end
    end

    context "when fix_unsafely is true and offense is unsafe" do
      let(:source) { "<div style='color: red'></div>" }
      let(:fix_unsafely) { true }
      let(:offenses) do
        [build_offense(
          severity: "warning",
          message: "Remove inline style",
          line: 1,
          column: 5,
          fix: ->(src) { src.sub(" style='color: red'", "") },
          unsafe: true
        )]
      end

      it "applies the unsafe fix" do
        expect(subject).to eq("<div></div>")
      end
    end

    context "when mixing safe and unsafe fixes with fix_unsafely false" do
      let(:source) { "<div class='a' style='color: red'></div>" }
      let(:offenses) do
        [
          build_offense(
            severity: "warning",
            message: "Use double quotes for class",
            line: 1,
            column: 5,
            fix: ->(src) { src.sub("class='a'", 'class="a"') }
          ),
          build_offense(
            severity: "warning",
            message: "Remove inline style",
            line: 1,
            column: 15,
            fix: ->(src) { src.sub(" style='color: red'", "") },
            unsafe: true
          )
        ]
      end

      it "applies only the safe fix" do
        expect(subject).to eq("<div class=\"a\" style='color: red'></div>")
      end
    end

    context "when mixing safe and unsafe fixes with fix_unsafely true" do
      let(:source) { "<div class='a' style='color: red'></div>" }
      let(:fix_unsafely) { true }
      let(:offenses) do
        [
          build_offense(
            severity: "warning",
            message: "Use double quotes for class",
            line: 1,
            column: 5,
            fix: ->(src) { src.sub("class='a'", 'class="a"') }
          ),
          build_offense(
            severity: "warning",
            message: "Remove inline style",
            line: 1,
            column: 15,
            fix: ->(src) { src.sub(" style='color: red'", "") },
            unsafe: true
          )
        ]
      end

      it "applies both fixes" do
        expect(subject).to eq('<div class="a"></div>')
      end
    end

    context "when mixing fixable and non-fixable offenses" do
      let(:source) { "<img src='photo.png'>" }
      let(:offenses) do
        [
          build_offense(
            severity: "error",
            message: "Missing alt attribute",
            line: 1,
            column: 0
          ),
          build_offense(
            severity: "warning",
            message: "Use double quotes",
            line: 1,
            column: 5,
            fix: ->(src) { src.sub("src='photo.png'", 'src="photo.png"') }
          )
        ]
      end

      it "applies only fixable offenses" do
        expect(subject).to eq('<img src="photo.png">')
      end
    end

    context "when the original source is not mutated" do
      let(:source) { "<div class='foo'></div>" }
      let(:offenses) do
        [build_offense(
          severity: "warning",
          message: "Use double quotes",
          line: 1,
          column: 5,
          fix: ->(src) { src.sub("class='foo'", 'class="foo"') }
        )]
      end

      it "does not modify the original source string" do
        original = source.dup
        subject
        expect(source).to eq(original)
      end
    end
  end
end
