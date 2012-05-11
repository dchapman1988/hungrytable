module Hungrytable
  class User < ::Hungrytable::Base
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

    def login(options)
      parse_uri_options(:email, :password, options)
      uri = "/user/?pid=#{ENV['OT_PARTNER_ID']}&email=#{@email}&pwd=#{@password}"
      response = @access_token.get(uri)
      parse_json(response.body)
    end

  end
end
