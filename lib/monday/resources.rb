# frozen_string_literal: true

require_relative "resources/account"
require_relative "resources/activity_log"
require_relative "resources/board"
require_relative "resources/board_view"
require_relative "resources/column"
require_relative "resources/group"
require_relative "resources/item"
require_relative "resources/subitem"
require_relative "resources/workspace"
require_relative "resources/update"

module Monday
  module Resources
    include Account
    include ActivityLog
    include Board
    include BoardView
    include Column
    include Group
    include Item
    include Subitem
    include Workspace
    include Update
  end
end
