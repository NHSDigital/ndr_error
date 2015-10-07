require 'simplecov'
SimpleCov.start

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)
require 'rails/test_help'

require 'mocha/mini_test'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.method_defined?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path('../fixtures', __FILE__)
end

module ActiveSupport
  # Add additional helper methods for creating logged errors
  class TestCase
    def create_fingerprint(digest = nil)
      digest ||= Digest::MD5.hexdigest SecureRandom.base64(32)
      NdrError::Fingerprint.find_or_create_by_id(digest)
    end

    def simulate_raise(klass, message, trace)
      exception = klass.new(message)
      exception.set_backtrace(trace)
      _print, error = NdrError.log(exception, { user_id: 'Bob Jones' }, nil)
      error
    end

    def build_custom_error(klass, message, trace)
      exception = klass.new(message)
      exception.set_backtrace(trace)

      error = NdrError::Log.new({})
      error.register_exception(exception)
      error.user_id = 'John Smith'
      error.stubs(valid?: true)

      error
    end
  end
end
