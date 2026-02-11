# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Lint::Rules::SourceRule do
  let(:matcher) { build(:pattern_matcher) }
  let(:context) { build(:context, source:) }
  let(:parse_result) { Herb.parse(source, track_whitespace: true) }

  let(:test_rule_class) do
    Class.new(described_class) do
      def self.rule_name
        "test-source-rule"
      end

      def self.default_severity
        "error"
      end
    end
  end

  describe "#check" do
    context "when check_source is not implemented" do
      subject { test_rule_class.new(matcher:).check(parse_result, context) }

      let(:source) { "<div>Hello</div>" }

      it "raises NotImplementedError" do
        expect { subject }.to raise_error(NotImplementedError, /must implement #check_source/)
      end
    end

    context "when check_source is implemented" do
      subject { counting_rule.new(matcher:).check(parse_result, context) }

      let(:source) { "line 1\nline 2\nline 3" }
      let(:counting_rule) do
        Class.new(described_class) do
          def self.rule_name
            "line-counter"
          end

          def check_source(source, _context)
            line_count = source.count("\n") + 1
            return unless line_count > 2

            location = location_from_offsets(0, source.length)
            add_offense(message: "Too many lines: #{line_count}", location:)
          end
        end
      end

      it "collects offenses from check_source" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Too many lines: 3")
      end
    end

    context "when check_source adds offense with autofix" do
      subject { rule.check(parse_result, context) }

      let(:source) { "test\n\n\n\nmore" }
      let(:rule_class) do
        Class.new(described_class) do
          def self.rule_name
            "test-autofix"
          end

          def check_source(source, _context)
            return unless source.include?("\n\n\n\n")

            add_offense_with_source_autofix(
              message: "Too many newlines",
              location: location_from_offsets(4, 8),
              start_offset: 6,
              end_offset: 8
            )
          end
        end
      end
      let(:rule) { rule_class.new(matcher:) }

      it "creates offense with AutofixContext containing offsets" do
        offenses = subject
        expect(offenses.size).to eq(1)

        offense = offenses.first
        expect(offense.autofix_context).not_to be_nil
        expect(offense.autofix_context.source_rule?).to be true
        expect(offense.autofix_context.visitor_rule?).to be false
        expect(offense.autofix_context.start_offset).to eq(6)
        expect(offense.autofix_context.end_offset).to eq(8)
        expect(offense.autofix_context.rule).to eq(rule)
      end
    end

    context "when on_new_investigation is overridden" do
      let(:source) { "test content" }
      let(:stateful_rule) do
        Class.new(described_class) do
          attr_reader :investigation_count

          def self.rule_name
            "stateful-rule"
          end

          def on_new_investigation
            super
            @investigation_count = (@investigation_count || 0) + 1
          end

          def check_source(_source, _context)
            # No-op for testing
          end
        end
      end

      it "calls on_new_investigation before checking source" do
        rule = stateful_rule.new(matcher:)

        rule.check(parse_result, context)
        expect(rule.investigation_count).to eq(1)

        rule.check(parse_result, context)
        expect(rule.investigation_count).to eq(2)
      end
    end
  end

  describe "#autofix_source" do
    subject { test_rule_class.new(matcher:).autofix_source(offense, "test source") }

    let(:source) { "test" }
    let(:offense) { build(:offense) }

    it "returns nil by default" do
      expect(subject).to be_nil
    end
  end

  describe "#location_from_offsets" do
    let(:source) { "line 1\nline 2\nline 3" }
    let(:rule) do
      Class.new(described_class) do
        def check_source(_source, _context)
          # Expose location_from_offsets for testing
        end

        def test_location_from_offsets(start_offset, end_offset)
          location_from_offsets(start_offset, end_offset)
        end
      end.new(matcher:)
    end

    before do
      # Initialize the rule by running check
      rule.check(parse_result, context)
    end

    it "correctly converts character offsets to location" do
      # "line 1\n" = 7 characters (0-6)
      # Start at offset 0, end at offset 6 (before newline)
      location = rule.test_location_from_offsets(0, 6)

      expect(location.start.line).to eq(0)
      expect(location.start.column).to eq(0)
      expect(location.end.line).to eq(0)
      expect(location.end.column).to eq(6)
    end

    it "handles multi-line locations" do
      # From start of "line 1" to start of "line 3"
      # "line 1\nline 2\n" = 14 bytes
      location = rule.test_location_from_offsets(0, 14)

      expect(location.start.line).to eq(0)
      expect(location.start.column).to eq(0)
      expect(location.end.line).to eq(2)
      expect(location.end.column).to eq(0)
    end
  end

  describe "#position_from_offset" do
    let(:source) { "abc\ndef\nghi" }
    let(:rule) do
      Class.new(described_class) do
        def check_source(_source, _context)
          # Expose position_from_offset for testing
        end

        def test_position_from_offset(offset)
          position_from_offset(offset)
        end
      end.new(matcher:)
    end

    before do
      # Initialize the rule by running check
      rule.check(parse_result, context)
    end

    it "returns (0, 0) for offset 0" do
      pos = rule.test_position_from_offset(0)
      expect(pos.line).to eq(0)
      expect(pos.column).to eq(0)
    end

    it "handles positions within first line" do
      # Offset 2 = 'c' in "abc"
      pos = rule.test_position_from_offset(2)
      expect(pos.line).to eq(0)
      expect(pos.column).to eq(2)
    end

    it "handles newlines correctly" do
      # Offset 3 = newline after "abc"
      pos = rule.test_position_from_offset(3)
      expect(pos.line).to eq(0)
      expect(pos.column).to eq(3)

      # Offset 4 = 'd' in "def" (line 1, column 0)
      pos = rule.test_position_from_offset(4)
      expect(pos.line).to eq(1)
      expect(pos.column).to eq(0)
    end

    it "handles positions on subsequent lines" do
      # "abc\ndef\n" = 8 characters
      # Offset 8 = 'g' in "ghi" (line 2, column 0)
      pos = rule.test_position_from_offset(8)
      expect(pos.line).to eq(2)
      expect(pos.column).to eq(0)
    end
  end
end
