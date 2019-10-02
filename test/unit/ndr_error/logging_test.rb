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

    test 'should trigger logging callbacks if provided' do
      params1 = nil
      params2 = nil
      callback1 = NdrError.after_log { |*args| params1 = args }
      callback2 = NdrError.after_log { |*args| params2 = args }

      issue = exception('boom')
      print, error_log = log(issue, { user_id: 'Bob' }, nil)

      assert_equal issue, params1[0]
      assert_equal print, params1[1]
      assert_equal error_log, params1[2]

      assert_equal params1, params2
    ensure
      NdrError._after_log_callbacks.delete(callback1)
      NdrError._after_log_callbacks.delete(callback2)
    end

    test 'should monitor in block form' do
      assert_difference(-> { Fingerprint.count }) do
        assert_raises do
          monitor { raise 'oops' }
        end
      end

      assert_difference(-> { Fingerprint.count }) do
        print, log = monitor(swallow: true) { raise 'oops' }
        assert print.is_a? Fingerprint
        assert log.is_a? Log
      end
    end

    test 'should capture causal information as related fingerprints' do
      trigger = -> { [].foo }
      params  = { user_id: 'Bob' }

      solo_print, = monitor(swallow: true, request: nil, ancillary_data: params) { trigger.call }

      assert_difference(-> { Fingerprint.count }, 2) do
        1 / 0
      rescue StandardError
        begin
          trigger.call
        rescue StandardError => e
          print, log = log(e, params, nil)
          cause = print.causal_error_fingerprint

          refute_equal solo_print.id, print.id, 'cause should have been factored'

          assert log.is_a? Log
          assert_equal 'NoMethodError', log.error_class
          assert_equal 'Bob', log.user_id

          assert cause.is_a? Fingerprint
          refute_equal cause, print
          assert cause.caused_error_fingerprints.include?(print)

          cause_log = cause.error_logs.first
          assert cause_log.is_a? Log
          assert_equal 'ZeroDivisionError', cause_log.error_class
          assert_equal 'Bob', cause_log.user_id
        end
      end
    end

    private

    def exception(message, backtrace = [])
      Exception.new(message).tap { |ex| ex.set_backtrace(backtrace) }
    end
  end
end
