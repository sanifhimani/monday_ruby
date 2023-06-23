# frozen_string_literal: true

module Monday
  class Request
    def self.post(uri, body, headers)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, headers)
      request.body = body.to_json
      http.request(request)
    end
  end
end
