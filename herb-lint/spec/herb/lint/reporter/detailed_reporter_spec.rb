# frozen_string_literal: true

require "tempfile"

RSpec.describe Herb::Lint::Reporter::DetailedReporter do
  describe "#report" do
    subject { reporter.report(aggregated_result) }

    let(:reporter) { described_class.new(io: output, context_lines: 2, show_progress:) }
    let(:output) { StringIO.new }
    let(:show_progress) { true }
    let(:aggregated_result) { Herb::Lint::AggregatedResult.new(results) }

    # Create a temporary file with sample code
    let(:temp_file) do
      file = Tempfile.new(["test", ".html.erb"])
      file.write(<<~ERB)
        <html>
        <body>
          <h1>Title</h1>
          <img src="test.jpg">
          <p>Content</p>
          <div>More content</div>
          <span>Text</span>
        </body>
        </html>
      ERB
      file.rewind
      file
    end

    after do
      temp_file.close
      temp_file.unlink
    end

    context "when there are offenses in a single file" do
      let(:results) do
        [
          build(:lint_result,
                file_path: temp_file.path,
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "html-img-require-alt",
                        message: "img tag should have an alt attribute",
                        start_line: 4,
                        start_column: 3)
                ])
        ]
      end

      it "displays offense with code context and summary" do
        subject

        # Remove ANSI color codes for comparison
        actual = output.string.gsub(/\e\[.*?m/, "")

        # Check header (file path displayed)
        expect(actual).to include(temp_file.path)

        # Check offense details
        expect(actual).to include("4:3")
        expect(actual).to include("✗ img tag should have an alt attribute")
        expect(actual).to include("(html-img-require-alt)")

        # Check code context (lines around offense)
        expect(actual).to include("<h1>Title</h1>") # Line 3 (before)
        expect(actual).to include('<img src="test.jpg">') # Line 4 (offense line)
        expect(actual).to include("<p>Content</p>") # Line 5 (after)

        # Check line numbers in gutter
        expect(actual).to include("3")
        expect(actual).to include("4")
        expect(actual).to include("5")

        # Check caret marker pointing to column
        expect(actual).to include("^")

        # Check summary
        expect(actual).to include("Summary:")
        expect(actual).to include("Checked")
        expect(actual).to include("1 file")
        expect(actual).to include("Offenses")
        expect(actual).to include("1 error")
      end

      context "with autofixable offense" do
        let(:results) do
          [
            build(:lint_result,
                  file_path: temp_file.path,
                  autofixable_count: 1,
                  error_count: 1)
          ]
        end

        it "displays [Correctable] label" do
          subject

          actual = output.string.gsub(/\e\[.*?m/, "")
          expect(actual).to include("[Correctable]")
          expect(actual).to include("1 autocorrectable using `--fix`")
        end
      end
    end

    context "when there are offenses in multiple files" do
      let(:temp_file2) do
        file = Tempfile.new(["test2", ".html.erb"])
        file.write(<<~ERB)
          <div>
            <p>Paragraph</p>
            <img src="photo.png">
          </div>
        ERB
        file.rewind
        file
      end

      let(:results) do
        [
          build(:lint_result,
                file_path: temp_file.path,
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "html-img-require-alt",
                        message: "img tag should have an alt attribute",
                        start_line: 4,
                        start_column: 3)
                ]),
          build(:lint_result,
                file_path: temp_file2.path,
                unfixed_offenses: [
                  build(:offense,
                        severity: "warning",
                        rule_name: "html-img-require-alt",
                        message: "img tag should have an alt attribute",
                        start_line: 3,
                        start_column: 3)
                ])
        ]
      end

      after do
        temp_file2.close
        temp_file2.unlink
      end

      it "displays offenses for each file with progress indicators" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")

        # Check both file paths
        expect(actual).to include(temp_file.path)
        expect(actual).to include(temp_file2.path)

        # Check progress indicators
        expect(actual).to include("[1/2]")
        expect(actual).to include("[2/2]")

        # Check both offenses
        expect(actual).to include("4:3")
        expect(actual).to include("3:3")

        # Check separator lines
        expect(actual).to include("─" * 80)

        # Check summary
        expect(actual).to include("Summary:")
        expect(actual).to include("2 files")
        expect(actual).to include("2 with offenses")
        expect(actual).to include("1 error")
        expect(actual).to include("1 warning")
      end

      context "with show_progress: false" do
        let(:show_progress) { false }

        it "does not display progress indicators" do
          subject

          actual = output.string.gsub(/\e\[.*?m/, "")

          expect(actual).not_to include("[1/2]")
          expect(actual).not_to include("[2/2]")
        end
      end
    end

    context "when there are no offenses" do
      let(:results) do
        [
          build(:lint_result, file_path: temp_file.path),
          build(:lint_result, file_path: "app/views/posts/index.html.erb")
        ]
      end

      it "displays only the summary with zero problems" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")
        expect(actual).to include("Summary:")
        expect(actual).to include("Checked")
        expect(actual).to include("2 files")
        expect(actual).to include("2 clean")
        expect(actual).to include("0 offenses")
        expect(actual).to include("All files are clean!")
      end
    end

    context "when the file does not exist" do
      let(:results) do
        [
          build(:lint_result,
                file_path: "/nonexistent/file.html.erb",
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "test-rule",
                        message: "Test message",
                        start_line: 1,
                        start_column: 0)
                ])
        ]
      end

      it "displays offense without code context" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")

        expect(actual).to include("/nonexistent/file.html.erb")
        expect(actual).to include("1:0")
        expect(actual).to include("✗ Test message")
        expect(actual).to include("(test-rule)")

        # Should not crash or show context
        expect(actual).to include("Summary:")
      end
    end

    context "with different severity levels" do
      let(:results) do
        [
          build(:lint_result,
                file_path: temp_file.path,
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "test-error",
                        message: "Error message",
                        start_line: 2,
                        start_column: 0),
                  build(:offense,
                        severity: "warning",
                        rule_name: "test-warning",
                        message: "Warning message",
                        start_line: 3,
                        start_column: 0),
                  build(:offense,
                        severity: "info",
                        rule_name: "test-info",
                        message: "Info message",
                        start_line: 4,
                        start_column: 0)
                ])
        ]
      end

      it "displays different severity symbols" do
        subject

        actual = output.string.gsub(/\e\[.*?m/, "")

        # Check all three severity levels
        expect(actual.scan(/✗/).count).to eq(1) # error
        expect(actual.scan(/⚠/).count).to eq(1) # warning
        expect(actual.scan(/ℹ/).count).to eq(1) # info
      end
    end

    context "with non-TTY output" do
      let(:results) do
        [
          build(:lint_result,
                file_path: temp_file.path,
                autofixable_count: 1)
        ]
      end

      it "does not add color codes" do
        subject

        # Verify no ANSI codes
        expect(output.string).not_to match(/\e\[.*?m/)
      end
    end
  end
end
