# frozen_string_literal: true

RSpec.describe Herb::Lint::UnnecessaryDirectiveDetector do
  describe ".detect" do
    subject { described_class.detect(directives, ignored_offenses) }

    let(:directives) do
      Herb::Lint::DirectiveParser::Directives.new(
        ignore_file: false,
        disable_comments:
      )
    end
    let(:ignored_offenses) { [] }

    let(:content_location) do
      Herb::Location.new(
        Herb::Position.new(1, 4),
        Herb::Position.new(1, 40)
      )
    end

    context "when there are no disable comments" do
      let(:disable_comments) { {} }

      it "returns no offenses" do
        expect(subject).to be_empty
      end
    end

    context "when disable all suppresses an offense" do
      let(:disable_comments) do
        {
          1 => Herb::Lint::DirectiveParser::DisableComment.new(
            match: true, rule_names: ["all"], rule_name_details: [],
            rules_string: "all", content_location:
          )
        }
      end
      let(:ignored_offenses) do
        [build(:offense, rule_name: "html-img-require-alt", start_line: 1)]
      end

      it "returns no offenses" do
        expect(subject).to be_empty
      end
    end

    context "when disable all does not suppress any offense" do
      let(:disable_comments) do
        {
          1 => Herb::Lint::DirectiveParser::DisableComment.new(
            match: true, rule_names: ["all"], rule_name_details: [],
            rules_string: "all", content_location:
          )
        }
      end

      it "reports an unnecessary directive offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("herb-disable-comment-unnecessary")
        expect(subject.first.message).to eq(
          "Unnecessary herb:disable directive (no offenses were suppressed)"
        )
        expect(subject.first.severity).to eq("warning")
      end

      it "uses content_location for the offense location" do
        expect(subject.first.location).to eq(content_location)
      end
    end

    context "when a specific rule suppresses an offense" do
      let(:disable_comments) do
        {
          1 => Herb::Lint::DirectiveParser::DisableComment.new(
            match: true,
            rule_names: ["html-img-require-alt"],
            rule_name_details: [
              Herb::Lint::DirectiveParser::DisableRuleName.new(name: "html-img-require-alt", offset: 14, length: 20)
            ],
            rules_string: "html-img-require-alt",
            content_location:
          )
        }
      end
      let(:ignored_offenses) do
        [build(:offense, rule_name: "html-img-require-alt", start_line: 1)]
      end

      it "returns no offenses" do
        expect(subject).to be_empty
      end
    end

    context "when a specific rule does not suppress any offense" do
      let(:disable_comments) do
        {
          1 => Herb::Lint::DirectiveParser::DisableComment.new(
            match: true,
            rule_names: ["html-img-require-alt"],
            rule_name_details: [
              Herb::Lint::DirectiveParser::DisableRuleName.new(name: "html-img-require-alt", offset: 14, length: 20)
            ],
            rules_string: "html-img-require-alt",
            content_location:
          )
        }
      end

      it "reports an unnecessary offense for that rule" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Unnecessary herb:disable for rule 'html-img-require-alt' (no matching offense)"
        )
      end

      it "computes location from content_location and detail offset" do
        loc = subject.first.location
        expect(loc.start.line).to eq(1)
        expect(loc.start.column).to eq(18)
        expect(loc.end.column).to eq(38)
      end
    end

    context "when one rule suppresses but another does not" do
      let(:disable_comments) do
        {
          1 => Herb::Lint::DirectiveParser::DisableComment.new(
            match: true,
            rule_names: %w[html-img-require-alt html-no-self-closing],
            rule_name_details: [
              Herb::Lint::DirectiveParser::DisableRuleName.new(name: "html-img-require-alt", offset: 14, length: 20),
              Herb::Lint::DirectiveParser::DisableRuleName.new(name: "html-no-self-closing", offset: 36, length: 20)
            ],
            rules_string: "html-img-require-alt, html-no-self-closing",
            content_location:
          )
        }
      end
      let(:ignored_offenses) do
        [build(:offense, rule_name: "html-img-require-alt", start_line: 1)]
      end

      it "reports an unnecessary offense only for the non-suppressed rule" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          "Unnecessary herb:disable for rule 'html-no-self-closing' (no matching offense)"
        )
      end
    end

    context "when comment is malformed (match=false)" do
      let(:disable_comments) do
        {
          1 => Herb::Lint::DirectiveParser::DisableComment.new(
            match: false, rule_names: [], rule_name_details: [],
            rules_string: "rule-name", content_location:
          )
        }
      end

      it "skips the comment" do
        expect(subject).to be_empty
      end
    end

    context "when multiple lines have disable comments and one is unnecessary" do
      let(:content_location_line2) do
        Herb::Location.new(
          Herb::Position.new(2, 4),
          Herb::Position.new(2, 40)
        )
      end
      let(:disable_comments) do
        {
          1 => Herb::Lint::DirectiveParser::DisableComment.new(
            match: true,
            rule_names: ["html-img-require-alt"],
            rule_name_details: [
              Herb::Lint::DirectiveParser::DisableRuleName.new(name: "html-img-require-alt", offset: 14, length: 20)
            ],
            rules_string: "html-img-require-alt",
            content_location:
          ),
          2 => Herb::Lint::DirectiveParser::DisableComment.new(
            match: true,
            rule_names: ["html-no-self-closing"],
            rule_name_details: [
              Herb::Lint::DirectiveParser::DisableRuleName.new(name: "html-no-self-closing", offset: 14, length: 20)
            ],
            rules_string: "html-no-self-closing",
            content_location: content_location_line2
          )
        }
      end
      let(:ignored_offenses) do
        [build(:offense, rule_name: "html-img-require-alt", start_line: 1)]
      end

      it "reports an unnecessary offense only for the line without suppression" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("html-no-self-closing")
        expect(subject.first.location.start.line).to eq(2)
      end
    end

    context "when comment has empty rule_names" do
      let(:disable_comments) do
        {
          1 => Herb::Lint::DirectiveParser::DisableComment.new(
            match: true, rule_names: [], rule_name_details: [],
            rules_string: nil, content_location:
          )
        }
      end

      it "skips the comment" do
        expect(subject).to be_empty
      end
    end
  end
end
