# frozen_string_literal: true

module Monday
  # Encapsulates the response that comes back from
  # the Monday.com API.
  #
  # Returns status code, parsed body and headers.
  class Response
    attr_reader :status, :body, :headers

    def initialize(response)
      @response = response
      @status = response.code.to_i
      @body = parse_body
      @headers = parse_headers
    end

    # Helper to determine if the response was successful.
    # Monday.com API returns 200 status code when there are formatting errors.
    def success?
      (200..299).cover?(status) && !errors?
    end

    private

    attr_reader :response

    def errors?
      parse_body.key?("errors") || parse_body.key?("error_message")
    end

    def parse_body
      JSON.parse(response.body)
    end

    def parse_headers
      response.each_header.to_h
    end
  end
end
