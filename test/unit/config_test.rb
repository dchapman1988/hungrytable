require 'test_helper'

describe Hungrytable::Config do
  describe 'when the correct ENV vars are not set' do
    before do
      ENV['OT_PARTNER_ID']   = nil
      ENV['OT_OAUTH_KEY']    = nil
      ENV['OT_OAUTH_SECRET'] = nil
    end

    it 'raises a HungrytableError' do
      [:partner_id, :oauth_key, :oauth_secret].each do |meth|
        -> {Hungrytable::Config.send meth}.must_raise Hungrytable::HungrytableError
      end
    end
  end
  
  describe 'when the ENV vars are set' do
    before do
      ENV['OT_PARTNER_ID']   = 'foo'
      ENV['OT_OAUTH_KEY']    = 'bar'
      ENV['OT_OAUTH_SECRET'] = 'baz'
    end

    describe '.partner_id' do
      it 'returns the value for OT_PARTNER_ID' do
        Hungrytable::Config.partner_id.must_equal 'foo'
      end
    end

    describe '.oauth_key' do
      it 'returns the value for OT_OAUTH_KEY' do
        Hungrytable::Config.oauth_key.must_equal 'bar'
      end
    end

    describe '.oauth_secret' do
      it 'returns the value for OT_OAUTH_SECRET' do
        Hungrytable::Config.oauth_secret.must_equal 'baz'
      end
    end
  end
end
