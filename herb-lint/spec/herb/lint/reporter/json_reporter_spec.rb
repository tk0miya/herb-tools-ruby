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

      it "outputs valid JSON with empty offenses array and zero summary" do
        subject

        expect(parsed_output).to eq(
          "offenses" => [],
          "summary" => {
            "filesChecked" => 0,
            "filesWithOffenses" => 0,
            "totalErrors" => 0,
            "totalWarnings" => 0,
            "totalInfo" => 0,
            "totalHints" => 0,
            "totalIgnored" => 0,
            "totalOffenses" => 0,
            "ruleCount" => 0
          },
          "timing" => nil,
          "completed" => true,
          "clean" => true,
          "message" => nil
        )
      end
    end

    context "when there are files with no offenses" do
      let(:results) do
        [
          build(:lint_result, file_path: "app/views/users/index.html.erb")
        ]
      end

      it "outputs empty offenses array and clean status" do
        subject

        expect(parsed_output["offenses"]).to eq([])
        expect(parsed_output["summary"]["totalOffenses"]).to eq(0)
        expect(parsed_output["summary"]["filesChecked"]).to eq(1)
        expect(parsed_output["summary"]["filesWithOffenses"]).to eq(0)
        expect(parsed_output["clean"]).to be(true)
      end
    end

    context "when a single file has offenses" do
      let(:results) do
        [
          build(:lint_result,
                file_path: "app/views/users/index.html.erb",
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "html-img-require-alt",
                        message: "Missing alt attribute on img tag",
                        start_line: 12,
                        start_column: 5),
                  build(:offense,
                        severity: "warning",
                        rule_name: "html-attribute-double-quotes",
                        message: "Prefer double quotes for attributes",
                        start_line: 24,
                        start_column: 3)
                ])
        ]
      end

      it "formats offenses correctly with all fields" do
        subject

        offenses = parsed_output["offenses"]
        expect(offenses.size).to eq(2)
        expect(offenses[0]).to eq(
          "filename" => "app/views/users/index.html.erb",
          "message" => "Missing alt attribute on img tag",
          "location" => {
            "start" => { "line" => 12, "column" => 5 },
            "end" => { "line" => 12, "column" => 5 }
          },
          "severity" => "error",
          "code" => "html-img-require-alt",
          "source" => "Herb Linter"
        )
        expect(offenses[1]).to eq(
          "filename" => "app/views/users/index.html.erb",
          "message" => "Prefer double quotes for attributes",
          "location" => {
            "start" => { "line" => 24, "column" => 3 },
            "end" => { "line" => 24, "column" => 3 }
          },
          "severity" => "warning",
          "code" => "html-attribute-double-quotes",
          "source" => "Herb Linter"
        )
      end
    end

    context "when multiple files have offenses" do
      let(:results) do
        [
          build(:lint_result,
                file_path: "app/views/users/index.html.erb",
                unfixed_offenses: [
                  build(:offense,
                        severity: "error",
                        rule_name: "html-img-require-alt",
                        message: "Missing alt attribute on img tag",
                        start_line: 12,
                        start_column: 5)
                ]),
          build(:lint_result,
                file_path: "app/views/posts/show.html.erb",
                unfixed_offenses: [
                  build(:offense,
                        severity: "warning",
                        rule_name: "html-attribute-double-quotes",
                        message: "Prefer double quotes for attributes",
                        start_line: 3,
                        start_column: 10),
                  build(:offense,
                        severity: "error",
                        rule_name: "html-no-duplicate-ids",
                        message: "Duplicate id attribute",
                        start_line: 7,
                        start_column: 1)
                ])
        ]
      end

      it "aggregates offenses from multiple files and computes summary counts correctly" do
        subject

        offenses = parsed_output["offenses"]
        expect(offenses.size).to eq(3)
        expect(offenses[0]["filename"]).to eq("app/views/users/index.html.erb")
        expect(offenses[1]["filename"]).to eq("app/views/posts/show.html.erb")
        expect(offenses[2]["filename"]).to eq("app/views/posts/show.html.erb")

        summary = parsed_output["summary"]
        expect(summary).to eq(
          "filesChecked" => 2,
          "filesWithOffenses" => 2,
          "totalErrors" => 2,
          "totalWarnings" => 1,
          "totalInfo" => 0,
          "totalHints" => 0,
          "totalIgnored" => 0,
          "totalOffenses" => 3,
          "ruleCount" => 0
        )
      end
    end

    context "when offenses have distinct end positions" do
      let(:results) do
        [
          build(:lint_result, unfixed_offenses: [
                  build(:offense,
                        rule_name: "html-img-require-alt",
                        message: "Missing alt attribute on img tag",
                        severity: "error",
                        start_line: 12,
                        start_column: 5,
                        end_line: 12,
                        end_column: 35)
                ])
        ]
      end

      it "includes correct location start and end positions" do
        subject

        offense = parsed_output["offenses"][0]
        expect(offense["location"]["start"]["line"]).to eq(12)
        expect(offense["location"]["start"]["column"]).to eq(5)
        expect(offense["location"]["end"]["line"]).to eq(12)
        expect(offense["location"]["end"]["column"]).to eq(35)
      end
    end

    context "when results include clean flag" do
      let(:results) do
        [
          build(:lint_result, unfixed_offenses: [
                  build(:offense, severity: "error", rule_name: "test-rule", message: "Test")
                ])
        ]
      end

      it "sets clean to false when offenses exist" do
        subject

        expect(parsed_output["clean"]).to be(false)
        expect(parsed_output["completed"]).to be(true)
      end
    end
  end
end
