require 'ndr_error/engine'

require 'ndr_error/backtrace_compression'
require 'ndr_error/finder'
require 'ndr_error/fuzzing'
require 'ndr_error/logging'
require 'ndr_error/uuid_builder'

# Configuration for NdrError + convienence methods.
module NdrError
  extend Finder
  extend Logging

  # Allows the host to define a parent model for the Log and
  # Fingerprint classes. Defaults to ActiveRecord::Base.
  mattr_accessor :abstract_model_class
  self.abstract_model_class = ActiveRecord::Base

  # Callable object, that by default is called by the NdrError::Middleware::PublicExceptions
  # middleware (with the request and exception objects) when an exception is handled.
  # Returning a "falsey" value will prevent the exception from being logged.
  mattr_accessor :exception_app_callback
  self.exception_app_callback = ->(_request, _exception) { true }

  # Callable object (called with controller context) that is used to check
  # if the current user is authenticated with the host app.
  mattr_accessor :check_current_user_authentication
  self.check_current_user_authentication = nil # Must be configured by the host app

  # Callable object (called with controller context) that is used to check
  # update/destroy permissions of the current session. Defaults to true.
  mattr_accessor :check_current_user_permissions
  self.check_current_user_permissions = ->(_context) { true }

  # The name of the error_log column that corresponds to the user.
  mattr_accessor :user_column
  self.user_column = nil # Must be configured by the host app

  # A callable object that returns a hash of current context (e.g. user).
  # The host app must at least set the :user_column to a value. If bundled
  # NdrError::Middleware::PublicExceptions middleware is used, it is called
  # with the Rack request object.
  mattr_accessor :log_parameters
  self.log_parameters = ->(_request) { {} }

  # Request parameters that we should not be capturing as part of the error context.
  mattr_accessor :filtered_parameters
  self.filtered_parameters = [] # Populated by a railtie

  # Callable object, which will give the app server hostname:
  mattr_accessor :hostname_identifier
  self.hostname_identifier = -> { 'unknown host' }

  # Callable object, which will give information about the current data
  mattr_accessor :database_identifier
  self.database_identifier = -> { 'unknown database' }

  # Callable object, which will return the current database time.
  mattr_accessor :database_time_checker
  self.database_time_checker = -> { nil }

  # The number of logs that are kept before only a counter is incremented
  mattr_accessor :fingerprint_threshold
  self.fingerprint_threshold = 100

  # How long to logs remain soft-deleted, before they are cleaned up?
  mattr_accessor :log_grace_period
  self.log_grace_period = 90.days

  # Should the captured backtrace be compressed?
  mattr_accessor :compress_backtrace
  self.compress_backtrace = true

  # Callable objects, which fuzz an Exception's message for hashing.
  mattr_accessor :description_fuzzers
  self.description_fuzzers = [
    ->(desc) { desc.sub('...[truncated]', '') }, # column length truncation
    ->(desc) { desc.gsub(/(undefined method `[^']*' for )(.*)/, '\1') }, # obj details
    ->(desc) { desc.gsub(/([0-9a-fA-F]*\d?[0-9a-fA-F]*)/, '') } # remove hex
  ]

  # Optionally, a regular expression against which the URL of
  # fingerprint tickets can be validated.
  mattr_accessor :ticket_url_format
  self.ticket_url_format = nil

  # Help Rails find the table of any
  # namespaced modules.
  def self.table_name_prefix
    'error_'
  end

  # Rails 5 uses versioned migrations (required as of 5.1). This helper method returns an
  # appropriate migration superclass for the Rails version of the host application. Note that the
  # 4.2 compatability layer is targetted since all the bundled migrations were written prior to
  # Rails 5.
  def self.migration_class
    Rails::VERSION::MAJOR < 5 ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  end
end
