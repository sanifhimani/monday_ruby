# frozen_string_literal: true

module Monday
  module Resource
    module Board
      DEFAULT_SELECT = %w[id name description].freeze

      def boards(args: {}, select: DEFAULT_SELECT)
        query = "query { boards(#{Util.format_args(args)}) {#{Util.format_select(select)}} }"

        make_request(query)
      end

      def create_board(args: {}, select: DEFAULT_SELECT)
        query = "mutation { create_board(#{Util.format_args(args)}) {#{Util.format_select(select)}} }"

        make_request(query)
      end

      def duplicate_board(args: {}, select: DEFAULT_SELECT)
        query = "mutation { duplicate_board(#{Util.format_args(args)}) { board { #{Util.format_select(select)} } } }"

        make_request(query)
      end

      def update_board(args: {})
        query = "mutation { update_board(#{Util.format_args(args)}) }"

        make_request(query)
      end

      def archive_board(board_id, select: ["id"])
        query = "mutation { archive_board(board_id: #{board_id}) {#{Util.format_select(select)}} }"

        make_request(query)
      end

      def delete_board(board_id, select: ["id"])
        query = "mutation { delete_board(board_id: #{board_id}) {#{Util.format_select(select)}} }"

        make_request(query)
      end

      def delete_board_subscribers(board_id, user_ids, select: ["id"])
        query = "mutation { delete_subscribers_from_board(board_id: #{board_id}, user_ids: #{user_ids}) {#{Util.format_select(select)}} }"

        make_request(query)
      end
    end
  end
end
