# frozen_string_literal: true

# Require files in ASCII order
require_relative "config/defaults"
require_relative "config/version"

module Herb
  module Config
    class Error < StandardError; end
  end
end
