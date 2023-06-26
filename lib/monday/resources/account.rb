# frozen_string_literal: true

module Monday
  module Resources
    # Represents Monday.com's account resource.
    module Account
      DEFAULT_SELECT = %w[id name].freeze

      # Retrieves the users account.
      #
      # Users can also select the columns they want to retrieve using the select option.
      # By default, ID and name are retrieved.
      def account(select: DEFAULT_SELECT)
        query = "query { users { account {#{Util.format_select(select)}}}}"

        make_request(query)
      end
    end
  end
end
