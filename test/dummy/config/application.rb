require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

module Dummy
  # Dummy application to host and test the engine
  class Application < Rails::Application
    # Initialize configuration defaults for current Rails version.
    config.load_defaults Rails.version.match(/[0-9]*[.][0-9]*/).to_s # e.g. 7.2

    # Rails 6.1 default
    # TODO: Some of our tests fail when this Rails 6.1 default is removed
    config.active_support.executor_around_test_case = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += %i[password dummy_app_test_sensitive_parameter]

    # Configure the ActionDispatch::ShowExceptions middleware to use NdrError's exception logger.
    config.exceptions_app = NdrError::Recorder.new(::ActionDispatch::PublicExceptions.new(Rails.public_path))
  end
end
