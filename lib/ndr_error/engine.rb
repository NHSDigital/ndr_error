require 'active_support/all' # TODO: want duration

require 'will_paginate'
require 'will_paginate/array'

require 'jquery-rails'

module NdrError
  # Engine configuration goes here; hook in to the host app.
  class Engine < ::Rails::Engine
    isolate_namespace NdrError

    # Hook into host app's asset pipeline
    initializer 'ndr_error.assets.precompile' do |app|
      app.config.assets.precompile += %w[
        ndr_error/ndr_error.css
        ndr_error/ndr_error.js
        ndr_error/bootstrap/glyphicons-halflings-regular*
      ]
    end

    # Extract context filtering from the host application
    initializer 'ndr_error.set_default_filtering' do |app|
      NdrError.filtered_parameters.concat app.config.filter_parameters
    end

    # Ensure helpers remain visible in development...
    # See:
    #
    #   * http://stackoverflow.com/questions/{9809787,26645033,12191822}
    #   * https://robots.thoughtbot.com/tips-for-writing-your-own-rails-engine
    #
    config.to_prepare do
      ApplicationController.helper(ApplicationHelper)
    end
  end
end
