require 'simplecov-rcov'
require 'coveralls'
require 'coverage/kit'
minimum_coverage = ActiveRecord::VERSION::MAJOR >= 4 ? 92.2 : 86.6
Coverage::Kit.setup(minimum_coverage: minimum_coverage)
