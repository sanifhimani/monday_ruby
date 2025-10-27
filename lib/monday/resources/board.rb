# frozen_string_literal: true

require_relative "base"

module Monday
  module Resources
    # Represents Monday.com's board resource.
    class Board < Base
      DEFAULT_SELECT = %w[id name description].freeze
      DEFAULT_PAGINATED_SELECT = %w[id name].freeze

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

      # Retrieves paginated items from a board.
      #
      # Uses cursor-based pagination for efficient data retrieval.
      # The items_page field is the modern replacement for the deprecated items field.
      #
      # @param board_id [Integer] The ID of the board
      # @param limit [Integer] Number of items to retrieve per page (default: 25, max: 500)
      # @param cursor [String, nil] Pagination cursor for fetching next page (expires after 60 minutes)
      # @param query_params [Hash, nil] Query parameters for filtering items with rules and operators
      # @param args [Hash] Additional board query arguments
      # @param select [Array] Fields to retrieve for each item
      # @return [Monday::Response] Response containing items and cursor
      #
      # @example Fetch first page of items
      #   response = client.board.items_page(board_id: 123, limit: 50)
      #   items = response.dig("data", "boards", 0, "items_page", "items")
      #   cursor = response.dig("data", "boards", 0, "items_page", "cursor")
      #
      # @example Fetch next page using cursor
      #   response = client.board.items_page(board_id: 123, cursor: cursor)
      #
      # @example Filter items by column value
      #   response = client.board.items_page(
      #     board_id: 123,
      #     limit: 100,
      #     query_params: {
      #       rules: [{ column_id: "status", compare_value: [1] }],
      #       operator: :and
      #     }
      #   )
      def items_page(board_ids:, limit: 25, cursor: nil, query_params: nil, select: DEFAULT_PAGINATED_SELECT)
        items_args_parts = ["limit: #{limit}"]
        items_args_parts << "cursor: \"#{cursor}\"" if cursor
        items_args_parts << "query_params: #{Util.format_graphql_object(query_params)}" if query_params

        items_args_string = items_args_parts.empty? ? "" : "(#{items_args_parts.join(", ")})"

        items_page_select = "items_page#{items_args_string}{cursor items{#{Util.format_select(select)}}}"

        board_args = { ids: board_ids.is_a?(Array) ? board_ids : [board_ids] }
        request_query = "query{boards#{Util.format_args(board_args)}{#{items_page_select}}}"

        make_request(request_query)
      end
    end
  end
end
