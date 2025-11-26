# frozen_string_literal: true

require_relative 'lib/hungrytable/version'

Gem::Specification.new do |s|
  s.name        = 'hungrytable'
  s.version     = Hungrytable::VERSION
  s.authors     = ['David Chapman']
  s.email       = ['dchapman1988@gmail.com']
  s.homepage    = 'https://github.com/dchapman1988/hungrytable'
  s.summary     = 'Ruby client for the OpenTable REST API'
  s.description = 'A Ruby gem providing a clean, object-oriented interface to interact with the OpenTable REST API ' \
                  'for restaurant reservations'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.0.0'
  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/dchapman1988/hungrytable/issues',
    'changelog_uri' => 'https://github.com/dchapman1988/hungrytable/blob/master/RELEASE_NOTES.md',
    'source_code_uri' => 'https://github.com/dchapman1988/hungrytable',
    'rubygems_mfa_required' => 'true'
  }

  s.files = Dir['lib/**/*', 'LICENSE', 'README.md', 'RELEASE_NOTES.md']
  s.require_paths = ['lib']

  # Runtime dependencies - modernized versions
  s.add_dependency 'activesupport', '>= 6.0', '< 8.0'
  s.add_dependency 'http', '~> 5.0' # Modern HTTP client replacing curb
  s.add_dependency 'oauth', '~> 1.1' # Dedicated OAuth library

  # Development dependencies are specified in Gemfile
end
