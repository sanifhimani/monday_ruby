# frozen_string_literal: true

require_relative "monday/client"
require_relative "monday/deprecation"
require_relative "monday/version"

# Module to configure the library globally
module Monday
  module_function

  def configure
    yield config
  end

  def config
    @config ||= Configuration.new
  end
end
