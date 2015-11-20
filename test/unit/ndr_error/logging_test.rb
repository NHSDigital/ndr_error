require 'test_helper'

module NdrError
  # Test our logging helper:
  class LoggingTest < ActiveSupport::TestCase
    include NdrError::Logging

    test 'should log errors from context' do
      issue = exception('Not found: 123', ['foo:23:in baz', 'bar:45:in baz'])

      print1, log1 = log(issue, { user_id: 'Bob' }, nil)
      print2, log2 = log(issue, { user_id: 'Sam' }, nil)

      assert print1 == print2
      refute log1 == log2

      assert_equal 'Bob', log1.user_id
      assert_equal 'Sam', log2.user_id
    end

    test 'should protect from mass-assignment' do
      failure = assert_raises(RuntimeError) { log(Exception.new, { clock_drift: 0 }, nil) }
      assert failure.message =~ /Mass-assigning/
    end

    private

    def exception(message, backtrace = [])
      Exception.new(message).tap { |ex| ex.set_backtrace(backtrace) }
    end
  end
end
