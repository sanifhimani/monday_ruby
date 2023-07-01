# frozen_string_literal: true

require "uri"
require "net/http"
require "json"

require_relative "configuration"
require_relative "request"
require_relative "response"
require_relative "resources"
require_relative "util"

module Monday
  # Client executes requests against the monday.com's API and
  # allows a user to mutate and retrieve resources.
  class Client
    include Resources

    JSON_CONTENT_TYPE = "application/json"
    private_constant :JSON_CONTENT_TYPE

    attr_reader :config

    def initialize(config_args = {})
      @config = config_options(config_args)
    end

    private

    def config_options(config_args)
      return Monday.config if config_args.empty?

      Monday::Configuration.new(**config_args)
    end

    def uri
      URI(@config.host)
    end

    def request_headers
      {
        "Content-Type": "application/json",
        Authorization: @config.token
      }
    end

    def make_request(body)
      response = Monday::Request.post(uri, body, request_headers)
      Monday::Response.new(response)
    end
  end
end
