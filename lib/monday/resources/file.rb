# frozen_string_literal: true

module Monday
  module Resources
    # Represents Monday.com's file asset resource.
    class File < Base
      DEFAULT_SELECT = %w[id].freeze

      # Adds a file to a file type column for an item.
      #
      # Allows customizing the column update using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, The ID is retrieved.
      def add_file_to_column(args: {}, select: DEFAULT_SELECT)
        cloned_args = args.clone
        variables = { file: cloned_args.delete(:file) }
        cloned_args.merge!(file: '$file')
        query = "mutation add_file($file: File!) { add_file_to_column#{Util.format_args(cloned_args)} {#{Util.format_select(select)}}}"
        make_file_request(query, variables)
      end

      # Adds a file to an update for an item.
      #
      # Allows customizing the update creation using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, The ID is retrieved.
      def add_file_to_update(args: {}, select: DEFAULT_SELECT)
        cloned_args = args.clone
        variables = { file: cloned_args.delete(:file) }
        cloned_args.merge!(file: '$file')
        query = "mutation ($file: File!) { add_file_to_update#{Util.format_args(cloned_args)} {#{Util.format_select(select)}}}"
        make_file_request(query, variables)
      end

      # Clear an item's files column.
      #
      # Allows customizing the update creation using the args option.
      # Allows customizing the values to retrieve using the select option.
      # By default, ID is retrieved.
      def clear_file_column(args: {}, select: DEFAULT_SELECT)
        merged_args = args.merge(value: '{\"clear_all\": true}')
        query = "mutation { change_column_value#{Util.format_args(merged_args)} {#{Util.format_select(select)}}}"
        make_request(query)
      end
    end
  end
end
