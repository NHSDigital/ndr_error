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

  s.required_ruby_version = '>= 2.2'

  s.add_dependency 'rails', '>= 3.2.22', '< 6'
  s.add_dependency 'will_paginate'

  s.add_dependency 'jquery-rails'
  s.add_dependency 'sass-rails'

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'pry'

  s.add_development_dependency 'test-unit', '~> 3.0'
  s.add_development_dependency 'mocha'

  s.add_development_dependency 'capybara'
  s.add_development_dependency 'capybara-screenshot'
  s.add_development_dependency 'poltergeist', '>= 1.8.0'

  s.add_development_dependency 'rubocop', '0.36.0'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'ndr_dev_support', '~> 1.1', '>= 1.1.3'
end
