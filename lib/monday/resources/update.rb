# frozen_string_literal: true

require_relative "base"

module Monday
  module Resources
    # Represents Monday.com's update resource.
    class Update < Base
      DEFAULT_SELECT = %w[id body created_at].freeze

      # Retrieves all the updates.
      #
      # Allows filtering updates using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, body and created_at fields are retrieved.
      def query(args: {}, select: DEFAULT_SELECT)
        request_query = "query{updates#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(request_query)
      end

      # Creates a new update.
      #
      # Allows customizing the update creation using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, body and created_at fields are retrieved.
      def create(args: {}, select: DEFAULT_SELECT)
        query = "mutation{create_update#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Like an update.
      #
      # Allows customizing the update creation using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID is retrieved.
      def like(args: {}, select: %w[id])
        query = "mutation{like_update#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Clear an item's update
      #
      # Allows customizing the update creation using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID is retrieved.
      def clear_item_updates(args: {}, select: %w[id])
        query = "mutation{clear_item_updates#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Delete an update
      #
      # Allows customizing the update creation using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID is retrieved.
      def delete(args: {}, select: %w[id])
        query = "mutation{delete_update#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end
    end
  end
end
