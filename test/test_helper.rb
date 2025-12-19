# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# SimpleCov must be loaded BEFORE any application code
require 'simplecov'
require 'simplecov-lcov'

# Configure LCOV formatter for CI
SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.single_report_path = 'coverage/lcov.info'
end

# Use multiple formatters: HTML for local, LCOV for CI
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
                                                                  SimpleCov::Formatter::HTMLFormatter,
                                                                  SimpleCov::Formatter::LcovFormatter
                                                                ])

SimpleCov.start do
  add_filter '/test/'
  command_name 'Unit Tests'
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
