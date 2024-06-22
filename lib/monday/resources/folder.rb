# frozen_string_literal: true

module Monday
  module Resources
    # Represents Monday.com's folder resource.
    module Folder
      DEFAULT_SELECT = %w[id name].freeze

      # Retrieves all the folders.
      #
      # Allows filtering folders using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID and name fields are retrieved.
      def folders(args: {}, select: DEFAULT_SELECT)
        query = "query { folders#{Util.format_args(args)} {#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Creates a new folder.
      #
      # Allows customizing creating a folder using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and description fields are retrieved.
      def create_folder(args: {}, select: DEFAULT_SELECT)
        query = "mutation { create_folder#{Util.format_args(args)} {#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Updates a folder.
      #
      # Allows customizing updating the folder using the args option.
      # Returns the ID of the updated folder.
      def update_folder(args: {})
        query = "mutation { update_folder#{Util.format_args(args)}}"

        make_request(query)
      end

      # Deletes a folder.
      #
      # Requires folder_id to delete the folder.
      # Allows customizing the values to retrieve using the select option.
      # By default, returns the ID of the folder deleted.
      def delete_folder(folder_id, select: ["id"])
        query = "mutation { delete_folder(folder_id: #{folder_id}) {#{Util.format_select(select)}}}"

        make_request(query)
      end
    end
  end
end
