# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe Herb::Core::FileDiscovery do
  describe "#discover" do
    subject { discovery.discover(paths) }

    let(:discovery) do
      described_class.new(
        base_dir: base_dir,
        include_patterns: include_patterns,
        exclude_patterns: exclude_patterns
      )
    end
    let(:base_dir) { Dir.mktmpdir }
    let(:include_patterns) { [] }
    let(:exclude_patterns) { [] }

    after { FileUtils.rm_rf(base_dir) }

    def create_file(relative_path)
      full_path = File.join(base_dir, relative_path)
      FileUtils.mkdir_p(File.dirname(full_path))
      FileUtils.touch(full_path)
    end

    context "when paths is empty (pattern-based discovery)" do
      let(:paths) { [] }

      context "with single include pattern" do
        let(:include_patterns) { ["**/*.html.erb"] }

        before do
          create_file("app/views/users/index.html.erb")
          create_file("app/views/users/show.html.erb")
          create_file("app/views/posts/index.html.erb")
          create_file("app/views/users/index.html")
          create_file("app/assets/application.js")
        end

        it "returns files matching the include pattern" do
          expect(subject).to contain_exactly(
            "app/views/users/index.html.erb",
            "app/views/users/show.html.erb",
            "app/views/posts/index.html.erb"
          )
        end
      end

      context "with multiple include patterns" do
        let(:include_patterns) { ["**/*.html.erb", "**/*.html"] }

        before do
          create_file("app/views/users/index.html.erb")
          create_file("app/views/users/index.html")
          create_file("app/assets/application.js")
        end

        it "returns files matching any of the patterns" do
          expect(subject).to contain_exactly(
            "app/views/users/index.html.erb",
            "app/views/users/index.html"
          )
        end
      end

      context "with overlapping patterns" do
        let(:include_patterns) { ["app/views/**/*.html.erb", "app/views/users/*.html.erb"] }

        before do
          create_file("app/views/users/index.html.erb")
          create_file("app/views/users/show.html.erb")
        end

        it "returns each file only once" do
          expect(subject).to contain_exactly(
            "app/views/users/index.html.erb",
            "app/views/users/show.html.erb"
          )
        end
      end

      context "with single exclude pattern" do
        let(:include_patterns) { ["**/*.html.erb"] }
        let(:exclude_patterns) { ["vendor/**/*"] }

        before do
          create_file("app/views/users/index.html.erb")
          create_file("vendor/gems/template.html.erb")
          create_file("vendor/cache/cached.html.erb")
        end

        it "excludes files matching the exclusion pattern" do
          expect(subject).to eq(["app/views/users/index.html.erb"])
        end
      end

      context "with multiple exclude patterns" do
        let(:include_patterns) { ["**/*.html.erb"] }
        let(:exclude_patterns) { ["vendor/**/*", "tmp/**/*"] }

        before do
          create_file("app/views/users/index.html.erb")
          create_file("vendor/gems/template.html.erb")
          create_file("tmp/cache/cached.html.erb")
        end

        it "excludes files matching any exclusion pattern" do
          expect(subject).to eq(["app/views/users/index.html.erb"])
        end
      end

      context "when no files match" do
        let(:include_patterns) { ["**/*.html.erb"] }

        before do
          create_file("app/assets/application.js")
        end

        it "returns an empty array" do
          expect(subject).to be_empty
        end
      end

      context "when sorting results" do
        let(:include_patterns) { ["**/*.html.erb"] }

        before do
          create_file("z/file.html.erb")
          create_file("a/file.html.erb")
          create_file("m/file.html.erb")
        end

        it "returns files in sorted order" do
          expect(subject).to eq(["a/file.html.erb", "m/file.html.erb", "z/file.html.erb"])
        end
      end
    end

    context "when paths contains files" do
      context "with single file path" do
        let(:include_patterns) { ["**/*.html.erb"] }
        let(:paths) { ["app/views/users/show.html.erb"] }

        before do
          create_file("app/views/users/index.html.erb")
          create_file("app/views/users/show.html.erb")
          create_file("app/views/posts/index.html.erb")
        end

        it "returns only the specified file, ignoring include patterns" do
          expect(subject).to eq(["app/views/users/show.html.erb"])
        end
      end

      context "with file path matching exclude pattern" do
        let(:exclude_patterns) { ["vendor/**/*"] }
        let(:paths) { ["vendor/gems/template.html.erb"] }

        before do
          create_file("vendor/gems/template.html.erb")
        end

        it "does not apply exclusion patterns to explicit file paths" do
          expect(subject).to eq(["vendor/gems/template.html.erb"])
        end
      end

      context "with non-existent file paths" do
        let(:paths) { ["app/views/missing.html.erb", "app/views/users/index.html.erb"] }

        before do
          create_file("app/views/users/index.html.erb")
        end

        it "ignores non-existent files" do
          expect(subject).to eq(["app/views/users/index.html.erb"])
        end
      end
    end

    context "when paths contains directories" do
      context "with single directory path" do
        let(:paths) { ["app/views/users"] }

        before do
          create_file("app/views/users/index.html.erb")
          create_file("app/views/users/show.html.erb")
          create_file("app/views/posts/index.html.erb")
        end

        it "returns all files in the directory recursively" do
          expect(subject).to contain_exactly(
            "app/views/users/index.html.erb",
            "app/views/users/show.html.erb"
          )
        end
      end

      context "with directory containing files matching exclude pattern" do
        let(:exclude_patterns) { ["**/vendor/**/*"] }
        let(:paths) { ["app/views"] }

        before do
          create_file("app/views/users/index.html.erb")
          create_file("app/views/vendor/excluded.html.erb")
        end

        it "applies exclusion patterns to files discovered from directory" do
          expect(subject).to eq(["app/views/users/index.html.erb"])
        end
      end
    end
  end
end
