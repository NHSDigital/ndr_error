module NdrError
  # Fingerprints group together similar error occurences.
  class Fingerprint < ActiveRecord::Base
    # Pagination:
    self.per_page = 10

    self.primary_key = 'error_fingerprintid'

    has_many :error_logs,
             autosave:    true,
             class_name:  'NdrError::Log',
             foreign_key: 'error_fingerprintid'

    validate :ensure_ticket_url_matched_a_supplied_format

    default_scope do
      order("#{table_name}.updated_at DESC, #{table_name}.error_fingerprintid DESC")
    end

    def self.filter_by_keywords(keywords)
      md5_match = keywords.map do |part|
        sanitize_sql(["#{table_name}.#{primary_key} LIKE ?", "%#{part}%"])
      end.join(' OR ')

      where(md5_match)
    end

    # Gets a fingerprint record for the given
    # MD5 digest.
    def self.find_or_create_by_id(digest)
      existing = find_by_error_fingerprintid(digest)

      existing || create do |print|
        print.count = 0
        print.error_fingerprintid = digest
      end
    end

    # Optionally, NdrError can validate ticket urls:
    def ensure_ticket_url_matched_a_supplied_format
      return unless NdrError.ticket_url_format && ticket_url.present?
      errors.add(:ticket_url, 'has bad format!') if ticket_url !~ NdrError.ticket_url_format
    end

    # Remove all instances of the error, but
    # keep the fingerprint record for the future.
    def purge!
      error_logs.each(&:flag_as_deleted!)
    end

    # Saves the supplied _log_ unless there is
    # already deemed to be enough evidence.
    # Stores an updated count regardless, though.
    #
    # `bypass_limit' can be set to true in order
    # to force creation of a new log record.
    #
    def store_log(log, bypass_limit = false)
      if bypass_limit || (error_logs.count < NdrError.fingerprint_threshold)
        error_logs << log
      end

      self.count += 1
      save!

      # Don't return the log if it was discarded:
      log.new_record? ? nil : log
    end

    # Returns the record corresponding to the
    # first occurrence of this type of error.
    # Reload the association as it may
    # have been loaded by rails internally
    # and won't have default scoping applied.
    def first_occurrence
      @_first ||= error_logs.reload.last
    end

    # Returns the record corresponding to the
    # most recent occurrence of this type of
    # error. Reload the association as it may
    # have been loaded by rails internally
    # and won't have default scoping applied.
    def latest_occurrence
      @_latest ||= error_logs.reload.first
    end
  end
end
