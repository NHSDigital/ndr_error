module NdrError
  # Module to contain helpers for logging
  module Logging
    # Which attributes can be populated when manually logging an exception:
    ANCILLARY_ATTRS_WHITELIST = [:user_id, :user_roles, :svn_revision].freeze

    # Log the given `exception`.
    def log(exception, ancillary_data, request_object)
      return log_client_error(exception, ancillary_data, request_object) if exception.client?

      log = initialize_log(ancillary_data)
      log.register_exception(exception)
      log.register_request(request_object)

      print = Fingerprint.find_or_create_by_id(log.md5_digest)
      error = print.store_log(log)

      [print, error]
    end

    private

    # Client errors are logged / fingerprinted differently
    def log_client_error(exception, ancillary_data, request_object)
      
    end

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
