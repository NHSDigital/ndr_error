require 'simplecov'
SimpleCov.start

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/config/environment.rb', __FILE__)
require 'rails/test_help'

require 'mocha/mini_test'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.method_defined?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path('../fixtures', __FILE__)
end

require 'database_cleaner'
DatabaseCleaner.strategy = :deletion

class ActionDispatch::IntegrationTest
  # Don't wrap each test case in a transaction:
  if respond_to?(:use_transactional_fixtures=)
    self.use_transactional_fixtures = false
  else
    self.use_transactional_tests = false
  end

  # Instead, insert fixtures afresh between each test:
  setup    { DatabaseCleaner.start }
  teardown { DatabaseCleaner.clean }
end

# Include all capybara + poltergeist config
require 'ndr_dev_support/integration_testing'

module ActiveSupport
  # Add additional helper methods for creating logged errors
  class TestCase
    def with_config(key, value)
      original_value = NdrError.send(key)
      NdrError.send("#{key}=", value)
      yield
    ensure
      NdrError.send("#{key}=", original_value)
    end

    def create_fingerprint(digest = nil)
      digest ||= Digest::MD5.hexdigest SecureRandom.base64(32)
      NdrError::Fingerprint.find_or_create_by_id(digest)
    end

    def simulate_raise(klass, message, trace, context = {})
      exception = klass.new(message)
      exception.set_backtrace(trace)
      _print, error = NdrError.log(exception, context, nil)
      error
    end

    def build_custom_error(klass, message, trace)
      exception = klass.new(message)
      exception.set_backtrace(trace)

      error = NdrError::Log.new({})
      error.register_exception(exception)
      error.stubs(valid?: true)

      error
    end
  end
end
