# frozen_string_literal: true

SimpleCov.configure do
  add_filter '/test/'
  add_filter '/spec/'
  add_filter '/.bundle/'
  add_filter '/vendor/'

  minimum_coverage 90

  # Track all files in lib/
  track_files 'lib/**/*.rb'
end
