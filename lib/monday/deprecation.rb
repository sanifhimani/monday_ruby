# frozen_string_literal: true

module Monday
  # Utility module for handling deprecation warnings
  module Deprecation
    # Issues a deprecation warning to stderr
    #
    # @param method_name [String] The name of the deprecated method
    # @param removal_version [String] The version in which the method will be removed
    # @param alternative [String, nil] The recommended alternative method
    #
    # @example
    #   Deprecation.warn(method_name: "items", removal_version: "2.0.0", alternative: "items_page")
    #   # => [DEPRECATION] `items` is deprecated and will be removed in v2.0.0. Use `items_page` instead.
    def self.warn(method_name:, removal_version:, alternative: nil)
      message = "[DEPRECATION] `#{method_name}` is deprecated and will be removed in v#{removal_version}."
      message += " Use `#{alternative}` instead." if alternative

      # Output to stderr so it doesn't interfere with normal output
      Kernel.warn message
    end
  end
end
