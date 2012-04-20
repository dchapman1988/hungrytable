# -*- encoding: utf-8 -*-
require File.expand_path('../lib/hungrytable/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["David Chapman"]
  gem.email         = ["david@isotope11.com"]
  gem.description   = %q{Interact with OpenTable's REST API}
  gem.summary       = %q{The purpose of this gem is to be able to interact with OpenTable's REST API.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "hungrytable"
  gem.require_paths = ["lib"]
  gem.version       = Hungrytable::VERSION
end
