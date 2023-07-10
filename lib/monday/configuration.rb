# frozen_string_literal: true

module Monday
  # Encapsulates configuration for the Monday.com API.
  #
  # Configuration options:
  #
  # token: used to authenticate the requests
  # host: defaults to https://api.monday.com/v2
  class Configuration
    DEFAULT_HOST = "https://api.monday.com/v2"
    DEFAULT_TOKEN = nil
    DEFAULT_VERSION = "2023-07"

    CONFIGURATION_FIELDS = %i[
      token
      host
      version
    ].freeze

    attr_accessor(*CONFIGURATION_FIELDS)

    def initialize(**config_args)
      invalid_keys = config_args.keys - CONFIGURATION_FIELDS
      raise ArgumentError, "Unknown arguments: #{invalid_keys}" unless invalid_keys.empty?

      @host = DEFAULT_HOST
      @token = DEFAULT_TOKEN
      @version = DEFAULT_VERSION

      config_args.each do |key, value|
        public_send("#{key}=", value)
      end
    end

    def reset
      @token = DEFAULT_TOKEN
      @host = DEFAULT_HOST
      @version = DEFAULT_VERSION
    end
  end
end
