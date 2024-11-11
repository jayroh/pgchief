# frozen_string_literal: true

require "dotenv/load"

# *********************
# * Do NOT move this! *
# *********************
#
# Set DATABASE_URL to correct test db instance before requiring the app code.
# Otherwise we set the constant at Pgchief::DATABASE_URL to wrong value.
#
ENV["DATABASE_URL"] = ENV.fetch("TEST_DATABASE_URL", "postgres://localhost")

require "pgchief"
require "pry"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
