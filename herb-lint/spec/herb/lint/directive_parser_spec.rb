# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Herb::Lint::DirectiveParser do
  describe ".parse" do
    subject { described_class.parse(document, source) }

    let(:document) { Herb.parse(source) }

    context "when template has no directives" do
      let(:source) { "<div>Hello</div>" }

      it "returns empty directives" do
        expect(subject.ignore_file?).to be false
        expect(subject.disable_comments).to be_empty
      end
    end

    context "when template has herb:linter ignore" do
      let(:source) { "<%# herb:linter ignore %>\n<div>Hello</div>" }

      it "sets ignore_file to true" do
        expect(subject.ignore_file?).to be true
      end
    end

    context "when template has single rule disable" do
      let(:source) { '<img src="test.png"> <%# herb:disable html-img-require-alt %>' }

      it "stores the disable comment for the line" do
        expect(subject.disable_comments.size).to eq(1)
        expect(subject.disable_comments[1]).to be_a(described_class::DisableComment)
        expect(subject.disable_comments[1].match).to be true
        expect(subject.disable_comments[1].rule_names).to eq(["html-img-require-alt"])
      end
    end

    context "when template has multiple rules disable (comma-separated)" do
      let(:source) { "<%# herb:disable rule1, rule2, rule3 %>" }

      it "parses all rule names" do
        comment = subject.disable_comments[1]
        expect(comment.rule_names).to eq(%w[rule1 rule2 rule3])
      end
    end

    context "when template has disable all" do
      let(:source) { "<%# herb:disable all %>" }

      it "parses all as a rule name" do
        comment = subject.disable_comments[1]
        expect(comment.match).to be true
        expect(comment.rule_names).to eq(["all"])
      end
    end

    context "when template has non-directive comments" do
      let(:source) { "<%# this is a normal comment %>\n<div></div>" }

      it "does not store them as disable comments" do
        expect(subject.disable_comments).to be_empty
        expect(subject.ignore_file?).to be false
      end
    end

    context "when template has malformed herb:disable comment" do
      let(:source) { "<%# herb:disablerule-name %>" }

      it "stores the comment with match=false" do
        comment = subject.disable_comments[1]
        expect(comment).not_to be_nil
        expect(comment.match).to be false
      end
    end

    context "when template has directives on multiple lines" do
      let(:source) do
        <<~ERB
          <img src="a.png"> <%# herb:disable html-img-require-alt %>
          <img src="b.png">
          <div> <%# herb:disable html-no-self-closing %>
        ERB
      end

      it "stores disable comments keyed by line number" do
        expect(subject.disable_comments.keys).to contain_exactly(1, 3)
        expect(subject.disable_comments[1].rule_names).to eq(["html-img-require-alt"])
        expect(subject.disable_comments[3].rule_names).to eq(["html-no-self-closing"])
      end
    end
  end

  describe ".parse_disable_comment_content" do
    subject { described_class.parse_disable_comment_content(content) }

    context "when content is not a herb:disable comment" do
      let(:content) { " just a comment " }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when content is a single rule disable" do
      let(:content) { " herb:disable html-img-require-alt " }

      it "parses the rule name" do
        expect(subject.match).to be true
        expect(subject.rule_names).to eq(["html-img-require-alt"])
        expect(subject.rules_string).to eq("html-img-require-alt")
      end
    end

    context "when content has multiple comma-separated rules" do
      let(:content) { " herb:disable rule1, rule2 " }

      it "parses all rule names" do
        expect(subject.match).to be true
        expect(subject.rule_names).to eq(%w[rule1 rule2])
        expect(subject.rules_string).to eq("rule1, rule2")
      end
    end

    context "when content is disable all" do
      let(:content) { " herb:disable all " }

      it "parses all as the rule name" do
        expect(subject.match).to be true
        expect(subject.rule_names).to eq(["all"])
      end
    end

    context "when content is herb:disable with no rules" do
      let(:content) { " herb:disable " }

      it "returns match=true with empty rule_names" do
        expect(subject.match).to be true
        expect(subject.rule_names).to be_empty
        expect(subject.rules_string).to be_nil
      end
    end

    context "when content is malformed (no space after prefix)" do
      let(:content) { " herb:disablerule-name " }

      it "returns match=false" do
        expect(subject.match).to be false
        expect(subject.rule_names).to be_empty
        expect(subject.rules_string).to eq("rule-name")
      end
    end

    context "when content has correct rule_name_details" do
      let(:content) { " herb:disable rule1, rule2 " }

      it "includes position info for each rule name" do
        expect(subject.rule_name_details.size).to eq(2)

        first = subject.rule_name_details[0]
        expect(first.name).to eq("rule1")
        expect(first.length).to eq(5)
        expect(content[first.offset, first.length]).to eq("rule1")

        second = subject.rule_name_details[1]
        expect(second.name).to eq("rule2")
        expect(second.length).to eq(5)
        expect(content[second.offset, second.length]).to eq("rule2")
      end
    end
  end

  describe ".disable_comment_content?" do
    it "returns true for herb:disable content" do
      expect(described_class.disable_comment_content?(" herb:disable rule1 ")).to be true
    end

    it "returns true for herb:disable with no rules" do
      expect(described_class.disable_comment_content?(" herb:disable ")).to be true
    end

    it "returns false for non-directive content" do
      expect(described_class.disable_comment_content?(" just a comment ")).to be false
    end

    it "returns false for herb:linter ignore content" do
      expect(described_class.disable_comment_content?(" herb:linter ignore ")).to be false
    end
  end

  describe "Directives#disabled_at?" do
    subject { described_class.parse(document, source) }

    let(:document) { Herb.parse(source) }

    context "when rule is disabled on the line" do
      let(:source) { '<img src="test.png"> <%# herb:disable html-img-require-alt %>' }

      it "returns true for the matching rule" do
        expect(subject.disabled_at?(1, "html-img-require-alt")).to be true
      end

      it "returns false for a different rule" do
        expect(subject.disabled_at?(1, "other-rule")).to be false
      end
    end

    context "when all rules are disabled on the line" do
      let(:source) { '<img src="test.png"> <%# herb:disable all %>' }

      it "returns true for any rule name" do
        expect(subject.disabled_at?(1, "html-img-require-alt")).to be true
        expect(subject.disabled_at?(1, "any-other-rule")).to be true
      end
    end

    context "when line has no disable comment" do
      let(:source) { "<img src=\"test.png\">\n<div></div>" }

      it "returns false" do
        expect(subject.disabled_at?(1, "html-img-require-alt")).to be false
        expect(subject.disabled_at?(2, "html-img-require-alt")).to be false
      end
    end

    context "when the disable comment is malformed" do
      let(:source) { "<%# herb:disablerule-name %>" }

      it "returns false" do
        expect(subject.disabled_at?(1, "rule-name")).to be false
      end
    end
  end
end
