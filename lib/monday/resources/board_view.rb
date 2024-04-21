# frozen_string_literal: true

module Monday
  module Resources
    # Represents Monday.com's board view resource.
    module BoardView
      DEFAULT_SELECT = %w[id name type].freeze

      # Retrieves board views from a specific board.
      #
      # Allows filtering views using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and type fields are retrieved.
      def board_views(args: {}, select: DEFAULT_SELECT)
        query = "query { boards#{Util.format_args(args)} { views {#{Util.format_select(select)}}}}"

        make_request(query)
      end
    end
  end
end
