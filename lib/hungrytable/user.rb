module Hungrytable
  class User < ::Hungrytable::Base
    def login(options)
      parse_uri_options(:email, :password, options)
      uri = "/user/?pid=#{ENV['OT_PARTNER_ID']}&email=#{@email}&pwd=#{@password}"
      response = @access_token.get(uri)
      parse_json(response.body)
    end

  end
end
