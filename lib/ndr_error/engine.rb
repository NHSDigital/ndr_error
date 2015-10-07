require 'active_support/all' # TODO: want duration

require 'will_paginate'
require 'will_paginate/array'

require 'jquery-rails'

module NdrError
  # Engine configuration goes here; hook in to the host app.
  class Engine < ::Rails::Engine
    isolate_namespace NdrError

    initializer 'ndr_error.assets.precompile' do |app|
      app.config.assets.precompile += %w(ndr_error.css ndr_error.js)
    end

    # Extract context filtering from the host application
    initializer 'ndr_error.set_default_filtering' do |app|
      NdrError.filtered_parameters.concat app.config.filter_parameters
    end
  end
end
