# frozen_string_literal: true

require "spec_helper"
require "open3"

RSpec.describe "CLI integration" do # rubocop:disable RSpec/DescribeClass
  let(:fixtures_path) { File.expand_path("../fixtures/templates", __dir__) }

  describe "--version flag" do
    subject { run_cli("--version") }

    it "outputs version and exits with success code" do
      expect(subject[:stdout]).to match(/herb-lint \d+\.\d+\.\d+/)
      expect(subject[:status].exitstatus).to eq(Herb::Lint::CLI::EXIT_SUCCESS)
    end
  end

  describe "--help flag" do
    subject { run_cli("--help") }

    it "outputs help text and exits with success code" do
      expect(subject[:stdout]).to include("Usage:")
      expect(subject[:status].exitstatus).to eq(Herb::Lint::CLI::EXIT_SUCCESS)
    end
  end

  describe "linting files" do
    context "with valid file" do
      subject { run_cli(fixture_path("valid.html.erb")) }

      it "reports no problems and exits with success code" do
        expect(subject[:stdout]).to include("0 problems")
        expect(subject[:status].exitstatus).to eq(Herb::Lint::CLI::EXIT_SUCCESS)
      end
    end

    context "with file containing offenses" do
      subject { run_cli(fixture_path("missing_alt.html.erb")) }

      it "reports offenses and exits with lint error code" do
        expect(subject[:stdout]).to include("alt-text")
        expect(subject[:stdout]).to include("1 problem")
        expect(subject[:status].exitstatus).to eq(Herb::Lint::CLI::EXIT_LINT_ERROR)
      end
    end

    context "with multiple files containing issues" do
      subject { run_cli(fixtures_path) }

      it "processes all files, reports offenses, and exits with lint error code" do
        expect(subject[:stdout]).to include("problems")
        expect(subject[:status].exitstatus).to eq(Herb::Lint::CLI::EXIT_LINT_ERROR)
      end
    end
  end

  describe "output format" do
    subject { run_cli(fixture_path("mixed_issues.html.erb")) }

    it "includes file path, line/column, severity, rule name, and summary" do
      expect(subject[:stdout]).to include("mixed_issues.html.erb")
      expect(subject[:stdout]).to match(/\d+:\d+/)
      expect(subject[:stdout]).to match(/error|warning/)
      expect(subject[:stdout]).to match(%r{alt-text|html/attribute-quotes})
      expect(subject[:stdout]).to match(/\d+ problems?\s+\(\d+ errors?,\s+\d+ warnings?\)/)
    end
  end

  private

  def run_cli(*args)
    herb_lint_path = File.expand_path("../../exe/herb-lint", __dir__)
    Dir.chdir(File.expand_path("../..", __dir__)) do
      stdout, stderr, status = Open3.capture3("bundle", "exec", herb_lint_path, *args)
      { stdout:, stderr:, status: }
    end
  end

  def fixture_path(filename)
    File.join(fixtures_path, filename)
  end
end
