# rubocop:disable Metrics/ClassLength
module NdrError
  # Stores instances of logs. Child of NdrError::Fingerprint.
  # Log records may be purged, whereas fingerprints are
  # designed to be eternally persisted.
  #
  class Log < ActiveRecord::Base
    include NdrError::BacktraceCompression
    include NdrError::Fuzzing
    include NdrError::UuidBuilder

    # Migrate away from host-specific column name:
    unless :user_id == NdrError.user_column
      alias_attribute :user_id, NdrError.user_column
    end

    self.primary_key = 'error_logid'

    belongs_to :error_fingerprint,
               class_name:  'NdrError::Fingerprint',
               foreign_key: 'error_fingerprintid'

    default_scope do
      scope = where("(status is null) or (status not like 'deleted%')")
      scope.order('created_at DESC, error_logid DESC')
    end

    validates :error_fingerprintid, presence: true
    validates :description, presence: true

    before_create :calculate_md5_digest
    before_create :register_system
    before_create :set_uuid_primary_key

    def self.text_columns
      user_column = NdrError.user_column.to_s
      %w(error_class description).tap do |text_columns|
        # Allow searching of `user_column` if it is textual:
        if :string == columns_hash[user_column].try(:type)
          text_columns << user_column
        else
          fail SecurityError, "Column '#{user_column}' not found!"
        end
      end
    end

    def self.filter_by_keywords(keywords)
      fragment   = text_columns.map { |column| "lower(#{column}) LIKE lower(:key)" }.join(' OR ')
      name_match = keywords.map { |part| sanitize_sql([fragment, key: "%#{part}%"]) }.join(' OR ')

      where(name_match)
    end

    # Make explicit when circumventing the default scope
    def self.including_deleted_logs(&block)
      unscoped(&block)
    end

    # Deletes all those errors that have been flagged for
    # deletion and whose soft-delete grace period has ended.
    #
    # Returns true if any records were deleted.
    def self.perform_cleanup!
      records = including_deleted_logs do
        where("status like 'deleted%'")
      end

      destroys = records.map do |record|
        stamp_string = record.status.sub(/^[^\d]+/, '')
        record.destroy if Time.zone.parse(stamp_string) < NdrError.log_grace_period.ago
      end

      destroys.any?
    end

    # Finds gets all errors that share an MD5 hash
    # (including _error_).
    def self.similar_to(error)
      error.error_fingerprint.error_logs
    end

    # Gets similar errors.
    def similar_errors(include_self = false)
      unless @_similar
        @_similar = {}
        @_similar[true]  = self.class.similar_to(self)
        @_similar[false] = @_similar[true] - [self]
      end

      @_similar[include_self ? true : false]
    end

    # Returns the previous historical occurence,
    # or nil if there wasn't one.
    def previous
      lookup = similar_errors(true).reverse
      index  = lookup.index(self)
      lookup[0...index].last
    end

    # Returns the next historical occurence,
    # or nil if there hasn't been one.
    def next
      lookup = similar_errors(true)
      index  = lookup.index(self)
      lookup[0...index].last
    end

    # Performs a soft-delete of this log.
    def flag_as_deleted!(time = Time.current)
      update_attribute(:status, "deleted at #{time.to_s(:db)}")
    end

    # Copy across attributes from the exception object.
    def register_exception(exception)
      self.error_class = exception.class.to_s
      self.backtrace   = exception.backtrace
      self.description = description_from(exception.message)

      self.parameters_yml = exception.metadata if client_error?
    end

    # Stores parameters from the given _request_ object
    # as YAML. Will attempt to store as many as possible
    # of the parameters in the available 4000 chars.
    def register_request(request)
      extract_request_params(request) unless client_error?
      extract_request_attributes(request)
    end

    # Store as much of `params' as possible in
    # the YAML parameters column.
    def parameters_yml=(params)
      yml_dump = {}.to_yaml
      parts    = params.sort_by { |_k, v| v.inspect.length }

      # `parts' was sorted by length so that we
      # can capture as many different parameters
      # as possible in the given column space:
      (1..parts.length).each do |length|
        sub_hash = Hash[parts.first(length)]
        sub_yml  = sub_hash.to_yaml

        break if sub_yml.length >= 4000
        yml_dump = sub_yml
      end

      self[:parameters_yml] = yml_dump
    end

    alias set_parameters_yml parameters_yml=

    # Returns the params hash associated
    # with the request.
    def parameters
      YAML.safe_load(parameters_yml, [Symbol])
    end

    # Formats error to be like the ruby error.
    def error_string
      [error_class, description].compact.join(': ')
    end

    # Returns true if clock drift of more than 3
    # seconds was present at the time of the error.
    def clock_drift?
      clock_drift && clock_drift >= 3.0
    end

    # Creates (and caches) the md5 of this error,
    # which is used to match to similar errors.
    def md5_digest
      @_digest ||= fuzz(description, backtrace)
    end

    # Allow the digest to be set manually if so desired.
    def md5_digest=(digest)
      @_digest = digest
    end

    def client_error?
      error_class == 'NdrError::JavascriptError'
    end

    private

    # For the given `request' object, return the
    # parameters in a form suitable for logging.
    def extract_request_params(request)
      params = {}

      if request
        sources = [:parameters, :request_parameters, :query_parameters]
        sources.inject(params) { |a, e| a.merge! request.send(e) }

        # Redact any sensitive parameters:
        params.each do |name, _value|
          params[name] = '[FILTERED]' if unloggable?(name)
        end
      end

      self.parameters_yml = params
    end

    def extract_request_attributes(request)
      return unless request

      uri = request.env[client_error? ? 'HTTP_REFERER' : 'REQUEST_URI']

      self.port       = request.env['SERVER_PORT']
      self.ip         = "#{request.env['REMOTE_ADDR']}/#{request.remote_ip}"
      self.url        = "#{uri} (on #{request.host})"
      self.user_agent = request.env['HTTP_USER_AGENT']
    end

    def description_from(message)
      return 'No Description available' if message.blank?
      message.size < 4000 ? message : "#{message[0..4000 - 15]}...[truncated]"
    end

    # Returns true if the parameter should not be captured:
    def unloggable?(parameter)
      NdrError.filtered_parameters.any? do |filter|
        case filter
        when Regexp then filter.match(parameter.to_s)
        else filter.to_s == parameter.to_s
        end
      end
    end

    def set_uuid_primary_key
      self.error_logid = construct_uuid
    end

    # Fill in other fields regarding system status.
    def register_system
      self.process_id  = Process.pid
      self.database    = NdrError.database_identifier.call
      self.clock_drift = calculate_clock_drift
      self.hostname    = NdrError.hostname_identifier.call
    end

    # Get the drift between the app server and the database.
    def calculate_clock_drift
      time_0  = Time.current
      db_time = NdrError.database_time_checker.call
      time_1  = Time.current

      db_time ? ((db_time - time_0) + (db_time - time_1)).abs / 2 : nil
    end

    # Strip line numbers from the backtrace, and hex
    # object ids from the error message, and create
    # an MD5 hash of the resultant string for comparison.
    def calculate_md5_digest
      self.error_fingerprintid = md5_digest
    end
  end
end
