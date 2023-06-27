# frozen_string_literal: true

module Monday
  module Resources
    # Represents Monday.com's board resource.
    module BoardView
      DEFAULT_SELECT = %w[id name type].freeze

      # Retrieves board views from a specific board.
      #
      # Allows users to filter views using the args option.
      # Users can also select the view fields they want to retrieve using the select option.
      # By default, ID, name and type fields are retrieved.
      def board_views(args: {}, select: DEFAULT_SELECT)
        query = "query { boards(#{Util.format_args(args)}) { views {#{Util.format_select(select)}}}}"

        make_request(query)
      end
    end
  end
end
