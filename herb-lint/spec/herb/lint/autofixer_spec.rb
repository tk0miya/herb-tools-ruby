# frozen_string_literal: true

RSpec.describe Herb::Lint::Autofixer do
  let(:safe_rule) { TestRules::SafeFixableRule.new(matcher: build(:pattern_matcher)) }
  let(:unsafe_rule) { TestRules::UnsafeFixableRule.new(matcher: build(:pattern_matcher)) }
  let(:failing_rule) { TestRules::FailingFixableRule.new(matcher: build(:pattern_matcher)) }
  let(:safe_source_rule) { TestRules::SafeSourceRule.new(matcher: build(:pattern_matcher)) }
  let(:failing_source_rule) { TestRules::FailingSourceRule.new(matcher: build(:pattern_matcher)) }

  let(:source) { "<div>hello</div>" }
  let(:fixed_source) { "<div></div>" }
  let(:parse_result) { Herb.parse(source, track_whitespace: true) }
  let(:element) { parse_result.value.children.first }

  describe "#autofixable?" do
    subject { autofixer.autofixable?(unsafe:) }

    context "when unsafe: false" do
      let(:unsafe) { false }

      context "when parse_result is nil" do
        let(:autofixer) { described_class.new(nil, [build(:offense)], source:) }

        it { is_expected.to be false }
      end

      context "when there are no offenses" do
        let(:autofixer) { described_class.new(parse_result, [], source:) }

        it { is_expected.to be false }
      end

      context "when offenses have no autofix_context" do
        let(:autofixer) { described_class.new(parse_result, [build(:offense)], source:) }

        it { is_expected.to be false }
      end

      context "when there is at least one safe autofixable offense" do
        let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: safe_rule) }
        let(:autofixer) { described_class.new(parse_result, [build(:offense, autofix_context:)], source:) }

        it { is_expected.to be true }
      end

      context "when there is at least one unsafe autofixable offense" do
        let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: unsafe_rule) }
        let(:autofixer) { described_class.new(parse_result, [build(:offense, autofix_context:)], source:) }

        it { is_expected.to be false }
      end

      context "with mixed autofixable and non-autofixable offenses" do
        let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: safe_rule) }
        let(:autofixer) do
          described_class.new(parse_result, [
                                build(:offense, autofix_context:),
                                build(:offense)
                              ], source:)
        end

        it { is_expected.to be true }
      end
    end

    context "when unsafe: true" do
      let(:unsafe) { true }

      context "when there is at least one safe autofixable offense" do
        let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: safe_rule) }
        let(:autofixer) { described_class.new(parse_result, [build(:offense, autofix_context:)], source:) }

        it { is_expected.to be true }
      end

      context "when there is at least one unsafe autofixable offense" do
        let(:autofix_context) { Herb::Lint::AutofixContext.new(node: element, rule: unsafe_rule) }
        let(:autofixer) { described_class.new(parse_result, [build(:offense, autofix_context:)], source:) }

        it { is_expected.to be true }
      end
    end
  end

  describe "#apply" do
    context "when there are no offenses" do
      subject { described_class.new(parse_result, [], source:).apply }

      it "returns an AutoFixResult with the original source" do
        expect(subject.source).to eq(source)
        expect(subject.fixed).to be_empty
        expect(subject.unfixed).to be_empty
      end
    end

    context "when offenses are not autofixable (no autofix_context)" do
      subject { described_class.new(parse_result, unfixed_offenses, source:).apply }

      let(:unfixed_offenses) { [build(:offense)] }

      it "returns all offenses as unfixed and keeps the original source" do
        expect(subject.source).to eq(source)
        expect(subject.fixed).to be_empty
        expect(subject.unfixed_count).to eq(1)
      end
    end

    context "when a safe autofix is applied successfully" do
      subject { described_class.new(parse_result, unfixed_offenses, source:).apply }

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
      subject { described_class.new(parse_result, unfixed_offenses, source:, unsafe: true).apply }

      let(:source) { "<span>hello</span>" }
      let(:fixed_source) { "<span></span>" }
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
      subject { described_class.new(parse_result, unfixed_offenses, source:).apply }

      let(:source) { "<span>hello</span>" }
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
      subject { described_class.new(parse_result, unfixed_offenses, source:).apply }

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
      subject { described_class.new(parse_result, unfixed_offenses, source:).apply }

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
      subject { described_class.new(parse_result, unfixed_offenses, source:, unsafe: true).apply }

      let(:source) { "<div>content</div><span>content</span>" }
      let(:fixed_source) { "<div></div><span></span>" }
      let(:div_element) { parse_result.value.children[0] }
      let(:span_element) { parse_result.value.children[1] }
      let(:safe_context) { Herb::Lint::AutofixContext.new(node: div_element, rule: safe_rule) }
      let(:unsafe_context) { Herb::Lint::AutofixContext.new(node: span_element, rule: unsafe_rule) }
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

    context "when a source rule autofix is applied successfully" do
      subject { described_class.new(parse_result, unfixed_offenses, source:).apply }

      let(:source) { "<div>hello</div>  " }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:fixed_source) { "<div>hello</div>" }
      let(:source_context) { Herb::Lint::AutofixContext.new(rule: safe_source_rule, start_offset: 16, end_offset: 18) }
      let(:unfixed_offenses) do
        [build(:offense, autofix_context: source_context)]
      end

      it "marks the offense as fixed and modifies the source" do
        expect(subject.fixed_count).to eq(1)
        expect(subject.unfixed).to be_empty
        expect(subject.source).to eq(fixed_source)
      end
    end

    context "when a source rule autofix returns nil (fix failed)" do
      subject { described_class.new(parse_result, unfixed_offenses, source:).apply }

      let(:source) { "<div>hello</div>  " }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      let(:source_context) { Herb::Lint::AutofixContext.new(rule: failing_source_rule, start_offset: 16, end_offset: 18) }
      let(:unfixed_offenses) do
        [build(:offense, autofix_context: source_context)]
      end

      it "marks the offense as unfixed and keeps the original source" do
        expect(subject.source).to eq(source)
        expect(subject.fixed).to be_empty
        expect(subject.unfixed_count).to eq(1)
      end
    end

    context "with mixed AST and source offenses" do
      subject { described_class.new(parse_result, unfixed_offenses, source:).apply }

      let(:source) { "<div>content</div>  " }
      let(:parse_result) { Herb.parse(source, track_whitespace: true) }
      # First AST fix clears div body: "<div></div>"
      # IdentityPrinter preserves trailing whitespace, but source fix fails (offsets out of bounds after AST changes)
      let(:fixed_source) { "<div></div>  " }
      let(:div_element) { parse_result.value.children.first }
      let(:ast_context) { Herb::Lint::AutofixContext.new(node: div_element, rule: safe_rule) }
      let(:source_context) { Herb::Lint::AutofixContext.new(rule: safe_source_rule, start_offset: 18, end_offset: 20) }
      let(:unfixed_offenses) do
        [
          build(:offense, autofix_context: ast_context),
          build(:offense, autofix_context: source_context)
        ]
      end

      it "applies AST fixes first, then source fixes fail when offsets are invalidated" do
        # AST fix succeeds, source fix fails because offsets are out of bounds after AST serialization
        expect(subject.fixed_count).to eq(1)
        expect(subject.unfixed_count).to eq(1)
        expect(subject.source).to eq(fixed_source)
      end
    end
  end
end
