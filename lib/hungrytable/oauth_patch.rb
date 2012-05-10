require 'oauth'
module OAuth::Client
  class Helper
    def oauth_parameters
      {   
        'oauth_body_hash'        => options[:body_hash],
        'oauth_callback'         => options[:oauth_callback],
        'oauth_consumer_key'     => options[:consumer].key,
        'oauth_token'            => options[:token] ? options[:token].token : '', 
        'oauth_signature_method' => options[:signature_method],
        'oauth_timestamp'        => timestamp,
        'oauth_nonce'            => nonce,
        'oauth_verifier'         => options[:oauth_verifier],
        'oauth_version'          => (options[:oauth_version] || '1.0'),
        'oauth_session_handle'   => options[:oauth_session_handle]
      }.reject { |k,v| v.to_s == "" && k.to_s != 'oauth_token' }
    end 
  end 
end
