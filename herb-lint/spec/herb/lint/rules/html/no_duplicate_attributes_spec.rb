# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoDuplicateAttributes do
  describe ".rule_name" do
    it "returns 'html-no-duplicate-attributes'" do
      expect(described_class.rule_name).to eq("html-no-duplicate-attributes")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow duplicate attributes on the same element")
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

    def duplicate_message(attr_name)
      "Duplicate attribute `#{attr_name}`. " \
        "Browsers only use the first occurrence and ignore duplicate attributes"
    end

    # Good examples from documentation
    context "with input having unique attributes (documentation example)" do
      let(:source) { '<input type="text" name="username" id="user-id" autocomplete="off">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with button having unique attributes (documentation example)" do
      let(:source) { '<button type="submit" disabled>Submit</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "with input having duplicate type attributes (documentation example)" do
      let(:source) { '<input type="text" type="password" name="username" autocomplete="off">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-duplicate-attributes")
        expect(subject.first.message).to eq(duplicate_message("type"))
        expect(subject.first.severity).to eq("error")
      end
    end

    context "with button having duplicate type attributes (documentation example)" do
      let(:source) { '<button type="submit" type="button" disabled>Submit</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-duplicate-attributes")
        expect(subject.first.message).to eq(duplicate_message("type"))
        expect(subject.first.severity).to eq("error")
      end
    end

    # Additional edge case tests
    context "when the same attribute appears three times" do
      let(:source) { '<div class="a" class="b" class="c">content</div>' }

      it "reports an offense for each duplicate" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to all(eq(duplicate_message("class")))
      end
    end

    context "when there are multiple different duplicate attributes" do
      let(:source) { '<div class="a" id="x" class="b" id="y">content</div>' }

      it "reports an offense for each duplicate" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to contain_exactly(
          duplicate_message("class"),
          duplicate_message("id")
        )
      end
    end

    context "with attributes having different cases" do
      let(:source) { '<div CLASS="foo" class="bar">content</div>' }

      it "reports an offense (case-insensitive check)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(duplicate_message("class"))
      end
    end

    context "with nested elements having separate duplicates" do
      let(:source) do
        <<~HTML
          <div class="a" class="b">
            <span class="c" class="d">text</span>
          </div>
        HTML
      end

      it "reports an offense for each element" do
        expect(subject.size).to eq(2)
      end
    end

    context "with element having no attributes" do
      let(:source) { "<div>text</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with boolean attributes not duplicated" do
      let(:source) { "<input disabled readonly>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with duplicate boolean attributes" do
      let(:source) { "<input disabled disabled>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq(duplicate_message("disabled"))
      end
    end

    def loop_will_duplicate_message(attr_name)
      "Attribute `#{attr_name}` inside loop will appear multiple times on this element. " \
        "Use a dynamic attribute name or move the attribute outside the loop"
    end

    def same_loop_iteration_message(attr_name)
      "Duplicate attribute `#{attr_name}` in same loop iteration. " \
        "Each iteration will produce an element with duplicate attributes"
    end

    def same_branch_message(attr_name)
      "Duplicate attribute `#{attr_name}` in same branch. " \
        "This branch will produce an element with duplicate attributes"
    end

    context "with .each loop" do
      context "when an attribute is inside the loop (will duplicate across iterations)" do
        let(:source) do
          <<~ERB
            <div <% items.each do |item| %> data-id="<%= item.id %>"<% end %>></div>
          ERB
        end

        it "reports a loop-will-duplicate offense" do
          expect(subject.size).to eq(1)
          expect(subject.first.message).to eq(loop_will_duplicate_message("data-id"))
        end
      end

      context "when the same attribute appears twice in the same loop iteration" do
        let(:source) do
          <<~ERB
            <div <% items.each do |item| %> class="a" class="b"<% end %>></div>
          ERB
        end

        it "reports loop-will-duplicate for the first and same-loop-iteration for the second" do
          expect(subject.size).to eq(2)
          expect(subject[0].message).to eq(loop_will_duplicate_message("class"))
          expect(subject[1].message).to eq(same_loop_iteration_message("class"))
        end
      end

      context "when a loop attribute duplicates an attribute outside the loop" do
        let(:source) do
          <<~ERB
            <div class="base" <% items.each do |item| %> class="extra"<% end %>></div>
          ERB
        end

        it "reports a duplicate-attribute offense" do
          expect(subject.size).to eq(1)
          expect(subject.first.message).to eq(duplicate_message("class"))
        end
      end
    end

    context "with for loop" do
      context "when an attribute is inside the loop (will duplicate across iterations)" do
        let(:source) do
          <<~ERB
            <div <% for item in items %> data-id="x"<% end %>></div>
          ERB
        end

        it "reports a loop-will-duplicate offense" do
          expect(subject.size).to eq(1)
          expect(subject.first.message).to eq(loop_will_duplicate_message("data-id"))
        end
      end
    end

    context "with if conditional" do
      context "when the same attribute appears in the same branch" do
        let(:source) do
          <<~ERB
            <div <% if condition %> class="a" class="b"<% end %>></div>
          ERB
        end

        it "reports a same-branch offense" do
          expect(subject.size).to eq(1)
          expect(subject.first.message).to eq(same_branch_message("class"))
        end
      end

      context "when the same attribute appears in different branches" do
        let(:source) do
          <<~ERB
            <div <% if condition %> class="a"<% else %> class="b"<% end %>></div>
          ERB
        end

        it "does not report an offense (valid conditional attribute)" do
          expect(subject).to be_empty
        end
      end

      context "when a conditional attribute duplicates an unconditional attribute" do
        let(:source) do
          <<~ERB
            <div class="base" <% if condition %> class="extra"<% end %>></div>
          ERB
        end

        it "reports a duplicate-attribute offense" do
          expect(subject.size).to eq(1)
          expect(subject.first.message).to eq(duplicate_message("class"))
        end
      end
    end

    context "with unless conditional" do
      context "when the same attribute appears in different branches" do
        let(:source) do
          <<~ERB
            <div <% unless condition %> class="a"<% else %> class="b"<% end %>></div>
          ERB
        end

        it "does not report an offense (valid conditional attribute)" do
          expect(subject).to be_empty
        end
      end
    end

    context "with nested control flow" do
      context "with loop in loop (.each inside .each)" do
        let(:source) do
          <<~ERB
            <div <% items.each do |i| %> <% i.subs.each do |s| %> class="x" <% end %> <% end %>>
          ERB
        end

        it "reports a loop-will-duplicate offense" do
          expect(subject.size).to eq(1)
          expect(subject.first.message).to eq(loop_will_duplicate_message("class"))
        end
      end

      context "with condition in loop (if inside .each)" do
        let(:source) do
          <<~ERB
            <div <% items.each do |i| %> <% if cond %> class="x" <% end %> <% end %>>
          ERB
        end

        it "reports a loop-will-duplicate offense" do
          expect(subject.size).to eq(1)
          expect(subject.first.message).to eq(loop_will_duplicate_message("class"))
        end
      end

      context "with loop in condition (.each inside if)" do
        let(:source) do
          <<~ERB
            <div <% if cond %> <% items.each do |i| %> class="x" <% end %> <% end %>>
          ERB
        end

        it "reports a loop-will-duplicate offense" do
          expect(subject.size).to eq(1)
          expect(subject.first.message).to eq(loop_will_duplicate_message("class"))
        end
      end

      context "with condition in condition (if inside if)" do
        let(:source) do
          <<~ERB
            <div <% if outer %> <% if inner %> class="x" <% end %> <% end %>>
          ERB
        end

        it "does not report an offense" do
          expect(subject).to be_empty
        end
      end

      context "with outer attribute and condition in loop conflict" do
        let(:source) do
          <<~ERB
            <div class="base" <% items.each do |i| %> <% if cond %> class="x" <% end %> <% end %>>
          ERB
        end

        it "reports a duplicate-attribute offense" do
          expect(subject.size).to eq(1)
          expect(subject.first.message).to eq(duplicate_message("class"))
        end
      end
    end
  end
end
