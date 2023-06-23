# frozen_string_literal: true

module Monday
  module Util
    def self.format_args(obj)
      obj.map do |key, value|
        "#{key}: #{value}"
      end.join(", ")
    end

    def self.format_select(array)
      array.map do |item|
        item.is_a?(Hash) ? "#{item.keys.first} { #{item.values.join(" ")} }" : item.to_s
      end.join(" ")
    end
  end
end
