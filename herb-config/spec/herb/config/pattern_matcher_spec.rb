# frozen_string_literal: true

RSpec.describe Herb::Config::PatternMatcher do
  describe "#match?" do
    subject { matcher.match?(file_path) }

    context "with only patterns" do
      let(:matcher) { described_class.new(only: ["app/views/**/*.html.erb"]) }

      context "when file matches only pattern" do
        let(:file_path) { "app/views/users/index.html.erb" }

        it "returns true" do
          expect(subject).to be true
        end
      end

      context "when file does not match only pattern" do
        let(:file_path) { "lib/templates/email.html.erb" }

        it "returns false" do
          expect(subject).to be false
        end
      end
    end

    context "with include patterns" do
      let(:matcher) { described_class.new(includes: ["**/*.html.erb", "**/*.xml.erb"]) }

      context "when file matches include pattern" do
        let(:file_path) { "app/views/index.html.erb" }

        it "returns true" do
          expect(subject).to be true
        end
      end

      context "when file matches another include pattern" do
        let(:file_path) { "app/views/feed.xml.erb" }

        it "returns true" do
          expect(subject).to be true
        end
      end

      context "when file does not match any include pattern" do
        let(:file_path) { "app/views/index.rb" }

        it "returns false" do
          expect(subject).to be false
        end
      end
    end

    context "with exclude patterns" do
      let(:matcher) { described_class.new(includes: ["**/*.html.erb"], excludes: ["legacy/**/*", "vendor/**/*"]) }

      context "when file matches include but is excluded" do
        let(:file_path) { "legacy/views/old.html.erb" }

        it "returns false" do
          expect(subject).to be false
        end
      end

      context "when file matches include and is not excluded" do
        let(:file_path) { "app/views/index.html.erb" }

        it "returns true" do
          expect(subject).to be true
        end
      end
    end

    context "with only and exclude patterns" do
      let(:matcher) { described_class.new(only: ["app/**/*"], excludes: ["app/legacy/**/*"]) }

      context "when file matches only and is not excluded" do
        let(:file_path) { "app/views/index.html.erb" }

        it "returns true" do
          expect(subject).to be true
        end
      end

      context "when file matches only but is excluded" do
        let(:file_path) { "app/legacy/old.html.erb" }

        it "returns false" do
          expect(subject).to be false
        end
      end

      context "when file does not match only" do
        let(:file_path) { "lib/templates/email.html.erb" }

        it "returns false" do
          expect(subject).to be false
        end
      end
    end

    context "with only, include, and exclude patterns" do
      let(:matcher) do
        described_class.new(
          only: ["app/views/**/*"],
          includes: ["**/*.html.erb"],
          excludes: ["**/legacy/**/*"]
        )
      end

      it "only patterns override include patterns" do
        # File matches include but not only
        expect(matcher.match?("lib/templates/page.html.erb")).to be false
      end

      it "exclude patterns apply even with only patterns" do
        # File matches only but is excluded
        expect(matcher.match?("app/views/legacy/old.html.erb")).to be false
      end

      it "matches when only is satisfied and not excluded" do
        expect(matcher.match?("app/views/users/index.html.erb")).to be true
      end
    end

    context "with empty patterns" do
      let(:matcher) { described_class.new }

      it "matches any file" do
        expect(matcher.match?("app/views/index.html.erb")).to be true
        expect(matcher.match?("lib/templates/page.rb")).to be true
      end
    end

    context "with glob patterns" do
      let(:matcher) { described_class.new(includes: ["**/*.{html,xml}.erb"]) }

      it "matches files with html extension" do
        expect(matcher.match?("app/views/index.html.erb")).to be true
      end

      it "matches files with xml extension" do
        expect(matcher.match?("app/views/feed.xml.erb")).to be true
      end

      it "does not match files without matching extension" do
        expect(matcher.match?("app/views/index.js.erb")).to be false
      end
    end
  end
end
