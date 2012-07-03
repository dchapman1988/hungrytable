require 'minitest/autorun'
require 'minitest/reporters'

require 'ostruct'
require 'pry'
require 'webmock'
include WebMock::API


# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Set up minitest
MiniTest::Unit.runner = MiniTest::SuiteRunner.new
MiniTest::Unit.runner.reporters << MiniTest::Reporters::SpecReporter.new
if ENV['JENKINS']
  MiniTest::Unit.runner.reporters << MiniTest::Reporters::JUnitReporter.new
end

require 'mocha'
require File.expand_path("../../lib/hungrytable.rb", __FILE__)
