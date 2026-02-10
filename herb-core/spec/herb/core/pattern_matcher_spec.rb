# frozen_string_literal: true

RSpec.describe Herb::Core::PatternMatcher do
  describe "#match?" do
    subject { matcher.match?(path) }

    let(:includes) { [] }
    let(:excludes) { [] }
    let(:only) { [] }
    let(:matcher) { described_class.new(includes:, excludes:, only:) }

    context "with no patterns specified" do
      context "when checking any path" do
        let(:path) { "app/views/users/index.html.erb" }

        it { is_expected.to be true }
      end

      context "when checking dotfile" do
        let(:path) { ".hidden/file.erb" }

        it { is_expected.to be true }
      end
    end

    context "with only include patterns" do
      let(:includes) { ["**/*.erb", "**/*.html"] }

      context "when path matches first pattern" do
        let(:path) { "app/views/index.html.erb" }

        it { is_expected.to be true }
      end

      context "when path matches second pattern" do
        let(:path) { "app/views/index.html" }

        it { is_expected.to be true }
      end

      context "when path matches neither pattern" do
        let(:path) { "app/assets/application.js" }

        it { is_expected.to be false }
      end
    end

    context "with only exclude patterns" do
      let(:excludes) { ["vendor/**", "tmp/**"] }

      context "when path matches first exclude pattern" do
        let(:path) { "vendor/gems/template.html.erb" }

        it { is_expected.to be false }
      end

      context "when path matches second exclude pattern" do
        let(:path) { "tmp/cache/cached.html.erb" }

        it { is_expected.to be false }
      end

      context "when path matches neither exclude pattern" do
        let(:path) { "app/views/users/index.html.erb" }

        it { is_expected.to be true }
      end
    end

    context "with only 'only' patterns" do
      let(:only) { ["app/views/**", "app/components/**"] }

      context "when path matches first only pattern" do
        let(:path) { "app/views/users/index.html.erb" }

        it { is_expected.to be true }
      end

      context "when path matches second only pattern" do
        let(:path) { "app/components/button/template.html.erb" }

        it { is_expected.to be true }
      end

      context "when path matches neither only pattern" do
        let(:path) { "lib/templates/index.html.erb" }

        it { is_expected.to be false }
      end
    end

    context "with include and exclude patterns" do
      let(:includes) { ["**/*.erb"] }
      let(:excludes) { ["vendor/**"] }

      context "when path matches include but not exclude" do
        let(:path) { "app/views/users/index.html.erb" }

        it { is_expected.to be true }
      end

      context "when path matches both include and exclude" do
        let(:path) { "vendor/gems/template.html.erb" }

        it("exclude takes precedence") { is_expected.to be false }
      end

      context "when path matches neither include nor exclude" do
        let(:path) { "app/assets/application.js" }

        it { is_expected.to be false }
      end
    end

    context "with only and exclude patterns" do
      let(:excludes) { ["**/legacy/**"] }
      let(:only) { ["app/views/**"] }

      context "when path matches only but not exclude" do
        let(:path) { "app/views/users/index.html.erb" }

        it { is_expected.to be true }
      end

      context "when path matches both only and exclude" do
        let(:path) { "app/views/legacy/old.html.erb" }

        it("exclude takes precedence") { is_expected.to be false }
      end

      context "when path does not match only" do
        let(:path) { "lib/templates/index.html.erb" }

        it { is_expected.to be false }
      end
    end

    context "with only and include patterns" do
      let(:includes) { ["**/*.erb"] }
      let(:only) { ["app/views/**"] }

      context "when path matches only pattern" do
        let(:path) { "app/views/users/index.html.erb" }

        it("only takes precedence over include") { is_expected.to be true }
      end

      context "when path matches include but not only" do
        let(:path) { "lib/templates/index.html.erb" }

        it("only takes precedence") { is_expected.to be false }
      end
    end

    context "with complex glob patterns" do
      context "with pattern ending in **" do
        let(:includes) { ["vendor/**"] }

        context "when matching file in subdirectory" do
          let(:path) { "vendor/gems/some_gem/file.rb" }

          it { is_expected.to be true }
        end

        context "when matching file directly in directory" do
          let(:path) { "vendor/file.rb" }

          it { is_expected.to be true }
        end
      end

      context "with wildcard in middle of path" do
        let(:includes) { ["app/*/templates/*.erb"] }
        let(:path) { "app/views/templates/index.html.erb" }

        it { is_expected.to be true }
      end

      context "with brace expansion pattern" do
        let(:includes) { ["**/*.{erb,html}"] }

        context "when path matches first extension" do
          let(:path) { "app/views/index.html.erb" }

          it { is_expected.to be true }
        end

        context "when path matches second extension" do
          let(:path) { "app/views/index.html" }

          it { is_expected.to be true }
        end
      end

      context "with single asterisk" do
        let(:includes) { ["app/*.erb"] }

        context "when file is directly in directory" do
          let(:path) { "app/template.html.erb" }

          it { is_expected.to be true }
        end

        context "when file is in subdirectory" do
          let(:path) { "app/views/template.html.erb" }

          it { is_expected.to be false }
        end
      end
    end
  end
end
