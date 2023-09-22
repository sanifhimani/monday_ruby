# frozen_string_literal: true

module Monday
  # Monday::Error is the base error class from which other
  # specific error classes are derived.
  class Error < StandardError
    attr_reader :response, :message, :code

    def initialize(message: nil, response: nil, code: nil)
      @response = response
      @message = error_message(message)
      @code = error_code(code)

      super(@message)
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

      response.body["error_message"].nil? ? response.body["errors"].to_s : response.body["error_message"].to_s
    end
  end

  # InternalServerError is raised when the request returns
  # a 500 status code.
  class InternalServerError < Error
  end

  # AuthorizationError is raised when the request returns
  # a 401 or 403 status code.
  #
  # It is also raised when the body returns the following error_code:
  #   UserUnauthorizedException
  class AuthorizationError < Error
  end

  # RateLimitError is raised when the request returns
  # a 429 status code.
  class RateLimitError < Error
  end

  # ResourceNotFoundError is raised when the request returns
  # a 404 status code.
  #
  # It is also raised when the body returns the following error_code:
  #   ResourceNotFoundException
  class ResourceNotFoundError < Error
  end

  # ResourceNotFoundError is raised when the request returns
  # a 400 status code.
  #
  # It is also raised when the body returns the following error_codes:
  #   InvalidUserIdException, InvalidVersionException, InvalidColumnIdException
  #   InvalidItemIdException, InvalidBoardIdException, InvalidArgumentException
  #   CreateBoardException, ItemsLimitationException, ItemNameTooLongException
  #   ColumnValueException, CorrectedValueException, InvalidGroupIdException
  class InvalidRequestError < Error
  end

  # ComplexityError is raised when the body returns the following error_code:
  #   ComplexityException
  class ComplexityError < Error
  end
end
