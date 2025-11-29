# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.start do
  add_filter '/test/'

  formatter SimpleCov::Formatter::CoberturaFormatter if ENV['CI']
end

require 'minitest/autorun'
require 'minitest/reporters'
require 'mocha/minitest'
require 'webmock/minitest'
require 'hungrytable'

# Use spec reporter for better output
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# Disable real HTTP requests in tests
WebMock.disable_net_connect!(allow_localhost: true)

# Test helper methods
module TestHelpers
  def setup_config
    Hungrytable::Config.reset!
    Hungrytable::Config.partner_id = 'test_partner_id'
    Hungrytable::Config.oauth_key = 'test_oauth_key'
    Hungrytable::Config.oauth_secret = 'test_oauth_secret'
  end

  def teardown_config
    Hungrytable::Config.reset!
  end
end

# Include helpers in all tests
class Minitest::Test
  include TestHelpers
end
