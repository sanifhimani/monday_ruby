# frozen_string_literal: true

module Monday
  module Resources
    # Represents Monday.com's workspace resource.
    module Workspace
      DEFAULT_SELECT = %w[id name description].freeze

      # Retrieves all the workspaces.
      #
      # Allows filtering workspaces using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and description fields are retrieved.
      def workspaces(args: {}, select: DEFAULT_SELECT)
        query = "query { workspaces#{Util.format_args(args)} {#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Creates a new workspaces.
      #
      # Allows customizing creating a workspace using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and description fields are retrieved.
      def create_workspace(args: {}, select: DEFAULT_SELECT)
        query = "mutation { create_workspace#{Util.format_args(args)} {#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Deletes a workspace.
      #
      # Requires workspace_id to delete the workspace.
      # Allows customizing the values to retrieve using the select option.
      # By default, returns the ID of the workspace deleted.
      def delete_workspace(workspace_id, select: ["id"])
        query = "mutation { delete_workspace(workspace_id: #{workspace_id}) {#{Util.format_select(select)}}}"

        make_request(query)
      end
    end
  end
end
