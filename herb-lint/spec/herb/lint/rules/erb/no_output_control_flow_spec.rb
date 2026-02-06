# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::NoOutputControlFlow do
  describe ".rule_name" do
    it "returns 'erb-no-output-control-flow'" do
      expect(described_class.rule_name).to eq("erb-no-output-control-flow")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow control flow statements in ERB output tags")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when if statement uses silent tag" do
      let(:source) { "<% if condition %><% end %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when if statement uses output tag" do
      let(:source) { "<%= if condition %><% end %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-output-control-flow")
        expect(subject.first.message).to eq(
          "Control flow statements like `if` should not be used with output tags. Use `<% if ... %>` instead."
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when unless statement uses output tag" do
      let(:source) { "<%= unless condition %><% end %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-output-control-flow")
        expect(subject.first.message).to eq(
          "Control flow statements like `unless` should not be used with output tags. Use `<% unless ... %>` instead."
        )
      end
    end

    context "when else statement uses output tag" do
      let(:source) { "<% if condition %><p>yes</p><%= else %><p>no</p><% end %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-output-control-flow")
        expect(subject.first.message).to eq(
          "Control flow statements like `else` should not be used with output tags. Use `<% else ... %>` instead."
        )
      end
    end

    context "when end statement uses output tag" do
      let(:source) { "<% if condition %><p>content</p><%= end %>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-no-output-control-flow")
        expect(subject.first.message).to eq(
          "Control flow statements like `end` should not be used with output tags. Use `<% end ... %>` instead."
        )
      end
    end

    context "when multiple control flow statements use output tags" do
      let(:source) do
        <<~ERB
          <%= if condition %>
            <p>text</p>
          <%= end %>
        ERB
      end

      it "reports an offense for each control flow statement" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:line)).to contain_exactly(1, 3)
      end
    end

    context "when regular output tag is used" do
      let(:source) { "<%= value %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when output tag contains method call" do
      let(:source) { "<%= user.name %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when control flow is in HTML context" do
      let(:source) do
        <<~ERB
          <div>
            <%= if active? %>
              <p>Active</p>
            <% end %>
          </div>
        ERB
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "when nested control flow has mixed tags" do
      let(:source) do
        <<~ERB
          <% if outer %>
            <%= if inner %>
              <p>text</p>
            <% end %>
          <% end %>
        ERB
      end

      it "reports offense only for the output tag" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end
  end
end
