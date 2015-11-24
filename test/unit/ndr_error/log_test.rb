require 'test_helper'

module NdrError
  # Unit Test Log.
  class LogTest < ActiveSupport::TestCase
    def setup
      Log.delete_all
      NdrError.compress_backtrace = false # For testing, we don't compress by default
    end

    test 'should flag as deleted successfully' do
      logged_error = simulate_raise(Exception, 'unknown bar', [])

      assert Log.all.include?(logged_error)

      assert_difference('logged_error.error_fingerprint.error_logs.count', -1) do
        logged_error.flag_as_deleted!

        refute Log.all.include?(logged_error)
        assert logged_error.status =~ /deleted at /
      end
    end

    test 'should hard delete properly' do
      new_error  = simulate_raise(Exception, 'unknown bar', [])
      old_error1 = simulate_raise(Exception, 'unknown bar', [])
      old_error2 = simulate_raise(Exception, 'unknown bar', [])

      new_error.flag_as_deleted!(80.days.ago)
      old_error1.flag_as_deleted!(100.days.ago)
      old_error2.flag_as_deleted!(120.days.ago)

      assert Log.perform_cleanup!
      refute Log.perform_cleanup!

      assert_raises(ActiveRecord::RecordNotFound) { Log.find(new_error.id) }
      assert_raises(ActiveRecord::RecordNotFound) { Log.find(old_error1.id) }
      assert_raises(ActiveRecord::RecordNotFound) { Log.find(old_error2.id) }

      Log.including_deleted_logs do
        assert Log.find(new_error.id)
        assert_raises(ActiveRecord::RecordNotFound) { Log.find(old_error1.id) }
        assert_raises(ActiveRecord::RecordNotFound) { Log.find(old_error2.id) }
      end
    end

    test 'should return backtrace as an array' do
      logged_error = simulate_raise(Exception, 'unknown bar', [])

      assert logged_error.backtrace.is_a?(Array)
    end

    test 'should store only a VARCHAR-length of the backtrace when not compressing' do
      refute NdrError.compress_backtrace

      logged_error = simulate_raise(Exception, 'unknown bar', [])

      logged_error.backtrace = [' ' * 900] * 3
      assert_equal 3, logged_error.backtrace.length

      trace = []
      500.times { |i| trace << "This is line #{i} of the trace:#{i} see #{i + 1}" }
      logged_error.backtrace = trace

      # The remaining 397 rows are dropped as they would overflow the column.
      assert_equal 103, logged_error.backtrace.length
    end

    test 'should store only a VARCHAR-length of the backtrace when compressing' do
      NdrError.compress_backtrace = true

      logged_error = simulate_raise(Exception, 'unknown bar', [])

      logged_error.backtrace = [' ' * 900] * 3
      assert_equal 3, logged_error.backtrace.length

      trace = []
      500.times { |i| trace << "This is line #{i} of the trace:#{i} see #{i + 1}" }
      logged_error.backtrace = trace

      # The remaining 94 rows are dropped as they would overflow the column.
      assert_equal 406, logged_error.backtrace.length
    end

    test 'should handle nested lines in backtraces' do
      logged_error = simulate_raise(Exception, 'unknown bar', [])

      logged_error.backtrace = [([' ' * 900] * 5).join("\n")]
      assert_equal 4, logged_error.backtrace.length
    end

    test 'should handle registering request=nil correctly' do
      error = Log.new
      error.register_request(nil)

      assert_equal({}, error.parameters)
    end

    test 'should store the params hash correctly when they fit in the column' do
      params1 = { a: 1 }
      params2 = { b: 2 }
      request = mock('request')
      request.stubs(
        parameters: {},
        query_parameters: params1,
        request_parameters: params2,
        remote_ip: '127.0.0.1',
        host: 'test-host',
        env: {}
      )

      error = Log.new
      error.register_request(request)

      assert_equal params1.merge(params2), error.parameters
    end

    test 'should store as much of the params hash as possible when there is too much' do
      params1 = { a: '1' * 1000, b: '3' * 100 }
      params2 = { c: '2' * 4000, d: '4' * 500 }
      request = mock('request')
      request.stubs(
        parameters: {},
        query_parameters: params1,
        request_parameters: params2,
        remote_ip: '127.0.0.1',
        host: 'test-host',
        env: {}
      )

      error = Log.new
      error.register_request(request)

      assert_equal params1.merge(d: '4' * 500), error.parameters
    end

    test 'should not store sensitive request params' do
      NdrError.filtered_parameters += [:amch, /^p\d/, :n, :p]

      params1 = { a: 1, amch: { 'sensitive' => 'password' } }
      params2 = { b: 2, n: 'bob', p: 'secret' }
      request = mock('request')
      request.stubs(
        parameters: { 'p2' => 'DANGER' },
        query_parameters: params1,
        request_parameters: params2,
        remote_ip: '127.0.0.1',
        host: 'test-host',
        env: {}
      )

      error = Log.new
      error.register_request(request)

      safe_output = {
        a: 1, b: 2, amch: '[FILTERED]', n: '[FILTERED]',
        p: '[FILTERED]', 'p2' => '[FILTERED]'
      }

      assert_equal safe_output, error.parameters
    end

    test 'should validate presence of user context' do
      logged_error = simulate_raise(Exception, 'unknown bar', [])

      logged_error.user_id = nil
      logged_error.valid?
      assert logged_error.errors[:user_id].any?, 'was no error'

      logged_error.user_id = 'Bob Jones'
      logged_error.valid?
      refute logged_error.errors[:user_id].any?, 'was still an error'
    end

    test 'should store error backtrace' do
      trace = %w( line1 line2 line3 )
      error = simulate_raise(Exception, 'boom', trace)

      assert_equal trace, error.backtrace
    end

    test 'should store error description' do
      text  = 'There was an error #123'
      error = simulate_raise(Exception, text, [])

      assert_equal text, error.description
    end

    test 'should store error missing description' do
      error = simulate_raise(Exception, '', [])

      assert_equal 'No Description available', error.description
    end

    test 'should store error type' do
      klass = RuntimeError
      error = simulate_raise(klass, 'msg', [])

      assert_equal klass.to_s, error.error_class
    end

    test 'should return most recent errors first' do
      error1 = simulate_raise(Exception, 'first error', [])
      error2 = simulate_raise(Exception, 'second error', [])
      errors = Log.all

      index1 = errors.index(error1)
      index2 = errors.index(error2)

      assert index2 < index1
      assert_equal error2, Log.first
    end

    test 'should store default for database if not configured' do
      error = simulate_raise(Exception, 'Not found: 123', [])
      assert_equal 'unknown database', error.database
    end

    test 'should store the database name if configured to do so' do
      begin
        original_database_identifier = NdrError.database_identifier
        NdrError.database_identifier = -> { 'SQLite test DB' }

        error = simulate_raise(Exception, 'Not found: 123', [])
        assert_equal 'SQLite test DB', error.database
      ensure
        NdrError.database_identifier = original_database_identifier
      end
    end

    test 'should store default for hostname if not configured' do
      error = simulate_raise(Exception, 'Not found: 123', [])
      assert_equal 'unknown host', error.hostname
    end

    test 'should store the hostname if configured to do so' do
      begin
        original_hostname_identifier = NdrError.hostname_identifier
        NdrError.hostname_identifier = -> { 'Dummy Host' }

        error = simulate_raise(Exception, 'Not found: 123', [])
        assert_equal 'Dummy Host', error.hostname
      ensure
        NdrError.hostname_identifier = original_hostname_identifier
      end
    end

    test 'should set the PID on create' do
      error = simulate_raise(Exception, 'Not found: 123', [])

      assert_equal Process.pid, error.process_id
    end

    test 'should not calculate clock drift without configuration' do
      error = simulate_raise(Exception, 'Not found: 123', [])
      assert_equal nil, error.clock_drift
    end

    test 'should auto-calculate clock drift on create when configured' do
      begin
        # For DB clock drift checking:
        NdrError.database_time_checker = lambda do
          stamp = ActiveRecord::Base.connection.execute('select CURRENT_TIMESTAMP')[0][0]
          Time.zone.parse(stamp) + Time.zone.utc_offset
        end

        error = simulate_raise(Exception, 'Not found: 123', [])
        assert error.clock_drift.is_a?(Numeric)
        assert !error.clock_drift.zero? # what are the chances!
      ensure
        NdrError.database_time_checker = -> { nil }
      end
    end

    test 'should have clock_drift? if the drift is >= 3' do
      error = simulate_raise(Exception, 'Not found: 123', [])
      error.stubs(clock_drift: 3)

      assert error.clock_drift?
    end

    test 'should not have clock_drift? if the drift is < 3' do
      error = simulate_raise(Exception, 'Not found: 123', [])
      error.stubs(clock_drift: 2.9)

      assert !error.clock_drift?
    end

    test 'should set a UUID primary key only on create' do
      error = simulate_raise(Exception, 'Not found: 123', [])
      uuid  = error.id
      assert_equal 36, uuid.length

      error.save!
      assert_equal uuid, error.id
    end

    test 'should MD5 based on fuzzy description and backtrace' do
      error1 = simulate_raise(Exception, 'Not found: 123', ['foo:23:in baz', 'bar:45:in baz'])
      error2 = simulate_raise(Exception, 'Not found: 456', ['foo:4:in baz', 'bar:6:in baz'])
      error3 = simulate_raise(Exception, 'Dot round: 456', ['foo:4:in bar', 'bar:6:in bar'])

      assert error1.error_fingerprintid == error2.error_fingerprintid
      assert error2.error_fingerprintid != error3.error_fingerprintid
    end

    test 'should not find error similar to itself' do
      error = simulate_raise(Exception, 'boom', [])
      refute error.similar_errors.index(error)
    end

    test 'should find similar identical errors' do
      error1 = simulate_raise(Exception, 'Not found: 123', [])
      error2 = simulate_raise(Exception, 'Not found: 123', [])
      error3 = simulate_raise(Exception, 'Not found: 123', [])

      assert_equal [error3, error2], error1.similar_errors
      assert_equal [error3, error1], error2.similar_errors
      assert_equal [error2, error1], error3.similar_errors

      assert error1.previous.nil?
      assert_equal error2, error1.next
      assert_equal error1, error2.previous
      assert_equal error3, error2.next
      assert_equal error2, error3.previous
      assert error3.next.nil?
    end

    test 'should find similar errors with only numerically differing descriptions' do
      error1 = simulate_raise(Exception, 'Not found: 123', [])
      error2 = simulate_raise(Exception, 'Not found: 456', [])
      error3 = simulate_raise(Exception, 'Not found: 123, sorry!', [])
      error4 = simulate_raise(Exception, 'Not found: 456, sorry!', [])

      assert_equal [error2], error1.similar_errors
      assert_equal [error1], error2.similar_errors
      assert_equal [error4], error3.similar_errors
      assert_equal [error3], error4.similar_errors
    end

    test 'should not find similar errors with textually differing descriptions' do
      error1 = simulate_raise(Exception, 'Not found: 123', [])
      error2 = simulate_raise(Exception, 'Dot round: 123', [])

      assert error1.similar_errors.blank?
      assert error2.similar_errors.blank?
    end

    test 'should not find similar errors with different backtraces' do
      error1 = simulate_raise(Exception, 'Not found: 123', %w( foo bar ))
      error2 = simulate_raise(Exception, 'Not found: 123', %w( bar baz ))
      error3 = simulate_raise(Exception, 'Not found: 456', %w( baz foo ))

      assert error1.similar_errors.blank?
      assert error2.similar_errors.blank?
      assert error3.similar_errors.blank?
    end

    test 'should find similar errors with same backtraces' do
      error1 = simulate_raise(Exception, 'Not found: 123', %w( foo bar ))
      error2 = simulate_raise(Exception, 'Not found: 123', %w( foo bar ))
      error3 = simulate_raise(Exception, 'Not found: 456', %w( foo bar ))

      assert_equal [error3, error2], error1.similar_errors
      assert_equal [error3, error1], error2.similar_errors
      assert_equal [error2, error1], error3.similar_errors
    end

    test 'should find similar errors with similar backtraces' do
      error1 = simulate_raise(Exception, 'Not found: 123', ['foo:12:in baz', 'bar:34:in baz'])
      error2 = simulate_raise(Exception, 'Not found: 123', ['foo:23:in baz', 'bar:45:in baz'])
      error3 = simulate_raise(Exception, 'Not found: 456', ['foo:4:in baz', 'bar:6:in baz'])

      assert_equal [error3, error2], error1.similar_errors
      assert_equal [error3, error1], error2.similar_errors
      assert_equal [error2, error1], error3.similar_errors
    end

    test 'should extract app trace using Rails.root' do
      app   = Rails.root.basename
      error = simulate_raise(Exception, 'msg', %W( bob/#{app}/foo bob/bar bob/#{app}/baz ))
      assert_equal %W( bob/#{app}/foo bob/#{app}/baz ), error.application_trace

      error = simulate_raise(Exception, 'msg', %w( deploy/shared/bar deploy/current/baz ))
      assert_equal %w( deploy/current/baz ), error.application_trace

      error = simulate_raise(Exception, 'msg', %w( deploy/releases/20150101 deploy/current/baz ))
      assert_equal %w( deploy/releases/20150101 deploy/current/baz ), error.application_trace

      error = simulate_raise(Exception, 'msg', %W( bob/gems/ndr_support bob/#{app}/foo ))
      assert_equal %W( bob/gems/ndr_support bob/#{app}/foo ), error.application_trace

      # ndr_* gems shouldn't get lumped in with 3rd-party gems:
      error = simulate_raise(Exception, 'msg', %w( bob/gems/ndr_support bob/gems/rails foo ))
      assert_equal %w( bob/gems/ndr_support ), error.application_trace

      # With nothing in the application, fall back to anything non gem-like:
      error = simulate_raise(Exception, 'msg', %w( bob/gems/rails foo ))
      assert_equal %w( foo ), error.application_trace
    end

    test 'should extract remote app trace with fallback' do
      app = Rails.root.basename

      # We don't need the fallback, so include those matches:
      error = simulate_raise(Exception, 'msg', %W( bob/#{app}/foo bob/gems/bar ))
      assert_equal %W( bob/#{app}/foo ), error.application_trace

      # Now we do need a fallback:
      error = simulate_raise(Exception, 'msg', %w( bob/local-app-copy/foo bob/gems/bar ))
      assert_equal %w( bob/local-app-copy/foo ), error.application_trace
    end
  end
end
