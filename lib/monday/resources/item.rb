# frozen_string_literal: true

require_relative "base"

module Monday
  module Resources
    # Represents Monday.com's item resource.
    class Item < Base
      DEFAULT_SELECT = %w[id name created_at].freeze
      DEFAULT_PAGINATED_SELECT = %w[id name].freeze

      # Retrieves all the items for the boards.
      #
      # Allows filtering items using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and created_at fields are retrieved.
      def query(args: {}, select: DEFAULT_SELECT)
        request_query = "query{items#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(request_query)
      end

      # Creates a new item.
      #
      # Allows customizing the item creation using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and created_at fields are retrieved.
      def create(args: {}, select: DEFAULT_SELECT)
        query = "mutation{create_item#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Duplicates an item.
      #
      # Allows customizing the item creation using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and created_at fields are retrieved.
      def duplicate(board_id, item_id, with_updates, select: DEFAULT_SELECT)
        query = "mutation{duplicate_item(board_id: #{board_id}, item_id: #{item_id}, " \
                "with_updates: #{with_updates}){#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Archives an item.
      #
      # Requires item_id to archive item.
      # Allows customizing the values to retrieve using the select option.
      # By default, returns the ID of the archived item.
      def archive(item_id, select: %w[id])
        query = "mutation{archive_item(item_id: #{item_id}){#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Deletes an item.
      #
      # Requires item_id to delete item.
      # Allows customizing the values to retrieve using the select option.
      # By default, returns the ID of the deleted item.
      def delete(item_id, select: %w[id])
        query = "mutation{delete_item(item_id: #{item_id}){#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Retrieves paginated items filtered by column values.
      #
      # Enables searching for items based on specific column values.
      # Uses cursor-based pagination for efficient data retrieval.
      #
      # @param board_id [Integer] The ID of the board
      # @param columns [Array<Hash>, nil] Column filtering criteria (mutually exclusive with cursor)
      #   Each hash should contain :column_id and :column_values
      # @param limit [Integer] Number of items to retrieve per page (default: 25, max: 500)
      # @param cursor [String, nil] Pagination cursor for fetching next page (mutually exclusive with columns)
      # @param select [Array] Fields to retrieve for each item
      # @return [Monday::Response] Response containing items and cursor
      #
      # @example Search items by column values
      #   response = client.item.page_by_column_values(
      #     board_id: 123,
      #     columns: [
      #       { column_id: "status", column_values: ["Done", "Working on it"] },
      #       { column_id: "text", column_values: ["High Priority"] }
      #     ],
      #     limit: 50
      #   )
      #   items = response.dig("data", "items_page_by_column_values", "items")
      #   cursor = response.dig("data", "items_page_by_column_values", "cursor")
      #
      # @example Fetch next page using cursor
      #   response = client.item.page_by_column_values(
      #     board_id: 123,
      #     cursor: cursor
      #   )
      #
      # @note Supported column types: Checkbox, Country, Date, Dropdown, Email, Hour, Link,
      #   Long Text, Numbers, People, Phone, Status, Text, Timeline, World Clock
      # @note Columns use AND logic; values within a column use ANY_OF logic
      def page_by_column_values(board_id:, columns: nil, limit: 25, cursor: nil, select: DEFAULT_PAGINATED_SELECT)
        query_string = build_items_page_by_column_values_query(board_id, columns, limit, cursor, select)
        make_request(query_string)
      end

      private

      def build_items_page_by_column_values_query(board_id, columns, limit, cursor, select)
        args_parts = ["board_id: #{board_id}", "limit: #{limit}"]
        args_parts << "cursor: \"#{cursor}\"" if cursor
        args_parts << "columns: #{format_columns(columns)}" if columns

        args_string = "(#{args_parts.join(", ")})"
        "query{items_page_by_column_values#{args_string}{cursor items{#{Util.format_select(select)}}}}"
      end

      def format_columns(columns)
        return nil unless columns

        column_strings = columns.map do |col|
          values = col[:column_values].map { |v| "\"#{v}\"" }.join(", ")
          "{column_id: \"#{col[:column_id]}\", column_values: [#{values}]}"
        end

        "[#{column_strings.join(", ")}]"
      end
    end
  end
end
