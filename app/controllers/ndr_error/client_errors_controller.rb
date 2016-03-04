module NdrError
  # Controller for receiving client errors
  class ClientErrorsController < ApplicationController
    def create
      exception        = JavascriptError.new(params[:client_error])
      ancillary        = {} # TODO: populate this as the middleware does
      fingerprint, log = NdrError.log(exception, ancillary, request)

      render json: {
        fingerprint: fingerprint.id,
        uuid: log.try(:id)
      }
    end
  end
end
