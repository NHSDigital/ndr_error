module NdrError
  # Controller for receiving client errors
  class ClientErrorsController < ApplicationController
    def create
      exception = JavascriptError.new(params[:client_error])

      error_params = params[:client_error]
      exception    = Exception.new(error_params.delete(:message))


      # TODO: this needs to be a separate message
      fingerprint, log = NdrError.log(exception, {}, request)

      # TODO: set error_class / message separately
      # TODO: strip 
      # TODO: don't do this here!
      log.update_attributes(
        url: request.env['HTTP_REFERER'],
        backtrace: (error_params.delete(:stack) || '').split("\n"),
        parameters_yml: error_params
      )

      render json: {
        fingerprint: fingerprint.id,
        uuid: log.try(:id)
      }
    end
  end
end
