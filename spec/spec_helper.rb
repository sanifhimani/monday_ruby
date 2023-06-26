# frozen_string_literal: true

require "monday_ruby"
require "webmock/rspec"

WebMock.disable_net_connect!(allow_localhost: true)
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.color_mode = :on
  config.formatter = :documentation
  config.order = :random

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def fixture_path
  File.expand_path("fixtures", __dir__)
end

def fixture(file)
  File.new("#{fixture_path}/#{file}")
end

def monday_url
  "https://api.monday.com/v2"
end
