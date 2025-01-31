$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'ndr_error/version'

# We list development dependencies for all Rails versions here.
# Rails version-specific dependencies can go in the relevant Gemfile.
# rubocop:disable Gemspec/DevelopmentDependencies
Gem::Specification.new do |s|
  s.name        = 'ndr_error'
  s.version     = NdrError::VERSION
  s.authors     = ['NCRS Development Team']
  s.email       = []
  s.summary     = 'Rails exception logging'
  s.description = 'Mountable engine for exception logging and fingerprinting'
  s.homepage    = 'https://github.com/NHSDigital/ndr_error'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'CHANGELOG.md', 'CODE_OF_CONDUCT.md',
                'MIT-LICENSE', 'Rakefile', 'README.md'] - ['.travis.yml']

  s.required_ruby_version = '>= 3.0'

  s.add_dependency 'rails', '>= 6.1', '< 7.3'

  # Support rails 6.1 with Ruby 3.1
  s.add_dependency 'net-imap'
  s.add_dependency 'net-pop'
  s.add_dependency 'net-smtp'

  s.add_dependency 'will_paginate'

  s.add_dependency 'ndr_ui', '>= 5.0'

  s.add_development_dependency 'pry'
  s.add_development_dependency 'puma'

  # Rails 6.1 and 7.0 do not support sqlite3 2.x; they specify gem "sqlite3", "~> 1.4"
  # in lib/active_record/connection_adapters/sqlite3_adapter.rb
  # cf. gemfiles/Gemfile.rails70
  s.add_development_dependency 'sqlite3'

  # Workaround build issue on GitHub Actions with ruby <= 3.1 when installing sass-embedded
  # gem version 1.81.0: NoMethodError: undefined method `parse' for #<Psych::Parser...>
  # https://bugs.ruby-lang.org/issues/19371
  s.add_development_dependency 'psych', '< 5'

  s.add_development_dependency 'mocha'
  s.add_development_dependency 'test-unit', '~> 3.0'

  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'ndr_dev_support', '>= 5.10'
  s.add_development_dependency 'simplecov'
end
# rubocop:enable Gemspec/DevelopmentDependencies
