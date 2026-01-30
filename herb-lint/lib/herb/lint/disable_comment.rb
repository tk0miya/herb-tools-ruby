# frozen_string_literal: true

module Herb
  module Lint
    # Represents a parsed `<%# herb:disable ... %>` comment.
    # This is a pure data container with no parsing or filtering logic.
    DisableComment = Data.define(
      :rule_names, #: Array[String]
      :line        #: Integer
    ) do
      # Returns true if this comment disables all rules.
      def disables_all? #: bool
        rule_names.include?("all")
      end

      # Returns true if this comment disables the given rule.
      # @rbs rule_name: String
      def disables_rule?(rule_name) #: bool
        disables_all? || rule_names.include?(rule_name)
      end
    end
  end
end
