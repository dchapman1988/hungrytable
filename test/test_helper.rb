# Set up simplecov
require 'simplecov'
require 'simplecov-rcov'
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter

require 'minitest/autorun'
require 'minitest/reporters'

require 'ostruct'
require 'pry'
require 'vcr'

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Set up minitest
MiniTest::Unit.runner = MiniTest::SuiteRunner.new
MiniTest::Unit.runner.reporters << MiniTest::Reporters::SpecReporter.new
if ENV['JENKINS']
  MiniTest::Unit.runner.reporters << MiniTest::Reporters::JUnitReporter.new
end

# Load the app
require File.expand_path("../../lib/hungrytable.rb", __FILE__)

# Record API Results via VCR
VCR.configure do |c|
  c.cassette_library_dir = 'vcr_cassettes'
end
