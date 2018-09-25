require 'test_helper'

module NdrError
  # Unit test Fingerprint.
  class FingerprintTest < ActiveSupport::TestCase
    test 'should not validate a blank ticket url' do
      with_ticket_url_regexp_as(%r{it/must/be/this}) do
        assert valid_ticket_url?('')
      end
    end

    test 'should not validate ticket url without format' do
      with_ticket_url_regexp_as(nil) do
        assert valid_ticket_url?('')
        assert valid_ticket_url?('this/is/ok')
      end
    end

    test 'should validate the ticket url with format supplied' do
      regexp = %r{https://github.com/PublicHealthEngland/ndr_error/issues/\d+}

      with_ticket_url_regexp_as(regexp) do
        valid_urls = %w[
          https://github.com/PublicHealthEngland/ndr_error/issues/1
          https://github.com/PublicHealthEngland/ndr_error/issues/22
        ]

        valid_urls.each { |url| assert valid_ticket_url?(url) }

        invalid_urls = %w[
          https://github.com/PublicHealthEngland/ndr_error/issues
          https://google.com
        ]

        invalid_urls.each { |url| refute valid_ticket_url?(url) }
      end
    end

    test 'should find_or_create_by_id correctly' do
      md5   = Digest::MD5.hexdigest('something')
      md5_2 = Digest::MD5.hexdigest('something else')
      first = nil
      other = nil

      assert_difference('Fingerprint.count') do
        first = Fingerprint.find_or_create_by_id(md5)
      end
      assert_equal md5, first.id

      assert_no_difference('Fingerprint.count') do
        other = Fingerprint.find_or_create_by_id(md5)
      end
      assert_equal first, other

      assert_difference('Fingerprint.count') do
        Fingerprint.find_or_create_by_id(md5_2)
      end
    end

    test 'should store error logs properly if below threshold' do
      error = build_error
      print = create_fingerprint(error.md5_digest)

      assert_difference('Log.count') do
        assert_difference('print.count') do
          log = print.store_log(error)

          refute error.new_record?
          assert_equal error, log
        end
      end
    end

    test 'should not store error logs if above threshold' do
      error = build_error
      print = create_fingerprint(error.md5_digest)
      NdrError.stubs(fingerprint_threshold: 1)
      assert print.store_log(error.dup)

      assert_no_difference('Log.count') do
        assert_difference('print.count') do
          log = print.store_log(error)

          assert error.new_record?
          assert log.nil?
        end
      end
    end

    test 'should store error logs if above threshold because of soft deletes' do
      error = build_error
      print = create_fingerprint(error.md5_digest)
      NdrError.stubs(fingerprint_threshold: 1)
      assert print.store_log(error.dup)

      print.purge!

      assert_difference('Log.count') do
        assert_difference('print.count') do
          log = print.store_log(error)

          refute error.new_record?
          assert_equal error, log
        end
      end
    end

    test 'should purge logs correctly' do
      error1  = simulate_raise(Exception, 'the error 1', [])
      _error2 = simulate_raise(Exception, 'the error 2', [])
      _error3 = simulate_raise(Exception, 'the error 3', [])
      print   = error1.error_fingerprint

      assert_equal 3, print.count
      assert_equal 3, print.error_logs.not_deleted.count
      assert_equal 0, print.error_logs.deleted.count

      print.purge!

      assert_equal 3, print.count
      assert_equal 0, print.error_logs.not_deleted.count
      assert_equal 3, print.error_logs.deleted.count
    end

    test 'should find earliest/latest occurrence correctly' do
      error1 = simulate_raise(Exception, 'Not found: 123', ['foo:23:in baz', 'bar:45:in baz'])
      error2 = simulate_raise(Exception, 'Not found: 456', ['foo:4:in baz', 'bar:6:in baz'])
      error3 = simulate_raise(Exception, 'Dot round: 123', ['foo:23:in baz', 'bar:45:in baz'])
      error4 = simulate_raise(Exception, 'Dot round: 456', ['foo:4:in baz', 'bar:6:in baz'])
      print1 = error1.error_fingerprint
      print2 = error3.error_fingerprint

      assert_equal error1, print1.first_occurrence
      assert_equal error2, print1.latest_occurrence

      assert_equal error3, print2.first_occurrence
      assert_equal error4, print2.latest_occurrence

      print1.purge!

      assert_nil print1.first_occurrence
      assert_nil print1.latest_occurrence
    end

    private

    def with_ticket_url_regexp_as(regexp, &block)
      with_config(:ticket_url_format, regexp, &block)
    end

    def valid_ticket_url?(url)
      Fingerprint.new { |print| print.ticket_url = url }.valid?
    end

    def build_error
      build_custom_error(Exception, 'message', [])
    end
  end
end
