# frozen_string_literal: true

require_relative "resources/account"
require_relative "resources/activity_log"
require_relative "resources/board"

module Monday
  module Resources
    include Account
    include ActivityLog
    include Board
  end
end
