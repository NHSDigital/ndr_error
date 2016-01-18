module NdrError
  # Mixin to help compressing/expanding stored backtraces.
  module BacktraceCompression
    # Attempts to return just the "application" trace, so we can
    # highlight "our" code vs. 3rd-party libraries.
    def application_trace
      app_trace = backtrace.select do |line|
        app = line =~ %r{/(#{Rails.root.basename}|current|releases)/}
        ndr = line =~ %r{/gems/ndr_}

        app || ndr
      end

      app_trace = backtrace.reject { |line| line =~ %r{/gems/} } if app_trace.blank?
      app_trace
    end

    # Returns the backtrace as an array.
    def backtrace
      inflate_backtrace(lines)
    end

    # Stores as much of the backtrace as is possible in a string.
    # Splits out any nested lines, e.g. TemplateError backtrace.
    def backtrace=(trace)
      array = trace ? trace.dup : []
      array = array.map { |line| line.split("\n") }.flatten
      dump  = deflate_backtrace(array)

      while dump.length >= 4000
        array.pop
        dump = deflate_backtrace(array)
      end

      self.lines = dump
    end

    private

    # Helper for wrapping the lines column, enables
    # the backtrace to be returned as an array rather
    # that as the stored string. If compression is enabled,
    # will decompress the string before returing the array.
    def inflate_backtrace(data)
      string = data || ''

      if NdrError.compress_backtrace
        data = Base64.decode64(string)
        begin
          string = Zlib::Inflate.inflate(data)
        rescue
          Rails.logger.warn('NdrError: failed to inflate backtrace!')
        end
      end

      string.split("\n")
    end

    # Type conversion helper, so backtrace can be assigned
    # as an array and saved as a string. If compression is
    # enabled, this method will compress the string too.
    def deflate_backtrace(lines)
      string = lines.join("\n")

      if NdrError.compress_backtrace
        data   = Zlib::Deflate.deflate(string)
        string = Base64.encode64(data)
      end

      string
    end
  end
end
