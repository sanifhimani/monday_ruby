# frozen_string_literal: true

module Monday
  # Defines the HTTP request methods.
  class Request
    # Performs a POST request
    def self.post(uri, query, headers, open_timeout: 10, read_timeout: 30)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = open_timeout
      http.read_timeout = read_timeout

      request = Net::HTTP::Post.new(uri.request_uri, headers)

      request.body = {
        "query" => query
      }.to_json

      http.request(request)
    end

    def self.post_multipart(uri, body, headers, open_timeout: 10, read_timeout: 30)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = open_timeout
      http.read_timeout = read_timeout

      params = {
        "query" => body[:query],
        "variables[file]" => body[:variables][:file]
      }

      request = Net::HTTP::Post::Multipart.new(uri.request_uri, params, headers)
      http.request(request)
    end
  end
end
