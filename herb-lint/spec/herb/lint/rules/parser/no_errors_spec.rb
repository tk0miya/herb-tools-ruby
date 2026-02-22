# frozen_string_literal: true

require_relative "../../../../spec_helper"

# NOTE: The parser/no-errors rule is not implemented as a standard rule class.
# It is integrated at the Linter level (lib/herb/lint/linter.rb).
# Tests are written using the Linter interface.
RSpec.describe "parser/no-errors rule" do # rubocop:disable RSpec/DescribeClass
  let(:linter) { Herb::Lint::Linter.new(config, rule_registry:) }
  let(:config) { Herb::Config::LinterConfig.new({}) }
  let(:rule_registry) { Herb::Lint::RuleRegistry.new(builtins: false, rules: [], config:) }

  describe "rule metadata" do
    it "uses 'parser-no-errors' as rule name" do
      result = linter.lint(file_path: "test.html.erb", source: "<%= 1 + %>")
      expect(result.unfixed_offenses.first.rule_name).to eq("parser-no-errors")
    end

    it "uses 'error' as severity" do
      result = linter.lint(file_path: "test.html.erb", source: "<%= 1 + %>")
      expect(result.unfixed_offenses.first.severity).to eq("error")
    end
  end

  describe "linting" do
    subject { linter.lint(file_path: "test.html.erb", source:) }

    # Good examples from documentation
    context "with properly matched tags (documentation example)" do
      let(:source) do
        <<~HTML
          <h2>Welcome to our site</h2>
          <p>This is a paragraph with proper structure.</p>

          <div class="container">
            <img src="image.jpg" alt="Description">
          </div>
        HTML
      end

      it "does not report an offense" do
        expect(subject.unfixed_offenses).to be_empty
      end
    end

    context "with valid ERB template (documentation example)" do
      let(:source) do
        <<~ERB
          <h2><%= @page.title %></h2>
          <p><%= @page.description %></p>

          <% if user_signed_in? %>
            <div class="user-section">
              <%= current_user.name %>
            </div>
          <% end %>
        ERB
      end

      it "does not report an offense" do
        expect(subject.unfixed_offenses).to be_empty
      end
    end

    # Bad examples from documentation
    context "with mismatched tags (documentation example)" do
      let(:source) { "<h2>Welcome to our site</h3>" }

      it "reports an offense" do
        expect(subject.unfixed_offenses).not_to be_empty
        expect(subject.unfixed_offenses.map(&:rule_name)).to all(eq("parser-no-errors"))
        expect(subject.unfixed_offenses.map(&:severity)).to all(eq("error"))
      end
    end

    context "with unclosed element (documentation example)" do
      let(:source) do
        <<~HTML
          <div>
            <p>This paragraph is never closed
          </div>
        HTML
      end

      it "reports an offense" do
        expect(subject.unfixed_offenses).not_to be_empty
        expect(subject.unfixed_offenses.map(&:rule_name)).to all(eq("parser-no-errors"))
        expect(subject.unfixed_offenses.map(&:severity)).to all(eq("error"))
      end
    end

    context "with orphaned closing tag (documentation example)" do
      let(:source) do
        <<~HTML
          Some content
          </div>
        HTML
      end

      it "reports an offense" do
        expect(subject.unfixed_offenses).not_to be_empty
        expect(subject.unfixed_offenses.map(&:rule_name)).to all(eq("parser-no-errors"))
        expect(subject.unfixed_offenses.map(&:severity)).to all(eq("error"))
      end
    end

    context "with invalid Ruby syntax in ERB (documentation example)" do
      let(:source) { "<%= 1 + %>" }

      it "reports an offense" do
        expect(subject.unfixed_offenses).not_to be_empty
        expect(subject.unfixed_offenses.map(&:rule_name)).to all(eq("parser-no-errors"))
        expect(subject.unfixed_offenses.map(&:severity)).to all(eq("error"))
      end
    end

    context "with mismatched quotes in attribute (documentation example)" do
      let(:source) { %(<div class="container'>Content</div>) }

      it "reports an offense" do
        expect(subject.unfixed_offenses).not_to be_empty
        expect(subject.unfixed_offenses.map(&:rule_name)).to all(eq("parser-no-errors"))
        expect(subject.unfixed_offenses.map(&:severity)).to all(eq("error"))
      end
    end

    context "with void element using closing tag (documentation example)" do
      let(:source) { %(<img src="image.jpg" alt="Description"></img>) }

      it "reports an offense" do
        expect(subject.unfixed_offenses).not_to be_empty
        expect(subject.unfixed_offenses.map(&:rule_name)).to all(eq("parser-no-errors"))
        expect(subject.unfixed_offenses.map(&:severity)).to all(eq("error"))
      end
    end
  end
end
