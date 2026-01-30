# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::ErbTagSpacing do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context) }

  describe ".rule_name" do
    it "returns 'erb/erb-tag-spacing'" do
      expect(described_class.rule_name).to eq("erb/erb-tag-spacing")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Consistent spacing inside ERB tags")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    context "when ERB output tag has correct spacing" do
      let(:template) { "<%= @user.name %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB statement tag has correct spacing" do
      let(:template) { "<% if @show %><% end %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB output tag has no leading space" do
      let(:template) { "<%=@user.name %>" }

      it "reports an offense for missing leading space" do
        offenses = subject.select { |o| o.message.include?("after") }
        expect(offenses.size).to eq(1)
        expect(offenses.first.rule_name).to eq("erb/erb-tag-spacing")
        expect(offenses.first.message).to eq("Expected single space after `<%=` inside ERB tag")
      end
    end

    context "when ERB output tag has no trailing space" do
      let(:template) { "<%= @user.name%>" }

      it "reports an offense for missing trailing space" do
        offenses = subject.select { |o| o.message.include?("before") }
        expect(offenses.size).to eq(1)
        expect(offenses.first.message).to eq("Expected single space before `%>` inside ERB tag")
      end
    end

    context "when ERB output tag has no spaces at all" do
      let(:template) { "<%=@user.name%>" }

      it "reports offenses for both missing leading and trailing spaces" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to include(
          "Expected single space after `<%=` inside ERB tag",
          "Expected single space before `%>` inside ERB tag"
        )
      end
    end

    context "when ERB output tag has multiple leading spaces" do
      let(:template) { "<%=  @user.name %>" }

      it "reports an offense for multiple leading spaces" do
        offenses = subject.select { |o| o.message.include?("after") }
        expect(offenses.size).to eq(1)
        expect(offenses.first.message).to eq(
          "Expected single space after `<%=` inside ERB tag, but found multiple spaces"
        )
      end
    end

    context "when ERB output tag has multiple trailing spaces" do
      let(:template) { "<%= @user.name  %>" }

      it "reports an offense for multiple trailing spaces" do
        offenses = subject.select { |o| o.message.include?("before") }
        expect(offenses.size).to eq(1)
        expect(offenses.first.message).to eq(
          "Expected single space before `%>` inside ERB tag, but found multiple spaces"
        )
      end
    end

    context "when ERB statement tag has no leading space" do
      let(:template) { "<%if @show %><% end %>" }

      it "reports an offense for missing leading space" do
        offenses = subject.select { |o| o.message.include?("after") }
        expect(offenses.size).to eq(1)
        expect(offenses.first.message).to eq("Expected single space after `<%` inside ERB tag")
      end
    end

    context "when ERB statement tag has multiple spaces" do
      let(:template) { "<%   if @show   %><% end %>" }

      it "reports offenses for multiple spaces" do
        expect(subject.size).to eq(2)
      end
    end

    context "when trim-mode output tag has correct spacing" do
      let(:template) { "<%= foo -%>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when trim-mode tag has no leading space" do
      let(:template) { "<%=foo -%>" }

      it "reports an offense for missing leading space" do
        offenses = subject.select { |o| o.message.include?("after") }
        expect(offenses.size).to eq(1)
        expect(offenses.first.message).to eq("Expected single space after `<%=` inside ERB tag")
      end
    end

    context "when trim-mode tag has no trailing space" do
      let(:template) { "<%= foo-%>" }

      it "reports an offense for missing trailing space" do
        offenses = subject.select { |o| o.message.include?("before") }
        expect(offenses.size).to eq(1)
        expect(offenses.first.message).to eq("Expected single space before `-%>` inside ERB tag")
      end
    end

    context "when trim-mode input tag has correct spacing" do
      let(:template) { "<%- trimmed %><% end %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB comment tag has correct spacing" do
      let(:template) { "<%# this is a comment %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB comment tag has no spacing" do
      let(:template) { "<%#comment%>" }

      it "reports offenses" do
        expect(subject.size).to eq(2)
      end
    end

    context "when ERB block tag has correct spacing" do
      let(:template) { "<% @items.each do |item| %><% end %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB block tag has no leading space" do
      let(:template) { "<%@items.each do |item| %><% end %>" }

      it "reports an offense" do
        offenses = subject.select { |o| o.message.include?("after") }
        expect(offenses.size).to eq(1)
      end
    end

    context "when multiple ERB tags have mixed spacing issues" do
      let(:template) { "<%=@user.name%><% if true %><% end %>" }

      it "reports offenses only for tags with spacing issues" do
        expect(subject.size).to eq(2)
      end
    end

    context "when ERB tag is inside HTML" do
      let(:template) { '<div class="<%= @class %>">Content</div>' }

      it "does not report an offense for correctly spaced ERB" do
        expect(subject).to be_empty
      end
    end

    context "when ERB yield tag has correct spacing" do
      let(:template) { "<%= yield %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB unless tag has correct spacing" do
      let(:template) { "<% unless @hidden %><% end %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ERB case/when tags have correct spacing" do
      let(:template) { "<% case @status %><% when 1 %><% end %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end
end
