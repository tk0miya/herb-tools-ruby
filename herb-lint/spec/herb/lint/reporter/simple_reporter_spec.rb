# frozen_string_literal: true

RSpec.describe Herb::Lint::Reporter::SimpleReporter do
  describe "#report" do
    subject { reporter.report(aggregated_result) }

    let(:reporter) { described_class.new(io: output) }
    let(:output) { StringIO.new }
    let(:aggregated_result) { Herb::Lint::AggregatedResult.new(results) }

    context "when there are offenses in multiple files" do
      let(:results) do
        [
          Herb::Lint::LintResult.new(
            file_path: "app/views/users/show.html.erb",
            offenses: [
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
            ],
            source: "<div></div>"
          ),
          Herb::Lint::LintResult.new(
            file_path: "app/views/posts/index.html.erb",
            offenses: [
              build(:offense,
                    severity: "error",
                    rule_name: "html-img-require-alt",
                    message: "img tag should have an alt attribute",
                    start_line: 8,
                    start_column: 15)
            ],
            source: "<div></div>"
          )
        ]
      end

      let(:expected_output) do
        <<~OUTPUT
          app/views/users/show.html.erb
            5:10  error    img tag should have an alt attribute  html-img-require-alt
            12:3  warning  Attribute value should be quoted  html-attribute-double-quotes

          app/views/posts/index.html.erb
            8:15  error    img tag should have an alt attribute  html-img-require-alt

          3 problems (2 errors, 1 warning) in 2 files
        OUTPUT
      end

      it "displays offenses for each file and summary" do
        subject

        expect(output.string).to eq(expected_output)
      end
    end

    context "when there are no offenses" do
      let(:results) do
        [
          Herb::Lint::LintResult.new(
            file_path: "app/views/users/show.html.erb",
            offenses: [],
            source: "<div></div>"
          ),
          Herb::Lint::LintResult.new(
            file_path: "app/views/posts/index.html.erb",
            offenses: [],
            source: "<div></div>"
          )
        ]
      end

      it "displays only the summary with zero problems" do
        subject

        expect(output.string).to eq("0 problems (0 errors, 0 warnings) in 2 files\n")
      end
    end

    context "when there are no files" do
      let(:results) { [] }

      it "displays summary with zero files" do
        subject

        expect(output.string).to eq("0 problems (0 errors, 0 warnings) in 0 files\n")
      end
    end

    context "when there are only errors" do
      let(:results) do
        [
          Herb::Lint::LintResult.new(
            file_path: "test.html.erb",
            offenses: [
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
            ],
            source: "<div></div>"
          )
        ]
      end

      let(:expected_output) do
        <<~OUTPUT
          test.html.erb
            1:0  error    Error message  test-rule
            2:5  error    Another error  test-rule

          2 problems (2 errors, 0 warnings) in 1 file
        OUTPUT
      end

      it "displays correct counts in summary" do
        subject

        expect(output.string).to eq(expected_output)
      end
    end

    context "when there are only warnings" do
      let(:results) do
        [
          Herb::Lint::LintResult.new(
            file_path: "test.html.erb",
            offenses: [
              build(:offense,
                    severity: "warning",
                    rule_name: "test-rule",
                    message: "Warning message",
                    start_line: 1,
                    start_column: 0)
            ],
            source: "<div></div>"
          )
        ]
      end

      let(:expected_output) do
        <<~OUTPUT
          test.html.erb
            1:0  warning  Warning message  test-rule

          1 problem (0 errors, 1 warning) in 1 file
        OUTPUT
      end

      it "displays correct counts in summary" do
        subject

        expect(output.string).to eq(expected_output)
      end
    end
  end
end
