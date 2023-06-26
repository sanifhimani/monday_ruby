# frozen_string_literal: true

module Monday
  module Resources
    # Represents Monday.com's board resource.
    module Board
      DEFAULT_SELECT = %w[id name description].freeze

      # Retrieves all the boards.
      #
      # Allows users to filter boards using the args option.
      # Users can also select the fields they want to retrieve using the select option.
      # By default, ID, name and description columns are retrieved.
      def boards(args: {}, select: DEFAULT_SELECT)
        query = "query { boards(#{Util.format_args(args)}) {#{Util.format_select(select)}} }"

        make_request(query)
      end

      # Creates a new boards.
      #
      # Allows users to customize creating a board using the args option.
      # Users can also select the fields they want to retrieve using the select option.
      # By default, ID, name and description columns are retrieved.
      def create_board(args: {}, select: DEFAULT_SELECT)
        query = "mutation { create_board(#{Util.format_args(args)}) {#{Util.format_select(select)}} }"

        make_request(query)
      end

      # Duplicates a board.
      #
      # Allows users to customize duplicating the board using the args option.
      # Users can also select the fields they want to retrieve using the select option.
      # By default, ID, name and description columns are retrieved.
      def duplicate_board(args: {}, select: DEFAULT_SELECT)
        query = "mutation { duplicate_board(#{Util.format_args(args)}) { board { #{Util.format_select(select)} } } }"

        make_request(query)
      end

      # Updates a board.
      #
      # Allows users to customize updating the board using the args option.
      # Returns the ID of the updated board.
      def update_board(args: {})
        query = "mutation { update_board(#{Util.format_args(args)}) }"

        make_request(query)
      end

      # Archives a board.
      #
      # Takes board_id as an argument.
      # Users can also select the fields they want to retrieve using the select option.
      # By default, returns the ID of the board archived.
      def archive_board(board_id, select: ["id"])
        query = "mutation { archive_board(board_id: #{board_id}) {#{Util.format_select(select)}} }"

        make_request(query)
      end

      # Deletes a board.
      #
      # Takes board_id as an argument.
      # Users can also select the fields they want to retrieve using the select option.
      # By default, returns the ID of the board deleted.
      def delete_board(board_id, select: ["id"])
        query = "mutation { delete_board(board_id: #{board_id}) {#{Util.format_select(select)}} }"

        make_request(query)
      end

      # Deletes the subscribers from a board.
      #
      # Takes board_id and user_ids as arguments.
      # Users can also select the fields they want to retrieve using the select option.
      # By default, returns the board ID.
      def delete_board_subscribers(board_id, user_ids, select: ["id"])
        query = "mutation { delete_subscribers_from_board(" \
                "board_id: #{board_id}, user_ids: #{user_ids}) {#{Util.format_select(select)}} }"

        make_request(query)
      end
    end
  end
end
