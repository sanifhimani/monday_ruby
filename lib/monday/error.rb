# frozen_string_literal: true

module Monday
  class Error < StandardError
    attr_reader :response, :message, :code

    def initialize(message: nil, response: nil, code: nil)
      @response = response
      @message = error_message(message)
      @code = error_code(code)

      super(message)
    end

    def error_data
      return {} if response&.body&.dig("error_data").nil?

      response.body["error_data"]
    end

    private

    def error_code(code)
      return code unless code.nil?

      response_error_code.nil? ? response&.status : response_error_code
    end

    def error_message(message)
      return response_error_message if message.nil?
      return message if response_error_message.nil?

      "#{message}: #{response_error_message}"
    end

    def response_error_code
      return if response.nil?

      response.body["status_code"]
    end

    def response_error_message
      return if response.nil?

      response.body["error_message"].nil? ? response.body["errors"] : response.body["error_message"]
    end
  end

  class InternalServerError < Error
  end

  class AuthorizationError < Error
  end

  class RateLimitError < Error
  end

  class ResourceNotFoundError < Error
  end

  class InvalidRequestError < Error
  end

  class ComplexityError < Error
  end
end
