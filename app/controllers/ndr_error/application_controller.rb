module NdrError
  # Global controller logic
  class ApplicationController < ActionController::Base
    before_action :authenticate

    # Ensure Rails doesn't find any host layouts first:
    layout 'ndr_error/ndr_error'

    helper NdrUi::BootstrapHelper

    private

    def authenticate
      return if NdrError.check_current_user_authentication.call(self)

      flash[:error] = 'You are not authenticated.'
      redirect_to main_app.url_for('/')
    end

    # Split out delimited search terms of more than 3 characters in length.
    def extract_keywords(query, split_on_space = true)
      splitter = split_on_space ? %r{[,;\\/\s]+} : %r{[,;\\/]+}
      (query || '').split(splitter).reject { |k| k.length < 3 }
    end
  end
end
