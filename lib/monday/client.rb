# frozen_string_literal: true

require "uri"
require "net/http"
require "json"

require_relative "configuration"
require_relative "request"
require_relative "response"
require_relative "resources"
require_relative "util"
require_relative "error"

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

      Configuration.new(**config_args)
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
      response = Request.post(uri, body, request_headers)

      handle_response(Response.new(response))
    end

    def handle_response(response)
      return response if response.success?

      raise_errors(response)
    end

    def raise_errors(response)
      raise default_exception(response) unless (200..299).cover?(response.status)

      raise response_exception(response)
    end

    def response_exception(response)
      error_code = response.body["error_code"]

      return Error.new(response: response) if error_code.nil?

      exception_klass, code = Util.response_error_exceptions_mapping(error_code)
      exception_klass.new(message: error_code, response: response, code: code)
    end

    def default_exception(response)
      Util.status_code_exceptions_mapping(response.status).new(response: response)
    end
  end
end
