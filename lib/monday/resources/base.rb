# frozen_string_literal: true

module Monday
  module Resources
    # Base class for all resources.
    class Base
      attr_reader :client

      def initialize(client)
        @client = client
      end

      protected

      def make_file_request(query, variables)
        client.make_file_request(query, variables)
      end

      def make_request(query)
        client.make_request(query)
      end
    end
  end
end
