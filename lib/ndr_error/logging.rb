module NdrError
  # Module to contain helpers for logging
  module Logging
    # Which attributes can be populated when manually logging an exception:
    ANCILLARY_ATTRS_WHITELIST = [:user_id, :user_roles, :svn_revision].freeze

    # Log the given `exception`.
    def log(exception, ancillary_data, request_object)
      # Capture details about a parent exception, if possible:
      parent_print, = exception.cause && log(exception.cause, ancillary_data, request_object)

      log = initialize_log(ancillary_data)
      log.register_exception(exception)
      log.register_request(request_object)
      log.register_parent(parent_print)

      print = Fingerprint.find_or_create_by_id(log.md5_digest)
      print.causal_error_fingerprint = parent_print
      error = print.store_log(log)

      [print, error]
    end

    def monitor(ancillary_data: {}, request: nil, swallow: false)
      yield
    rescue Exception => exception # rubocop:disable Lint/RescueException
      data = log(exception, ancillary_data, request)
      swallow ? data : raise(exception)
    end

    private

    # Manual attribute whitelisting:
    def initialize_log(ancillary_data)
      Log.new.tap do |log|
        ancillary_data.symbolize_keys.each do |key, value|
          fail "Mass-assigning #{key} is forbidden!" unless ANCILLARY_ATTRS_WHITELIST.include?(key)

          if ActiveRecord::Base.respond_to?(:protected_attributes)
            log.assign_attributes({ key => value }, without_protection: true)
          else
            log.assign_attributes(key => value)
          end
        end
      end
    end
  end
end
