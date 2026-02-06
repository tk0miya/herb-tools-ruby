# frozen_string_literal: true

RSpec.describe Herb::Lint::Rules::StrictLocalsValidator do
  describe ".locals_declaration?" do
    subject { described_class.locals_declaration?(comment) }

    context "with valid strict locals syntax" do
      let(:comment) { "locals: (name:)" }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "with locals declaration missing colon" do
      let(:comment) { "locals(name:)" }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "with singular local" do
      let(:comment) { "local: (name:)" }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "with locals missing space after colon" do
      let(:comment) { "locals:(name:)" }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "with empty locals declaration" do
      let(:comment) { "locals: ()" }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "with unrelated comment" do
      let(:comment) { "TODO: fix this" }

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "with comment containing locals word but no syntax" do
      let(:comment) { "locals are nice" }

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "with empty string" do
      let(:comment) { "" }

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "with leading whitespace" do
      let(:comment) { "  locals: (name:)  " }

      it "returns true" do
        expect(subject).to be true
      end
    end
  end

  describe ".validate" do
    subject { described_class.validate(comment) }

    context "with valid syntax" do
      context "with single keyword argument" do
        let(:comment) { "locals: (name:)" }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end

      context "with keyword argument with default value" do
        let(:comment) { "locals: (name: \"default\")" }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end

      context "with multiple keyword arguments" do
        let(:comment) { "locals: (name:, age:)" }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end

      context "with multiple keyword arguments with defaults" do
        let(:comment) { "locals: (name:, age: 0, visible: true)" }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end

      context "with empty locals" do
        let(:comment) { "locals: ()" }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end

      context "with double-splat argument" do
        let(:comment) { "locals: (**attributes)" }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end

      context "with leading and trailing whitespace" do
        let(:comment) { "  locals: (name:)  " }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end
    end

    context "with format errors" do
      context "when using locals without colon" do
        let(:comment) { "locals(name:)" }

        it "returns error about missing colon" do
          expect(subject).to include("Use `locals:` with a colon")
          expect(subject).to include("not `locals()`")
        end
      end

      context "when using singular local" do
        let(:comment) { "local: (name:)" }

        it "returns error about singular form" do
          expect(subject).to include("Use `locals:` (plural)")
          expect(subject).to include("not `local:`")
        end
      end

      context "when missing colon before parentheses" do
        let(:comment) { "locals (name:)" }

        it "returns error about missing colon" do
          expect(subject).to include("Use `locals:` with a colon before the parentheses")
        end
      end

      context "when missing space after colon" do
        let(:comment) { "locals:(name:)" }

        it "returns error about missing space" do
          expect(subject).to include("Missing space after `locals:`")
        end
      end

      context "when missing parentheses" do
        let(:comment) { "locals: name:" }

        it "returns error about wrapping in parentheses" do
          expect(subject).to include("Wrap parameters in parentheses")
        end
      end

      context "when empty locals without parentheses" do
        let(:comment) { "locals:" }

        it "returns error about adding parameters" do
          expect(subject).to include("Add parameters after `locals:`")
        end
      end

      context "with unbalanced parentheses (missing closing)" do
        let(:comment) { "locals: (name:" }

        it "returns error about unbalanced parentheses" do
          expect(subject).to include("Unbalanced parentheses")
        end
      end

      context "with unbalanced parentheses (extra closing)" do
        let(:comment) { "locals: (name:))" }

        it "returns error about unbalanced parentheses" do
          expect(subject).to include("Unbalanced parentheses")
        end
      end
    end

    context "with parameter errors" do
      context "when using block argument" do
        let(:comment) { "locals: (&block)" }

        it "returns error about block argument" do
          expect(subject).to include("Block argument `&block` is not allowed")
          expect(subject).to include("keyword arguments")
        end
      end

      context "when using splat argument" do
        let(:comment) { "locals: (*args)" }

        it "returns error about splat argument" do
          expect(subject).to include("Splat argument `*args` is not allowed")
          expect(subject).to include("keyword arguments")
        end
      end

      context "when using invalid double-splat syntax" do
        let(:comment) { "locals: (**)" }

        it "returns error about double-splat format" do
          expect(subject).to include("Invalid double-splat syntax")
          expect(subject).to include("`**name` format")
        end
      end

      context "when using positional argument" do
        let(:comment) { "locals: (name)" }

        it "returns error about positional argument" do
          expect(subject).to include("Positional argument `name` is not allowed")
          expect(subject).to include("keyword argument format: `name:`")
        end
      end

      context "when using invalid parameter format" do
        let(:comment) { "locals: (@name)" }

        it "returns error about invalid parameter" do
          expect(subject).to include("Invalid parameter `@name`")
          expect(subject).to include("keyword argument format")
        end
      end

      context "with leading comma" do
        let(:comment) { "locals: (,name:)" }

        it "returns error about unexpected comma" do
          expect(subject).to include("Unexpected comma")
        end
      end

      context "with trailing comma" do
        let(:comment) { "locals: (name:,)" }

        it "returns error about unexpected comma" do
          expect(subject).to include("Unexpected comma")
        end
      end

      context "with double comma" do
        let(:comment) { "locals: (name:,,age:)" }

        it "returns error about unexpected comma" do
          expect(subject).to include("Unexpected comma")
        end
      end
    end

    context "with complex valid cases" do
      context "with keyword arguments and nested default values" do
        let(:comment) { "locals: (options: { a: 1 })" }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end

      context "with keyword arguments and array default values" do
        let(:comment) { "locals: (items: [1, 2, 3])" }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end

      context "with double-splat and keyword arguments" do
        let(:comment) { "locals: (name:, **rest)" }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end
    end
  end
end
