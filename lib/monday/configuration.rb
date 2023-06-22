# frozen_string_literal: true

module Monday
  class Configuration
    DEFAULT_HOST = "https://api.monday.com/v2"
    private_constant :DEFAULT_HOST

    CONFIGURATION_FIELDS = %i[
      token
      host
    ].freeze

    attr_accessor(*CONFIGURATION_FIELDS)

    def self.configure
      new.tap do |instance|
        yield(instance) if block_given?
      end
    end

    def initialize(**config_args)
      invalid_keys = config_args.keys - CONFIGURATION_FIELDS
      raise ArgumentError, "Unknown arguments: #{invalid_keys}" unless invalid_keys.empty?

      @host = DEFAULT_HOST

      config_args.each do |key, value|
        public_send("#{key}=", value)
      end
    end
  end
end
