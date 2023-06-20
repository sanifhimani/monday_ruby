# frozen_string_literal: true

module Monday
  module Configuration
    VALID_OPTIONS = %i[token host].freeze

    DEFAULT_TOKEN = nil
    DEFAULT_HOST = "https://api.monday.com/v2"

    attr_accessor *VALID_OPTIONS

    def self.extended(base)
      base.reset
    end

    def configure
      yield self
    end

    def options
      VALID_OPTIONS.inject({}) do |option, key|
        option.merge!(key => send(key))
      end
    end

    def reset
      self.token = DEFAULT_TOKEN
      self.host = DEFAULT_HOST
    end
  end
end
