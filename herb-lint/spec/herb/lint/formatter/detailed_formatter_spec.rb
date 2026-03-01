# frozen_string_literal: true

RSpec.describe Herb::Lint::Formatter::DetailedFormatter do
  # Helper to strip ANSI color codes for easier testing
  def strip_colors(text)
    text.gsub(/\e\[.*?m/, "")
  end

  describe "#report" do
    subject { formatter.report(aggregated_result) }

    let(:formatter) { described_class.new(io: output) }
    let(:output) { StringIO.new }
    let(:aggregated_result) { Herb::Lint::AggregatedResult.new(results) }

    context "with a single file containing offenses" do
      let(:source_code) do
        <<~ERB
          <div>
            <h1>Title</h1>
            <img src="photo.jpg">
            <p>Some text</p>
          </div>
        ERB
      end

      let(:results) do
        [
          build(:lint_result,
                file_path: "app/views/users/show.html.erb",
                source: source_code,
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "html-img-require-alt",
                        message: "img tag should have an alt attribute",
                        start_line: 3,
                        start_column: 3)
                ])
        ]
      end

      it "displays formatted output with file path, offense details, and source context" do
        subject

        actual = strip_colors(output.string)

        # File header (no progress indicator for single file)
        expect(actual).to start_with("app/views/users/show.html.erb\n\n")

        # Offense header line
        expected_offense_header = "  3:3    ✗ img tag should have an alt attribute (html-img-require-alt)\n"
        expect(actual).to include(expected_offense_header)

        # Source code context (lines 1-5 with line 3 +/- 2 context)
        expected_source_context = [
          "    1 │ <div>",
          "    2 │   <h1>Title</h1>",
          "  → 3 │   <img src=\"photo.jpg\">",
          "      │   ~",
          "    4 │   <p>Some text</p>",
          "    5 │ </div>"
        ].join("\n")

        expect(actual).to include(expected_source_context)

        # Summary section should be present
        expect(actual).to include("Summary:")
      end
    end

    context "with multiple files containing offenses" do
      let(:results) do
        [
          build(:lint_result,
                file_path: "app/views/users/show.html.erb",
                source: "<img src=\"user.jpg\">\n<p>Text</p>\n",
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "html-img-require-alt",
                        message: "img tag should have an alt attribute",
                        start_line: 1,
                        start_column: 1)
                ]),
          build(:lint_result,
                file_path: "app/views/posts/index.html.erb",
                source: "<div class='container'>\n  <img src=\"post.jpg\">\n</div>\n",
                unfixed_offenses: [
                  build(:offense,
                        severity: "warning",
                        rule_name: "html-attribute-double-quotes",
                        message: "Attribute value should be quoted",
                        start_line: 2,
                        start_column: 3)
                ])
        ]
      end

      it "displays each file with progress indicator and separator" do
        subject

        actual = strip_colors(output.string)

        # First file section
        first_file_section = [
          "────────────────────────────────────────────────── [1/2]",
          "app/views/users/show.html.erb",
          "",
          "  1:1    ✗ img tag should have an alt attribute (html-img-require-alt)",
          "",
          "  → 1 │ <img src=\"user.jpg\">",
          "      │ ~",
          "    2 │ <p>Text</p>"
        ].join("\n")

        expect(actual).to include(first_file_section)

        # Second file section
        second_file_section = [
          "────────────────────────────────────────────────── [2/2]",
          "app/views/posts/index.html.erb",
          "",
          "  2:3    ⚠ Attribute value should be quoted (html-attribute-double-quotes)",
          "",
          "    1 │ <div class='container'>",
          "  → 2 │   <img src=\"post.jpg\">",
          "      │   ~",
          "    3 │ </div>"
        ].join("\n")

        expect(actual).to include(second_file_section)
      end
    end

    context "with different severity levels" do
      let(:source_code) do
        <<~ERB
          <div>
            <p>Error line</p>
            <p>Warning line</p>
          </div>
        ERB
      end

      let(:results) do
        [
          build(:lint_result,
                source: source_code,
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "test-rule",
                        message: "Error message",
                        start_line: 2,
                        start_column: 1),
                  build(:offense,
                        severity: "warning",
                        rule_name: "test-rule",
                        message: "Warning message",
                        start_line: 3,
                        start_column: 1)
                ])
        ]
      end

      it "displays appropriate symbols for each severity level" do
        subject

        actual = strip_colors(output.string)

        # Error offense with ✗ symbol
        error_section = [
          "  2:1    ✗ Error message (test-rule)",
          "",
          "    1 │ <div>",
          "  → 2 │   <p>Error line</p>",
          "      │ ~",
          "    3 │   <p>Warning line</p>",
          "    4 │ </div>"
        ].join("\n")

        expect(actual).to include(error_section)

        # Warning offense with ⚠ symbol
        warning_section = [
          "  3:1    ⚠ Warning message (test-rule)",
          "",
          "    1 │ <div>",
          "    2 │   <p>Error line</p>",
          "  → 3 │   <p>Warning line</p>",
          "      │ ~",
          "    4 │ </div>"
        ].join("\n")

        expect(actual).to include(warning_section)
      end
    end

    context "with autofixable offenses" do
      let(:source_code) do
        <<~ERB
          <div>
            <img src="photo.jpg">
          </div>
        ERB
      end

      let(:results) do
        [
          build(:lint_result,
                source: source_code,
                unfixed_offenses: [
                  build(:offense,
                        :autofixable,
                        severity: "error",
                        rule_name: "html-img-require-alt",
                        message: "img tag should have an alt attribute",
                        start_line: 2,
                        start_column: 3)
                ])
        ]
      end

      it "displays [Correctable] label in offense header" do
        subject

        actual = strip_colors(output.string)

        # Offense header should include [Correctable] label
        expected_header = "  2:3    ✗ img tag should have an alt attribute (html-img-require-alt) [Correctable]\n"
        expect(actual).to include(expected_header)
      end
    end

    context "with no offenses" do
      let(:results) do
        [
          build(:lint_result, file_path: "app/views/users/show.html.erb")
        ]
      end

      it "displays only summary without file details" do
        subject

        actual = strip_colors(output.string)

        # Should not display file path when there are no offenses
        expect(actual).not_to include("app/views/users/show.html.erb")

        # Summary should still be present with 0 offenses
        expect(actual).to include("Summary:")
        expect(actual).to include("0 offenses")
      end
    end

    context "with offenses at the start of the file" do
      let(:source_code) do
        <<~ERB
          <img src="photo.jpg">
          <p>Line 2</p>
          <p>Line 3</p>
          <p>Line 4</p>
        ERB
      end

      let(:results) do
        [
          build(:lint_result,
                source: source_code,
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "test-rule",
                        message: "Error on line 1",
                        start_line: 1,
                        start_column: 1)
                ])
        ]
      end

      it "shows context from line 1 (cannot show lines before)" do
        subject

        actual = strip_colors(output.string)

        # Should show lines 1-3 (line 1 + 2 lines after, can't go below line 1)
        expected_context = [
          "  → 1 │ <img src=\"photo.jpg\">",
          "      │ ~",
          "    2 │ <p>Line 2</p>",
          "    3 │ <p>Line 3</p>"
        ].join("\n")

        expect(actual).to include(expected_context)
      end
    end

    context "with offenses at the end of the file" do
      let(:source_code) do
        <<~ERB
          <p>Line 1</p>
          <p>Line 2</p>
          <img src="photo.jpg">
        ERB
      end

      let(:results) do
        [
          build(:lint_result,
                source: source_code,
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "test-rule",
                        message: "Error on last line",
                        start_line: 3,
                        start_column: 1)
                ])
        ]
      end

      it "shows context up to last line (cannot show lines after)" do
        subject

        actual = strip_colors(output.string)

        # Should show lines 1-3 (2 lines before + line 3, can't go beyond last line)
        expected_context = [
          "    1 │ <p>Line 1</p>",
          "    2 │ <p>Line 2</p>",
          "  → 3 │ <img src=\"photo.jpg\">",
          "      │ ~"
        ].join("\n")

        expect(actual).to include(expected_context)
      end
    end

    context "with non-TTY output" do
      let(:output) { StringIO.new }
      let(:results) do
        [
          build(:lint_result,
                source: "<img>\n",
                unfixed_offenses: [
                  build(:offense,
                        :autofixable,
                        severity: "error",
                        rule_name: "test-rule",
                        message: "Test message",
                        start_line: 1,
                        start_column: 1)
                ])
        ]
      end

      it "outputs plain text without ANSI color codes" do
        subject

        # Output should contain all expected elements
        expect(output.string).to include("Test message")
        expect(output.string).to include("[Correctable]")

        # But should not contain any ANSI color codes
        expect(output.string).not_to match(/\e\[.*?m/)
      end
    end

    context "with multiple offenses on different lines" do
      let(:source_code) do
        <<~ERB
          <div>
            <img src="photo1.jpg">
            <p>Some text</p>
            <img src="photo2.jpg">
          </div>
        ERB
      end

      let(:results) do
        [
          build(:lint_result,
                source: source_code,
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "html-img-require-alt",
                        message: "First img tag missing alt",
                        start_line: 2,
                        start_column: 3),
                  build(:offense,
                        severity: "error",
                        rule_name: "html-img-require-alt",
                        message: "Second img tag missing alt",
                        start_line: 4,
                        start_column: 3)
                ])
        ]
      end

      it "displays each offense with its own source context" do
        subject

        actual = strip_colors(output.string)

        # First offense (line 2) with context
        first_offense_section = [
          "  2:3    ✗ First img tag missing alt (html-img-require-alt)",
          "",
          "    1 │ <div>",
          "  → 2 │   <img src=\"photo1.jpg\">",
          "      │   ~",
          "    3 │   <p>Some text</p>",
          "    4 │   <img src=\"photo2.jpg\">"
        ].join("\n")

        expect(actual).to include(first_offense_section)

        # Second offense (line 4) with context
        second_offense_section = [
          "  4:3    ✗ Second img tag missing alt (html-img-require-alt)",
          "",
          "    2 │   <img src=\"photo1.jpg\">",
          "    3 │   <p>Some text</p>",
          "  → 4 │   <img src=\"photo2.jpg\">",
          "      │   ~",
          "    5 │ </div>"
        ].join("\n")

        expect(actual).to include(second_offense_section)
      end
    end

    context "with TTY output and theme_name:" do
      # A StringIO with tty? stubbed to true so that DiagnosticRenderer and
      # SyntaxRenderer both operate in TTY mode.
      let(:tty_output) do
        io = StringIO.new
        allow(io).to receive(:tty?).and_return(true)
        io
      end
      let(:results) do
        [
          build(:lint_result,
                source: "<div>\n  <p>Hello</p>\n</div>\n",
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "test-rule",
                        message: "Test error",
                        start_line: 1,
                        start_column: 1)
                ])
        ]
      end

      context "when theme_name: nil" do
        let(:formatter) { described_class.new(io: tty_output, theme_name: nil) }

        it "produces no 24-bit ANSI syntax highlighting codes" do
          subject

          # DiagnosticRenderer uses named ANSI codes (e.g. \e[90m) for line numbers/arrows.
          # SyntaxRenderer with a hex-color theme produces \e[38;2;R;G;Bm (24-bit true-color).
          # With theme_name: nil, no 24-bit codes should appear.
          expect(tty_output.string).not_to match(/\e\[38;2;/)
        end
      end

      context "when theme_name: 'onedark'" do
        let(:formatter) { described_class.new(io: tty_output, theme_name: "onedark") }

        it "produces 24-bit ANSI syntax highlighting codes" do
          subject

          # Onedark theme uses hex colors (e.g. #E06C75 for HTML tags), which produce
          # \e[38;2;R;G;Bm escape codes via Color.colorize.
          expect(tty_output.string).to match(/\e\[38;2;/)
        end
      end

      context "when theme_name: is an unknown name" do
        let(:formatter) { described_class.new(io: tty_output, theme_name: "unknown-theme") }

        it "does not raise an error and produces no 24-bit ANSI syntax highlighting codes" do
          expect { subject }.not_to raise_error
          # Unknown theme falls back to plain text for source content.
          expect(tty_output.string).not_to match(/\e\[38;2;/)
        end
      end
    end

    context "with offense spanning multiple columns" do
      let(:source_code) do
        <<~ERB
          <div>
            <img src="photo.jpg">
          </div>
        ERB
      end

      let(:results) do
        [
          build(:lint_result,
                source: source_code,
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "html-img-require-alt",
                        message: "img element should have alt attribute",
                        start_line: 2,
                        start_column: 3,
                        end_line: 2,
                        end_column: 24)
                ])
        ]
      end

      it "displays multi-character pointer to show the full range" do
        subject

        actual = strip_colors(output.string)

        # Should show pointer spanning from column 3 to 24 (22 characters)
        expected_context = [
          "    1 │ <div>",
          "  → 2 │   <img src=\"photo.jpg\">",
          "      │   ~~~~~~~~~~~~~~~~~~~~~~",
          "    3 │ </div>"
        ].join("\n")

        expect(actual).to include(expected_context)
      end
    end
  end
end
