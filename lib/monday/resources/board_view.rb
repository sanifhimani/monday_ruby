# frozen_string_literal: true

require_relative "base"

module Monday
  module Resources
    # Represents Monday.com's board view resource.
    class BoardView < Base
      DEFAULT_SELECT = %w[id name type].freeze

      # Retrieves board views from a specific board.
      #
      # Allows filtering views using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and type fields are retrieved.
      def query(args: {}, select: DEFAULT_SELECT)
        request_query = "query{boards#{Util.format_args(args)}{views{#{Util.format_select(select)}}}}"

        make_request(request_query)
      end
    end
  end
end
