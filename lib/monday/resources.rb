# frozen_string_literal: true

require_relative "resources/board"
require_relative "resources/account"

module Monday
  module Resources
    include Account
    include Board
  end
end
