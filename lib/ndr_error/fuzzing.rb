module NdrError
  # Mixin to help with fuzzing of exception messages/traces.
  module Fuzzing
    def fuzz(description, backtrace)
      Digest::MD5.hexdigest(fuzz_description(description) + fuzz_backtrace(backtrace))
    end

    private

    # Prepare a fuzzed description:
    def fuzz_description(description)
      # Apply the fuzzers sequentially:
      NdrError.description_fuzzers.inject(description) { |a, e| e.call(a) }
    end

    # Fuzz a backtrace:
    #   * independent of deployment paths
    #   * independent of line numbers
    def fuzz_backtrace(backtrace)
      backtrace.map { |line| fuzz_line(line) }.join("\n")
    end

    def fuzz_line(line)
      line = line.sub(Rails.root.to_s, 'Rails.root')

      # Remove gem version numbers from backtrace
      line.sub!(Regexp.new('/gems/([^/]*-)[0-9][0-9.]*/'), '/gems/\1/')

      # Remove GEM_PATH / LOAD_PATH differences:
      sub_paths!(line)

      # Remove Rails compiled callback & template identifiers:
      line.gsub!(Regexp.new('___?[0-9][0-9_]*[0-9]'), '__COMPILED_ID')

      # Remove line numbers:
      line.gsub!(/:(\d+):/, '')

      line
    end

    def sub_paths!(line)
      Gem.path.each do |path|
        line.sub!(Regexp.new('^' + Regexp.escape(path)), 'Gem.path')
      end

      $LOAD_PATH.each do |path|
        line.sub!(Regexp.new('^' + Regexp.escape(path)), '$LOAD_PATH')
      end
    end
  end
end
