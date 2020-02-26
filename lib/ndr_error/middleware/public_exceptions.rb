module NdrError
  module Middleware
    # Middleware for logging exceptions, can be used as exception_app for Rails.
    class PublicExceptions < NdrError::Recorder
      def initialize(public_path)
        super ::ActionDispatch::PublicExceptions.new(public_path)
      end
    end
  end
end
