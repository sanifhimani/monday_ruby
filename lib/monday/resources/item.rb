# frozen_string_literal: true

require "byebug"

module Monday
  module Resources
    # Represents Monday.com's item resource.
    module Item
      DEFAULT_SELECT = %w[id name created_at].freeze

      # Retrieves all the items for the boards.
      #
      # Allows filtering items using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and created_at fields are retrieved.
      def items(args: {}, select: DEFAULT_SELECT)
        query = "query { items(#{Util.format_args(args)}) {#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Creates a new item.
      #
      # Allows customizing the item creation using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and created_at fields are retrieved.
      def create_item(args: {}, select: DEFAULT_SELECT)
        query = "mutation { create_item(#{Util.format_args(args)}) {#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Duplicates an item.
      #
      # Allows customizing the item creation using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and created_at fields are retrieved.
      def duplicate_item(board_id, item_id, with_updates, select: DEFAULT_SELECT)
        query = "mutation { duplicate_item(board_id: #{board_id}, item_id: #{item_id}, " \
                "with_updates: #{with_updates}) {#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Archives an item.
      #
      # Requires item_id to archive item.
      # Allows customizing the values to retrieve using the select option.
      # By default, returns the ID of the archived item.
      def archive_item(item_id, select: %w[id])
        query = "mutation { archive_item(item_id: #{item_id}) {#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Deletes an item.
      #
      # Requires item_id to delete item.
      # Allows customizing the values to retrieve using the select option.
      # By default, returns the ID of the deleted item.
      def delete_item(item_id, select: %w[id])
        query = "mutation { delete_item(item_id: #{item_id}) {#{Util.format_select(select)}}}"

        make_request(query)
      end
    end
  end
end
