# frozen_string_literal: true

require 'test_helper'

class ConfigTest < Minitest::Test
  def setup
    Hungrytable::Config.reset!
  end

  def teardown
    Hungrytable::Config.reset!
    ENV.delete('OT_PARTNER_ID')
    ENV.delete('OT_OAUTH_KEY')
    ENV.delete('OT_OAUTH_SECRET')
  end

  def test_partner_id_from_env
    ENV['OT_PARTNER_ID'] = 'env_partner_id'

    assert_equal 'env_partner_id', Hungrytable::Config.partner_id
  end

  def test_oauth_key_from_env
    ENV['OT_OAUTH_KEY'] = 'env_oauth_key'

    assert_equal 'env_oauth_key', Hungrytable::Config.oauth_key
  end

  def test_oauth_secret_from_env
    ENV['OT_OAUTH_SECRET'] = 'env_oauth_secret'

    assert_equal 'env_oauth_secret', Hungrytable::Config.oauth_secret
  end

  def test_partner_id_direct_assignment
    Hungrytable::Config.partner_id = 'direct_partner_id'

    assert_equal 'direct_partner_id', Hungrytable::Config.partner_id
  end

  def test_oauth_key_direct_assignment
    Hungrytable::Config.oauth_key = 'direct_oauth_key'

    assert_equal 'direct_oauth_key', Hungrytable::Config.oauth_key
  end

  def test_oauth_secret_direct_assignment
    Hungrytable::Config.oauth_secret = 'direct_oauth_secret'

    assert_equal 'direct_oauth_secret', Hungrytable::Config.oauth_secret
  end

  def test_base_url_default
    assert_equal 'https://secure.opentable.com/api/otapi_v3.ashx', Hungrytable::Config.base_url
  end

  def test_base_url_can_be_overridden
    Hungrytable::Config.base_url = 'https://custom.url'

    assert_equal 'https://custom.url', Hungrytable::Config.base_url
  end

  def test_missing_partner_id_raises_error
    assert_raises(Hungrytable::ConfigurationError) do
      Hungrytable::Config.partner_id
    end
  end

  def test_missing_oauth_key_raises_error
    assert_raises(Hungrytable::ConfigurationError) do
      Hungrytable::Config.oauth_key
    end
  end

  def test_missing_oauth_secret_raises_error
    assert_raises(Hungrytable::ConfigurationError) do
      Hungrytable::Config.oauth_secret
    end
  end

  def test_valid_returns_true_when_all_config_present
    ENV['OT_PARTNER_ID'] = 'test'
    ENV['OT_OAUTH_KEY'] = 'test'
    ENV['OT_OAUTH_SECRET'] = 'test'

    assert_predicate Hungrytable::Config, :valid?
  end

  def test_valid_returns_false_when_config_missing
    refute_predicate Hungrytable::Config, :valid?
  end

  def test_reset_clears_all_config
    Hungrytable::Config.partner_id = 'test'
    Hungrytable::Config.oauth_key = 'test'
    Hungrytable::Config.oauth_secret = 'test'

    Hungrytable::Config.reset!

    refute_predicate Hungrytable::Config, :valid?
  end

  def test_configure_block
    Hungrytable.configure do |config|
      config.partner_id = 'block_partner_id'
      config.oauth_key = 'block_oauth_key'
      config.oauth_secret = 'block_oauth_secret'
    end

    assert_equal 'block_partner_id', Hungrytable::Config.partner_id
    assert_equal 'block_oauth_key', Hungrytable::Config.oauth_key
    assert_equal 'block_oauth_secret', Hungrytable::Config.oauth_secret
  end
end
