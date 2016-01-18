$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'ndr_error/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'ndr_error'
  s.version     = NdrError::VERSION
  s.authors     = ['NCRS Development Team']
  s.email       = []
  s.summary     = 'Rails exception logging'
  s.description = 'Mountable engine for exception logging and fingerprinting'
  s.homepage    = 'https://github.com/PublicHealthEngland/ndr_error'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['MIT-LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'rails', '>= 3.2.22', '< 5'
  s.add_dependency 'will_paginate'

  s.add_dependency 'jquery-rails'
  s.add_dependency 'sass-rails'

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'pry'

  s.add_development_dependency 'test-unit', '~> 3.0'
  s.add_development_dependency 'mocha'

  s.add_development_dependency 'rubocop', '0.36.0'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'ndr_support', '~> 3.2', '>= 3.2.1'
end
