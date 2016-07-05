# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dependent_restrict/version'

Gem::Specification.new do |spec|
  spec.name          = "dependent_restrict"
  spec.version       = DependentRestrict::VERSION
  spec.description   = %q{This gem is not needed in Rails 3 as dependent => :raise is included in 3.0.}
  spec.summary       = %q{Add dependent restrict and improves functionality to ActiveRecord 2/3/4.x.}
  spec.authors       = ["Michael Noack"]
  spec.email         = ['support@travellink.com.au']
  spec.homepage      = 'http://github.com/sealink/dependent_restrict'

  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'activerecord', '>= 3.0', '< 6.0.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-rcov'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'travis'
end
