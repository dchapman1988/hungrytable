# frozen_string_literal: true

module Hungrytable
  # HTTP POST request handler
  class PostRequest < Request
    private

    def make_request
      response = HTTP
                 .headers('Authorization' => auth_header)
                 .post(uri, form: params)

      handle_http_errors(response)
    rescue HTTP::Error => e
      raise HTTPError, "HTTP request failed: #{e.message}"
    end

    def auth_header
      RequestHeader.new(:post, uri, params, {}).to_s
    end
  end
end
