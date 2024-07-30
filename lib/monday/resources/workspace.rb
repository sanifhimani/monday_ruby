# frozen_string_literal: true

require_relative "base"

module Monday
  module Resources
    # Represents Monday.com's workspace resource.
    class Workspace < Base
      DEFAULT_SELECT = %w[id name description].freeze

      # Retrieves all the workspaces.
      #
      # Allows filtering workspaces using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and description fields are retrieved.
      def query(args: {}, select: DEFAULT_SELECT)
        request_query = "query{workspaces#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(request_query)
      end

      # Creates a new workspaces.
      #
      # Allows customizing creating a workspace using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and description fields are retrieved.
      def create(args: {}, select: DEFAULT_SELECT)
        query = "mutation{create_workspace#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end

      # Deletes a workspace.
      #
      # Requires workspace_id to delete the workspace.
      # Allows customizing the values to retrieve using the select option.
      # By default, returns the ID of the workspace deleted.
      def delete(workspace_id, select: ["id"])
        query = "mutation{delete_workspace(workspace_id: #{workspace_id}){#{Util.format_select(select)}}}"

        make_request(query)
      end
    end
  end
end
