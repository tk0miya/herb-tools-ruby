# frozen_string_literal: true

require "json"

RSpec.describe Herb::Lint::Reporter::JsonReporter do
  describe "#report" do
    subject { reporter.report(aggregated_result) }

    let(:reporter) { described_class.new(io: output) }
    let(:output) { StringIO.new }
    let(:aggregated_result) { Herb::Lint::AggregatedResult.new(results) }
    let(:parsed_output) { JSON.parse(output.string) }

    context "when there are no files" do
      let(:results) { [] }

      it "outputs valid JSON with empty files array and zero summary" do
        subject

        expect(parsed_output).to eq(
          "files" => [],
          "summary" => {
            "fileCount" => 0,
            "offenseCount" => 0,
            "errorCount" => 0,
            "warningCount" => 0,
            "fixableCount" => 0
          }
        )
      end
    end

    context "when there are files with no offenses" do
      let(:results) do
        [
          Herb::Lint::LintResult.new(
            file_path: "app/views/users/index.html.erb",
            offenses: [],
            source: "<div></div>"
          )
        ]
      end

      it "outputs files with empty offenses arrays" do
        subject

        expect(parsed_output["files"]).to eq(
          [
            {
              "path" => "app/views/users/index.html.erb",
              "offenses" => []
            }
          ]
        )
        expect(parsed_output["summary"]["offenseCount"]).to eq(0)
      end
    end

    context "when a single file has offenses" do
      let(:results) do
        [
          Herb::Lint::LintResult.new(
            file_path: "app/views/users/index.html.erb",
            offenses: [
              build_offense(
                severity: "error",
                rule_name: "html-img-require-alt",
                message: "Missing alt attribute on img tag",
                line: 12,
                column: 5
              ),
              build_offense(
                severity: "warning",
                rule_name: "html-attribute-double-quotes",
                message: "Prefer double quotes for attributes",
                line: 24,
                column: 3
              )
            ],
            source: "<div></div>"
          )
        ]
      end

      it "formats offenses correctly with all fields" do
        subject

        offenses = parsed_output["files"][0]["offenses"]
        expect(offenses.size).to eq(2)
        expect(offenses[0]).to eq(
          "rule" => "html-img-require-alt",
          "severity" => "error",
          "message" => "Missing alt attribute on img tag",
          "line" => 12,
          "column" => 5,
          "endLine" => 12,
          "endColumn" => 5,
          "fixable" => false
        )
        expect(offenses[1]).to eq(
          "rule" => "html-attribute-double-quotes",
          "severity" => "warning",
          "message" => "Prefer double quotes for attributes",
          "line" => 24,
          "column" => 3,
          "endLine" => 24,
          "endColumn" => 3,
          "fixable" => false
        )
      end
    end

    context "when multiple files have offenses" do
      let(:results) do
        [
          Herb::Lint::LintResult.new(
            file_path: "app/views/users/index.html.erb",
            offenses: [
              build_offense(
                severity: "error",
                rule_name: "html-img-require-alt",
                message: "Missing alt attribute on img tag",
                line: 12,
                column: 5
              )
            ],
            source: "<div></div>"
          ),
          Herb::Lint::LintResult.new(
            file_path: "app/views/posts/show.html.erb",
            offenses: [
              build_offense(
                severity: "warning",
                rule_name: "html-attribute-double-quotes",
                message: "Prefer double quotes for attributes",
                line: 3,
                column: 10
              ),
              build_offense(
                severity: "error",
                rule_name: "html-no-duplicate-ids",
                message: "Duplicate id attribute",
                line: 7,
                column: 1
              )
            ],
            source: "<div></div>"
          )
        ]
      end

      it "aggregates files and computes summary counts correctly" do
        subject

        expect(parsed_output["files"].size).to eq(2)
        expect(parsed_output["files"][0]["path"]).to eq("app/views/users/index.html.erb")
        expect(parsed_output["files"][1]["path"]).to eq("app/views/posts/show.html.erb")
        expect(parsed_output["files"][0]["offenses"].size).to eq(1)
        expect(parsed_output["files"][1]["offenses"].size).to eq(2)

        summary = parsed_output["summary"]
        expect(summary).to eq(
          "fileCount" => 2,
          "offenseCount" => 3,
          "errorCount" => 2,
          "warningCount" => 1,
          "fixableCount" => 0
        )
      end
    end

    context "when offenses have distinct end positions" do
      let(:results) do
        start_pos = Herb::Position.new(12, 5)
        end_pos = Herb::Position.new(12, 35)
        location = Herb::Location.new(start_pos, end_pos)

        [
          Herb::Lint::LintResult.new(
            file_path: "test.html.erb",
            offenses: [
              Herb::Lint::Offense.new(
                rule_name: "html-img-require-alt",
                message: "Missing alt attribute on img tag",
                severity: "error",
                location:
              )
            ],
            source: "<div></div>"
          )
        ]
      end

      it "includes correct endLine and endColumn" do
        subject

        offense = parsed_output["files"][0]["offenses"][0]
        expect(offense["line"]).to eq(12)
        expect(offense["column"]).to eq(5)
        expect(offense["endLine"]).to eq(12)
        expect(offense["endColumn"]).to eq(35)
      end
    end

    context "when fixable flag is included" do
      let(:results) do
        [
          Herb::Lint::LintResult.new(
            file_path: "test.html.erb",
            offenses: [
              build_offense(severity: "error", rule_name: "test-rule", message: "Test", line: 1, column: 0)
            ],
            source: "<div></div>"
          )
        ]
      end

      it "sets fixable to false for all offenses" do
        subject

        offense = parsed_output["files"][0]["offenses"][0]
        expect(offense["fixable"]).to be(false)
      end
    end
  end
end
