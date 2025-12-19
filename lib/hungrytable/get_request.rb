# frozen_string_literal: true

module Hungrytable
  # HTTP GET request handler
  class GetRequest < Request
    # Default timeout for HTTP requests (in seconds)
    DEFAULT_TIMEOUT = 30

    private

    def make_request
      response = HTTP
                 .timeout(DEFAULT_TIMEOUT)
                 .headers('Authorization' => auth_header)
                 .get(uri)

      handle_http_errors(response)
    rescue HTTP::Error => e
      raise HTTPError, "HTTP request failed: #{e.message}"
    end

    def auth_header
      RequestHeader.new(:get, uri, {}, {}).to_s
    end
  end
end
