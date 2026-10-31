# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shout/version'

Gem::Specification.new do |gem|
  gem.name          = "shout-ruby-ffi"
  gem.version       = Shout::VERSION
  gem.authors       = ["Roel van Dijk"]
  gem.email         = ["roel@rustradio.org"]
  gem.description   = %q{Ruby FFI wrapper around libshout for streaming to Icecast servers.}
  gem.summary       = %q{Easily connect and stream audio/metadata to Icecast using libshout.}
  gem.homepage      = "http://github.com/rdvdijk/shout-ruby-ffi"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "ffi"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "simplecov", "~> 0.22"
  gem.add_development_dependency "simplecov-lcov", "~> 0.8"
end
