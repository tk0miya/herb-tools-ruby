# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # File path and naming utilities for lint rules
      module FileHelpers
        # Extracts the basename (filename) from a file path
        # Works with both forward slashes and backslashes
        #
        # @rbs file_path: String -- the file path
        # @rbs return: String
        def basename(file_path)
          last_slash = [file_path.rindex("/"), file_path.rindex("\\")].compact.max

          last_slash ? file_path[(last_slash + 1)..] : file_path
        end

        # Checks if a file is a Rails partial (filename starts with `_`)
        # Returns nil if file_name is nil (unknown context)
        #
        # @rbs file_name: String? -- the file name or path
        # @rbs return: bool?
        def partial_file?(file_name)
          return nil if file_name.nil? # rubocop:disable Style/ReturnNilInPredicateMethodDefinition

          basename(file_name).start_with?("_")
        end
      end
    end
  end
end
