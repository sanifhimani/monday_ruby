# frozen_string_literal: true

require_relative "base"

module Monday
  module Resources
    # Represents Monday.com's activity log resource.
    class ActivityLog < Base
      DEFAULT_SELECT = %w[id event data].freeze

      # Retrieves the activity logs for boards.
      #
      # Requires board_ids to retrieve the logs.
      # Allows filtering activity logs using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, event and data are retrieved.
      def query(board_ids, args: {}, select: DEFAULT_SELECT)
        request_query = "query{boards(ids: #{board_ids})" \
                        "{activity_logs#{Util.format_args(args)}{#{Util.format_select(select)}}}}"

        make_request(request_query)
      end
    end
  end
end
