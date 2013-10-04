module Hungrytable
  module Config
    extend self

    def partner_id
      ENV['OT_PARTNER_ID'] || config_error('OT_PARTNER_ID')
    end

    def oauth_key
      ENV['OT_OAUTH_KEY'] || config_error('OT_OAUTH_KEY')
    end

    def oauth_secret
      ENV['OT_OAUTH_SECRET'] || config_error('OT_OAUTH_SECRET')
    end

    def base_url
      'https://secure.opentable.com/api/otapi_v3.ashx'
    end

    private
    def config_error var
      raise HungrytableError, "ENV variable #{var} must be set."
    end
  end
end
