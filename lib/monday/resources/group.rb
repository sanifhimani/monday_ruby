# frozen_string_literal: true

require_relative "base"

module Monday
  module Resources
    # Represents Monday.com's group resource.
    class Group < Base
      DEFAULT_SELECT = %w[id title].freeze
      DEFAULT_PAGINATED_SELECT = %w[id name].freeze

      # Retrieves all the groups.
      #
      # Allows filtering groups using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID and title fields are retrieved.
      def query(args: {}, select: DEFAULT_SELECT)
        request_query = "query{boards#{Util.format_args(args)}{groups{#{Util.format_select(select)}}}}"

        make_request(request_query)
      end

      # Creates a new group.
      #
      # Allows customizing creating a group using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID and title fields are retrieved.
      def create(args: {}, select: DEFAULT_SELECT)
        query = "mutation{create_group#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Updates a group.
      #
      # Allows customizing updating the group using the args option.
      # By default, returns the ID of the updated group.
      def update(args: {}, select: ["id"])
        query = "mutation{update_group#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Deletes a group.
      #
      # Requires board_id and group_id in args option to delete the group.
      # Allows customizing the values to retrieve using the select option.
      # By default, returns the ID of the group deleted.
      def delete(args: {}, select: ["id"])
        query = "mutation{delete_group#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Archives a group.
      #
      # Requires board_id and group_id in args option to archive the group.
      # Allows customizing the values to retrieve using the select option.
      # By default, returns the ID of the group archived.
      def archive(args: {}, select: ["id"])
        query = "mutation{archive_group#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Duplicates a group.
      #
      # Requires board_id and group_id in args option to duplicate the group.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID and title fields are retrieved.
      def duplicate(args: {}, select: DEFAULT_SELECT)
        query = "mutation{duplicate_group#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Move item to group.
      #
      # Requires item_id and group_id in args option to move an item to a group.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID and title fields are retrieved.
      def move_item(args: {}, select: ["id"])
        query = "mutation{move_item_to_group#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Retrieves paginated items from a group.
      #
      # Uses cursor-based pagination for efficient data retrieval.
      # The items_page field is the modern replacement for the deprecated items field.
      #
      # @param board_ids [Integer, Array<Integer>] The ID(s) of the board(s) containing the group
      # @param group_ids [String, Array<String>] The ID(s) of the group(s)
      # @param limit [Integer] Number of items to retrieve per page (default: 25, max: 500)
      # @param cursor [String, nil] Pagination cursor for fetching next page (expires after 60 minutes)
      # @param query_params [Hash, nil] Query parameters for filtering items with rules and operators
      # @param select [Array] Fields to retrieve for each item
      # @return [Monday::Response] Response containing items and cursor
      #
      # @example Fetch first page of items from a group
      #   response = client.group.items_page(board_ids: 123, group_ids: "group_1", limit: 50)
      #   items = response.dig("data", "boards", 0, "groups", 0, "items_page", "items")
      #   cursor = response.dig("data", "boards", 0, "groups", 0, "items_page", "cursor")
      #
      # @example Fetch next page using cursor
      #   response = client.group.items_page(board_ids: 123, group_ids: "group_1", cursor: cursor)
      #
      # @example Filter items by column value
      #   response = client.group.items_page(
      #     board_ids: 123,
      #     group_ids: "group_1",
      #     limit: 100,
      #     query_params: {
      #       rules: [{ column_id: "status", compare_value: [1] }],
      #       operator: :and
      #     }
      #   )
      def items_page(
        board_ids:, group_ids:, limit: 25, cursor: nil, query_params: nil, select: DEFAULT_PAGINATED_SELECT
      )
        items_page_query = build_items_page_query(limit, cursor, query_params, select)
        request_query = build_groups_items_page_request(board_ids, group_ids, items_page_query)

        make_request(request_query)
      end

      private

      def build_items_page_query(limit, cursor, query_params, select)
        args_parts = ["limit: #{limit}"]
        args_parts << "cursor: \"#{cursor}\"" if cursor
        args_parts << "query_params: #{Util.format_graphql_object(query_params)}" if query_params

        args_string = "(#{args_parts.join(", ")})"
        "items_page#{args_string}{cursor items{#{Util.format_select(select)}}}"
      end

      def build_groups_items_page_request(board_ids, group_ids, items_page_query)
        board_args = { ids: board_ids.is_a?(Array) ? board_ids : [board_ids] }
        group_ids_formatted = format_group_ids(group_ids)

        boards_part = "boards#{Util.format_args(board_args)}"
        groups_part = "groups(ids: #{group_ids_formatted})"
        "query{#{boards_part}{#{groups_part}{#{items_page_query}}}}"
      end

      def format_group_ids(group_ids)
        ids_array = group_ids.is_a?(Array) ? group_ids : [group_ids]
        "[#{ids_array.map { |id| "\"#{id}\"" }.join(", ")}]"
      end
    end
  end
end
