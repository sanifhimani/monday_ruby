# frozen_string_literal: true

require "coveralls"
require "dotenv"
require "monday_ruby"
require "simplecov"
require "vcr"
require "webmock/rspec"

Dotenv.load
SimpleCov.start

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

WebMock.disable_net_connect!(allow_localhost: true)
RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.color_mode = :on
  config.formatter = :documentation
  config.order = :random
  config.warnings = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

VCR.configure do |config|
  config.hook_into :webmock
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.ignore_localhost = true
  config.default_cassette_options = { record: :none }

  config.filter_sensitive_data("<TOKEN>") { ENV.fetch("token", nil) }
  config.configure_rspec_metadata!
end

def invalid_client
  Monday::Client.new(
    token: "invalid_token"
  )
end

def valid_client
  Monday::Client.new(
    token: ENV.fetch("token", nil)
  )
end

def monday_url
  "https://api.monday.com/v2"
end
