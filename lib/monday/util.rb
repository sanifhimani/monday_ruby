# frozen_string_literal: true

module Monday
  class Util
    class << self
      def format_args(obj)
        obj.map do |key, value|
          "#{key}: #{formatted_args_value(value)}"
        end.join(", ")
      end

      def format_select(array)
        array.map do |item|
          item.is_a?(Hash) ? "#{item.keys.first} { #{item.values.join(" ")} }" : item.to_s
        end.join(" ")
      end

      private

      def formatted_args_value(value)
        return "\"#{value}\"" unless single_word?(value)

        value
      end

      def single_word?(word)
        return word unless word.is_a?(String)

        !word.strip.include?(" ")
      end
    end
  end
end
