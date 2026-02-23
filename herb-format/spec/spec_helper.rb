# frozen_string_literal: true

require "factory_bot"
require "herb/format"

FactoryBot.find_definitions

# Load shared test helpers from spec/support
Dir[File.join(__dir__, "support", "**", "*.rb")].each { require _1 }

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
