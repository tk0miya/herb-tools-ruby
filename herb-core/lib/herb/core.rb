# frozen_string_literal: true

require "pathname"

# NOTE: require_relative should be in ASCII order
require_relative "core/file_discovery"
require_relative "core/pattern_matcher"
require_relative "core/version"

module Herb
  module Core
    class Error < StandardError; end
  end
end
