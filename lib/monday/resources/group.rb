# frozen_string_literal: true

require_relative "base"

module Monday
  module Resources
    # Represents Monday.com's group resource.
    class Group < Base
      DEFAULT_SELECT = %w[id title].freeze

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
    end
  end
end
