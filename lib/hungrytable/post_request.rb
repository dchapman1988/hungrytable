module Hungrytable
  class PostRequest < Request
    private
    def auth_header
      Hungrytable::RequestHeader.new(:post, @uri, {}, {})
    end

    def make_request
      Curl::Easy.http_post(@uri, @params.to_query) do |curl|
        curl.headers['Authorization'] = auth_header
      end
    end

  end
end
