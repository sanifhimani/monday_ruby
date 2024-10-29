# frozen_string_literal: true

require_relative "base"

module Monday
  module Resources
    # Represents Monday.com's board resource.
    class Folder < Base
      DEFAULT_SELECT = %w[id name].freeze

      # Retrieves all the folders.
      #
      # Allows filtering folders using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID and name fields are retrieved.
      def query(args: {}, select: DEFAULT_SELECT)
        request_query = "query{folders#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(request_query)
      end

      # Create a new folder.
      #
      # Allows customizing creating a folder using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID and name fields are retrieved.
      def create(args: {}, select: DEFAULT_SELECT)
        query = "mutation{create_folder#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Update a folder.
      #
      # Allows customizing updating the folder using the args option.
      # By default, returns the ID of the updated folder.
      def update(args: {}, select: ["id"])
        query = "mutation{update_folder#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Delete a folder.
      #
      # Requires folder_id in args option to delete the folder.
      # Allows customizing the values to retrieve using the select option.
      # By default, returns the ID of the folder deleted.
      def delete(args: {}, select: ["id"])
        query = "mutation{delete_folder#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end
    end
  end
end
