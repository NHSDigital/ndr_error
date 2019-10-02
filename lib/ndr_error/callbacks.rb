module NdrError
  # contains logic for registering callbacks
  module Callbacks
    def self.extended(base)
      base.mattr_accessor :_after_log_callbacks
      base._after_log_callbacks = []
    end

    # Register callbacks that will be called after an exception
    # has been logged.
    #
    #   NdrError.after_log do |exception, fingerprint, log|
    #     # ...
    #   end
    #
    # Multiple callbacks can be registered.
    def after_log(&block)
      _after_log_callbacks << block
    end

    def run_after_log_callbacks(*args)
      _after_log_callbacks.each do |callback|
        callback.call(*args)
      end
    end
  end
end
