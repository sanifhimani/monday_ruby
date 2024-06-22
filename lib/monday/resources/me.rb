# frozen_string_literal: true

module Monday
  module Resources
    # Represents Monday.com's account resource.
    module Me
      DEFAULT_SELECT = %w[id name].freeze

      # Retrieves the users account.
      #
      # Allows customizing the values to retrieve using the select option.
      # By default, ID and name are retrieved.
      def me(select: DEFAULT_SELECT)
        query = "query { me {#{Util.format_select(select)}}}"

        make_request(query)
      end
    end
  end
end
