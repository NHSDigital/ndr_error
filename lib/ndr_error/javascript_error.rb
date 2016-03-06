module NdrError
  class JavascriptError < Exception
    attr_reader :source

    def initialize(parameters)
      @source = parameters.with_indifferent_access

      super(@source['message'])

      set_backtrace_from_stack
    end

    def metadata
      source.except('message', 'stack')
    end

    private

    def set_backtrace_from_stack
      set_backtrace @source.fetch('stack', '').split("\n")
    end
  end
end