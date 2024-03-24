# frozen_string_literal: true

module Monday
  # Utility class to format arguments for Monday.com API.
  class Util
    class << self
      # Converts the arguments object into a valid string for API.
      #
      # input: { key: "multiple word value" }
      # output: "key: \"multiple word value\""
      def format_args(obj)
        obj.map do |key, value|
          "#{key}: #{formatted_args_value(value)}"
        end.join(", ")
      end

      # Converts the select values into a valid string for API.
      #
      # input: ["id", "name", { "columns": ["id"] }]
      # output: "id name columns { id }"
      def format_select(value)
        return format_hash(value) if value.is_a?(Hash)
        return format_array(value) if value.is_a?(Array)

        values
      end

      def status_code_exceptions_mapping(status_code)
        {
          "500" => InternalServerError,
          "429" => RateLimitError,
          "404" => ResourceNotFoundError,
          "403" => AuthorizationError,
          "401" => AuthorizationError,
          "400" => InvalidRequestError
        }[status_code.to_s] || Error
      end

      def response_error_exceptions_mapping(error_code)
        {
          "ComplexityException" => [ComplexityError, 429],
          "UserUnauthorizedException" => [AuthorizationError, 403],
          "ResourceNotFoundException" => [ResourceNotFoundError, 404],
          "InvalidUserIdException" => [InvalidRequestError, 400],
          "InvalidVersionException" => [InvalidRequestError, 400],
          "InvalidColumnIdException" => [InvalidRequestError, 400],
          "InvalidItemIdException" => [InvalidRequestError, 400],
          "InvalidSubitemIdException" => [InvalidRequestError, 400],
          "InvalidBoardIdException" => [InvalidRequestError, 400],
          "InvalidGroupIdException" => [InvalidRequestError, 400],
          "InvalidArgumentException" => [InvalidRequestError, 400],
          "CreateBoardException" => [InvalidRequestError, 400],
          "ItemsLimitationException" => [InvalidRequestError, 400],
          "ItemNameTooLongException" => [InvalidRequestError, 400],
          "ColumnValueException" => [InvalidRequestError, 400],
          "CorrectedValueException" => [InvalidRequestError, 400],
          "InvalidWorkspaceIdException" => [InvalidRequestError, 400]
        }[error_code] || [Error, 400]
      end

      private

      def format_array(array)
        array.map do |item|
          item.is_a?(Hash) ? format_hash(item) : item.to_s
        end.join(" ")
      end

      def format_hash(hash)
        hash.map do |key, value|
          value.is_a?(Array) ? "#{key} { #{format_array(value)} }" : "#{key} { #{value} }"
        end.join(" ")
      end

      def formatted_args_value(value)
        return value.to_json.to_json if value.is_a?(Hash)
        return value if integer?(value)

        "\"#{value}\""
      end

      def integer?(value)
        value.is_a?(Integer)
      end
    end
  end
end
