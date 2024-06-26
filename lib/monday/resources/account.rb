# frozen_string_literal: true

require_relative "base"

module Monday
  module Resources
    # Represents Monday.com's account resource.
    class Account < Base
      DEFAULT_SELECT = %w[id name].freeze

      # Retrieves the users account.
      #
      # Allows customizing the values to retrieve using the select option.
      # By default, ID and name are retrieved.
      def query(select: DEFAULT_SELECT)
        request_query = "query{users{account {#{Util.format_select(select)}}}}"

        make_request(request_query)
      end
    end
  end
end
