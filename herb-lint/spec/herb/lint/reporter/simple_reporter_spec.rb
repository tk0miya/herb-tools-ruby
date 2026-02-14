# frozen_string_literal: true

RSpec.describe Herb::Lint::Reporter::SimpleReporter do
  describe "#report" do
    subject { reporter.report(aggregated_result) }

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

      it "displays offenses for each file" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).to include("app/views/users/show.html.erb")
        expect(actual).to include("5:10   ✗ img tag should have an alt attribute (html-img-require-alt)")
        expect(actual).to include("12:3   ⚠ Attribute value should be quoted (html-attribute-double-quotes)")
        expect(actual).to include("app/views/posts/index.html.erb")
        expect(actual).to include("8:15   ✗ img tag should have an alt attribute (html-img-require-alt)")
      end

      it "delegates summary display to SummaryReporter" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).to include("Summary:")
      end
    end

    context "with different severity levels" do
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
                        severity: "warning",
                        rule_name: "test-rule",
                        message: "Warning message",
                        start_line: 2,
                        start_column: 5)
                ])
        ]
      end

      it "displays appropriate symbols for each severity" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).to include("1:0    ✗ Error message (test-rule)")
        expect(actual).to include("2:5    ⚠ Warning message (test-rule)")
      end
    end

    context "with autofixable offenses" do
      let(:results) do
        [
          build(:lint_result,
                file_path: "test.html.erb",
                autofixable_count: 1)
        ]
      end

      it "displays [Correctable] label for autofixable offenses" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).to include("test.html.erb")
        expect(actual).to include("1:0    ✗ Test message (test-rule) [Correctable]")
      end
    end

    context "with no offenses" do
      let(:results) do
        [
          build(:lint_result, file_path: "app/views/users/show.html.erb")
        ]
      end

      it "does not display offense details but delegates to SummaryReporter" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).not_to include("app/views/users/show.html.erb")
        expect(actual).to include("Summary:")
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

        expect(output.string).to include("test.html.erb")
        expect(output.string).to include("1:0    ✗ Test message (test-rule) [Correctable]")
        expect(output.string).not_to match(/\e\[.*?m/)
      end
    end
  end
end
