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

# Capybara configuration:
require 'capybara/rails'
require 'capybara/poltergeist'

require 'capybara-screenshot'
if defined?(MiniTest)
  require 'capybara-screenshot/minitest'
else
  require 'capybara-screenshot/testunit'
end

Capybara.register_driver :poltergeist do |app|
  options = {
    # debug: true, # Uncomment for more verbose
    inspector: true, # DEBUGGING suppport.
    phantomjs_options: ['--proxy-type=none'],
    js_errors: false,
    timeout: 60
  }

  Capybara::Poltergeist::Driver.new(app, options)
end

# Ensure that we are always using poltergeist:
Capybara.default_driver    = :poltergeist
Capybara.javascript_driver = :poltergeist

# Save screenshots to tmp/capybara/... on integration test error/failure:
Capybara::Screenshot.register_driver(:poltergeist) do |driver, path|
  driver.render(path, full: true) # Take full-height screenshots
end

module Capybara
  class Session
    # Variant of Capybara's #within_window method, that doesn't return
    # to the preview window on an exception. This allows us to screenshot
    # a popup automatically if a test errors/fails whilst it has focus.
    def within_screenshot_compatible_window(window_or_proc)
      original = current_window

      case window_or_proc
      when Capybara::Window
        switch_to_window(window_or_proc) unless original == window_or_proc
      when Proc
        switch_to_window { window_or_proc.call }
      else
        fail ArgumentError, 'Unsupported window type!'
      end

      scopes << nil
      yield
      @scopes.pop
      switch_to_window(original)
    end
  end

  module CustomDSL
    delegate :within_screenshot_compatible_window, to: :page
  end
end

module ActionDispatch
  class IntegrationTest
    # Make the Capybara DSL available in all integration tests
    include Capybara::DSL
    include Capybara::CustomDSL

    include Capybara::Screenshot::MiniTestPlugin if defined?(MiniTest)
  end
end

# Capybara starts another rails application in a new thread
# to test against. For transactional fixtures to work, we need
# to share the database connection between threads.
#
# Multiple connections:
#   We authenticate users by using their credentials to attempt
#   a database connection. Normally, when a user's connection is
#   added to the pool, any other connections of theirs are
#   automatically purged, to prevent spurious simultaneous logins.
#   In the (integration) test environment, this would purge the
#   primary test connection, so this behaviour is disabled.
#
# Monkey patch from: https://gist.github.com/josevalim/470808
#
module ActiveRecord
  class Base
    mattr_accessor :shared_connection

    def self.connection
      shared_connection || retrieve_connection
    end
  end
end
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

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
