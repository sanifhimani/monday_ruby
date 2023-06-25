# frozen_string_literal: true

require "uri"
require "net/http"
require "json"

require_relative "configuration"
require_relative "request"
require_relative "response"
require_relative "resource"
require_relative "util"

module Monday
  class Client
    include Resource

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

    private

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
