# frozen_string_literal: true

module Monday
  module Resources
    # Represents Monday.com's subitem resource.
    module Subitem
      DEFAULT_SELECT = %w[id name created_at].freeze

      # Retrieves all the subitems for the item.
      #
      # Allows filtering subitems using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and created_at fields are retrieved.
      def subitems(args: {}, select: DEFAULT_SELECT)
        query = "query { items#{Util.format_args(args)} { subitems{#{Util.format_select(select)}}}}"

        make_request(query)
      end

      # Creates a new subitem.
      #
      # Allows customizing the subitem creation using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID, name and created_at fields are retrieved.
      def create_subitem(args: {}, select: DEFAULT_SELECT)
        query = "mutation { create_subitem#{Util.format_args(args)} {#{Util.format_select(select)}}}"

        make_request(query)
      end
    end
  end
end
