# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "herb/config"

RSpec.describe Herb::Lint::Runner do
  describe "#run" do
    subject { runner.run(paths) }

    let(:runner) { described_class.new(config) }
    let(:config) { Herb::Config::LinterConfig.new(config_hash) }
    let(:config_hash) { { "linter" => linter_config } }
    let(:linter_config) { { "include" => include_patterns, "exclude" => exclude_patterns } }
    let(:include_patterns) { ["**/*.html.erb"] }
    let(:exclude_patterns) { [] }
    let(:paths) { [] }

    around do |example|
      Dir.mktmpdir do |temp_dir|
        Dir.chdir(temp_dir) do
          example.run
        end
      end
    end

    def create_file(relative_path, content = "")
      full_path = File.join(Dir.pwd, relative_path)
      FileUtils.mkdir_p(File.dirname(full_path))
      # Ensure content ends with newline if not empty
      content_with_newline = if content.empty? || content.end_with?("\n")
                               content
                             else
                               "#{content}\n"
                             end
      File.write(full_path, content_with_newline)
    end

    context "when discovering files from patterns" do
      before do
        create_file("app/views/users/index.html.erb", '<img src="test.png">')
        create_file("app/views/posts/show.html.erb", '<img src="image.png" alt="Image">')
        create_file("app/assets/application.js", "// javascript")
      end

      it "discovers files matching include patterns" do
        expect(subject.file_count).to eq(2)
      end

      it "returns an AggregatedResult" do
        expect(subject).to be_a(Herb::Lint::AggregatedResult)
      end
    end

    context "when discovering files from explicit paths" do
      let(:paths) { ["app/views/users/index.html.erb"] }

      before do
        create_file("app/views/users/index.html.erb", '<img src="test.png">')
        create_file("app/views/posts/show.html.erb", '<img src="image.png">')
      end

      it "processes only the specified files" do
        expect(subject.file_count).to eq(1)
      end
    end

    context "when processing multiple files" do
      before do
        create_file("app/views/a.html.erb", '<img src="a.png">')
        create_file("app/views/b.html.erb", '<img src="b.png">')
        create_file("app/views/c.html.erb", '<img src="c.png">')
      end

      it "processes all files and aggregates results" do
        expect(subject.file_count).to eq(3)
        expect(subject.offense_count).to eq(6)
      end
    end

    context "when aggregating results" do
      before do
        create_file("app/views/valid.html.erb", '<img src="test.png" alt="Test">')
        create_file("app/views/invalid.html.erb", '<img src="test.png">')
      end

      it "aggregates offense counts correctly" do
        expect(subject.file_count).to eq(2)
        expect(subject.offense_count).to eq(3)
        expect(subject.error_count).to eq(1)
      end

      it "reports success correctly" do
        expect(subject.success?).to be(false)
      end
    end

    context "when all files are valid" do
      before do
        create_file("app/views/valid.html.erb", '<%= image_tag "test.png", alt: "Test" %>')
      end

      it "reports success" do
        expect(subject.success?).to be(true)
        expect(subject.offense_count).to eq(0)
      end
    end

    context "when no files match" do
      it "returns an empty result" do
        expect(subject.file_count).to eq(0)
        expect(subject.offense_count).to eq(0)
        expect(subject.success?).to be(true)
      end
    end

    context "with exclude patterns" do
      let(:exclude_patterns) { ["vendor/**/*"] }

      before do
        create_file("app/views/index.html.erb", '<img src="test.png">')
        create_file("vendor/gems/template.html.erb", '<img src="test.png">')
      end

      it "excludes files matching exclude patterns" do
        expect(subject.file_count).to eq(1)
      end
    end

    context "with fix: false" do
      let(:runner) { described_class.new(config, fix: false) }
      let(:paths) { ["app/views/test.html.erb"] }

      before do
        create_file("app/views/test.html.erb", "<% %>\n<p>Hello</p>")
      end

      it "does not modify files" do
        original_content = File.read("app/views/test.html.erb")

        expect(subject.offense_count).to eq(1)
        expect(File.read("app/views/test.html.erb")).to eq(original_content)
      end
    end

    context "with fix: true" do
      let(:runner) { described_class.new(config, fix: true) }
      let(:paths) { ["app/views/test.html.erb"] }

      context "when there are fixable offenses" do
        before do
          create_file("app/views/test.html.erb", "<% %>\n<p>Hello</p>")
        end

        it "applies fixes and writes file" do
          expect(subject.offense_count).to eq(0)
          expect(File.read("app/views/test.html.erb")).to eq("\n<p>Hello</p>\n")
        end
      end

      context "when there are non-fixable offenses" do
        before do
          create_file("app/views/test.html.erb", '<img src="test.png">')
        end

        it "does not modify files" do
          original_content = File.read("app/views/test.html.erb")

          expect(subject.offense_count).to be > 0
          expect(File.read("app/views/test.html.erb")).to eq(original_content)
        end
      end

      context "when files have no offenses" do
        before do
          create_file("app/views/test.html.erb", "<p>Hello</p>")
        end

        it "does not modify files" do
          original_content = File.read("app/views/test.html.erb")

          expect(subject.success?).to be(true)
          expect(File.read("app/views/test.html.erb")).to eq(original_content)
        end
      end

      context "when processing multiple files" do
        let(:paths) { ["app/views"] }

        before do
          create_file("app/views/a.html.erb", "<% %>\n<p>A</p>")
          create_file("app/views/b.html.erb", "<% %>\n<p>B</p>")
          create_file("app/views/c.html.erb", "<p>C</p>")
        end

        it "applies fixes to all files with fixable offenses" do
          expect(subject.file_count).to eq(3)
          expect(subject.offense_count).to eq(0)
          expect(File.read("app/views/a.html.erb")).to eq("\n<p>A</p>\n")
          expect(File.read("app/views/b.html.erb")).to eq("\n<p>B</p>\n")
          expect(File.read("app/views/c.html.erb")).to eq("<p>C</p>\n")
        end
      end
    end

    context "with fix: true and unsafe: true" do
      let(:runner) { described_class.new(config, fix: true, unsafe: true) }
      let(:paths) { ["app/views/test.html.erb"] }

      before do
        create_file("app/views/test.html.erb", "<% %>\n<p>Hello</p>")
      end

      it "applies all fixes including unsafe ones" do
        expect(subject.offense_count).to eq(0)
        expect(File.read("app/views/test.html.erb")).to eq("\n<p>Hello</p>\n")
      end
    end
  end

  describe "#config" do
    subject { runner.config }

    let(:runner) { described_class.new(config) }
    let(:config) { Herb::Config::LinterConfig.new({}) }

    it "returns the config passed to the initializer" do
      expect(subject).to eq(config)
    end
  end
end
