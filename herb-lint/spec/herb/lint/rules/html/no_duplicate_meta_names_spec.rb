# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoDuplicateMetaNames do
  describe ".rule_name" do
    it "returns 'html-no-duplicate-meta-names'" do
      expect(described_class.rule_name).to eq("html-no-duplicate-meta-names")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq(
        "Disallow duplicate meta elements with the same name or http-equiv attribute"
      )
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    # Good examples from documentation
    context "when meta names are different (good example 1)" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="description" content="Welcome to our site">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
          </head>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when same meta name is in different conditional branches (good example 2)" do
      let(:source) do
        <<~HTML
          <head>
            <% if mobile? %>
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <% else %>
              <meta name="viewport" content="width=1024">
            <% end %>
          </head>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when duplicate name attribute exists (bad example 1)" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta name="viewport" content="width=1024">
          </head>
        HTML
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-duplicate-meta-names")
        expect(subject.first.message).to eq(
          'Duplicate `<meta>` tag with `name="viewport"`. ' \
          "Meta names should be unique within the `<head>` section."
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when duplicate http-equiv attribute exists (bad example 2)" do
      let(:source) do
        <<~HTML
          <head>
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta http-equiv="X-UA-Compatible" content="chrome=1">
          </head>
        HTML
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-duplicate-meta-names")
        expect(subject.first.message).to eq(
          'Duplicate `<meta>` tag with `http-equiv="X-UA-Compatible"`. ' \
          "`http-equiv` values should be unique within the `<head>` section."
        )
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when a global meta conflicts with a conditional meta (bad example 3)" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="viewport" content="width=1024">

            <% if mobile? %>
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <% else %>
              <meta http-equiv="refresh" content="30">
            <% end %>
          </head>
        HTML
      end

      it "reports one offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          'Duplicate `<meta>` tag with `name="viewport"`. ' \
          "Meta names should be unique within the `<head>` section."
        )
      end
    end

    context "when all meta names are unique" do
      let(:source) do
        <<~HTML
          <meta name="description" content="Page description">
          <meta name="viewport" content="width=device-width">
          <meta name="author" content="John">
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when the same meta name appears three times" do
      let(:source) do
        <<~HTML
          <meta name="description" content="First">
          <meta name="description" content="Second">
          <meta name="description" content="Third">
        HTML
      end

      it "reports an offense for each duplicate" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to all(include('name="description"'))
      end
    end

    context "when meta elements have no name or http-equiv attribute" do
      let(:source) do
        <<~HTML
          <meta charset="utf-8">
          <meta property="og:title" content="My Site">
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when meta name attribute has empty value" do
      let(:source) do
        <<~HTML
          <meta name="" content="First">
          <meta name="" content="Second">
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when meta names differ only in case" do
      let(:source) do
        <<~HTML
          <meta name="Description" content="First">
          <meta name="description" content="Second">
        HTML
      end

      it "reports an offense (case-insensitive comparison)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include('name="description"')
      end
    end

    context "when non-meta elements have the same name attribute" do
      let(:source) do
        <<~HTML
          <input name="email" type="text">
          <input name="email" type="hidden">
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with a mix of meta and non-meta elements" do
      let(:source) do
        <<~HTML
          <meta name="description" content="Page">
          <input name="description" type="text">
          <meta name="viewport" content="width=device-width">
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with a single meta element" do
      let(:source) { '<meta name="description" content="Page">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with nested meta elements in head" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="description" content="First">
            <title>Page</title>
            <meta name="description" content="Second">
          </head>
        HTML
      end

      it "reports one offense on the correct line" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include('name="description"')
        expect(subject.first.line).to eq(4)
      end
    end

    context "when same meta name appears in different branches of unless" do
      let(:source) do
        <<~HTML
          <head>
            <% unless desktop? %>
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <% else %>
              <meta name="viewport" content="width=1024">
            <% end %>
          </head>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when same meta name in different branches of if/elsif/else" do
      let(:source) do
        <<~HTML
          <head>
            <% if mobile? %>
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <% elsif tablet? %>
              <meta name="viewport" content="width=768">
            <% else %>
              <meta name="viewport" content="width=1024">
            <% end %>
          </head>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when http-equiv values differ only in case" do
      let(:source) do
        <<~HTML
          <meta http-equiv="X-UA-Compatible" content="IE=edge">
          <meta http-equiv="x-ua-compatible" content="chrome=1">
        HTML
      end

      it "reports an offense (case-insensitive comparison)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("http-equiv=")
      end
    end

    context "when name and http-equiv have the same value" do
      let(:source) do
        <<~HTML
          <meta name="refresh" content="30">
          <meta http-equiv="refresh" content="30">
        HTML
      end

      it "does not report an offense (name and http-equiv are tracked separately)" do
        expect(subject).to be_empty
      end
    end

    context "when duplicate meta names appear within the same conditional branch" do
      let(:source) do
        <<~HTML
          <head>
            <% if mobile? %>
              <meta name="viewport" content="width=device-width">
              <meta name="viewport" content="width=1024">
            <% end %>
          </head>
        HTML
      end

      it "reports an offense with control flow branch context" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          'Duplicate `<meta>` tag with `name="viewport"` within the same control flow branch. ' \
          "Meta names should be unique within the `<head>` section."
        )
      end
    end

    context "when same meta name is in different case/when branches" do
      let(:source) do
        <<~HTML
          <head>
            <% case device_type %>
            <% when :mobile %>
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <% when :tablet %>
              <meta name="viewport" content="width=768">
            <% else %>
              <meta name="viewport" content="width=1024">
            <% end %>
          </head>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when same meta name appears in different when branches of case/in" do
      let(:source) do
        <<~HTML
          <head>
            <% case version %>
            <% in 1 %>
              <meta name="viewport" content="width=device-width">
            <% in 2 %>
              <meta name="viewport" content="width=1024">
            <% end %>
          </head>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # .each do is ERBBlockNode → CONDITIONAL in TS original
    context "when same meta name appears twice in the same .each do block" do
      let(:source) do
        <<~HTML
          <head>
            <% items.each do |item| %>
              <meta name="description" content="First">
              <meta name="description" content="Second">
            <% end %>
          </head>
        HTML
      end

      it "reports an offense with 'within the same control flow branch' (CONDITIONAL path)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          'Duplicate `<meta>` tag with `name="description"` within the same control flow branch. ' \
          "Meta names should be unique within the `<head>` section."
        )
      end
    end

    # for/while/until are ERBForNode/ERBWhileNode/ERBUntilNode → LOOP in TS original.
    # LOOP only checks current loop body; it does NOT check document_metas and does NOT
    # promote to document_metas on exit.
    context "when a single meta name appears inside a for loop (LOOP path)" do
      let(:source) do
        <<~HTML
          <head>
            <% for item in items %>
              <meta name="description" content="<%= item %>">
            <% end %>
          </head>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when the same meta name appears globally and inside a for loop" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="description" content="Global">
            <% for item in items %>
              <meta name="description" content="<%= item %>">
            <% end %>
          </head>
        HTML
      end

      it "does not report an offense (LOOP path does not check document_metas)" do
        expect(subject).to be_empty
      end
    end

    context "when same meta name appears twice in the same for loop body" do
      let(:source) do
        <<~HTML
          <head>
            <% for item in items %>
              <meta name="description" content="First">
              <meta name="description" content="Second">
            <% end %>
          </head>
        HTML
      end

      it "reports an offense with 'within the same loop iteration' (LOOP path)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(
          'Duplicate `<meta>` tag with `name="description"` within the same loop iteration. ' \
          "Meta names should be unique within the `<head>` section."
        )
      end
    end
  end
end
