# frozen_string_literal: true

require_relative "base"

module Monday
  module Resources
    # Represents Monday.com's board resource.
    class Board < Base
      DEFAULT_SELECT = %w[id name description].freeze

      # Retrieves all the boards.
      #
      # Allows filtering boards using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and description fields are retrieved.
      def query(args: {}, select: DEFAULT_SELECT)
        request_query = "query{boards#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(request_query)
      end

      # Creates a new boards.
      #
      # Allows customizing creating a board using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and description fields are retrieved.
      def create(args: {}, select: DEFAULT_SELECT)
        query = "mutation{create_board#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Duplicates a board.
      #
      # Allows customizing duplicating the board using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and description fields are retrieved.
      def duplicate(args: {}, select: DEFAULT_SELECT)
        query = "mutation{duplicate_board#{Util.format_args(args)}{board{#{Util.format_select(select)}}}}"

        make_request(query)
      end

      # Updates a board.
      #
      # Allows customizing updating the board using the args option.
      # Returns the ID of the updated board.
      def update(args: {})
        query = "mutation{update_board#{Util.format_args(args)}}"

        make_request(query)
      end

      # Archives a board.
      #
      # Requires board_id to archive board.
      # Allows customizing the values to retrieve using the select option.
      # By default, returns the ID of the board archived.
      def archive(board_id, select: ["id"])
        query = "mutation{archive_board(board_id: #{board_id}){#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Deletes a board.
      #
      # Requires board_id to delete the board.
      # Allows customizing the values to retrieve using the select option.
      # By default, returns the ID of the board deleted.
      def delete(board_id, select: ["id"])
        query = "mutation{delete_board(board_id: #{board_id}){#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Deletes the subscribers from a board.
      #
      # Requires board_id and user_ids to delete subscribers.
      # Allows customizing the values to retrieve using the select option.
      # By default, returns the deleted subscriber IDs.
      def delete_subscribers(board_id, user_ids, select: ["id"])
        Deprecation.warn(
          method_name: "delete_subscribers",
          removal_version: "2.0.0",
          alternative: "user.delete_from_board"
        )

        query = "mutation{delete_subscribers_from_board(" \
                "board_id: #{board_id}, user_ids: #{user_ids}){#{Util.format_select(select)}}}"

        make_request(query)
      end
    end
  end
end
