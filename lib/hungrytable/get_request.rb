module Hungrytable
  class GetRequest < Request
    private
    def auth_header
      Hungrytable::RequestHeader.new(:get, @uri, {}, {})
    end

    def make_request
      Curl::Easy.perform(@uri) do |curl|
        curl.headers['Authorization'] = auth_header
      end
    end

  end
end
