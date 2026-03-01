# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::Runner do
  let(:config) { build(:formatter_config) }
  let(:runner) { described_class.new(config:) }

  describe "#run" do
    around do |example|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          example.run
        end
      end
    end

    context "with no files" do
      subject { runner.run }

      it "returns an empty AggregatedResult" do
        expect(subject).to be_a(Herb::Format::AggregatedResult)
        expect(subject.file_count).to eq(0)
      end
    end

    context "with specific files" do
      subject { runner.run(["test.html.erb"]) }

      before { File.write("test.html.erb", "<div>test</div>") }

      it "formats the provided files" do
        expect(subject.file_count).to eq(1)
      end
    end

    context "with exclude patterns configured" do
      subject { runner.run(["vendor/test.html.erb"]) }

      let(:config) do
        Herb::Config::FormatterConfig.new(
          "formatter" => { "enabled" => true, "exclude" => ["vendor/**"] }
        )
      end

      before do
        FileUtils.mkdir_p("vendor")
        File.write("vendor/test.html.erb", "<div>test</div>")
      end

      it "excludes files matching the exclude patterns" do
        expect(subject.file_count).to eq(0)
      end
    end

    context "when check: false (default)" do
      subject { runner.run(["test.html.erb"]) }

      let(:runner) { described_class.new(config:, check: false) }

      before { File.write("test.html.erb", "<div><p>Hello</p></div>") }

      it "writes changed content to disk" do
        expect(subject.changed_count).to eq(1)
        expect(File.read("test.html.erb")).to eq("<div>\n  <p>Hello</p>\n</div>")
      end
    end

    context "when check: true" do
      subject { runner.run(["test.html.erb"]) }

      let(:runner) { described_class.new(config:, check: true) }
      let(:original_content) { "<div>test</div>" }

      before { File.write("test.html.erb", original_content) }

      it "does not write changes to disk" do
        subject
        expect(File.read("test.html.erb")).to eq(original_content)
      end
    end

    context "when a file has an ignore directive" do
      subject { runner.run(["test.html.erb"]) }

      let(:runner) { described_class.new(config:, check: false) }
      let(:original_content) { "<%# herb:formatter ignore %>\n<div>test</div>" }

      before { File.write("test.html.erb", original_content) }

      it "does not write ignored files" do
        expect(subject.ignored_count).to eq(1)
        expect(File.read("test.html.erb")).to eq(original_content)
      end
    end

    context "when a file fails to parse" do
      subject { runner.run(["test.html.erb"]) }

      let(:runner) { described_class.new(config:, check: false) }
      let(:original_content) { "<div><span></div>" }

      before { File.write("test.html.erb", original_content) }

      it "does not write the errored file" do
        expect(subject.error_count).to eq(1)
        expect(File.read("test.html.erb")).to eq(original_content)
      end
    end

    context "when an individual file raises an error" do
      subject { runner.run(["nonexistent.html.erb", "valid.html.erb"]) }

      before { File.write("valid.html.erb", "<div>test</div>") }

      it "continues processing remaining files and records the error" do
        expect(subject.file_count).to eq(2)
        expect(subject.error_count).to eq(1)
      end
    end
  end

  describe "#format_source" do
    subject { runner.format_source(source, file_path:) }

    let(:file_path) { "stdin" }

    context "with valid ERB content" do
      let(:source) { "<div><p>Hello</p></div>" }

      it "returns a formatted FormatResult without error" do
        expect(subject).to be_a(Herb::Format::FormatResult)
        expect(subject.error?).to be false
        expect(subject.formatted).to eq("<div>\n  <p>Hello</p>\n</div>")
      end
    end

    context "with already formatted content" do
      let(:source) { "<div>\n  <p>Hello</p>\n</div>" }

      it "returns unchanged result" do
        expect(subject.changed?).to be false
      end
    end

    context "with invalid ERB content" do
      let(:source) { "<div><span></div>" }

      it "returns an error result" do
        expect(subject.error?).to be true
      end
    end
  end
end
