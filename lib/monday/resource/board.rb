# frozen_string_literal: true

module Monday
  module Resource
    module Board
      DEFAULT_SELECT = %w[id name description].freeze

      def boards(args: {}, select: DEFAULT_SELECT)
        formatted_args = Util.format_args(args)
        formatted_select = Util.format_select(select)

        query = "query { boards(#{formatted_args}) {#{formatted_select}} }"
        body = {
          "query" => query
        }

        make_request(body)
      end
    end
  end
end
