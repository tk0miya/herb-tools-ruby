# frozen_string_literal: true

RSpec.describe Herb::Lint::Reporter::SummaryReporter do
  describe "#display_summary" do
    subject { reporter.display_summary(aggregated_result) }

    let(:reporter) { described_class.new(io: output) }
    let(:output) { StringIO.new }
    let(:aggregated_result) { Herb::Lint::AggregatedResult.new(results) }

    context "with offenses in multiple files" do
      let(:results) do
        [
          build(:lint_result,
                file_path: "app/views/users/show.html.erb",
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "html-img-require-alt",
                        message: "img tag should have an alt attribute",
                        start_line: 5,
                        start_column: 10),
                  build(:offense,
                        severity: "warning",
                        rule_name: "html-attribute-double-quotes",
                        message: "Attribute value should be quoted",
                        start_line: 12,
                        start_column: 3)
                ]),
          build(:lint_result,
                file_path: "app/views/posts/index.html.erb",
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "html-img-require-alt",
                        message: "img tag should have an alt attribute",
                        start_line: 8,
                        start_column: 15)
                ])
        ]
      end

      it "displays summary with file counts and offense breakdown" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).to include("Summary:")
        expect(actual).to include("Checked")
        expect(actual).to include("2 files")
        expect(actual).to include("Files")
        expect(actual).to include("2 with offenses")
        expect(actual).to include("0 clean")
        expect(actual).to include("Offenses")
        expect(actual).to include("2 errors")
        expect(actual).to include("1 warning")
        expect(actual).to include("3 offenses across 2 files")
        expect(actual).to include("Fixable")
        expect(actual).to include("3 offenses")
      end
    end

    context "with no offenses" do
      let(:results) do
        [
          build(:lint_result, file_path: "app/views/users/show.html.erb"),
          build(:lint_result, file_path: "app/views/posts/index.html.erb")
        ]
      end

      it "displays summary with zero problems and success message" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).to include("Summary:")
        expect(actual).to include("Checked")
        expect(actual).to include("2 files")
        expect(actual).to include("Files")
        expect(actual).to include("2 clean")
        expect(actual).to include("Offenses")
        expect(actual).to include("0 offenses")
        expect(actual).to include("All files are clean!")
      end
    end

    context "with no files" do
      let(:results) { [] }

      it "displays summary with zero files and no Files line" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).to include("Summary:")
        expect(actual).to include("Checked")
        expect(actual).to include("0 files")
        expect(actual).not_to include("Files")
        expect(actual).to include("Offenses")
        expect(actual).to include("0 offenses")
        expect(actual).not_to include("All files are clean!")
      end
    end

    context "with single file" do
      let(:results) do
        [
          build(:lint_result,
                file_path: "test.html.erb",
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "test-rule",
                        message: "Error message",
                        start_line: 1,
                        start_column: 0)
                ])
        ]
      end

      it "displays summary without Files line" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).to include("Summary:")
        expect(actual).to include("Checked")
        expect(actual).to include("1 file")
        expect(actual).not_to include("Files")
        expect(actual).to include("Offenses")
        expect(actual).to include("1 error")
      end
    end

    context "with only errors" do
      let(:results) do
        [
          build(:lint_result, unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "test-rule",
                        message: "Error message",
                        start_line: 1,
                        start_column: 0),
                  build(:offense,
                        severity: "error",
                        rule_name: "test-rule",
                        message: "Another error",
                        start_line: 2,
                        start_column: 5)
                ])
        ]
      end

      it "displays errors with 0 warnings in green" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).to include("Summary:")
        expect(actual).to include("Offenses")
        expect(actual).to include("2 errors")
        expect(actual).to include("0 warnings")
        expect(actual).to include("Fixable")
        expect(actual).to include("2 offenses")
      end
    end

    context "with only warnings" do
      let(:results) do
        [
          build(:lint_result, unfixed_offenses: [
                  build(:offense,
                        severity: "warning",
                        rule_name: "test-rule",
                        message: "Warning message",
                        start_line: 1,
                        start_column: 0)
                ])
        ]
      end

      it "displays only warnings without error count" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).to include("Summary:")
        expect(actual).to include("Offenses")
        expect(actual).to include("1 warning")
        expect(actual).not_to include("0 errors")
        expect(actual).to include("Fixable")
        expect(actual).to include("1 offense")
      end
    end

    context "with autofixable offenses" do
      let(:results) do
        [
          build(:lint_result,
                file_path: "app/views/users/show.html.erb",
                autofixable_count: 2,
                error_count: 3)
        ]
      end

      it "displays fixable count with autocorrect message" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).to include("Summary:")
        expect(actual).to include("Fixable")
        expect(actual).to include("5 offenses")
        expect(actual).to include("2 autocorrectable using `--fix`")
      end
    end

    context "with autofixed offenses" do
      let(:results) do
        [
          build(:lint_result,
                file_path: "app/views/users/show.html.erb",
                autofixed_count: 1,
                autofixable_count: 1,
                error_count: 2)
        ]
      end

      it "displays remaining fixable count" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).to include("Summary:")
        expect(actual).to include("Fixable")
        expect(actual).to include("3 offenses")
        expect(actual).to include("1 autocorrectable using `--fix`")
      end
    end

    context "with all offenses autofixed" do
      let(:results) do
        [
          build(:lint_result,
                file_path: "app/views/users/show.html.erb",
                autofixed_count: 2),
          build(:lint_result,
                file_path: "app/views/posts/index.html.erb",
                autofixed_count: 1)
        ]
      end

      it "displays zero offenses and success message" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).to include("Summary:")
        expect(actual).to include("Offenses")
        expect(actual).to include("0 offenses")
        expect(actual).to include("All files are clean!")
      end
    end

    context "with non-TTY output" do
      let(:output) { StringIO.new }
      let(:results) do
        [
          build(:lint_result,
                file_path: "test.html.erb",
                autofixable_count: 1)
        ]
      end

      it "does not add ANSI color codes" do
        subject

        expect(output.string).to include("Summary:")
        expect(output.string).to include("Checked")
        expect(output.string).to include("1 file")
        expect(output.string).to include("Offenses")
        expect(output.string).to include("1 error")
        expect(output.string).to include("Fixable")
        expect(output.string).to include("1 offense")
        expect(output.string).to include("1 autocorrectable using `--fix`")
        expect(output.string).not_to match(/\e\[.*?m/)
      end
    end
  end
end
