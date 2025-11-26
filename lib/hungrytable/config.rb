# frozen_string_literal: true

module Hungrytable
  # Configuration module for Hungrytable
  module Config
    class << self
      attr_writer :partner_id, :oauth_key, :oauth_secret, :base_url

      def partner_id
        @partner_id ||= ENV.fetch('OT_PARTNER_ID') do
          raise ConfigurationError, 'OT_PARTNER_ID must be set via ENV or Config.partner_id='
        end
      end

      def oauth_key
        @oauth_key ||= ENV.fetch('OT_OAUTH_KEY') do
          raise ConfigurationError, 'OT_OAUTH_KEY must be set via ENV or Config.oauth_key='
        end
      end

      def oauth_secret
        @oauth_secret ||= ENV.fetch('OT_OAUTH_SECRET') do
          raise ConfigurationError, 'OT_OAUTH_SECRET must be set via ENV or Config.oauth_secret='
        end
      end

      def base_url
        @base_url ||= 'https://secure.opentable.com/api/otapi_v3.ashx'
      end

      # Reset configuration to defaults (useful for testing)
      def reset!
        @partner_id = nil
        @oauth_key = nil
        @oauth_secret = nil
        @base_url = nil
      end

      # Check if all required configuration is present
      def valid?
        partner_id && oauth_key && oauth_secret
        true
      rescue ConfigurationError
        false
      end
    end
  end
end
