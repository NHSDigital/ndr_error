module NdrError
  # Controller for receiving client errors
  class ClientErrorsController < ApplicationController
    def create
      Rails.logger.info(params.inspect)

      exception  = Exception.new(params[:message])
      parameters = {}

      # TODO: this needs to be a separate message
      fingerprint, log = NdrError.log(exception, parameters, request)

      # TODO: set error_class / message separately
      # TODO: strip 
      # TODO: don't do this here!
      log.update_attributes(
        url: params[:path],
        backtrace: (params[:stack] || '').split("\n")
      )

      render json: {
        fingerprint: fingerprint.id,
        uuid: log.try(:id)
      }
    end
  end
end
