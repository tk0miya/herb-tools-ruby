# frozen_string_literal: true

module Herb
  module Format
    module Errors
      class Error < StandardError; end

      class ConfigurationError < Error; end
      class ParseError < Error; end
      class RewriterError < Error; end
      class FileNotFoundError < Error; end
    end
  end
end
