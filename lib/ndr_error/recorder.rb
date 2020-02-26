module NdrError
  # Middleware for logging exceptions, can be used as exception_app for Rails.
  class Recorder
    # the parent_handler could be the host app's routes, or an instance
    # of ActionDispatch::PublicExceptions, or any other middleware.
    def initialize(parent_handler)
      @parent_handler = parent_handler
    end

    def call(env)
      rescuing_everything do
        request   = ActionDispatch::Request.new(env)
        exception = env['action_dispatch.exception']

        # "falsey" callback return value allows logging to be skipped
        log_exception(request, exception) if run_exception_callback(request, exception)
      end

      @parent_handler.call(env)
    end

    private

    def log_exception(request, exception)
      parameters = NdrError.log_parameters.call(request)
      _fingerprint, _log = NdrError.log(exception, parameters, request)
    end

    def run_exception_callback(request, exception)
      NdrError.exception_app_callback.call(request, exception)
    end

    # Unhandled exceptions with logging could terminate the web server!
    def rescuing_everything
      yield
    rescue Exception => exception # rubocop:disable Lint/RescueException
      # "Log the exception caused by logging an exception..."
      Rails.logger.warn <<-MSG.strip_heredoc
        NdrError failed to log an exception!
          logging error class:   #{exception.class}
          logging error message: #{exception.message}
      MSG
    end
  end
end
