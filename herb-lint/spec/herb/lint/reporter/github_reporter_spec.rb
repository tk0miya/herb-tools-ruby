# frozen_string_literal: true

RSpec.describe Herb::Lint::Reporter::GithubReporter do
  describe "#report" do
    subject { reporter.report(aggregated_result) }

    let(:reporter) { described_class.new(io: output) }
    let(:output) { StringIO.new }
    let(:aggregated_result) { Herb::Lint::AggregatedResult.new(results) }
    let(:output_lines) { output.string.split("\n") }

    context "when there are no files" do
      let(:results) { [] }

      it "outputs nothing" do
        subject

        expect(output.string).to be_empty
      end
    end

    context "when there are files with no offenses" do
      let(:results) do
        [build(:lint_result, file_path: "app/views/users/index.html.erb")]
      end

      it "outputs nothing" do
        subject

        expect(output.string).to be_empty
      end
    end

    context "when a file has error severity offense" do
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
                ])
        ]
      end

      it "outputs GitHub error annotation with file path, location, and message" do
        subject

        expect(output_lines).to eq([
                                     "::error file=app/views/users/index.html.erb,line=12,col=5::" \
                                     "Missing alt attribute on img tag (html-img-require-alt)"
                                   ])
      end
    end

    context "when a file has warning severity offense" do
      let(:results) do
        [
          build(:lint_result,
                file_path: "app/views/users/index.html.erb",
                unfixed_offenses: [
                  build(:offense,
                        severity: "warning",
                        rule_name: "html-attribute-double-quotes",
                        message: "Prefer double quotes for attributes",
                        start_line: 24,
                        start_column: 3)
                ])
        ]
      end

      it "outputs GitHub warning annotation" do
        subject

        expect(output_lines).to eq([
                                     "::warning file=app/views/users/index.html.erb,line=24,col=3::" \
                                     "Prefer double quotes for attributes (html-attribute-double-quotes)"
                                   ])
      end
    end

    context "when a file has info severity offense" do
      let(:results) do
        [
          build(:lint_result,
                file_path: "app/views/users/index.html.erb",
                unfixed_offenses: [
                  build(:offense,
                        severity: "info",
                        rule_name: "html-style-guide",
                        message: "Consider using semantic HTML",
                        start_line: 5,
                        start_column: 1)
                ])
        ]
      end

      it "outputs GitHub notice annotation" do
        subject

        expect(output_lines).to eq([
                                     "::notice file=app/views/users/index.html.erb,line=5,col=1::" \
                                     "Consider using semantic HTML (html-style-guide)"
                                   ])
      end
    end

    context "when a file has hint severity offense" do
      let(:results) do
        [
          build(:lint_result,
                file_path: "app/views/users/index.html.erb",
                unfixed_offenses: [
                  build(:offense,
                        severity: "hint",
                        rule_name: "html-optimization",
                        message: "This could be optimized",
                        start_line: 8,
                        start_column: 2)
                ])
        ]
      end

      it "outputs GitHub notice annotation" do
        subject

        expect(output_lines).to eq([
                                     "::notice file=app/views/users/index.html.erb,line=8,col=2::" \
                                     "This could be optimized (html-optimization)"
                                   ])
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

      it "outputs all annotations in order" do
        subject

        expect(output_lines).to eq([
                                     "::error file=app/views/users/index.html.erb,line=12,col=5::" \
                                     "Missing alt attribute on img tag (html-img-require-alt)",
                                     "::warning file=app/views/posts/show.html.erb,line=3,col=10::" \
                                     "Prefer double quotes for attributes (html-attribute-double-quotes)",
                                     "::error file=app/views/posts/show.html.erb,line=7,col=1::" \
                                     "Duplicate id attribute (html-no-duplicate-ids)"
                                   ])
      end
    end
  end
end
