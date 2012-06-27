module Hungrytable
  class Request
    def initialize uri, params={}
      @uri    = Hungrytable::Config.base_url << uri
      @params = params
    end

    def parsed_response
      JSON.parse(response)
    end

    private
    def response
      @response ||= make_request.body_str
    end
  end
end
