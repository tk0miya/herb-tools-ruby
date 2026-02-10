# frozen_string_literal: true

RSpec.describe Herb::Lint::Autofixer do
  # Stub rule: clears the element body (safe autofix)
  let(:safe_rule) do
    Class.new(Herb::Lint::Rules::VisitorRule) do
      def self.rule_name = "test/safe-rule"
      def self.description = "Safe test rule"
      def self.default_severity = "warning"
      def self.safe_autofixable? = true
      def self.unsafe_autofixable? = false

      def autofix(node, _parse_result)
        node.body.clear
        true
      end
    end.new(matcher: build(:pattern_matcher))
  end

  # Stub rule: clears the element body (unsafe autofix)
  let(:unsafe_rule) do
    Class.new(Herb::Lint::Rules::VisitorRule) do
      def self.rule_name = "test/unsafe-rule"
      def self.description = "Unsafe test rule"
      def self.default_severity = "warning"
      def self.safe_autofixable? = false
      def self.unsafe_autofixable? = true

      def autofix(node, _parse_result)
        node.body.clear
        true
      end
    end.new(matcher: build(:pattern_matcher))
  end

  # Stub rule whose autofix always fails
  let(:failing_rule) do
    Class.new(Herb::Lint::Rules::VisitorRule) do
      def self.rule_name = "test/failing-rule"
      def self.description = "Failing test rule"
      def self.default_severity = "warning"
      def self.safe_autofixable? = true
      def self.unsafe_autofixable? = false

      def autofix(_node, _parse_result)
        false
      end
    end.new(matcher: build(:pattern_matcher))
  end

  let(:source) { "<div>hello</div>" }
  let(:fixed_source) { "<div></div>" }
  let(:parse_result) { Herb.parse(source, track_whitespace: true) }
  let(:element) { parse_result.value.children.first }

  describe "#autofixable?" do
    subject { autofixer.autofixable?(unsafe:) }

    context "when unsafe: false" do
      let(:unsafe) { false }

      context "when parse_result is nil" do
        let(:autofixer) { described_class.new(nil, [build(:offense)]) }

        it { is_expected.to be false }
      end

      context "when there are no offenses" do
        let(:autofixer) { described_class.new(parse_result, []) }

        it { is_expected.to be false }
      end

      context "when offenses have no autofix_context" do
        let(:autofixer) { described_class.new(parse_result, [build(:offense)]) }

        it { is_expected.to be false }
      end

      context "when there is at least one safe autofixable offense" do
        let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: safe_rule) }
        let(:autofixer) { described_class.new(parse_result, [build(:offense, autofix_context:)]) }

        it { is_expected.to be true }
      end

      context "when there is at least one unsafe autofixable offense" do
        let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: unsafe_rule) }
        let(:autofixer) { described_class.new(parse_result, [build(:offense, autofix_context:)]) }

        it { is_expected.to be false }
      end

      context "with mixed autofixable and non-autofixable offenses" do
        let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: safe_rule) }
        let(:autofixer) do
          described_class.new(parse_result, [
                                build(:offense, autofix_context:),
                                build(:offense)
                              ])
        end

        it { is_expected.to be true }
      end
    end

    context "when unsafe: true" do
      let(:unsafe) { true }

      context "when there is at least one safe autofixable offense" do
        let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: safe_rule) }
        let(:autofixer) { described_class.new(parse_result, [build(:offense, autofix_context:)]) }

        it { is_expected.to be true }
      end

      context "when there is at least one unsafe autofixable offense" do
        let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: unsafe_rule) }
        let(:autofixer) { described_class.new(parse_result, [build(:offense, autofix_context:)]) }

        it { is_expected.to be true }
      end
    end
  end

  describe "#apply" do
    context "when there are no offenses" do
      subject { described_class.new(parse_result, []).apply }

      it "returns an AutoFixResult with the original source" do
        expect(subject.source).to eq(source)
        expect(subject.fixed).to be_empty
        expect(subject.unfixed).to be_empty
      end
    end

    context "when offenses are not autofixable (no autofix_context)" do
      subject { described_class.new(parse_result, unfixed_offenses).apply }

      let(:unfixed_offenses) { [build(:offense)] }

      it "returns all offenses as unfixed and keeps the original source" do
        expect(subject.source).to eq(source)
        expect(subject.fixed).to be_empty
        expect(subject.unfixed_count).to eq(1)
      end
    end

    context "when a safe autofix is applied successfully" do
      subject { described_class.new(parse_result, unfixed_offenses).apply }

      let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: safe_rule) }
      let(:unfixed_offenses) do
        [build(:offense, autofix_context:)]
      end

      it "marks the offense as fixed and modifies the source" do
        expect(subject.fixed_count).to eq(1)
        expect(subject.unfixed).to be_empty
        expect(subject.source).to eq(fixed_source)
      end
    end

    context "when an unsafe autofix is applied with unsafe: true" do
      subject { described_class.new(parse_result, unfixed_offenses, unsafe: true).apply }

      let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: unsafe_rule) }
      let(:unfixed_offenses) do
        [build(:offense, autofix_context:)]
      end

      it "marks the offense as fixed and modifies the source" do
        expect(subject.fixed_count).to eq(1)
        expect(subject.unfixed).to be_empty
        expect(subject.source).to eq(fixed_source)
      end
    end

    context "when an unsafe autofix is skipped without unsafe flag" do
      subject { described_class.new(parse_result, unfixed_offenses).apply }

      let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: unsafe_rule) }
      let(:unfixed_offenses) do
        [build(:offense, autofix_context:)]
      end

      it "marks the offense as unfixed and keeps the original source" do
        expect(subject.source).to eq(source)
        expect(subject.fixed).to be_empty
        expect(subject.unfixed_count).to eq(1)
      end
    end

    context "when autofix returns false (fix failed)" do
      subject { described_class.new(parse_result, unfixed_offenses).apply }

      let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: failing_rule) }
      let(:unfixed_offenses) do
        [build(:offense, autofix_context:)]
      end

      it "marks the offense as unfixed and keeps the original source" do
        expect(subject.source).to eq(source)
        expect(subject.fixed).to be_empty
        expect(subject.unfixed_count).to eq(1)
      end
    end

    context "with a mix of autofixable and non-autofixable offenses" do
      subject { described_class.new(parse_result, unfixed_offenses).apply }

      let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: safe_rule) }
      let(:unfixed_offenses) do
        [
          build(:offense, autofix_context:),
          build(:offense)
        ]
      end

      it "fixes the autofixable offense and keeps the non-autofixable one as unfixed" do
        expect(subject.fixed_count).to eq(1)
        expect(subject.unfixed_count).to eq(1)
        expect(subject.source).to eq(fixed_source)
      end
    end

    context "with unsafe: true and both safe and unsafe offenses" do
      subject { described_class.new(parse_result, unfixed_offenses, unsafe: true).apply }

      let(:safe_context) { Herb::Lint::AutofixContext.new(node: element, rule: safe_rule) }
      let(:unsafe_context) { Herb::Lint::AutofixContext.new(node: element, rule: unsafe_rule) }
      let(:unfixed_offenses) do
        [
          build(:offense, autofix_context: safe_context),
          build(:offense, autofix_context: unsafe_context)
        ]
      end

      it "fixes both safe and unsafe offenses" do
        expect(subject.fixed_count).to eq(2)
        expect(subject.unfixed).to be_empty
        expect(subject.source).to eq(fixed_source)
      end
    end
  end
end
