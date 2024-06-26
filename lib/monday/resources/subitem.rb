# frozen_string_literal: true

require_relative "base"

module Monday
  module Resources
    # Represents Monday.com's subitem resource.
    class Subitem < Base
      DEFAULT_SELECT = %w[id name created_at].freeze

      # Retrieves all the subitems for the item.
      #
      # Allows filtering subitems using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and created_at fields are retrieved.
      def query(args: {}, select: DEFAULT_SELECT)
        request_query = "query{items#{Util.format_args(args)}{ subitems{#{Util.format_select(select)}}}}"

        make_request(request_query)
      end

      # Creates a new subitem.
      #
      # Allows customizing the subitem creation using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and created_at fields are retrieved.
      def create(args: {}, select: DEFAULT_SELECT)
        query = "mutation{create_subitem#{Util.format_args(args)}{#{Util.format_select(select)}}}"

        make_request(query)
      end
    end
  end
end
