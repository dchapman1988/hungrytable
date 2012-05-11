module Hungrytable
  class Restaurant < ::Hungrytable::Base
    def initialize
      validate_environment_variables

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
      uri = "/restaurant/?pid=#{ENV['OT_PARTNER_ID']}&rid=#{restaurant_id}"
      response = @access_token.get(uri)
      parse_json(response.body)
    end

    def search(options)
      parse_uri_options(:restaurant_id, :date_time, :party_size, options)
      uri = "/table/?pid=#{ENV['OT_PARTNER_ID']}&st=0&rid=#{@restaurant_id}&dt=#{@date_time}&ps=#{@party_size}"
      response = @access_token.get(uri)
      parse_json(response.body)
    end
  end
end
