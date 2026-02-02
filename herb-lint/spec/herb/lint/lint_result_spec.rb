# frozen_string_literal: true

RSpec.describe Herb::Lint::LintResult do
  describe "#initialize" do
    subject { described_class.new(file_path:, offenses:, source:) }

    let(:file_path) { "app/views/users/index.html.erb" }
    let(:offenses) { [] }
    let(:source) { "<div>Hello</div>" }

    it "sets all attributes correctly" do
      expect(subject.file_path).to eq("app/views/users/index.html.erb")
      expect(subject.offenses).to eq([])
      expect(subject.source).to eq("<div>Hello</div>")
    end
  end

  describe "#error_count" do
    subject { lint_result.error_count }

    let(:lint_result) { described_class.new(file_path: "test.html.erb", offenses:, source: "<div></div>") }

    context "when there are no offenses" do
      let(:offenses) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are only errors" do
      let(:offenses) do
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
      let(:offenses) do
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

    let(:lint_result) { described_class.new(file_path: "test.html.erb", offenses:, source: "<div></div>") }

    context "when there are no offenses" do
      let(:offenses) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are only warnings" do
      let(:offenses) do
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
      let(:offenses) do
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

    let(:lint_result) { described_class.new(file_path: "test.html.erb", offenses:, source: "<div></div>") }

    context "when there are no offenses" do
      let(:offenses) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are multiple offenses" do
      let(:offenses) do
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
        described_class.new(file_path: "test.html.erb", offenses: [], source:, parse_result:)
      end

      let(:source) { "<div>Hello</div>" }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }

      it "returns the parse result" do
        expect(subject.parse_result).to equal(parse_result)
      end
    end

    context "when parse_result is not provided" do
      subject { described_class.new(file_path: "test.html.erb", offenses: [], source: "<div></div>") }

      it "defaults to nil" do
        expect(subject.parse_result).to be_nil
      end
    end
  end
end
