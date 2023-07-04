# frozen_string_literal: true

require "monday_ruby"
require "webmock/rspec"
require "vcr"
require "dotenv"

Dotenv.load

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

def fixture_path
  File.expand_path("fixtures", __dir__)
end

def fixture(file)
  File.new("#{fixture_path}/#{file}")
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
