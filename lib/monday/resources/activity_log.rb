# frozen_string_literal: true

module Monday
  module Resources
    # Represents Monday.com's activity log resource.
    module ActivityLog
      DEFAULT_SELECT = %w[id event data].freeze

      # Retrieves the activity logs for boards.
      #
      # Requires board_ids to retrieve the logs.
      # Allows users to filter activity logs using the args option.
      # Users can also select the fields they want to retrieve using the select option.
      # By default, ID, event and data are retrieved.
      def activity_logs(board_ids, args: {}, select: DEFAULT_SELECT)
        query = "query { boards(ids: #{board_ids}) " \
                "{ activity_logs(#{Util.format_args(args)}) {#{Util.format_select(select)}}}}"

        make_request(query)
      end
    end
  end
end
