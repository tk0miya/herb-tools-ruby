# frozen_string_literal: true

RSpec.describe Herb::Lint::LintResult do
  describe "#initialize" do
    subject { described_class.new(file_path:, unfixed_offenses:, source:) }

    let(:file_path) { "app/views/users/index.html.erb" }
    let(:unfixed_offenses) { [] }
    let(:source) { "<div>Hello</div>" }

    it "sets all attributes correctly" do
      expect(subject.file_path).to eq("app/views/users/index.html.erb")
      expect(subject.unfixed_offenses).to eq([])
      expect(subject.source).to eq("<div>Hello</div>")
    end
  end

  describe "#error_count" do
    subject { lint_result.error_count }

    let(:lint_result) { described_class.new(file_path: "test.html.erb", unfixed_offenses:, source: "<div></div>") }

    context "when there are no offenses" do
      let(:unfixed_offenses) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are only errors" do
      let(:unfixed_offenses) do
        [
          build(:offense, severity: "error"),
          build(:offense, severity: "error")
        ]
      end

      it "returns the count of errors" do
        expect(subject).to eq(2)
      end
    end

    context "when there are mixed severities" do
      let(:unfixed_offenses) do
        [
          build(:offense, severity: "error"),
          build(:offense, severity: "warning"),
          build(:offense, severity: "error"),
          build(:offense, severity: "info")
        ]
      end

      it "returns only the count of errors" do
        expect(subject).to eq(2)
      end
    end
  end

  describe "#warning_count" do
    subject { lint_result.warning_count }

    let(:lint_result) { described_class.new(file_path: "test.html.erb", unfixed_offenses:, source: "<div></div>") }

    context "when there are no offenses" do
      let(:unfixed_offenses) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are only warnings" do
      let(:unfixed_offenses) do
        [
          build(:offense, severity: "warning"),
          build(:offense, severity: "warning"),
          build(:offense, severity: "warning")
        ]
      end

      it "returns the count of warnings" do
        expect(subject).to eq(3)
      end
    end

    context "when there are mixed severities" do
      let(:unfixed_offenses) do
        [
          build(:offense, severity: "error"),
          build(:offense, severity: "warning"),
          build(:offense, severity: "warning"),
          build(:offense, severity: "info")
        ]
      end

      it "returns only the count of warnings" do
        expect(subject).to eq(2)
      end
    end
  end

  describe "#offense_count" do
    subject { lint_result.offense_count }

    let(:lint_result) { described_class.new(file_path: "test.html.erb", unfixed_offenses:, source: "<div></div>") }

    context "when there are no offenses" do
      let(:unfixed_offenses) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are multiple offenses" do
      let(:unfixed_offenses) do
        [
          build(:offense, severity: "error"),
          build(:offense, severity: "warning"),
          build(:offense, severity: "info")
        ]
      end

      it "returns the total count of all offenses" do
        expect(subject).to eq(3)
      end
    end
  end

  describe "#parse_result" do
    context "when parse_result is provided" do
      subject do
        described_class.new(file_path: "test.html.erb", unfixed_offenses: [], source:, parse_result:)
      end

      let(:source) { "<div>Hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }

      it "returns the parse result" do
        expect(subject.parse_result).to equal(parse_result)
      end
    end

    context "when parse_result is not provided" do
      subject { described_class.new(file_path: "test.html.erb", unfixed_offenses: [], source: "<div></div>") }

      it "defaults to nil" do
        expect(subject.parse_result).to be_nil
      end
    end
  end

  describe "#autofixed_offenses" do
    context "when autofixed_offenses is provided" do
      subject do
        described_class.new(
          file_path: "test.html.erb",
          unfixed_offenses: [],
          source: "<div></div>",
          autofixed_offenses:
        )
      end

      let(:autofixed_offenses) do
        [
          build(:offense, severity: "error"),
          build(:offense, severity: "warning")
        ]
      end

      it "returns the autofixed offenses" do
        expect(subject.autofixed_offenses).to eq(autofixed_offenses)
      end
    end

    context "when autofixed_offenses is not provided" do
      subject { described_class.new(file_path: "test.html.erb", unfixed_offenses: [], source: "<div></div>") }

      it "defaults to empty array" do
        expect(subject.autofixed_offenses).to eq([])
      end
    end
  end

  describe "#autofixed_count" do
    subject { lint_result.autofixed_count }

    let(:lint_result) do
      described_class.new(
        file_path: "test.html.erb",
        unfixed_offenses: [],
        source: "<div></div>",
        autofixed_offenses:
      )
    end

    context "when there are no autofixed offenses" do
      let(:autofixed_offenses) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are autofixed offenses" do
      let(:autofixed_offenses) do
        [
          build(:offense, severity: "error"),
          build(:offense, severity: "warning"),
          build(:offense, severity: "error")
        ]
      end

      it "returns the count of autofixed offenses" do
        expect(subject).to eq(3)
      end
    end
  end

  describe "#autofixable_count" do
    subject { lint_result.autofixable_count }

    let(:lint_result) { described_class.new(file_path: "test.html.erb", unfixed_offenses:, source: "<div></div>") }

    context "when there are no offenses" do
      let(:unfixed_offenses) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are no fixable offenses" do
      let(:unfixed_offenses) do
        [
          build(:offense),
          build(:offense)
        ]
      end

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are fixable offenses" do
      let(:unfixed_offenses) do
        [
          build(:offense, :autofixable),
          build(:offense),
          build(:offense, :autofixable)
        ]
      end

      it "returns the count of fixable offenses" do
        expect(subject).to eq(2)
      end
    end

    context "when all offenses are fixable" do
      let(:unfixed_offenses) do
        [
          build(:offense, :autofixable),
          build(:offense, :autofixable),
          build(:offense, :autofixable)
        ]
      end

      it "returns the total count" do
        expect(subject).to eq(3)
      end
    end
  end
end
