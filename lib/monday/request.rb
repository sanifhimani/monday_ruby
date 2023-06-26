# frozen_string_literal: true

module Monday
  # Defines the HTTP request methods.
  class Request
    # Performs a POST request
    def self.post(uri, query, headers)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, headers)

      request.body = {
        "query" => query
      }.to_json

      http.request(request)
    end
  end
end
