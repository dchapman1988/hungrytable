module Hungrytable
  class Restaurant < ::Hungrytable::Base
    def initialize
      @consumer = OAuth::Consumer.new(
        ENV['OT_OAUTH_KEY'],
        ENV['OT_OAUTH_SECRET'],
        realm: 'http://www.opentable.com/',
        site: 'https://secure.opentable.com/api/otapi_v2.ashx',
        request_token_path: '',
        authorize_path: '',
        access_token_path: '',
        oauth_token: '',
        oauth_version: '1.0',
        http_method: :get
      )
      
      @access_token = OAuth::AccessToken.new(@consumer)
    end

    def get_details(restaurant_id)
      response = @access_token.get("/restaurant/?pid=#{ENV['OT_PARTNER_ID']}&rid=#{restaurant_id}")
      parse_json(response.body)
    end

    def search
    end
  end
end
