# frozen_string_literal: true

require_relative "configuration"

module Monday
  class Client
    JSON_CONTENT_TYPE = "application/json"
    private_constant :JSON_CONTENT_TYPE

    Monday::Configuration::CONFIGURATION_FIELDS.each do |config_key|
      define_method(config_key) do
        @config.public_send(config_key)
      end
    end

    def initialize(config_args = {})
      @config = Monday::Configuration.new(**config_args)
      yield(@config) if block_given?
    end
  end
end
